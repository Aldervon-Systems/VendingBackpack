import { SESSION_TTL_MS, STORAGE_KEYS } from "@/lib/constants";
import { getStoredValue, removeStoredValue, setStoredValue } from "@/lib/storage";
import {
  isSessionState,
  type AddMachinePayload,
  type AuthCredentials,
  type CreateOrganizationPayload,
  type CreateOrganizationResponse,
  type OrganizationSummary,
  type SessionState,
  type SessionUser,
  type SignupPayload,
  type UserRole,
  type VerifyAdminPayload,
} from "@/types/auth";
import type { AuthRepository } from "@/lib/api/interfaces/auth-repository";

const managerUser: SessionUser = {
  id: "mgr-01",
  name: "Renee Goodman",
  email: "renee@aldervon.com",
  role: "manager",
  organizationId: "org_aldervon",
  organizationName: "Aldervon Systems",
};

const employeeUser: SessionUser = {
  id: "emp-07",
  name: "Amanda Jones",
  email: "amanda.jones@example.com",
  role: "employee",
  organizationId: "org_aldervon",
  organizationName: "Aldervon Systems",
};

function delay<T>(value: T, ms = 420): Promise<T> {
  return new Promise((resolve) => {
    window.setTimeout(() => resolve(value), ms);
  });
}

export class MockAuthRepository implements AuthRepository {
  async restoreSession(): Promise<SessionState | null> {
    const session = getStoredValue<SessionState>(STORAGE_KEYS.session, { validate: isSessionState });
    return delay(session, 560);
  }

  async login(credentials: AuthCredentials): Promise<SessionState> {
    const role = credentials.targetRole ?? inferRole(credentials.email);
    const user = role === "manager" ? managerUser : employeeUser;
    const nextSession = createSession({
      user: {
        ...user,
        email: credentials.email || user.email,
        organizationName: credentials.organizationName || user.organizationName,
        organizationId: credentials.organizationId ?? user.organizationId,
      },
    });

    setStoredValue(STORAGE_KEYS.session, nextSession, { ttlMs: SESSION_TTL_MS });
    return delay(nextSession);
  }

  async signup(payload: SignupPayload): Promise<SessionState> {
    const nextSession = createSession({
      user: {
        id: payload.role === "manager" ? "mgr-new" : "emp-new",
        name: payload.name,
        email: payload.email,
        role: payload.role,
        organizationId: payload.organizationId ?? "org_new",
        organizationName: payload.organizationName,
      },
    });

    setStoredValue(STORAGE_KEYS.session, nextSession, { ttlMs: SESSION_TTL_MS });
    return delay(nextSession);
  }

  async logout(): Promise<void> {
    removeStoredValue(STORAGE_KEYS.session);
    return delay(undefined, 180);
  }

  async setRoleOverride(role: UserRole | null): Promise<SessionState | null> {
    const session = getStoredValue<SessionState>(STORAGE_KEYS.session, { validate: isSessionState });
    if (!session || session.user.role !== "manager") {
      return delay(session);
    }

    const nextSession: SessionState = {
      ...session,
      roleOverride: role,
      issuedAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + SESSION_TTL_MS).toISOString(),
    };

    setStoredValue(STORAGE_KEYS.session, nextSession, { ttlMs: SESSION_TTL_MS });
    return delay(nextSession, 220);
  }

  async searchOrganizations(query: string): Promise<OrganizationSummary[]> {
    const organizations = [
      { id: "org_aldervon", name: "Aldervon Systems" },
      { id: "org_atlas", name: "Atlas Foods" },
      { id: "org_boston", name: "Boston Beverage Lab" },
    ];

    return delay(
      organizations.filter((organization) => organization.name.toLowerCase().includes(query.toLowerCase())),
      220,
    );
  }

  async createOrganization(payload: CreateOrganizationPayload): Promise<CreateOrganizationResponse> {
    const slug = payload.name.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");

    return delay(
      {
        organizationId: `org_${slug || "new_org"}`,
        totpSeed: "JBSWY3DPEHPK3PXP",
        totpUri: "otpauth://totp/VendingBackpack:mock",
      },
      240,
    );
  }

  async verifyAdmin(_payload: VerifyAdminPayload): Promise<boolean> {
    return delay(true, 220);
  }

  async updateWhitelist(_organizationId: string, _emails: string[]): Promise<void> {
    await delay(undefined, 180);
  }

  async addMachine(_payload: AddMachinePayload): Promise<void> {
    await delay(undefined, 180);
  }
}

function createSession({ user }: { user: SessionUser }): SessionState {
  return {
    accessToken: "mock_token",
    user,
    roleOverride: null,
    issuedAt: new Date().toISOString(),
    expiresAt: new Date(Date.now() + SESSION_TTL_MS).toISOString(),
    authMode: "mock",
  };
}

function inferRole(email: string): UserRole {
  const normalized = email.toLowerCase();
  return normalized.includes("manager") || normalized.includes("admin") || normalized.includes("renee")
    ? "manager"
    : "employee";
}
