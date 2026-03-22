"use client";

import { AppShell } from "@/components/shell/app-shell";
import { LoadingScreen } from "@/components/primitives/loading-screen";
import { useAuthGuard } from "@/hooks/use-auth-guard";

export default function ProtectedLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const { isAuthenticated, isRestoring } = useAuthGuard();

  if (isRestoring || !isAuthenticated) {
    return <LoadingScreen label="Opening authenticated shell" />;
  }

  return <AppShell>{children}</AppShell>;
}