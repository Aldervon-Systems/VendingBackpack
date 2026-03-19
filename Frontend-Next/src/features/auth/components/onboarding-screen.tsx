"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, CheckCircle2, Plus, Trash2 } from "lucide-react";
import { useMemo, useState } from "react";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityCard } from "@/components/parity/parity-card";
import { ParityField } from "@/components/parity/parity-field";
import { APP_ROUTES } from "@/lib/routes";

type OnboardingScreenProps = {
  step: 1 | 2 | 3;
};

export function OnboardingScreen({ step }: OnboardingScreenProps) {
  const router = useRouter();
  const [managerEmail, setManagerEmail] = useState("renee@aldervon.com");
  const [managerPassword, setManagerPassword] = useState("password123");
  const [organizationName, setOrganizationName] = useState("Aldervon Systems");
  const [adminPassword, setAdminPassword] = useState("admin");
  const [nextEmail, setNextEmail] = useState("");
  const [whitelist, setWhitelist] = useState<string[]>(["ops@aldervon.com", "warehouse@aldervon.com"]);

  const progressIndex = step - 1;
  const titleMap = useMemo(
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
        nextHref: APP_ROUTES.login,
      },
    }),
    [],
  );

  const current = titleMap[step];

  return (
    <div className="onboarding-page">
      <div className="onboarding-shell">
        <div className="onboarding-topbar">
          <Link className="onboarding-back" href={APP_ROUTES.login}>
            <ArrowLeft size={16} />
          </Link>
          <div className="eyebrow">ORG ONBOARDING</div>
        </div>

        <div className="onboarding-progress">
          {Array.from({ length: 4 }).map((_, index) => (
            <span key={index} className="onboarding-progress__bar" data-active={index <= progressIndex} />
          ))}
        </div>

        <ParityCard className="onboarding-card">
          <div className="onboarding-step-title">{current.title}</div>
          <p className="onboarding-step-subtitle">{current.subtitle}</p>

          {step === 1 ? (
            <div className="onboarding-fields">
              <ParityField
                id="manager-email"
                label="MANAGER EMAIL"
                value={managerEmail}
                onChange={(event) => setManagerEmail(event.target.value)}
              />
              <ParityField
                id="manager-password"
                label="PERSONAL PASSWORD"
                type="password"
                value={managerPassword}
                onChange={(event) => setManagerPassword(event.target.value)}
              />
            </div>
          ) : null}

          {step === 2 ? (
            <div className="onboarding-fields">
              <ParityField
                id="organization-name"
                label="ORGANIZATION NAME"
                value={organizationName}
                onChange={(event) => setOrganizationName(event.target.value)}
              />
              <ParityField
                id="admin-password"
                label="ORG ADMIN PASSWORD (MASTER KEY)"
                type="password"
                value={adminPassword}
                onChange={(event) => setAdminPassword(event.target.value)}
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
                    value={nextEmail}
                    onChange={(event) => setNextEmail(event.target.value)}
                  />
                </div>
                <button
                  className="whitelist-entry__add"
                  type="button"
                  onClick={() => {
                    if (!nextEmail.trim()) {
                      return;
                    }

                    setWhitelist((currentItems) => [...currentItems, nextEmail.trim()]);
                    setNextEmail("");
                  }}
                >
                  <Plus size={18} />
                </button>
              </div>

              <div className="whitelist-list">
                {whitelist.map((email) => (
                  <div key={email} className="whitelist-list__row">
                    <span>{email}</span>
                    <button
                      type="button"
                      className="whitelist-list__remove"
                      onClick={() => setWhitelist((currentItems) => currentItems.filter((item) => item !== email))}
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                ))}
              </div>

              <div className="onboarding-note">
                <CheckCircle2 size={16} />
                <span>Mock provisioning state only. Visual shell matches the Flutter onboarding steps.</span>
              </div>
            </div>
          ) : null}

          <ParityButton className="onboarding-button" fullWidth onClick={() => router.push(current.nextHref)}>
            {current.buttonLabel}
          </ParityButton>
        </ParityCard>
      </div>
    </div>
  );
}
