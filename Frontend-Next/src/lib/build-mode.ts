export type BuildAuthMode = "api" | "seed";

export function getBuildAuthMode(): BuildAuthMode {
  return process.env.NEXT_PUBLIC_AUTH_MODE === "seed" ? "seed" : "api";
}
