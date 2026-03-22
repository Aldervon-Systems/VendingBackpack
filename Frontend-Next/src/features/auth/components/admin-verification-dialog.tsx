"use client";

import { useState } from "react";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityField } from "@/components/parity/parity-field";
import { ParityModalFrame } from "@/components/parity/parity-modal-frame";
import { useAuth } from "@/providers/auth-provider";

type AdminVerificationDialogProps = {
  onClose: () => void;
  onVerified: () => void;
};

export function AdminVerificationDialog({ onClose, onVerified }: AdminVerificationDialogProps) {
  const { session, verifyAdmin } = useAuth();
  const [adminPassword, setAdminPassword] = useState("");
  const [totpCode, setTotpCode] = useState("");
  const [error, setError] = useState("");

  async function verify() {
    if (!adminPassword.trim() || !totpCode.trim()) {
      setError("Provide both credentials");
      return;
    }

    const organizationId = session?.user.organizationId;
    if (!organizationId) {
      setError("No organization linked to session");
      return;
    }

    try {
      const verified = await verifyAdmin({
        organizationId,
        adminPassword,
        totpCode,
      });

      if (verified) {
        setError("");
        onVerified();
      } else {
        setError("Verification failed");
      }
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : "Verification failed");
    }
  }

  return (
    <ParityModalFrame title="DUAL-KEY CHALLENGE" subtitle="Provide secondary credentials to access administrative backend." onClose={onClose}>
      <div className="modal-form">
        <ParityField
          id="admin-password-verify"
          label="ORGANIZATION ADMIN PASSWORD"
          type="password"
          value={adminPassword}
          onChange={(event) => setAdminPassword(event.target.value)}
        />
        <ParityField
          id="totp-code"
          label="6-DIGIT TOTP CODE"
          value={totpCode}
          onChange={(event) => setTotpCode(event.target.value)}
          inputMode="numeric"
        />
        {error ? <div className="form-error">{error.toUpperCase()}</div> : null}
        <div className="modal-actions">
          <ParityButton tone="ghost" onClick={onClose}>
            CANCEL
          </ParityButton>
          <ParityButton onClick={verify}>VERIFY</ParityButton>
        </div>
      </div>
    </ParityModalFrame>
  );
}
