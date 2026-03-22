"use client";

import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { DEMO_PASSPHRASE, findAdminProfile } from "@/admin-center-data";
import { SESSION_TTL_MS, STORAGE_KEYS } from "@/lib/constants";
import { getStoredValue, removeStoredValue, setStoredValue } from "@/lib/storage";
import type { AuthCredentials, SessionState } from "@/types/auth";
import { isSessionState } from "@/types/auth";

type AuthContextValue = {
  session: SessionState | null;
  isRestoring: boolean;
  isAuthenticated: boolean;
  login: (credentials: AuthCredentials) => Promise<void>;
  logout: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: Readonly<{ children: React.ReactNode }>) {
  const [session, setSession] = useState<SessionState | null>(null);
  const [isRestoring, setIsRestoring] = useState(true);

  useEffect(() => {
    const restored = getStoredValue<SessionState>(STORAGE_KEYS.session, { validate: isSessionState });
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
      removeStoredValue(STORAGE_KEYS.session);
      return;
    }

    const timeoutId = window.setTimeout(() => {
      setSession(null);
      removeStoredValue(STORAGE_KEYS.session);
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
        const normalizedEmail = credentials.email.trim().toLowerCase();
        const profile = findAdminProfile(normalizedEmail);

        if (!profile) {
          throw new Error("This admin center only allows approved platform operator accounts.");
        }

        if (credentials.passphrase !== DEMO_PASSPHRASE) {
          throw new Error("Incorrect passphrase. Use the current operations demo passphrase to open the workspace.");
        }

        const nextSession: SessionState = {
          user: {
            email: profile.email,
            name: profile.name,
            title: profile.title,
            clearance: profile.clearance,
            shift: credentials.shiftNote?.trim() || profile.shift,
            scope: profile.scope,
          },
          issuedAt: new Date().toISOString(),
          expiresAt: new Date(Date.now() + SESSION_TTL_MS).toISOString(),
          accessToken: `admin-${normalizedEmail}-${Date.now()}`,
          authMode: "local",
        };

        setStoredValue(STORAGE_KEYS.session, nextSession, { ttlMs: SESSION_TTL_MS });
        setSession(nextSession);
      },
      async logout() {
        removeStoredValue(STORAGE_KEYS.session);
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
