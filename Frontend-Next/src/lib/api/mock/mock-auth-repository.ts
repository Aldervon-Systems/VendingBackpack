import { SESSION_TTL_MS, STORAGE_KEYS } from "@/lib/constants";
import { getStoredValue, removeStoredValue, setStoredValue } from "@/lib/storage";
import { isSessionState, type AuthCredentials, type SessionState, type SessionUser, type SignupPayload, type UserRole } from "@/types/auth";
import type { AuthRepository } from "@/lib/api/interfaces/auth-repository";

const managerUser: SessionUser = {
  id: "mgr-01",
  name: "Renee Goodman",
  email: "renee@aldervon.com",
  role: "manager",
  organizationName: "Aldervon Systems",
};

const employeeUser: SessionUser = {
  id: "emp-07",
  name: "Amanda Jones",
  email: "amanda.jones@example.com",
  role: "employee",
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
}

function createSession({ user }: { user: SessionUser }): SessionState {
  return {
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
