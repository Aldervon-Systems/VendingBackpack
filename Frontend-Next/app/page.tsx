"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/providers/auth-provider";
import { LoadingScreen } from "@/components/primitives/loading-screen";
import { APP_ROUTES } from "@/lib/routes";

export default function HomePage() {
  const router = useRouter();
  const { isAuthenticated, isRestoring } = useAuth();

  useEffect(() => {
    if (isRestoring) {
      return;
    }

    router.replace(isAuthenticated ? APP_ROUTES.dashboard : APP_ROUTES.login);
  }, [isAuthenticated, isRestoring, router]);

  return <LoadingScreen label="Preparing your workspace" />;
}