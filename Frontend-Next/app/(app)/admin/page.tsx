"use client";

import { LoadingScreen } from "@/components/primitives/loading-screen";
import { AdminModal } from "@/features/admin/components/admin-modal";
import { useAuthGuard } from "@/hooks/use-auth-guard";

export default function AdminPage() {
  const { isAuthenticated, isRestoring, effectiveRole } = useAuthGuard({ managerOnly: true });

  if (isRestoring || !isAuthenticated || effectiveRole !== "manager") {
    return <LoadingScreen label="Checking admin access" />;
  }

  return <AdminModal />;
}
