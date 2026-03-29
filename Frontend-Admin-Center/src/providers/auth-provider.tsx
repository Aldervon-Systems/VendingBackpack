"use client";

import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { LocalAdminAuthRepository } from "@/features/auth/lib/admin-auth-repository";
import type { AuthCredentials, SessionState } from "@/types/auth";

type AuthContextValue = {
  session: SessionState | null;
  isRestoring: boolean;
  isAuthenticated: boolean;
  login: (credentials: AuthCredentials) => Promise<void>;
  logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);
const authRepository = new LocalAdminAuthRepository();

export function AuthProvider({ children }: Readonly<{ children: React.ReactNode }>) {
  const [session, setSession] = useState<SessionState | null>(null);
  const [isRestoring, setIsRestoring] = useState(true);

  useEffect(() => {
    const restored = authRepository.restoreSession();
    setSession(restored);
    setIsRestoring(false);
  }, []);

  useEffect(() => {
    if (!session) {
      return;
    }

    const expiresAt = new Date(session.expiresAt).getTime();
    const remaining = expiresAt - Date.now();

    if (remaining <= 0) {
      setSession(null);
      void authRepository.logout();
      return;
    }

    const timeoutId = window.setTimeout(() => {
      setSession(null);
      void authRepository.logout();
    }, remaining);

    return () => {
      window.clearTimeout(timeoutId);
    };
  }, [session]);

  const value = useMemo<AuthContextValue>(
    () => ({
      session,
      isRestoring,
      isAuthenticated: Boolean(session),
      async login(credentials) {
        const nextSession = await authRepository.login(credentials);
        setSession(nextSession);
      },
      async logout() {
        await authRepository.logout();
        setSession(null);
      },
    }),
    [isRestoring, session],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error("useAuth must be used within AuthProvider");
  }

  return context;
}
