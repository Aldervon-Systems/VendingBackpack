"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { MapPin, Plus, Trash2 } from "lucide-react";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityField } from "@/components/parity/parity-field";
import { ParityModalFrame } from "@/components/parity/parity-modal-frame";
import { ParityOverlay } from "@/components/parity/parity-overlay";
import { useAuth } from "@/providers/auth-provider";
import { APP_ROUTES } from "@/lib/routes";

export function AdminModal() {
  const router = useRouter();
  const { session, addMachine, updateWhitelist } = useAuth();
  const [tab, setTab] = useState<"machines" | "whitelist">("machines");
  const [machineName, setMachineName] = useState("");
  const [vin, setVin] = useState("");
  const [lat, setLat] = useState("42.3601");
  const [lng, setLng] = useState("-71.0589");
  const [newEmail, setNewEmail] = useState("");
  const [whitelist, setWhitelist] = useState(["ops@aldervon.com", "warehouse@aldervon.com"]);
  const [error, setError] = useState("");
  const [isSaving, setIsSaving] = useState(false);

  function close() {
    router.back();
    window.setTimeout(() => {
      if (window.location.pathname === APP_ROUTES.admin) {
        router.replace(APP_ROUTES.dashboard);
      }
    }, 0);
  }

  async function handleAddMachine() {
    const organizationId = session?.user.organizationId;
    if (!organizationId) {
      setError("No organization linked to session");
      return;
    }

    const latitude = Number.parseFloat(lat);
    const longitude = Number.parseFloat(lng);

    if (!machineName.trim() || !vin.trim() || Number.isNaN(latitude) || Number.isNaN(longitude)) {
      setError("Provide valid machine details");
      return;
    }

    setIsSaving(true);
    setError("");

    try {
      await addMachine({
        organizationId,
        vin,
        name: machineName,
        lat: latitude,
        lng: longitude,
      });
      setMachineName("");
      setVin("");
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : "Machine creation failed");
    } finally {
      setIsSaving(false);
    }
  }

  async function handleSaveWhitelist() {
    const organizationId = session?.user.organizationId;
    if (!organizationId) {
      setError("No organization linked to session");
      return;
    }

    setIsSaving(true);
    setError("");

    try {
      await updateWhitelist(organizationId, whitelist);
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : "Whitelist update failed");
    } finally {
      setIsSaving(false);
    }
  }

  return (
    <ParityOverlay onBackdropClick={close}>
      <ParityModalFrame title="ORGANIZATION ADMIN" onClose={close} className="admin-modal">
        <div className="admin-tabs">
          <button className="admin-tabs__tab" type="button" data-active={tab === "machines"} onClick={() => setTab("machines")}>
            MACHINES
          </button>
          <button className="admin-tabs__tab" type="button" data-active={tab === "whitelist"} onClick={() => setTab("whitelist")}>
            WHITELIST
          </button>
        </div>

        {tab === "machines" ? (
          <div className="modal-form">
            <div className="admin-block-title">REGISTER NEW MACHINE</div>
            <div className="admin-block-copy">Link hardware to your organization network.</div>
            <ParityField
              id="machine-name"
              label="MACHINE NAME (E.G. UNIT-01)"
              value={machineName}
              onChange={(event) => setMachineName(event.target.value)}
            />
            <ParityField id="vin" label="VIN NUMBER" value={vin} onChange={(event) => setVin(event.target.value)} />
            <div className="admin-grid">
              <ParityField id="latitude" label="LATITUDE" value={lat} onChange={(event) => setLat(event.target.value)} />
              <ParityField id="longitude" label="LONGITUDE" value={lng} onChange={(event) => setLng(event.target.value)} />
            </div>
            <button
              className="admin-utility-link"
              type="button"
              onClick={() => {
                setLat("42.3601");
                setLng("-71.0589");
              }}
            >
              <MapPin size={14} />
              <span>USE DEMO HUB COORDS</span>
            </button>
            <ParityButton fullWidth onClick={handleAddMachine} disabled={isSaving}>
              {isSaving ? "WORKING..." : "REGISTER AS NETWORK NODE"}
            </ParityButton>
          </div>
        ) : (
          <div className="modal-form">
            <div className="admin-block-title">MANAGE EMPLOYEE WHITELIST</div>
            <div className="admin-block-copy">Only these emails will be allowed to signup under your organization.</div>
            <div className="admin-whitelist-entry">
              <div className="admin-whitelist-entry__field">
                <ParityField
                  id="new-whitelist-email"
                  label="EMAIL ADDRESS"
                  value={newEmail}
                  onChange={(event) => setNewEmail(event.target.value)}
                />
              </div>
              <button
                className="admin-whitelist-entry__add"
                type="button"
                onClick={() => {
                  if (!newEmail.trim()) {
                    return;
                  }

                  setWhitelist((currentItems) => [...currentItems, newEmail.trim()]);
                  setNewEmail("");
                }}
              >
                <Plus size={18} />
              </button>
            </div>
            <div className="admin-whitelist-list">
              {whitelist.map((email) => (
                <div key={email} className="admin-whitelist-list__row">
                  <span>{email}</span>
                  <button type="button" onClick={() => setWhitelist((currentItems) => currentItems.filter((item) => item !== email))}>
                    <Trash2 size={14} />
                  </button>
                </div>
              ))}
            </div>
            <ParityButton tone="dark" fullWidth onClick={handleSaveWhitelist} disabled={isSaving}>
              {isSaving ? "WORKING..." : "SAVE WHITELIST"}
            </ParityButton>
          </div>
        )}
        {error ? <div className="form-error form-error--compact">{error.toUpperCase()}</div> : null}
      </ParityModalFrame>
    </ParityOverlay>
  );
}
