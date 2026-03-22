export type UserRole = "manager" | "employee";

export type SessionUser = {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  organizationId: string | null;
  organizationName: string;
};

export type SessionState = {
  user: SessionUser;
  roleOverride: UserRole | null;
  issuedAt: string;
  expiresAt: string;
  accessToken: string;
  authMode: "mock" | "api";
};

export type AuthCredentials = {
  email: string;
  password: string;
  organizationId?: string;
  organizationName?: string;
  targetRole?: UserRole;
};

export type SignupPayload = {
  name: string;
  email: string;
  password: string;
  organizationId?: string;
  organizationName: string;
  role: UserRole;
};

export type OrganizationSummary = {
  id: string;
  name: string;
};

export type CreateOrganizationPayload = {
  name: string;
  managerEmail: string;
  managerPassword: string;
  adminPassword: string;
  whitelist: string[];
};

export type CreateOrganizationResponse = {
  organizationId: string;
  totpSeed: string;
  totpUri: string;
};

export type VerifyAdminPayload = {
  organizationId: string;
  adminPassword: string;
  totpCode: string;
};

export type AddMachinePayload = {
  organizationId: string;
  vin: string;
  name: string;
  lat: number;
  lng: number;
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
    (typeof sessionUser.organizationId === "string" || sessionUser.organizationId === null) &&
    typeof sessionUser.organizationName === "string" &&
    isUserRole(sessionUser.role) &&
    (candidate.roleOverride === null || isUserRole(candidate.roleOverride)) &&
    typeof candidate.issuedAt === "string" &&
    typeof candidate.expiresAt === "string" &&
    typeof candidate.accessToken === "string" &&
    (candidate.authMode === "mock" || candidate.authMode === "api")
  );
}
