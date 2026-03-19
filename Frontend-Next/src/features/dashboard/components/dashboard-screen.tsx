"use client";

import { useEffect, useState } from "react";
import { CircleDollarSign, LaptopMinimal, Radio, TriangleAlert } from "lucide-react";
import { ParityCard } from "@/components/parity/parity-card";
import { ParitySectionHeader } from "@/components/parity/parity-section-header";
import { MockDashboardRepository } from "@/lib/api/mock/mock-dashboard-repository";
import { useAuth } from "@/providers/auth-provider";
import { LoadingScreen } from "@/components/primitives/loading-screen";
import { StatusPill } from "@/components/primitives/status-pill";
import type { DashboardSnapshot } from "@/types/dashboard";

const dashboardRepository = new MockDashboardRepository();

export function DashboardScreen() {
  const { effectiveRole } = useAuth();
  const [snapshot, setSnapshot] = useState<DashboardSnapshot | null>(null);

  useEffect(() => {
    let active = true;

    if (!effectiveRole) {
      return;
    }

    dashboardRepository.getSnapshot(effectiveRole).then((nextSnapshot) => {
      if (active) {
        setSnapshot(nextSnapshot);
      }
    });

    return () => {
      active = false;
    };
  }, [effectiveRole]);

  if (!snapshot) {
    return <LoadingScreen label="Loading dashboard snapshot" />;
  }

  const metricIcons = [LaptopMinimal, Radio, CircleDollarSign];
  const sectionTitle = effectiveRole === "manager" ? "ALL NETWORK NODES" : "ASSIGNED ROUTE NODES";

  return (
    <div className="dashboard-screen">
      <section className="dashboard-block">
        <ParitySectionHeader title="SYSTEM OVERVIEW" subtitle="LIVE ENVIRONMENT METRICS" />
        <div className="dashboard-metrics">
          {snapshot.kpis.map((kpi, index) => {
            const Icon = metricIcons[index] ?? TriangleAlert;

            return (
              <ParityCard key={kpi.label} className="metric-card">
                <div className="metric-card__label">
                  <Icon size={14} />
                  <span>{kpi.label.toUpperCase()}</span>
                </div>
                <div className="metric-card__value">{kpi.value}</div>
              </ParityCard>
            );
          })}
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title={sectionTitle} subtitle="REAL-TIME STATUS & PAYLOAD" />
        <div className="machine-card-list">
          {snapshot.machineSummaries.map((machine) => (
            <ParityCard key={machine.id} className="machine-stop-card">
              <div className="machine-stop-card__header">
                <div>
                  <div className="machine-stop-card__title">UNIT {machine.id}</div>
                  <div className="machine-stop-card__meta">{machine.name.toUpperCase()}</div>
                </div>
                <StatusPill label={machine.status === "online" ? "ONLINE" : "ATTENTION"} tone={machine.status === "online" ? "success" : "warning"} />
              </div>
              <div className="machine-stop-card__details">
                <div className="machine-stop-card__row">
                  <span>OPERATIVE</span>
                  <strong>{machine.assignedTo.toUpperCase()}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>WINDOW</span>
                  <strong>{machine.nextServiceWindow}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>TOP ITEM</span>
                  <strong>{machine.topItem.toUpperCase()}</strong>
                </div>
              </div>
            </ParityCard>
          ))}
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="ROUTE NOTES" subtitle="LIVE OPERATIONS SIGNALS" />
        <div className="notes-list">
          {snapshot.routeHighlights.map((highlight) => (
            <ParityCard key={highlight} className="note-row">
              {highlight}
            </ParityCard>
          ))}
        </div>
      </section>
    </div>
  );
}
