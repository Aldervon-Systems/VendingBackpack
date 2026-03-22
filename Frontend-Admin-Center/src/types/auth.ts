export type AdminSessionUser = {
  email: string;
  name: string;
  title: string;
  clearance: string;
  shift: string;
  scope: string;
};

export type SessionState = {
  user: AdminSessionUser;
  issuedAt: string;
  expiresAt: string;
  accessToken: string;
  authMode: "local";
};

export type AuthCredentials = {
  email: string;
  passphrase: string;
  shiftNote?: string;
};

function isSessionUser(value: unknown): value is AdminSessionUser {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const candidate = value as Record<string, unknown>;

  return (
    typeof candidate.email === "string" &&
    typeof candidate.name === "string" &&
    typeof candidate.title === "string" &&
    typeof candidate.clearance === "string" &&
    typeof candidate.shift === "string" &&
    typeof candidate.scope === "string"
  );
}

export function isSessionState(value: unknown): value is SessionState {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const candidate = value as Record<string, unknown>;

  return (
    isSessionUser(candidate.user) &&
    typeof candidate.issuedAt === "string" &&
    typeof candidate.expiresAt === "string" &&
    typeof candidate.accessToken === "string" &&
    candidate.authMode === "local"
  );
}
