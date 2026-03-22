"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { AuthForm } from "@/features/auth/components/auth-form";
import { useAuth } from "@/providers/auth-provider";
import { APP_ROUTES } from "@/lib/routes";
import { LoadingScreen } from "@/components/primitives/loading-screen";

export default function LoginPage() {
  const router = useRouter();
  const { isAuthenticated, isRestoring } = useAuth();

  useEffect(() => {
    if (!isRestoring && isAuthenticated) {
      router.replace(APP_ROUTES.overview);
    }
  }, [isAuthenticated, isRestoring, router]);

  if (isRestoring) {
    return <LoadingScreen label="Restoring login state" />;
  }

  return <AuthForm mode="login" />;
}
