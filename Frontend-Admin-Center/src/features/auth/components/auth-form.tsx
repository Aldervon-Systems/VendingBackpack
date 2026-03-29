"use client";

import { useRouter } from "next/navigation";
import { Zap } from "lucide-react";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityCard } from "@/components/parity/parity-card";
import { ParityField } from "@/components/parity/parity-field";
import { useAuthFormViewModel } from "@/features/auth/hooks/use-auth-form-view-model";
import { useAuth } from "@/providers/auth-provider";
import { APP_ROUTES } from "@/lib/routes";

type AuthFormProps = {
  mode?: "login";
};

export function AuthForm({ mode = "login" }: AuthFormProps) {
  const router = useRouter();
  const { login } = useAuth();
  const {
    authSeed,
    error,
    isSubmitting,
    formState,
    setError,
    setIsSubmitting,
    setFormState,
    loadAccessCredentials,
  } = useAuthFormViewModel();

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
            Sign in with an approved platform admin account to access cross-tenant controls kept separate from manager
            workflows.
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
            onClick={loadAccessCredentials}
          >
            LOAD ACCESS CREDENTIALS
          </ParityButton>
        </form>

        <div className="auth-links">
          <p className="muted">Admin access is intentionally separate from the manager shell.</p>
          <p className="muted">Primary access: {authSeed.primaryAccess}</p>
          <p className="muted">Also accepted: {authSeed.acceptedEmails.join(", ")}</p>
        </div>
      </ParityCard>
    </div>
  );
}
