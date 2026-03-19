import type { AuthCredentials, SessionState, SignupPayload, UserRole } from "@/types/auth";

export interface AuthRepository {
  restoreSession(): Promise<SessionState | null>;
  login(credentials: AuthCredentials): Promise<SessionState>;
  signup(payload: SignupPayload): Promise<SessionState>;
  logout(): Promise<void>;
  setRoleOverride(role: UserRole | null): Promise<SessionState | null>;
}