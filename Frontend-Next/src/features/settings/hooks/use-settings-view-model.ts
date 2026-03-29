"use client";

import { useRouter } from "next/navigation";
import { APP_ROUTES } from "@/lib/routes";
import { useAuth } from "@/providers/auth-provider";
import { useShell } from "@/providers/shell-provider";

export function useSettingsViewModel(onClose: () => void) {
  const router = useRouter();
  const { session, adminVerified, actualRole, effectiveRole, logout, setEmployeeView } = useAuth();
  const { setAdminVerificationOpen } = useShell();
  const isManager = actualRole === "manager";
  const employeeSimulationEnabled = isManager && effectiveRole === "employee";

  function navigateTo(href: string) {
    onClose();
    router.push(href);
  }

  async function signOut() {
    await logout();
    onClose();
    router.replace(APP_ROUTES.login);
  }

  return {
    session,
    adminVerified,
    actualRole,
    effectiveRole,
    isManager,
    employeeSimulationEnabled,
    setEmployeeView,
    setAdminVerificationOpen,
    navigateTo,
    signOut,
  };
}
