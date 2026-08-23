import type { MetadataRoute } from "next";

const SITE_URL = "https://www.valgate.co";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: [
        "/app",
        "/app/",
        "/portfolio",
        "/portfolio/",
        "/property",
        "/property/",
        "/rental",
        "/rental/",
        "/settings",
        "/settings/",
        "/profile",
        "/profile/",
        "/add-property",
        "/add-property/",
        "/design-system",
        "/design-system/",
        "/login",
        "/login/",
        "/register",
        "/register/",
        "/forgot-password",
        "/forgot-password/",
        "/accept-invitation",
        "/accept-invitation/",
        "/oauth-consent",
        "/oauth-consent/",
        "/api",
        "/api/",
        "/mcp",
        "/mcp/",
      ],
    },
    sitemap: `${SITE_URL}/sitemap.xml`,
  };
}
