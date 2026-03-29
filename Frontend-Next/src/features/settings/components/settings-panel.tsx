"use client";

import { CheckCircle2, ShieldCheck, UserRound } from "lucide-react";
import { useRouter } from "next/navigation";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityCard } from "@/components/parity/parity-card";
import { useAuth } from "@/providers/auth-provider";
import { useShell } from "@/providers/shell-provider";
import { APP_ROUTES } from "@/lib/routes";

type SettingsPanelProps = {
  onClose: () => void;
};

export function SettingsPanel({ onClose }: SettingsPanelProps) {
  const router = useRouter();
  const { session, actualRole, effectiveRole, logout, setEmployeeView } = useAuth();
  const { adminVerified, setAdminVerificationOpen } = useShell();
  const isManager = actualRole === "manager";
  const employeeSimulationEnabled = isManager && effectiveRole === "employee";

  function navigateTo(href: string) {
    onClose();
    router.push(href);
  }

  return (
    <div className="settings-panel">
      <ParityCard className="settings-panel__sheet" kind="surface">
        <div className="settings-panel__header">
          <div>
            <div className="parity-section-header__title">CONFIGURATION / SESSION</div>
            <div className="parity-section-header__subtitle">LOCAL SHELL CONTROLS</div>
          </div>
          <ParityButton tone="ghost" onClick={onClose}>
            CLOSE
          </ParityButton>
        </div>

        <div className="settings-panel__stack">
          <ParityCard kind="foundation" className="settings-panel__group">
            <div className="settings-panel__row">
              <div className="settings-panel__row-label">
                <UserRound size={16} />
                <span>SESSION OWNER</span>
              </div>
              <strong>{session?.user.name}</strong>
            </div>
            <div className="settings-panel__row">
              <span>ORGANIZATION</span>
              <strong>{session?.user.organizationName}</strong>
            </div>
            <div className="settings-panel__row">
              <span>ACTIVE VIEW</span>
              <strong>{effectiveRole === "manager" ? "Manager" : "Employee"}</strong>
            </div>
          </ParityCard>

          {isManager ? (
            <>
              <ParityCard kind="foundation" className="settings-panel__group">
                <div className="settings-panel__row settings-panel__row--start">
                  <div>
                    <div className="settings-panel__toggle-title">EMPLOYEE SIMULATION</div>
                    <div className="settings-panel__toggle-copy">Restricts view to standard operative nodes.</div>
                  </div>
                  <button
                    className="settings-panel__switch"
                    type="button"
                    role="switch"
                    aria-label="Employee simulation"
                    aria-checked={employeeSimulationEnabled}
                    data-active={employeeSimulationEnabled}
                    onClick={async () => {
                      await setEmployeeView(!employeeSimulationEnabled);
                    }}
                  >
                    <span className="settings-panel__switch-track">
                      <span className="settings-panel__switch-thumb" />
                    </span>
                    <span className="settings-panel__switch-label">{employeeSimulationEnabled ? "ENABLED" : "DISABLED"}</span>
                  </button>
                </div>
              </ParityCard>

              <ParityCard kind="foundation" className={`settings-panel__group ${adminVerified ? "settings-panel__group--verified" : ""}`}>
                <div className="settings-panel__row">
                  <div className="settings-panel__row-label">
                    <ShieldCheck size={16} />
                    <span>ORG ADMIN ACCESS</span>
                  </div>
                  <span className={`settings-panel__status ${adminVerified ? "settings-panel__status--verified" : ""}`}>
                    {adminVerified ? "Verified" : "Pending"}
                  </span>
                </div>
                <div className="settings-panel__toggle-copy">
                  {adminVerified ? "Verified: Administrative commands unlocked" : "Requires Dual-Key Challenge"}
                </div>
                <div className="settings-panel__actions">
                  {adminVerified ? (
                    <div className="settings-panel__verified-indicator">
                      <CheckCircle2 size={16} />
                      <span>VERIFIED</span>
                    </div>
                  ) : (
                    <ParityButton onClick={() => setAdminVerificationOpen(true)}>VERIFY</ParityButton>
                  )}
                  <ParityButton tone="ghost" onClick={() => navigateTo(APP_ROUTES.admin)}>
                    OPEN ADMIN CONSOLE
                  </ParityButton>
                </div>
              </ParityCard>

              <ParityCard kind="foundation" className="settings-panel__group">
                <div className="settings-panel__toggle-title">PROVISION NEW ORGANIZATION</div>
                <div className="settings-panel__toggle-copy">
                  Launch the onboarding flow to create a new organization workspace and administrative keychain.
                </div>
                <div className="settings-panel__actions">
                  <ParityButton onClick={() => navigateTo(APP_ROUTES.onboardingStep1)}>OPEN PROVISIONING</ParityButton>
                </div>
              </ParityCard>
            </>
          ) : (
            <ParityCard kind="foundation" className="settings-panel__group">
              <div className="settings-panel__restricted">NO CONFIGURABLE PARAMETERS FOR THIS SECURITY LEVEL</div>
              <div className="settings-panel__toggle-copy">
                Session details remain visible, but manager-only controls are locked while operating in employee mode.
              </div>
            </ParityCard>
          )}
        </div>

        <div className="settings-panel__footer">
          <ParityButton tone="dark" fullWidth onClick={onClose}>
            DISMISS
          </ParityButton>
          <ParityButton
            tone="ghost"
            fullWidth
            onClick={async () => {
              await logout();
              onClose();
              router.replace(APP_ROUTES.login);
            }}
          >
            SIGN OUT
          </ParityButton>
        </div>
      </ParityCard>
    </div>
  );
}
