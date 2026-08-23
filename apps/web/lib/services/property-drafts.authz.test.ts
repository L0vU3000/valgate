import { describe, it, expect, vi, beforeEach } from "vitest";
import { PgDialect } from "drizzle-orm/pg-core";
import type { Ctx } from "@/lib/services/_mapping";

vi.mock("server-only", () => ({}));

// ---------------------------------------------------------------------------
// property-drafts cross-org authorization: regression tests for the already-shipped
// P0 fix. createPropertyDraft / updatePropertyDraft now call assertOrgAdmin(ctx,
// targetOrgId) ONLY when a targetOrgId is supplied AND differs from ctx.orgId — so a
// plain member can still create/update drafts in their OWN org, but writing into a
// different org first requires org-admin rights in that target org.
//
// Everything below the service is mocked — no live DB, no credentials, deterministic:
//   * @/lib/services/_crud   — assertOrgAdmin / scopedInsert / requireMember are
//     spies that record call ORDER into a shared array, so we can prove the admin
//     check runs BEFORE the write (and, when it throws, that the write never runs).
//   * @/lib/db/client        — a faithful Drizzle update chain; its WHERE is rendered
//     to { sql, params } via the real PgDialect so we can prove the org scope binds
//     the right org value.
//   * @/lib/db/column-classifier — convertRowToDb/convertRowToDomain are identity so
//     the mapping layer neither needs the real schema nor a real row shape.
//
// Proves:
//   1) cross-org create invokes assertOrgAdmin(ctx, targetOrgId) BEFORE the cross-org
//      insertion, and that insertion carries the { orgId: targetOrgId } override; if the
//      admin check throws, no insert is issued.
//   2) cross-org update invokes assertOrgAdmin(ctx, targetOrgId) BEFORE the DB update
//      (which is scoped to targetOrgId); if the admin check throws, no update is issued.
//   3) own-org create/update (no targetOrgId, or targetOrgId === ctx.orgId) do NOT
//      invoke assertOrgAdmin — preserving the plain-member write path.
// ---------------------------------------------------------------------------

const dialect = new PgDialect();

// Render a real Drizzle WHERE condition to { sql, params } exactly as the driver would
// before sending it to Postgres — no hand-parsing of Drizzle internals.
function render(cond: unknown): { sql: string; params: unknown[] } {
  const q = (dialect as unknown as {
    sqlToQuery: (c: unknown) => { sql: string; params: unknown[] };
  }).sqlToQuery(cond);
  return { sql: q.sql, params: q.params };
}

const store = vi.hoisted(() => ({
  // Global chronological log of the guarded side effects, in the order they fire.
  callOrder: [] as string[],
  // When true, the mocked assertOrgAdmin rejects (simulates "not an admin in target org").
  assertOrgAdminRejects: false,
  // Recorded DB update chain activity.
  updateCalls: 0,
  updateWheres: [] as { sql: string; params: unknown[] }[],
  updateSets: [] as Record<string, unknown>[],
  selectCalls: 0,
}));

vi.mock("@/lib/env", () => ({
  env: {
    DATABASE_URL: "postgresql://mock-property-drafts-authz-tests-only",
    DEMO_MODE: false,
    DEMO_ALLOW_WRITES: false,
  },
}));

// Identity mapping — the service's rowToDraft() just reads fields straight off the row,
// so no real schema/row shape is needed to exercise the authorization branches.
vi.mock("@/lib/db/column-classifier", () => ({
  convertRowToDb: (_table: unknown, row: Record<string, unknown>) => ({ ...row }),
  convertRowToDomain: (_table: unknown, row: Record<string, unknown>) => ({ ...row }),
}));

vi.mock("@/lib/services/_crud", () => ({
  // Ordered spies for the two guarded operations under test.
  assertOrgAdmin: vi.fn(async () => {
    store.callOrder.push("assertOrgAdmin");
    if (store.assertOrgAdminRejects) throw new Error("forbidden");
  }),
  scopedInsert: vi.fn(
    async (
      _ctx: Ctx,
      _table: unknown,
      _prefix: string,
      input: { title: string; step: number; form: Record<string, unknown> },
    ) => {
      store.callOrder.push("scopedInsert");
      return { id: "DRFT-0001", title: input.title, step: input.step, form: input.form, updatedAt: 1 };
    },
  ),
  // requireMember is a no-op here: the role gate is orthogonal to the cross-org check we
  // are pinning, and a plain member already passes it.
  requireMember: vi.fn(),
  // Unused by property-drafts but imported by its sibling services (documents/properties)
  // which load transitively; provide harmless stubs so those imports resolve.
  requireAdmin: vi.fn(),
  scopedUpdate: vi.fn(),
  scopedDelete: vi.fn(),
}));

vi.mock("@/lib/db/client", () => {
  const db = {
    update: () => {
      store.callOrder.push("db.update");
      store.updateCalls += 1;
      return {
        set: (vals: Record<string, unknown>) => {
          store.updateSets.push(vals);
          return {
            where: (cond: unknown) => {
              store.updateWheres.push(render(cond));
              return {
                returning: () =>
                  Promise.resolve([
                    { id: "DRFT-0001", title: vals.title ?? "t", step: vals.step ?? 1, form: vals.form ?? {}, updatedAt: 2 },
                  ]),
              };
            },
          };
        },
      };
    },
    select: () => {
      store.callOrder.push("db.select");
      store.selectCalls += 1;
      return {
        from: () => ({
          where: (cond: unknown) => {
            store.updateWheres.push(render(cond));
            return {
              orderBy: () => {
                return Object.assign(Promise.resolve([] as unknown[]), {
                  limit: () => Promise.resolve([] as unknown[]),
                }) as Promise<unknown[]> & { limit: () => Promise<unknown[]> };
              },
            };
          },
        }),
      };
    },
    delete: () => {
      store.callOrder.push("db.delete");
      return {
        where: (cond: unknown) => {
          store.updateWheres.push(render(cond));
          return Promise.resolve(1);
        },
      };
    },
  };
  return { db };
});

import { createPropertyDraft, updatePropertyDraft, listPropertyDrafts, convertDraftToDocumentsForOrg } from "./property-drafts";
import { assertOrgAdmin, scopedInsert } from "@/lib/services/_crud";

const CTX: Ctx = { userId: "USR-0001", orgId: "ORG-0001", orgRole: "member" };
const TARGET_ORG = "ORG-CLIENT-0002";

beforeEach(() => {
  store.callOrder.length = 0;
  store.assertOrgAdminRejects = false;
  store.updateCalls = 0;
  store.updateWheres.length = 0;
  store.updateSets.length = 0;
  store.selectCalls = 0;
  vi.mocked(assertOrgAdmin).mockClear();
  vi.mocked(scopedInsert).mockClear();
});

describe("createPropertyDraft — cross-org authorization", () => {
  it("asserts org-admin in the target org BEFORE the cross-org insert", async () => {
    await createPropertyDraft(
      CTX,
      { title: "Client tower", step: 1, form: {} },
      TARGET_ORG,
    );

    // The admin check ran, keyed on (ctx, targetOrgId)...
    expect(assertOrgAdmin).toHaveBeenCalledTimes(1);
    expect(assertOrgAdmin).toHaveBeenCalledWith(CTX, TARGET_ORG);
    // ...strictly before the insert...
    expect(store.callOrder).toEqual(["assertOrgAdmin", "scopedInsert"]);
    // ...and the insert targets the OTHER org via the { orgId: targetOrgId } override.
    expect(scopedInsert).toHaveBeenCalledTimes(1);
    const extra = vi.mocked(scopedInsert).mock.calls[0]![5];
    expect(extra).toEqual({ orgId: TARGET_ORG });
  });

  it("does not insert when the target-org admin check fails (gate, not just an ordering)", async () => {
    store.assertOrgAdminRejects = true;

    await expect(
      createPropertyDraft(CTX, { title: "Client tower", step: 1, form: {} }, TARGET_ORG),
    ).rejects.toThrow("forbidden");

    expect(assertOrgAdmin).toHaveBeenCalledTimes(1);
    expect(scopedInsert).not.toHaveBeenCalled();
    expect(store.callOrder).toEqual(["assertOrgAdmin"]);
  });
});

describe("createPropertyDraft — own-org (member) path", () => {
  it("does NOT assert org-admin when no targetOrgId is supplied", async () => {
    await createPropertyDraft(CTX, { title: "My draft", step: 1, form: {} });

    expect(assertOrgAdmin).not.toHaveBeenCalled();
    expect(scopedInsert).toHaveBeenCalledTimes(1);
    // No org override — scopedInsert stamps ctx.orgId itself.
    expect(vi.mocked(scopedInsert).mock.calls[0]![5]).toBeUndefined();
    expect(store.callOrder).toEqual(["scopedInsert"]);
  });

  it("does NOT assert org-admin when targetOrgId equals ctx.orgId", async () => {
    await createPropertyDraft(CTX, { title: "My draft", step: 1, form: {} }, CTX.orgId);

    expect(assertOrgAdmin).not.toHaveBeenCalled();
    expect(scopedInsert).toHaveBeenCalledTimes(1);
    expect(store.callOrder).toEqual(["scopedInsert"]);
  });
});

describe("updatePropertyDraft — cross-org authorization", () => {
  it("asserts org-admin in the target org BEFORE the DB update, scoped to the target org", async () => {
    await updatePropertyDraft(CTX, "DRFT-0001", { title: "renamed" }, TARGET_ORG);

    expect(assertOrgAdmin).toHaveBeenCalledTimes(1);
    expect(assertOrgAdmin).toHaveBeenCalledWith(CTX, TARGET_ORG);
    // The admin check strictly precedes the UPDATE.
    expect(store.callOrder).toEqual(["assertOrgAdmin", "db.update"]);
    expect(store.updateCalls).toBe(1);

    // The UPDATE is scoped to the TARGET org (and this user + this id), not ctx.orgId.
    expect(store.updateWheres).toHaveLength(1);
    const w = store.updateWheres[0]!;
    expect(w.sql).toContain("org_id");
    expect(w.params).toContain(TARGET_ORG);
    expect(w.params).toContain(CTX.userId);
    expect(w.params).toContain("DRFT-0001");
    expect(w.params).not.toContain(CTX.orgId);
  });

  it("does not update when the target-org admin check fails (gate, not just an ordering)", async () => {
    store.assertOrgAdminRejects = true;

    await expect(
      updatePropertyDraft(CTX, "DRFT-0001", { title: "renamed" }, TARGET_ORG),
    ).rejects.toThrow("forbidden");

    expect(assertOrgAdmin).toHaveBeenCalledTimes(1);
    expect(store.updateCalls).toBe(0);
    expect(store.updateWheres).toHaveLength(0);
    expect(store.callOrder).toEqual(["assertOrgAdmin"]);
  });
});

describe("updatePropertyDraft — own-org (member) path", () => {
  it("does NOT assert org-admin when no targetOrgId is supplied, and scopes the update to ctx.orgId", async () => {
    await updatePropertyDraft(CTX, "DRFT-0001", { title: "renamed" });

    expect(assertOrgAdmin).not.toHaveBeenCalled();
    expect(store.callOrder).toEqual(["db.update"]);
    expect(store.updateCalls).toBe(1);

    const w = store.updateWheres[0]!;
    expect(w.sql).toContain("org_id");
    expect(w.params).toContain(CTX.orgId);
    expect(w.params).toContain(CTX.userId);
    expect(w.params).toContain("DRFT-0001");
  });

  it("does NOT assert org-admin when targetOrgId equals ctx.orgId", async () => {
    await updatePropertyDraft(CTX, "DRFT-0001", { title: "renamed" }, CTX.orgId);

    expect(assertOrgAdmin).not.toHaveBeenCalled();
    expect(store.callOrder).toEqual(["db.update"]);
    const w = store.updateWheres[0]!;
    expect(w.params).toContain(CTX.orgId);
  });
});

describe("listPropertyDrafts — cross-org authorization", () => {
  it("asserts org-admin in the target org BEFORE the DB select", async () => {
    await listPropertyDrafts(CTX, TARGET_ORG);

    expect(assertOrgAdmin).toHaveBeenCalledWith(CTX, TARGET_ORG);
    expect(store.callOrder).toEqual(["assertOrgAdmin", "db.select"]);
    expect(store.selectCalls).toBe(1);

    const w = store.updateWheres[0]!;
    expect(w.params).toContain(TARGET_ORG);
    expect(w.params).toContain(CTX.userId);
  });

  it("does not select when the target-org admin check fails", async () => {
    store.assertOrgAdminRejects = true;

    await expect(listPropertyDrafts(CTX, TARGET_ORG)).rejects.toThrow("forbidden");

    expect(store.selectCalls).toBe(0);
    expect(store.callOrder).toEqual(["assertOrgAdmin"]);
  });

  it("does NOT assert org-admin when no targetOrgId is supplied", async () => {
    await listPropertyDrafts(CTX);

    expect(assertOrgAdmin).not.toHaveBeenCalled();
    expect(store.callOrder).toEqual(["db.select"]);
    const w = store.updateWheres[0]!;
    expect(w.params).toContain(CTX.orgId);
  });
});

describe("convertDraftToDocumentsForOrg — cross-org authorization", () => {
  it("asserts org-admin in the target org BEFORE any target-org operations", async () => {
    await convertDraftToDocumentsForOrg(CTX, "DRFT-0001", "PROP-0001", TARGET_ORG);

    expect(assertOrgAdmin).toHaveBeenCalledWith(CTX, TARGET_ORG);
    expect(store.callOrder[0]).toBe("assertOrgAdmin");
  });

  it("does not perform any target-org operations when the admin check fails", async () => {
    store.assertOrgAdminRejects = true;

    await expect(
      convertDraftToDocumentsForOrg(CTX, "DRFT-0001", "PROP-0001", TARGET_ORG),
    ).rejects.toThrow("forbidden");

    expect(store.callOrder).toEqual(["assertOrgAdmin"]);
    expect(store.updateCalls).toBe(0);
  });
});
