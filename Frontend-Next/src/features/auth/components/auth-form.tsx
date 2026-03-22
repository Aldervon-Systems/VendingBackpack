"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Search, X, Zap } from "lucide-react";
import { ParityCard } from "@/components/parity/parity-card";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityField } from "@/components/parity/parity-field";
import { useAuth } from "@/providers/auth-provider";
import { APP_ROUTES } from "@/lib/routes";
import type { OrganizationSummary, UserRole } from "@/types/auth";

type AuthFormProps = {
  mode: "login" | "signup";
};

export function AuthForm({ mode }: AuthFormProps) {
  const router = useRouter();
  const { login, signup, searchOrganizations, sessionExpired } = useAuth();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [role, setRole] = useState<UserRole>("employee");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedOrganization, setSelectedOrganization] = useState<{ id: string; name: string } | null>(null);
  const [organizationResults, setOrganizationResults] = useState<OrganizationSummary[]>([]);
  const [formState, setFormState] = useState({
    name: "",
    email: "",
    password: "",
  });

  useEffect(() => {
    let active = true;

    async function runSearch() {
      if (selectedOrganization || searchQuery.trim().length < 2) {
        setOrganizationResults([]);
        return;
      }

      try {
        const results = await searchOrganizations(searchQuery.trim());
        if (active) {
          setOrganizationResults(results);
        }
      } catch {
        if (active) {
          setOrganizationResults([]);
        }
      }
    }

    const timeoutId = window.setTimeout(() => {
      void runSearch();
    }, 180);

    return () => {
      active = false;
      window.clearTimeout(timeoutId);
    };
  }, [searchOrganizations, searchQuery, selectedOrganization]);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);

    try {
      if (mode === "login") {
        await login({
          email: formState.email,
          password: formState.password,
          organizationId: selectedOrganization?.id,
          organizationName: selectedOrganization?.name || searchQuery,
        });
      } else {
        await signup({
          name: formState.name || "New Team Member",
          email: formState.email,
          password: formState.password,
          organizationId: selectedOrganization?.id,
          organizationName: selectedOrganization?.name || searchQuery || "Aldervon Systems",
          role,
        });
      }

      router.replace(APP_ROUTES.dashboard);
    } finally {
      setIsSubmitting(false);
    }
  }

  function updateField(field: keyof typeof formState, value: string) {
    setFormState((current) => ({ ...current, [field]: value }));
  }

  return (
    <div className="auth-page">
      <ParityCard className="auth-card" kind="surface">
        <div className="auth-logo">
          <Zap size={28} strokeWidth={2.4} />
        </div>

        <div className="auth-copy">
          <h1 className="auth-title">{mode === "login" ? "Sign In" : "Register"}</h1>
          <p className="auth-subtitle">
            {mode === "login" ? "Access the VBP Lab Environment" : "Provision a new operator profile."}
          </p>
        </div>

        {selectedOrganization ? (
          <div className="tenant-chip">
            <span className="tenant-chip__label">TENANT: {selectedOrganization.name.toUpperCase()}</span>
            <button
              className="tenant-chip__close"
              type="button"
              onClick={() => {
                setSelectedOrganization(null);
                setSearchQuery("");
              }}
            >
              <X size={14} />
            </button>
          </div>
        ) : (
          <div className="auth-tenant-stack">
            <ParityField
              id="organization"
              label="SELECT ORGANIZATION (TENANT)"
              value={searchQuery}
              onChange={(event) => setSearchQuery(event.target.value)}
              autoComplete="off"
              placeholder="Search organization"
              suffix={<Search size={16} />}
            />

            {organizationResults.length ? (
              <div className="tenant-results">
                {organizationResults.map((organization) => (
                  <button
                    key={organization.id}
                    className="tenant-results__item"
                    type="button"
                    onClick={() => {
                      setSelectedOrganization(organization);
                      setSearchQuery(organization.name);
                    }}
                  >
                    {organization.name}
                  </button>
                ))}
              </div>
            ) : null}
          </div>
        )}

        <form className="auth-form" onSubmit={handleSubmit}>
          {mode === "signup" ? (
            <>
              <ParityField
                id="name"
                label="FULL NAME"
                value={formState.name}
                onChange={(event) => updateField("name", event.target.value)}
                autoComplete="name"
              />
              <ParityField
                as="select"
                id="role"
                label="ACCOUNT TYPE"
                value={role}
                onChange={(value) => setRole(value as UserRole)}
                options={[
                  { value: "employee", label: "Employee" },
                  { value: "manager", label: "Manager" },
                ]}
              />
            </>
          ) : null}

          <ParityField
            id="email"
            label="EMAIL ADDRESS"
            value={formState.email}
            onChange={(event) => updateField("email", event.target.value)}
            autoComplete="email"
          />

          <ParityField
            id="password"
            label="PASSWORD"
            type="password"
            value={formState.password}
            onChange={(event) => updateField("password", event.target.value)}
            autoComplete={mode === "login" ? "current-password" : "new-password"}
          />

          {sessionExpired ? <div className="form-error">SESSION EXPIRED</div> : null}

          <ParityButton className="auth-primary" type="submit" fullWidth disabled={isSubmitting}>
            {isSubmitting ? "WORKING..." : mode === "login" ? "AUTHENTICATE" : "INITIALIZE ACCOUNT"}
          </ParityButton>
        </form>

        <div className="auth-links">
          <Link className="auth-link auth-link--accent" href={APP_ROUTES.onboardingStep1}>
            REGISTER NEW ORGANIZATION
          </Link>
          <Link className="auth-link auth-link--muted" href={mode === "login" ? APP_ROUTES.signup : APP_ROUTES.login}>
            {mode === "login" ? "CREATE NEW ACCOUNT" : "BACK TO SIGN IN"}
          </Link>
        </div>
      </ParityCard>
    </div>
  );
}
