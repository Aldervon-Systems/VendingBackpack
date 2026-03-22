"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { APP_ROUTES } from "@/lib/routes";
import { useAuth } from "@/providers/auth-provider";

export function useAuthGuard(_options?: { managerOnly?: boolean }) {
  const router = useRouter();
  const { isAuthenticated, isRestoring } = useAuth();

  useEffect(() => {
    if (isRestoring) {
      return;
    }

    if (!isAuthenticated) {
      router.replace(APP_ROUTES.login);
    }
  }, [isAuthenticated, isRestoring, router]);

  return { isAuthenticated, isRestoring };
}
