"use client";

import { ParityCard } from "@/components/parity/parity-card";
import { ParitySectionHeader } from "@/components/parity/parity-section-header";
import { StatusPill } from "@/components/primitives/status-pill";
import { useIncidentsViewModel } from "@/features/incidents/hooks/use-incidents-view-model";

function toneForSeverity(severity: string) {
  if (severity === "Critical" || severity === "High") {
    return "warning" as const;
  }

  return "default" as const;
}

export function IncidentsScreen() {
  const { incidents, playbook, openCount, criticalCount, highCount, mediumCount } = useIncidentsViewModel();

  return (
    <div className="dashboard-screen">
      <section className="dashboard-block">
        <ParitySectionHeader title="INCIDENT COMMAND" subtitle="RESPONSE QUEUE" />
        <div className="dashboard-metrics">
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>OPEN</span>
            </div>
            <div className="metric-card__value">{openCount}</div>
            <div className="metric-card__meta">Total incidents awaiting action</div>
          </ParityCard>
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>CRITICAL</span>
            </div>
            <div className="metric-card__value">{criticalCount}</div>
            <div className="metric-card__meta">Immediate command queue</div>
          </ParityCard>
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>HIGH</span>
            </div>
            <div className="metric-card__value">{highCount}</div>
            <div className="metric-card__meta">High-priority follow-up</div>
          </ParityCard>
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>MEDIUM</span>
            </div>
            <div className="metric-card__value">{mediumCount}</div>
            <div className="metric-card__meta">Tracked recovery items</div>
          </ParityCard>
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="INCIDENT BOARD" subtitle="EVERY ACTIVE PLATFORM ISSUE" />
        <div className="machine-card-list">
          {incidents.map((incident) => (
            <ParityCard key={incident.title} className="machine-stop-card">
              <div className="machine-stop-card__header">
                <div>
                  <div className="machine-stop-card__title">{incident.title}</div>
                  <div className="machine-stop-card__meta">{incident.organization}</div>
                </div>
                <StatusPill label={incident.severity.toUpperCase()} tone={toneForSeverity(incident.severity)} />
              </div>
              <div className="machine-stop-card__details">
                <div className="machine-stop-card__row">
                  <span>OWNER</span>
                  <strong>{incident.owner}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>ETA</span>
                  <strong>{incident.eta}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>IMPACT</span>
                  <strong>{incident.impact}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>NOTE</span>
                  <strong>{incident.note}</strong>
                </div>
              </div>
            </ParityCard>
          ))}
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="OPERATOR RULES" subtitle="DURING ACTIVE INCIDENTS" />
        <div className="notes-list">
          {playbook.map((step) => (
            <ParityCard key={step.title} className="note-row">
              <strong>{step.title}</strong>
              <p>{step.copy}</p>
            </ParityCard>
          ))}
        </div>
      </section>
    </div>
  );
}
