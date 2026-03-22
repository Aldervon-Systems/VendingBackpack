"use client";

import { LoadingScreen } from "@/components/primitives/loading-screen";
import { useAuthGuard } from "@/hooks/use-auth-guard";
import { CorporateScreen } from "@/features/corporate/components/corporate-screen";

export default function CorporatePage() {
  const { isAuthenticated, isRestoring, effectiveRole } = useAuthGuard({ managerOnly: true });

  if (isRestoring || !isAuthenticated || effectiveRole !== "manager") {
    return <LoadingScreen label="Loading corporate analytics" />;
  }

  return <CorporateScreen />;
}
