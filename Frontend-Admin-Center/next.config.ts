import path from "node:path";
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  output: "export",
  trailingSlash: true,
  images: {
    unoptimized: true,
  },
  outputFileTracingRoot: path.join(__dirname),
  poweredByHeader: false,
};

export default nextConfig;
