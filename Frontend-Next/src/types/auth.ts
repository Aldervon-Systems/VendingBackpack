export type UserRole = "manager" | "employee";

export type SessionUser = {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  organizationName: string;
};

export type SessionState = {
  user: SessionUser;
  roleOverride: UserRole | null;
  issuedAt: string;
  expiresAt: string;
  authMode: "mock";
};

export type AuthCredentials = {
  email: string;
  password: string;
  organizationName?: string;
  targetRole?: UserRole;
};

export type SignupPayload = {
  name: string;
  email: string;
  password: string;
  organizationName: string;
  role: UserRole;
};

function isUserRole(value: unknown): value is UserRole {
  return value === "manager" || value === "employee";
}

export function isSessionState(value: unknown): value is SessionState {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const candidate = value as Record<string, unknown>;
  const user = candidate.user;

  if (typeof user !== "object" || user === null) {
    return false;
  }

  const sessionUser = user as Record<string, unknown>;

  return (
    typeof sessionUser.id === "string" &&
    typeof sessionUser.name === "string" &&
    typeof sessionUser.email === "string" &&
    typeof sessionUser.organizationName === "string" &&
    isUserRole(sessionUser.role) &&
    (candidate.roleOverride === null || isUserRole(candidate.roleOverride)) &&
    typeof candidate.issuedAt === "string" &&
    typeof candidate.expiresAt === "string" &&
    candidate.authMode === "mock"
  );
}
