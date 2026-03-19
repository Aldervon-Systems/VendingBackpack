"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, CheckCircle2, Plus, Trash2 } from "lucide-react";
import { useMemo, useState } from "react";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityCard } from "@/components/parity/parity-card";
import { ParityField } from "@/components/parity/parity-field";
import { useAuth } from "@/providers/auth-provider";
import { APP_ROUTES } from "@/lib/routes";
import { useOnboardingDraft } from "@/hooks/use-onboarding-draft";

type OnboardingScreenProps = {
  step: 1 | 2 | 3 | 4;
};

type StepDescriptor = {
  title: string;
  subtitle: string;
  buttonLabel: string;
  nextHref: string;
};

export function OnboardingScreen({ step }: OnboardingScreenProps) {
  const router = useRouter();
  const { createOrganization } = useAuth();
  const { draft, setDraft, resetDraft } = useOnboardingDraft();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [newWhitelistEmail, setNewWhitelistEmail] = useState("");
  const [error, setError] = useState("");
  const progressIndex = step - 1;

  const current = useMemo<Record<1 | 2 | 3 | 4, StepDescriptor>>(
    () => ({
      1: {
        title: "MANAGER VALIDATION",
        subtitle: "Only active Managers can provision new Organizations.",
        buttonLabel: "CONTINUE",
        nextHref: APP_ROUTES.onboardingStep2,
      },
      2: {
        title: "ORGANIZATION DETAILS",
        subtitle: "Define your corporate entity and administrative keys.",
        buttonLabel: "CONTINUE",
        nextHref: APP_ROUTES.onboardingStep3,
      },
      3: {
        title: "ACCESS CONTROL LIST (WHITELIST)",
        subtitle: "Add authorized email addresses for this Organization.",
        buttonLabel: "PROVISION ORGANIZATION",
        nextHref: APP_ROUTES.onboardingStep4,
      },
      4: {
        title: "IDENTITY SYNC",
        subtitle: "Save the TOTP seed before completing setup.",
        buttonLabel: "COMPLETE SETUP",
        nextHref: APP_ROUTES.login,
      },
    }),
    [],
  );

  async function handleStepThreeProvision() {
    setIsSubmitting(true);
    setError("");

    try {
      const result = await createOrganization({
        name: draft.organizationName,
        managerEmail: draft.managerEmail,
        managerPassword: draft.managerPassword,
        adminPassword: draft.adminPassword,
        whitelist: draft.whitelist,
      });

      setDraft((currentDraft) => ({
        ...currentDraft,
        organizationId: result.organizationId,
        totpSeed: result.totpSeed,
        totpUri: result.totpUri,
      }));
      router.push(APP_ROUTES.onboardingStep4);
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : "Provision failed");
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleCompleteSetup() {
    resetDraft();
    router.replace(APP_ROUTES.login);
  }

  return (
    <div className="onboarding-page">
      <div className="onboarding-shell">
        <div className="onboarding-topbar">
          <Link className="onboarding-back" href={APP_ROUTES.login}>
            <ArrowLeft size={16} />
          </Link>
          <div className="eyebrow">ORG ONBOARDING</div>
        </div>

        <div className="onboarding-progress" aria-label="Organization onboarding progress">
          {Array.from({ length: 4 }).map((_, index) => (
            <span key={index} className="onboarding-progress__bar" data-active={index <= progressIndex} />
          ))}
        </div>

        <ParityCard className="onboarding-card">
          <div className="onboarding-step-title">{current[step].title}</div>
          <p className="onboarding-step-subtitle">{current[step].subtitle}</p>

          {step === 1 ? (
            <div className="onboarding-fields">
              <ParityField
                id="manager-email"
                label="MANAGER EMAIL"
                value={draft.managerEmail}
                onChange={(event) => setDraft((currentDraft) => ({ ...currentDraft, managerEmail: event.target.value }))}
              />
              <ParityField
                id="manager-password"
                label="PERSONAL PASSWORD"
                type="password"
                value={draft.managerPassword}
                onChange={(event) => setDraft((currentDraft) => ({ ...currentDraft, managerPassword: event.target.value }))}
              />
            </div>
          ) : null}

          {step === 2 ? (
            <div className="onboarding-fields">
              <ParityField
                id="organization-name"
                label="ORGANIZATION NAME"
                value={draft.organizationName}
                onChange={(event) => setDraft((currentDraft) => ({ ...currentDraft, organizationName: event.target.value }))}
              />
              <ParityField
                id="admin-password"
                label="ORG ADMIN PASSWORD (MASTER KEY)"
                type="password"
                value={draft.adminPassword}
                onChange={(event) => setDraft((currentDraft) => ({ ...currentDraft, adminPassword: event.target.value }))}
              />
            </div>
          ) : null}

          {step === 3 ? (
            <div className="onboarding-fields">
              <div className="whitelist-entry">
                <div className="whitelist-entry__field">
                  <ParityField
                    id="whitelist-email"
                    label="ADD EMAIL"
                    value={newWhitelistEmail}
                    placeholder="Add an allowed email and press +"
                    onChange={(event) => setNewWhitelistEmail(event.target.value)}
                  />
                </div>
                <button
                  className="whitelist-entry__add"
                  type="button"
                  onClick={() => {
                    if (!newWhitelistEmail.trim()) {
                      return;
                    }

                    setDraft((currentDraft) => ({
                      ...currentDraft,
                      whitelist: [...currentDraft.whitelist, newWhitelistEmail.trim()],
                    }));
                    setNewWhitelistEmail("");
                  }}
                >
                  <Plus size={18} />
                </button>
              </div>

              <div className="whitelist-list">
                {draft.whitelist.map((email) => (
                  <div key={email} className="whitelist-list__row">
                    <span>{email}</span>
                    <button
                      type="button"
                      className="whitelist-list__remove"
                      onClick={() =>
                        setDraft((currentDraft) => ({
                          ...currentDraft,
                          whitelist: currentDraft.whitelist.filter((item) => item !== email),
                        }))
                      }
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                ))}
              </div>

              <div className="onboarding-note">
                <CheckCircle2 size={16} />
                <span>Provisioning now creates the organization and returns the TOTP seed for step four.</span>
              </div>
            </div>
          ) : null}

          {step === 4 ? (
            <div className="onboarding-fields">
              <div className="totp-seed-block">
                <div className="parity-field__label">TOTP SEED</div>
                <code className="totp-seed-block__value">{draft.totpSeed || "PENDING PROVISION"}</code>
              </div>
              {draft.totpUri ? <div className="muted totp-seed-block__uri">{draft.totpUri}</div> : null}
              <div className="onboarding-note">
                <CheckCircle2 size={16} />
                <span>Save this seed securely. You will need it to verify administrative changes.</span>
              </div>
            </div>
          ) : null}

          {error ? <div className="form-error">{error.toUpperCase()}</div> : null}

          <ParityButton
            className="onboarding-button"
            fullWidth
            onClick={
              step === 1 || step === 2
                ? () => router.push(current[step].nextHref)
                : step === 3
                  ? handleStepThreeProvision
                  : handleCompleteSetup
            }
            disabled={isSubmitting}
          >
            {isSubmitting ? "WORKING..." : current[step].buttonLabel}
          </ParityButton>
        </ParityCard>
      </div>
    </div>
  );
}
