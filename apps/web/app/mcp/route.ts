// Phase 3 — the authenticated, multi-tenant MCP front door (HTTP transport).
//
// Flow: an AI client (Claude, Cursor, …) authenticates with Clerk via OAuth, gets a machine
// token, and sends it as a Bearer token to POST /mcp. `withMcpAuth` + `verifyClerkToken`
// validate that token; the resulting Clerk user id is turned into a real Valgate Ctx by
// ctxFromMcpAuth(). From there the SAME tool + resources as the stdio server run — org-scoping
// and role checks come for free from the service layer.
//
// Clerk OAuth tokens are "machine tokens" (free during Clerk's public beta, priced later).
// Discovery metadata lives at /.well-known/oauth-protected-resource/mcp (see that route).
import { auth } from "@clerk/nextjs/server";
import { verifyClerkToken } from "@clerk/mcp-tools/next";
import { createMcpHandler, experimental_withMcpAuth as withMcpAuth } from "mcp-handler";
import { registerValgateMcp } from "@/mcp-server/register";
import { ctxFromMcpAuth } from "@/mcp-server/ctxFor";
import {
  isClientAllowed,
  isUnboundEndpointAllowed,
  parseClientAllowlist,
} from "@/mcp-server/clientAllowlist";
import { env } from "@/lib/env";
import { mcpLimiter, allowed } from "@/lib/ratelimit";

// This route hits the database per request and reads request auth — never statically prerender.
export const dynamic = "force-dynamic";

// M1 — audience binding via an OAuth client allowlist.
//
// Important reality about Clerk OAuth tokens: they are bound to the Clerk *instance*, NOT to this
// specific /mcp resource. `verifyClerkToken` (and Clerk's token verification underneath it) only
// confirm the token is a valid OAuth token in our instance and hand back its clientId, scopes, and
// userId — they do NOT check that the token was minted for THIS server (there is no audience/
// resource claim to match). So without this check, any OAuth client registered in our Clerk
// instance could call /mcp. Since Clerk gives us the token's `clientId`, the way to bind explicitly
// is to allowlist the client ids we trust.
//
// Behaviour (the pure allowlist decision lives in @/mcp-server/clientAllowlist, unit-tested there):
//   - MCP_ALLOWED_OAUTH_CLIENT_IDS set   → only those client ids are accepted; others get 401.
//   - MCP_ALLOWED_OAUTH_CLIENT_IDS unset → the endpoint is UNBOUND (any client in the instance). We
//     handle that case by environment, so an unbound endpoint is never a silent production accident:
//       · production → FAIL CLOSED (reject all) UNLESS MCP_ALLOW_ANY_OAUTH_CLIENT=true, the explicit
//         "run open for Dynamic Client Registration" opt-in (DCR mints fresh client ids we can't
//         allowlist ahead of time). This mirrors CRON_SECRET: unset means locked, never open.
//       · dev/test → accept any client with a warning, so local testing is never blocked.
function isOAuthClientAllowed(clientId: string | undefined): boolean {
  const allowlist = parseClientAllowlist(env.MCP_ALLOWED_OAUTH_CLIENT_IDS);
  if (allowlist.length === 0) {
    const isProduction = process.env.NODE_ENV === "production";
    if (!isUnboundEndpointAllowed(isProduction, env.MCP_ALLOW_ANY_OAUTH_CLIENT)) {
      // No allowlist AND no explicit open-mode opt-in, in production → refuse. The operator must
      // consciously choose: set MCP_ALLOWED_OAUTH_CLIENT_IDS, or set MCP_ALLOW_ANY_OAUTH_CLIENT=true.
      console.error(
        "[valgate-mcp] /mcp is unbound in production and MCP_ALLOW_ANY_OAUTH_CLIENT is not set — rejecting. Set MCP_ALLOWED_OAUTH_CLIENT_IDS to allowlist clients, or MCP_ALLOW_ANY_OAUTH_CLIENT=true to run open for DCR.",
      );
      return false;
    }
    console.warn(
      "[valgate-mcp] MCP_ALLOWED_OAUTH_CLIENT_IDS is not set — /mcp accepts any Clerk OAuth client in this instance. Set it to bind /mcp to specific clients.",
    );
    return true;
  }
  return isClientAllowed(clientId, allowlist);
}

// Cache pre-dispatch authentication by request so withMcpAuth can keep owning the established
// invalid-token response without verifying an allowed request twice.
const authenticatedRequests = new WeakMap<object, Awaited<ReturnType<typeof verifyClerkToken>>>();

async function authenticate(request: Request, token: string | undefined) {
  const cached = authenticatedRequests.get(request);
  if (cached) return cached;

  const clerkAuth = await auth({ acceptsToken: "oauth_token" });
  const authInfo = await verifyClerkToken(clerkAuth, token);
  if (!authInfo || !isOAuthClientAllowed(authInfo.clientId)) {
    if (authInfo) {
      console.error(
        "[valgate-mcp] rejecting token from non-allowlisted OAuth client:",
        authInfo.clientId,
      );
    }
    return undefined;
  }

  authenticatedRequests.set(request, authInfo);
  return authInfo;
}

// Build the MCP server for each request, wiring the shared tool/resources to the AUTHENTICATED
// caller. The Clerk user id rides in extra.authInfo.extra.userId (set by verifyClerkToken below).
const handler = createMcpHandler((server) => {
  registerValgateMcp(server, async (extra, options) => {
    const userId = extra.authInfo?.extra?.userId as string | undefined;
    if (!userId) {
      // Should never happen when withMcpAuth requires a valid token, but fail closed.
      throw new Error("unauthenticated");
    }
    // Reads pass no options (primary-org default); writes pass requestedOrgId + requireExplicitOrg.
    return ctxFromMcpAuth(userId, {
      requestedOrgId: options?.requestedOrgId,
      requireExplicitOrg: options?.requireExplicitOrg,
    });
  });
});

// Wrap the handler so only requests carrying a valid Clerk OAuth token reach the tools.
// `auth({ acceptsToken: 'oauth_token' })` parses the incoming Bearer token as a Clerk OAuth
// (machine) token; verifyClerkToken confirms it is a valid OAuth token in our Clerk instance and
// extracts the clientId, scopes, and user id. It does NOT verify the token was issued for THIS
// specific server (Clerk tokens carry no audience/resource claim) — so we add an explicit client
// allowlist check below (see isOAuthClientAllowed). Returning undefined from this verifier yields
// 401 + a WWW-Authenticate header that points clients at the protected-resource metadata to start
// the OAuth flow.
const authHandler = withMcpAuth(
  handler,
  async (req, token) => {
    return authenticate(req, token);
  },
  {
    required: true,
    resourceMetadataPath: "/.well-known/oauth-protected-resource/mcp",
  },
);

// Authenticate and decide the per-user limit before handing the request to mcp-handler. This is
// the dispatch boundary: rejected traffic must not run a tool and merely have its result replaced.
async function withRateLimit(request: Request): Promise<Response> {
  const authorization = request.headers.get("Authorization") ?? "";
  const [scheme, token] = authorization.split(" ");
  const bearer = scheme.toLowerCase() === "bearer" ? token : undefined;
  const authInfo = await authenticate(request, bearer);

  // Let withMcpAuth produce its established 401 response and WWW-Authenticate metadata.
  if (!authInfo) return authHandler(request);

  const userId = authInfo.extra?.userId as string | undefined;
  if (userId && !(await allowed(mcpLimiter, userId))) {
    console.warn("[valgate-mcp] rate limit exceeded for user:", userId);
    return new Response(
      JSON.stringify({ error: "rate_limit_exceeded", retry_after_seconds: 60 }),
      {
        status: 429,
        headers: {
          "Content-Type": "application/json",
          "Retry-After": "60",
        },
      },
    );
  }
  return authHandler(request);
}

export { withRateLimit as GET, withRateLimit as POST };
