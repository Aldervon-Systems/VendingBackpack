"use client";

import { apiRequest } from "@/lib/api/api-client";
import type { DashboardRepository } from "@/lib/api/interfaces/dashboard-repository";
import type { UserRole } from "@/types/auth";
import type { DashboardSnapshot, DashboardViewPreferences } from "@/types/dashboard";

type LiveMachine = {
  id: string;
  name: string;
  status?: string;
  battery?: number;
};

type FeedKey = "inventory" | "employees" | "dailyStats" | "machines";

function formatFeedLabel(feedKey: FeedKey) {
  switch (feedKey) {
    case "inventory":
      return "inventory";
    case "employees":
      return "employees";
    case "dailyStats":
      return "daily stats";
    case "machines":
      return "machines";
  }
}

function createUnavailableSnapshot(role: UserRole, failedFeeds: FeedKey[], hasAnyLiveData: boolean): DashboardSnapshot {
  const feedSummary = failedFeeds.length
    ? `Live ${failedFeeds.map(formatFeedLabel).join(", ")} ${failedFeeds.length === 1 ? "is" : "are"} currently unavailable.`
    : "No live dashboard data is available for this session yet.";

  return {
    heroLabel: role === "manager" ? "Fleet revenue today" : "Your route progress",
    heroValue: role === "manager" ? "$0" : "0 / 0 stops",
    heroNote: hasAnyLiveData ? feedSummary : `Dashboard feed unavailable. ${feedSummary}`,
    kpis:
      role === "manager"
        ? [
            { label: "Active machines", value: "0", tone: "default" as const },
            { label: "Employees", value: "0", tone: "default" as const },
            { label: "Revenue today", value: "$0", tone: "warning" as const },
          ]
        : [
            { label: "Stops left", value: "0", tone: "default" as const },
            { label: "Machines online", value: "0", tone: "default" as const },
            { label: "Low stock alerts", value: "0", tone: "warning" as const },
          ],
    machineSummaries: [],
    routeHighlights: [feedSummary],
  };
}

function appendFeedWarning(snapshot: DashboardSnapshot, failedFeeds: FeedKey[]): DashboardSnapshot {
  if (!failedFeeds.length) {
    return snapshot;
  }

  const feedSummary = `Unavailable live feeds: ${failedFeeds.map(formatFeedLabel).join(", ")}.`;

  return {
    ...snapshot,
    heroNote: `${snapshot.heroNote} ${feedSummary}`.trim(),
    routeHighlights: [...snapshot.routeHighlights, feedSummary],
  };
}

function buildLiveSnapshot(
  role: UserRole,
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

export class ApiDashboardRepository implements DashboardRepository {
  async getSnapshot(role: UserRole): Promise<DashboardSnapshot> {
    const [inventoryResult, employeesResult, dailyStatsResult, machinesResult] = await Promise.allSettled([
      apiRequest<Record<string, Array<{ sku: string; name: string; qty: number; barcode: string }>>>("/inventory"),
      apiRequest<Array<{ id: string; name: string }>>("/employees"),
      apiRequest<Array<{ amount?: number }>>("/daily_stats"),
      apiRequest<Array<{ id: string; name: string; status?: string }>>("/machines"),
    ]);

    const failedFeeds: FeedKey[] = [];

    const inventory =
      inventoryResult.status === "fulfilled"
        ? (inventoryResult.value ?? {})
        : (failedFeeds.push("inventory"), {});
    const employees =
      employeesResult.status === "fulfilled"
        ? (employeesResult.value ?? [])
        : (failedFeeds.push("employees"), []);
    const dailyStats =
      dailyStatsResult.status === "fulfilled"
        ? (dailyStatsResult.value ?? [])
        : (failedFeeds.push("dailyStats"), []);
    const machines =
      machinesResult.status === "fulfilled"
        ? (machinesResult.value ?? [])
        : (failedFeeds.push("machines"), []);

    const liveSnapshot = buildLiveSnapshot(role, inventory, employees, dailyStats, machines);
    if (!liveSnapshot) {
      return createUnavailableSnapshot(role, failedFeeds, false);
    }

    return appendFeedWarning(liveSnapshot, failedFeeds);
  }

  async getPreferences(): Promise<DashboardViewPreferences> {
    return apiRequest<DashboardViewPreferences>("/dashboard/preferences", { method: "GET" });
  }

  async savePreferences(preferences: DashboardViewPreferences): Promise<DashboardViewPreferences> {
    return apiRequest<DashboardViewPreferences>("/dashboard/preferences", {
      method: "PUT",
      body: preferences,
    });
  }
}
