"use client";

import Link from "next/link";
import { ShieldCheck, UserRound } from "lucide-react";
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

          {actualRole === "manager" ? (
            <ParityCard kind="foundation" className="settings-panel__group">
              <div className="settings-panel__row">
                <div>
                  <div className="settings-panel__toggle-title">EMPLOYEE SIMULATION</div>
                  <div className="settings-panel__toggle-copy">Preview the employee shell without losing manager access.</div>
                </div>
                <ParityButton tone="ghost" onClick={() => setEmployeeView(effectiveRole === "manager")}>
                  {effectiveRole === "manager" ? "ENABLE" : "RETURN"}
                </ParityButton>
              </div>
            </ParityCard>
          ) : null}

          <ParityCard kind="foundation" className={`settings-panel__group ${adminVerified ? "settings-panel__group--verified" : ""}`}>
            <div className="settings-panel__row">
              <div className="settings-panel__row-label">
                <ShieldCheck size={16} />
                <span>ORG ADMIN ACCESS</span>
              </div>
              <strong>{adminVerified ? "Verified" : "Pending"}</strong>
            </div>
            <div className="settings-panel__toggle-copy">
              Administrative workflows remain modal-based and require a secondary credential challenge.
            </div>
            <div className="settings-panel__actions">
              <ParityButton onClick={() => setAdminVerificationOpen(true)}>
                {adminVerified ? "RE-VERIFY ACCESS" : "VERIFY ACCESS"}
              </ParityButton>
              <Link className="settings-panel__link" href={APP_ROUTES.admin} onClick={onClose}>
                OPEN ADMIN CONSOLE
              </Link>
            </div>
          </ParityCard>
        </div>

        <div className="settings-panel__footer">
          <ParityButton
            tone="ghost"
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
