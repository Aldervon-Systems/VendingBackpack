"use client";

import { useEffect, useState } from "react";
import { CircleDollarSign, LaptopMinimal, Radio, TriangleAlert } from "lucide-react";
import { ParityCard } from "@/components/parity/parity-card";
import { ParitySectionHeader } from "@/components/parity/parity-section-header";
import { LoadingScreen } from "@/components/primitives/loading-screen";
import { StatusPill } from "@/components/primitives/status-pill";
import { apiRequest } from "@/lib/api/api-client";
import { MockDashboardRepository } from "@/lib/api/mock/mock-dashboard-repository";
import { useAuth } from "@/providers/auth-provider";
import type { DashboardSnapshot } from "@/types/dashboard";

const fallbackRepository = new MockDashboardRepository();

type LiveMachine = {
  id: string;
  name: string;
  status?: string;
  battery?: number;
};

function buildLiveSnapshot(
  role: "manager" | "employee",
  inventory: Record<string, Array<{ sku: string; name: string; qty: number; barcode: string }>>,
  employees: Array<{ id: string; name: string }>,
  dailyStats: Array<{ amount?: number }>,
  machines: LiveMachine[],
): DashboardSnapshot | null {
  const machineEntries: LiveMachine[] = machines.length
    ? machines
    : Object.entries(inventory).map(([id, rows]) => ({
        id,
        name: `Machine ${id}`,
        status: rows.some((row) => row.qty > 0) ? "online" : "attention",
      }));

  if (!machineEntries.length && !employees.length && !dailyStats.length && !Object.keys(inventory).length) {
    return null;
  }

  const latestDailyStat = dailyStats.length ? dailyStats[dailyStats.length - 1] : null;
  const revenueToday = latestDailyStat ? Number(latestDailyStat.amount ?? 0) : 0;
  const topItems = Object.values(inventory).flat();
  const activeMachineCount = machineEntries.filter((machine) => machine.status !== "attention").length;
  const totalMachineCount = machineEntries.length;

  return {
    heroLabel: role === "manager" ? "Fleet revenue today" : "Your route progress",
    heroValue:
      role === "manager"
        ? `$${revenueToday.toLocaleString("en-US", { maximumFractionDigits: 0 }) || "0"}`
        : `${Math.min(activeMachineCount, totalMachineCount)} / ${Math.max(totalMachineCount, 1)} stops`,
    heroNote:
      role === "manager"
        ? `${totalMachineCount || 0} machines reporting and ${employees.length || 0} employees loaded from the backend.`
        : `${topItems.length || 0} warehouse rows remain available for the current route.`,
    kpis:
      role === "manager"
        ? [
            { label: "Active machines", value: String(activeMachineCount || 0), tone: "success" as const },
            { label: "Employees", value: String(employees.length || 0), tone: "default" as const },
            { label: "Revenue today", value: `$${revenueToday.toLocaleString("en-US", { maximumFractionDigits: 0 }) || "0"}`, tone: "warning" as const },
          ]
        : [
            { label: "Stops left", value: String(Math.max(totalMachineCount - activeMachineCount, 0)), tone: "default" as const },
            { label: "Machines online", value: String(activeMachineCount || 0), tone: "success" as const },
            { label: "Low stock alerts", value: String(topItems.filter((row) => row.qty <= 1).length), tone: "warning" as const },
          ],
    machineSummaries: machineEntries.slice(0, 3).map((machine, index) => {
      const inventoryRows = inventory[machine.id] ?? [];
      const topItem = inventoryRows[0]?.name ?? (index === 0 ? "Cold Brew" : "Inventory rows pending");

      return {
        id: machine.id,
        name: machine.name,
        status: machine.status === "attention" ? "attention" : "online",
        assignedTo: role === "manager" ? (employees[index]?.name ?? "Unassigned") : "You",
        nextServiceWindow: index === 0 ? "11:30 AM" : index === 1 ? "1:15 PM" : "3:45 PM",
        topItem,
      };
    }),
    routeHighlights: [
      `${totalMachineCount || 0} machines reporting through the live API.`,
      `${employees.length || 0} employees loaded from backend fixtures.`,
      dailyStats.length ? `Most recent revenue entry is $${revenueToday.toLocaleString("en-US", { maximumFractionDigits: 0 }) || "0"}.` : "No daily stats have been recorded yet.",
    ],
  };
}

export function DashboardScreen() {
  const { effectiveRole } = useAuth();
  const [snapshot, setSnapshot] = useState<DashboardSnapshot | null>(null);

  useEffect(() => {
    let active = true;
    const role = effectiveRole;

    if (!role) {
      return;
    }

    async function loadSnapshot() {
      try {
        const [inventory, employees, dailyStats, machines] = await Promise.all([
          apiRequest<Record<string, Array<{ sku: string; name: string; qty: number; barcode: string }>>>("/inventory"),
          apiRequest<Array<{ id: string; name: string }>>("/employees"),
          apiRequest<Array<{ amount?: number }>>("/daily_stats"),
          apiRequest<Array<{ id: string; name: string; status?: string }>>("/machines"),
        ]);

        const liveSnapshot = buildLiveSnapshot(role!, inventory ?? {}, employees ?? [], dailyStats ?? [], machines ?? []);
        const nextSnapshot = liveSnapshot ?? (await fallbackRepository.getSnapshot(role!));

        if (active) {
          setSnapshot(nextSnapshot);
        }
      } catch {
        const fallbackSnapshot = await fallbackRepository.getSnapshot(role!);
        if (active) {
          setSnapshot(fallbackSnapshot);
        }
      }
    }

    void loadSnapshot();

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
