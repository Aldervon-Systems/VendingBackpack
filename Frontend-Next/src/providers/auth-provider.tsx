"use client";

import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { ApiAuthRepository } from "@/lib/api/repositories/api-auth-repository";
import type {
  AddMachinePayload,
  AuthCredentials,
  CreateOrganizationPayload,
  CreateOrganizationResponse,
  OrganizationSummary,
  SessionState,
  SignupPayload,
  UserRole,
  VerifyAdminPayload,
} from "@/types/auth";

type AuthContextValue = {
  session: SessionState | null;
  isRestoring: boolean;
  isAuthenticated: boolean;
  sessionExpired: boolean;
  actualRole: UserRole | null;
  effectiveRole: UserRole | null;
  login: (credentials: AuthCredentials) => Promise<void>;
  signup: (payload: SignupPayload) => Promise<void>;
  logout: () => Promise<void>;
  setEmployeeView: (enabled: boolean) => Promise<void>;
  searchOrganizations: (query: string) => Promise<OrganizationSummary[]>;
  createOrganization: (payload: CreateOrganizationPayload) => Promise<CreateOrganizationResponse>;
  verifyAdmin: (payload: VerifyAdminPayload) => Promise<boolean>;
  updateWhitelist: (organizationId: string, emails: string[]) => Promise<void>;
  addMachine: (payload: AddMachinePayload) => Promise<void>;
};

const authRepository = new ApiAuthRepository();
const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: Readonly<{ children: React.ReactNode }>) {
  const [session, setSession] = useState<SessionState | null>(null);
  const [isRestoring, setIsRestoring] = useState(true);
  const [sessionExpired, setSessionExpired] = useState(false);

  useEffect(() => {
    let active = true;

    authRepository.restoreSession().then((restored) => {
      if (!active) {
        return;
      }

      setSession(restored);
      setSessionExpired(false);
      setIsRestoring(false);
    });

    return () => {
      active = false;
    };
  }, []);

  const value = useMemo<AuthContextValue>(() => {
    const actualRole = session?.user.role ?? null;
    const effectiveRole = session?.roleOverride ?? actualRole;
    const isAuthenticated = Boolean(session?.user);

    return {
      session,
      isRestoring,
      isAuthenticated,
      sessionExpired,
      actualRole,
      effectiveRole,
      async login(credentials) {
        const nextSession = await authRepository.login(credentials);
        setSessionExpired(false);
        setSession(nextSession);
      },
      async signup(payload) {
        const nextSession = await authRepository.signup(payload);
        setSessionExpired(false);
        setSession(nextSession);
      },
      async logout() {
        await authRepository.logout();
        setSessionExpired(false);
        setSession(null);
      },
      async setEmployeeView(enabled) {
        const nextSession = await authRepository.setRoleOverride(enabled ? "employee" : null);
        setSession(nextSession);
      },
      searchOrganizations(query) {
        return authRepository.searchOrganizations(query);
      },
      createOrganization(payload) {
        return authRepository.createOrganization(payload);
      },
      verifyAdmin(payload) {
        return authRepository.verifyAdmin(payload);
      },
      updateWhitelist(organizationId, emails) {
        return authRepository.updateWhitelist(organizationId, emails);
      },
      addMachine(payload) {
        return authRepository.addMachine(payload);
      },
    };
  }, [isRestoring, session, sessionExpired]);

  useEffect(() => {
    if (!session) {
      return;
    }

    const expiryTime = new Date(session.expiresAt).getTime();
    const remaining = expiryTime - Date.now();

    if (remaining <= 0) {
      setSession(null);
      setSessionExpired(true);
      void authRepository.logout();
      return;
    }

    const timeoutId = window.setTimeout(() => {
      setSession(null);
      setSessionExpired(true);
      void authRepository.logout();
    }, remaining);

    return () => {
      window.clearTimeout(timeoutId);
    };
  }, [session]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error("useAuth must be used within AuthProvider");
  }

  return context;
}
