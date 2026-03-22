"use client";

import { ParityCard } from "@/components/parity/parity-card";
import { ParitySectionHeader } from "@/components/parity/parity-section-header";
import { StatusPill } from "@/components/primitives/status-pill";
import { ACCESS_POLICIES, APPROVAL_REQUESTS, ADMIN_PROFILES } from "@/admin-center-data";

export function AccessScreen() {
  return (
    <div className="dashboard-screen">
      <section className="dashboard-block">
        <ParitySectionHeader title="ADMIN DIRECTORY" subtitle="APPROVED OPERATOR ROSTER" />
        <div className="dashboard-metrics">
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>APPROVED ADMINS</span>
            </div>
            <div className="metric-card__value">{ADMIN_PROFILES.length}</div>
            <div className="metric-card__meta">Approved platform operators</div>
          </ParityCard>
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>PENDING REQUESTS</span>
            </div>
            <div className="metric-card__value">{APPROVAL_REQUESTS.length}</div>
            <div className="metric-card__meta">Access approvals awaiting review</div>
          </ParityCard>
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>POLICY SETS</span>
            </div>
            <div className="metric-card__value">{ACCESS_POLICIES.length}</div>
            <div className="metric-card__meta">Rules enforcing session safety</div>
          </ParityCard>
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="APPROVED ADMIN DIRECTORY" subtitle="WHO CAN ENTER THIS WORKSPACE" />
        <div className="machine-card-list">
          {ADMIN_PROFILES.map((profile) => (
            <ParityCard key={profile.email} className="machine-stop-card">
              <div className="machine-stop-card__header">
                <div>
                  <div className="machine-stop-card__title">{profile.name}</div>
                  <div className="machine-stop-card__meta">{profile.title}</div>
                </div>
                <StatusPill label={profile.clearance.toUpperCase()} tone="success" />
              </div>
              <div className="machine-stop-card__details">
                <div className="machine-stop-card__row">
                  <span>EMAIL</span>
                  <strong>{profile.email}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>SHIFT</span>
                  <strong>{profile.shift}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>SCOPE</span>
                  <strong>{profile.scope}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>LAST ACTIVE</span>
                  <strong>{profile.lastActive}</strong>
                </div>
              </div>
            </ParityCard>
          ))}
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="PENDING APPROVALS" subtitle="ADMIN ACCESS REVIEW AND APPROVAL FLOW" />
        <div className="machine-card-list">
          {APPROVAL_REQUESTS.map((request) => (
            <ParityCard key={`${request.name}-${request.organization}`} className="machine-stop-card">
              <div className="machine-stop-card__header">
                <div>
                  <div className="machine-stop-card__title">{request.name}</div>
                  <div className="machine-stop-card__meta">{request.organization}</div>
                </div>
                <StatusPill label="PENDING" tone="warning" />
              </div>
              <div className="machine-stop-card__details">
                <div className="machine-stop-card__row">
                  <span>SCOPE</span>
                  <strong>{request.scope}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>AGE</span>
                  <strong>{request.age}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>SPONSOR</span>
                  <strong>{request.sponsor}</strong>
                </div>
              </div>
            </ParityCard>
          ))}
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="ACCESS POLICIES" subtitle="SESSION SAFETY AND CONTROL RULES" />
        <div className="notes-list">
          {ACCESS_POLICIES.map((policy) => (
            <ParityCard key={policy.title} className="note-row">
              <strong>{policy.title}</strong>
              <p>{policy.copy}</p>
            </ParityCard>
          ))}
        </div>
      </section>
    </div>
  );
}
