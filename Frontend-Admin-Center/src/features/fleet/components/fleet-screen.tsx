"use client";

import { ParityCard } from "@/components/parity/parity-card";
import { ParitySectionHeader } from "@/components/parity/parity-section-header";
import { StatusPill } from "@/components/primitives/status-pill";
import { MACHINE_ALERTS, RELEASE_RINGS } from "@/admin-center-data";

function toneForStatus(status: string) {
  if (status === "Healthy") {
    return "success" as const;
  }

  if (status === "Maintenance") {
    return "default" as const;
  }

  return "warning" as const;
}

export function FleetScreen() {
  const healthyCount = MACHINE_ALERTS.filter((machine) => machine.status === "Healthy").length;
  const watchCount = MACHINE_ALERTS.filter((machine) => machine.status === "Watch").length;
  const offlineCount = MACHINE_ALERTS.filter((machine) => machine.status === "Offline").length;
  const maintenanceCount = MACHINE_ALERTS.filter((machine) => machine.status === "Maintenance").length;

  return (
    <div className="dashboard-screen">
      <section className="dashboard-block">
        <ParitySectionHeader title="FLEET COMMAND" subtitle="MACHINE HEALTH AND RELEASE STATE" />
        <div className="dashboard-metrics">
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>MONITORED</span>
            </div>
            <div className="metric-card__value">{MACHINE_ALERTS.length}</div>
            <div className="metric-card__meta">Fleet nodes under admin watch</div>
          </ParityCard>
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>HEALTHY</span>
            </div>
            <div className="metric-card__value">{healthyCount}</div>
            <div className="metric-card__meta">Machines with recent heartbeats</div>
          </ParityCard>
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>WATCH</span>
            </div>
            <div className="metric-card__value">{watchCount}</div>
            <div className="metric-card__meta">Machines needing follow-up</div>
          </ParityCard>
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>OFFLINE / MAINTENANCE</span>
            </div>
            <div className="metric-card__value">{offlineCount + maintenanceCount}</div>
            <div className="metric-card__meta">Active interventions required</div>
          </ParityCard>
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="MACHINE ALERTS" subtitle="FLEET CONTROL ACROSS ORGANIZATIONS" />
        <div className="machine-card-list">
          {MACHINE_ALERTS.map((machine) => (
            <ParityCard key={machine.name} className="machine-stop-card">
              <div className="machine-stop-card__header">
                <div>
                  <div className="machine-stop-card__title">{machine.name}</div>
                  <div className="machine-stop-card__meta">
                    {machine.organization} · {machine.site}
                  </div>
                </div>
                <StatusPill label={machine.status.toUpperCase()} tone={toneForStatus(machine.status)} />
              </div>
              <div className="machine-stop-card__details">
                <div className="machine-stop-card__row">
                  <span>FIRMWARE</span>
                  <strong>{machine.firmware}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>HEARTBEAT</span>
                  <strong>{machine.heartbeat}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>NEXT ACTION</span>
                  <strong>{machine.nextAction}</strong>
                </div>
              </div>
            </ParityCard>
          ))}
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="FIRMWARE SUMMARY" subtitle="CROSS-TENANT COMMAND POSTURE" />
        <div className="machine-card-list">
          {RELEASE_RINGS.map((ring) => (
            <ParityCard key={ring.title} className="machine-stop-card">
              <div className="machine-stop-card__header">
                <div>
                  <div className="machine-stop-card__title">{ring.title}</div>
                  <div className="machine-stop-card__meta">Rollout summary</div>
                </div>
              </div>
              <div className="machine-stop-card__details">
                <div className="machine-stop-card__row">
                  <span>SUMMARY</span>
                  <strong>{ring.copy}</strong>
                </div>
              </div>
            </ParityCard>
          ))}
        </div>
      </section>
    </div>
  );
}
