"use client";

import { apiRequest, clearAccessToken, setAccessToken } from "@/lib/api/api-client";
import { SESSION_TTL_MS, STORAGE_KEYS } from "@/lib/constants";
import { getStoredValue, removeStoredValue, setStoredValue } from "@/lib/storage";
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
import type { AuthRepository } from "@/lib/api/interfaces/auth-repository";
import { isSessionState } from "@/types/auth";

function createSessionState({
  accessToken,
  user,
  roleOverride = null,
  authMode = "api",
}: Pick<SessionState, "accessToken" | "user"> &
  Partial<Pick<SessionState, "roleOverride" | "authMode">>): SessionState {
  return {
    accessToken,
    user,
    roleOverride,
    issuedAt: new Date().toISOString(),
    expiresAt: new Date(Date.now() + SESSION_TTL_MS).toISOString(),
    authMode,
  };
}

function persistSession(session: SessionState) {
  setStoredValue(STORAGE_KEYS.session, session, { ttlMs: SESSION_TTL_MS });
  setAccessToken(session.accessToken);
}

function clearSession() {
  clearAccessToken();
  removeStoredValue(STORAGE_KEYS.session);
}

export class ApiAuthRepository implements AuthRepository {
  async restoreSession(): Promise<SessionState | null> {
    const session = getStoredValue<SessionState>(STORAGE_KEYS.session, { validate: isSessionState });

    if (!session) {
      clearAccessToken();
      return null;
    }

    setAccessToken(session.accessToken);

    try {
      await apiRequest<{ user: Record<string, unknown> }>("/me", { method: "GET" });
      return session;
    } catch {
      clearSession();
      return null;
    }
  }

  async login(credentials: AuthCredentials): Promise<SessionState> {
    const response = await apiRequest<{
      access_token: string;
      user: {
        id: string;
        name: string;
        email: string;
        role: UserRole;
        organization_id?: string | null;
      };
    }>("/token", {
      method: "POST",
      body: {
        email: credentials.email,
        password: credentials.password,
        organization_id: credentials.organizationId,
      },
    });

    const session = createSessionState({
      accessToken: response.access_token,
      user: {
        id: response.user.id,
        name: response.user.name,
        email: response.user.email,
        role: response.user.role,
        organizationId: response.user.organization_id ?? credentials.organizationId ?? null,
        organizationName: credentials.organizationName ?? credentials.organizationId ?? "Organization",
      },
    });

    persistSession(session);
    return session;
  }

  async signup(payload: SignupPayload): Promise<SessionState> {
    const response = await apiRequest<{
      access_token: string;
      user: {
        id: string;
        name: string;
        email: string;
        role: UserRole;
        organization_id?: string | null;
      };
    }>("/signup", {
      method: "POST",
      body: {
        name: payload.name,
        email: payload.email,
        password: payload.password,
        role: payload.role,
        organization_id: payload.organizationId,
      },
    });

    const session = createSessionState({
      accessToken: response.access_token,
      user: {
        id: response.user.id,
        name: response.user.name,
        email: response.user.email,
        role: response.user.role,
        organizationId: response.user.organization_id ?? payload.organizationId ?? null,
        organizationName: payload.organizationName,
      },
    });

    persistSession(session);
    return session;
  }

  async logout(): Promise<void> {
    clearSession();
  }

  async setRoleOverride(role: UserRole | null): Promise<SessionState | null> {
    const session = getStoredValue<SessionState>(STORAGE_KEYS.session, { validate: isSessionState });
    if (!session || session.user.role !== "manager") {
      return session;
    }

    const nextSession: SessionState = {
      ...session,
      roleOverride: role,
      issuedAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + SESSION_TTL_MS).toISOString(),
    };

    persistSession(nextSession);
    return nextSession;
  }

  async searchOrganizations(query: string): Promise<OrganizationSummary[]> {
    const response = await apiRequest<Array<{ id: string; name: string }>>(
      `/organizations/search?q=${encodeURIComponent(query)}`,
      { method: "GET" },
    );

    return response.map((organization) => ({
      id: organization.id,
      name: organization.name,
    }));
  }

  async createOrganization(payload: CreateOrganizationPayload): Promise<CreateOrganizationResponse> {
    const response = await apiRequest<CreateOrganizationResponse>("/organizations/create", {
      method: "POST",
      body: {
        name: payload.name,
        manager_email: payload.managerEmail,
        manager_password: payload.managerPassword,
        admin_password: payload.adminPassword,
        whitelist: payload.whitelist,
      },
    });

    return response;
  }

  async verifyAdmin(payload: VerifyAdminPayload): Promise<boolean> {
    const response = await apiRequest<{ verified: boolean }>("/organizations/verify_admin", {
      method: "POST",
      body: {
        organization_id: payload.organizationId,
        admin_password: payload.adminPassword,
        totp_code: payload.totpCode,
      },
    });

    return response.verified;
  }

  async updateWhitelist(organizationId: string, emails: string[]): Promise<void> {
    await apiRequest(`/organizations/${organizationId}/whitelist`, {
      method: "POST",
      body: {
        emails,
      },
    });
  }

  async addMachine(payload: AddMachinePayload): Promise<void> {
    await apiRequest(`/organizations/${payload.organizationId}/machines`, {
      method: "POST",
      body: {
        vin: payload.vin,
        name: payload.name,
        lat: payload.lat,
        lng: payload.lng,
      },
    });
  }
}
