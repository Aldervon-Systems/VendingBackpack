import { DEMO_PASSPHRASE, findAdminProfile, ADMIN_PROFILES } from "@/admin-center-data";
import { SESSION_TTL_MS, STORAGE_KEYS } from "@/lib/constants";
import { getStoredValue, removeStoredValue, setStoredValue } from "@/lib/storage";
import type { AuthCredentials, SessionState } from "@/types/auth";
import { isSessionState } from "@/types/auth";

export type AdminAuthSeed = {
  defaultEmail: string;
  defaultPassphrase: string;
  defaultShiftNote: string;
  primaryAccess: string;
  acceptedEmails: string[];
};

export interface AdminAuthRepository {
  getAuthSeed(): AdminAuthSeed;
  restoreSession(): SessionState | null;
  login(credentials: AuthCredentials): Promise<SessionState>;
  logout(): Promise<void>;
}

export class LocalAdminAuthRepository implements AdminAuthRepository {
  getAuthSeed(): AdminAuthSeed {
    const primaryProfile = ADMIN_PROFILES[0];

    return {
      defaultEmail: primaryProfile?.email ?? "ops.admin@aldervon.com",
      defaultPassphrase: DEMO_PASSPHRASE,
      defaultShiftNote: primaryProfile?.shift ?? "Morning platform review",
      primaryAccess: "ops.admin@aldervon.com / AldervonOps!",
      acceptedEmails: ADMIN_PROFILES.slice(1).map((profile) => profile.email),
    };
  }

  restoreSession(): SessionState | null {
    return getStoredValue<SessionState>(STORAGE_KEYS.session, { validate: isSessionState });
  }

  async login(credentials: AuthCredentials): Promise<SessionState> {
    const normalizedEmail = credentials.email.trim().toLowerCase();
    const profile = findAdminProfile(normalizedEmail);

    if (!profile) {
      throw new Error("This admin center only allows approved platform operator accounts.");
    }

    if (credentials.passphrase !== DEMO_PASSPHRASE) {
      throw new Error("Incorrect passphrase. Use the current operations passphrase to open the workspace.");
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
    return nextSession;
  }

  async logout(): Promise<void> {
    removeStoredValue(STORAGE_KEYS.session);
  }
}
