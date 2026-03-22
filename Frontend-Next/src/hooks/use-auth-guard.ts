"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { APP_ROUTES } from "@/lib/routes";
import { useAuth } from "@/providers/auth-provider";

export function useAuthGuard(options?: { managerOnly?: boolean }) {
  const router = useRouter();
  const { isAuthenticated, isRestoring, effectiveRole } = useAuth();

  useEffect(() => {
    if (isRestoring) {
      return;
    }

    if (!isAuthenticated) {
      router.replace(APP_ROUTES.login);
      return;
    }

    if (options?.managerOnly && effectiveRole !== "manager") {
      router.replace(APP_ROUTES.dashboard);
    }
  }, [effectiveRole, isAuthenticated, isRestoring, options?.managerOnly, router]);

  return { isAuthenticated, isRestoring, effectiveRole };
}