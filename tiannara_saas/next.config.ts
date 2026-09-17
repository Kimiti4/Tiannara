import type { NextConfig } from "next";

const apiUpstream =
  process.env.API_UPSTREAM_URL || "http://127.0.0.1:8004";

const nextConfig: NextConfig = {
  async rewrites() {
    return [
      {
        source: "/api/v1/:path*",
        destination: `${apiUpstream}/api/v1/:path*`,
      },
      {
        source: "/ws/:path*",
        destination: `${apiUpstream}/ws/:path*`,
      },
    ];
  },
};

export default nextConfig;
