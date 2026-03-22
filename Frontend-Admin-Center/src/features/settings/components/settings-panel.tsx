"use client";

import Link from "next/link";
import { ShieldCheck, UserRound } from "lucide-react";
import { useRouter } from "next/navigation";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityCard } from "@/components/parity/parity-card";
import { useAuth } from "@/providers/auth-provider";
import { APP_ROUTES } from "@/lib/routes";

type SettingsPanelProps = {
  onClose: () => void;
};

function formatMoment(value: string | undefined) {
  if (!value) {
    return "Unknown";
  }

  return new Intl.DateTimeFormat("en-US", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}

export function SettingsPanel({ onClose }: SettingsPanelProps) {
  const router = useRouter();
  const { session, logout } = useAuth();

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
              <span>TITLE</span>
              <strong>{session?.user.title}</strong>
            </div>
            <div className="settings-panel__row">
              <span>CLEARANCE</span>
              <strong>{session?.user.clearance}</strong>
            </div>
            <div className="settings-panel__row">
              <span>SCOPE</span>
              <strong>{session?.user.scope}</strong>
            </div>
          </ParityCard>

          <ParityCard kind="foundation" className="settings-panel__group">
            <div className="settings-panel__row">
              <div className="settings-panel__row-label">
                <ShieldCheck size={16} />
                <span>SESSION WINDOW</span>
              </div>
              <strong>8 HOURS</strong>
            </div>
            <div className="settings-panel__toggle-copy">
              This demo session persists locally so the admin shell can be reviewed before backend authentication is wired
              in.
            </div>
            <div className="settings-panel__row">
              <span>ISSUED</span>
              <strong>{formatMoment(session?.issuedAt)}</strong>
            </div>
            <div className="settings-panel__row">
              <span>EXPIRES</span>
              <strong>{formatMoment(session?.expiresAt)}</strong>
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
          <Link className="settings-panel__link" href={APP_ROUTES.overview} onClick={onClose}>
            RETURN TO OVERVIEW
          </Link>
        </div>
      </ParityCard>
    </div>
  );
}
