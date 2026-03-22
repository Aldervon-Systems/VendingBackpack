"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { Zap } from "lucide-react";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityCard } from "@/components/parity/parity-card";
import { ParityField } from "@/components/parity/parity-field";
import { useAuth } from "@/providers/auth-provider";
import { APP_ROUTES } from "@/lib/routes";
import { ADMIN_PROFILES, DEMO_PASSPHRASE } from "@/admin-center-data";

type AuthFormProps = {
  mode?: "login";
};

export function AuthForm({ mode = "login" }: AuthFormProps) {
  const router = useRouter();
  const { login } = useAuth();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [formState, setFormState] = useState({
    email: ADMIN_PROFILES[0]?.email ?? "ops.admin@aldervon.com",
    passphrase: DEMO_PASSPHRASE,
    shiftNote: "Morning platform review",
  });

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);
    setError("");

    try {
      await login({
        email: formState.email,
        passphrase: formState.passphrase,
        shiftNote: formState.shiftNote,
      });
      router.replace(APP_ROUTES.overview);
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : "Sign-in failed");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="auth-page">
      <ParityCard className="auth-card" kind="surface">
        <div className="auth-logo">
          <Zap size={28} strokeWidth={2.4} />
        </div>

        <div className="auth-copy">
          <h1 className="auth-title">{mode === "login" ? "Admin Center" : "Admin Center"}</h1>
          <p className="auth-subtitle">
            Sign in with an approved platform admin account. This local session mirrors the main app&apos;s auth flow while
            keeping cross-tenant controls separate from manager workflows.
          </p>
        </div>

        <form className="auth-form" onSubmit={handleSubmit}>
          <ParityField
            id="admin-email"
            label="WORK EMAIL"
            value={formState.email}
            onChange={(event) => setFormState((current) => ({ ...current, email: event.target.value }))}
            autoComplete="email"
            placeholder="ops.admin@aldervon.com"
          />

          <ParityField
            id="admin-passphrase"
            label="PASSPHRASE"
            type="password"
            value={formState.passphrase}
            onChange={(event) => setFormState((current) => ({ ...current, passphrase: event.target.value }))}
            autoComplete="current-password"
            placeholder="Current operations passphrase"
          />

          <ParityField
            id="shift-note"
            label="SHIFT NOTE"
            value={formState.shiftNote}
            onChange={(event) => setFormState((current) => ({ ...current, shiftNote: event.target.value }))}
            placeholder="Morning platform review"
          />

          {error ? <div className="form-error">{error}</div> : null}

          <ParityButton className="auth-primary" type="submit" fullWidth disabled={isSubmitting}>
            {isSubmitting ? "WORKING..." : "SIGN IN TO ADMIN CENTER"}
          </ParityButton>

          <ParityButton
            tone="ghost"
            fullWidth
            type="button"
            onClick={() => {
              const demoProfile = ADMIN_PROFILES[0];
              setFormState({
                email: demoProfile?.email ?? "ops.admin@aldervon.com",
                passphrase: DEMO_PASSPHRASE,
                shiftNote: demoProfile?.shift ?? "Morning platform review",
              });
              setError("");
            }}
          >
            LOAD DEMO CREDENTIALS
          </ParityButton>
        </form>

        <div className="auth-links">
          <p className="muted">Admin access is intentionally separate from the manager shell.</p>
          <p className="muted">
            Demo access: ops.admin@aldervon.com / AldervonOps!
          </p>
          <p className="muted">
            Also accepted: {ADMIN_PROFILES.slice(1).map((profile) => profile.email).join(", ")}
          </p>
        </div>
      </ParityCard>
    </div>
  );
}
