import type { Metadata, Viewport } from "next";
import Script from "next/script";
import { ClerkProvider } from "@clerk/nextjs";
import "../styles/index.css";
import { AgentationProvider } from "./_components/agentation-provider";

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  themeColor: "#ffffff",
};

const SITE_URL = "https://www.valgate.co";
const SITE_DESCRIPTION =
  "Valgate is a property portfolio management platform for tracking rentals, properties, and portfolio performance in one place.";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: "Valgate",
    template: "%s | Valgate",
  },
  description: SITE_DESCRIPTION,
  alternates: {
    canonical: "/",
  },
  openGraph: {
    type: "website",
    url: "/",
    siteName: "Valgate",
    title: "Valgate",
    description: SITE_DESCRIPTION,
  },
  twitter: {
    card: "summary",
    title: "Valgate",
    description: SITE_DESCRIPTION,
  },
  // .ico first so clients that hard-request /favicon.ico (e.g. some connector UIs) get a
  // real raster mark; svg second for crisp rendering in browsers that support it.
  icons: {
    icon: [
      { url: "/favicon.ico", sizes: "48x48", type: "image/x-icon" },
      { url: "/favicon.svg", type: "image/svg+xml" },
    ],
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "Valgate",
  },
  formatDetection: {
    telephone: false,
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    // Custom auth pages live at /login and /register (headless Clerk). The fallback redirect URLs
    // send users to the authed home ("/app") after sign-in/up when no explicit redirect is set.
    <ClerkProvider
      signInUrl="/login"
      signUpUrl="/register"
      signInFallbackRedirectUrl="/app"
      signUpFallbackRedirectUrl="/app"
      taskUrls={{
        "choose-organization": "/login/tasks",
        "reset-password": "/login/tasks",
        "setup-mfa": "/login/tasks",
      }}
    >
      <html lang="en" suppressHydrationWarning>
        <body className="antialiased">
          <Script
            src="https://mcp.figma.com/mcp/html-to-design/capture.js"
            strategy="lazyOnload"
          />
          {children}
          <AgentationProvider />
        </body>
      </html>
    </ClerkProvider>
  );
}
