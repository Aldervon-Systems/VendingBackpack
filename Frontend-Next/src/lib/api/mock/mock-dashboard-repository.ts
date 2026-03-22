import type { DashboardRepository } from "@/lib/api/interfaces/dashboard-repository";
import type { DashboardSnapshot } from "@/types/dashboard";
import type { UserRole } from "@/types/auth";

const managerSnapshot: DashboardSnapshot = {
  heroLabel: "Fleet revenue today",
  heroValue: "$14,280",
  heroNote: "10 machines reporting, 2 restocks due before 4 PM",
  kpis: [
    { label: "Active machines", value: "18", tone: "success" },
    { label: "Assigned routes", value: "7", tone: "default" },
    { label: "Service risks", value: "3", tone: "warning" },
  ],
  machineSummaries: [
    { id: "M-101", name: "Union Station", status: "online", assignedTo: "Jordan Park", nextServiceWindow: "11:30 AM", topItem: "Cold Brew" },
    { id: "M-114", name: "City Hall", status: "attention", assignedTo: "Maya Chen", nextServiceWindow: "1:15 PM", topItem: "Trail Mix" },
    { id: "M-120", name: "North Campus", status: "online", assignedTo: "Luis Vega", nextServiceWindow: "3:45 PM", topItem: "Sparkling Water" },
  ],
  routeHighlights: [
    "Jordan is 2 stops ahead of schedule.",
    "City Hall machine is trending low on premium snacks.",
    "Warehouse intake is clear for the afternoon delivery wave.",
  ],
};

const employeeSnapshot: DashboardSnapshot = {
  heroLabel: "Your route progress",
  heroValue: "5 / 7 stops",
  heroNote: "You are ahead by 18 minutes and one restock is marked urgent.",
  kpis: [
    { label: "Stops left", value: "2", tone: "default" },
    { label: "Machines online", value: "6", tone: "success" },
    { label: "Low stock alerts", value: "1", tone: "warning" },
  ],
  machineSummaries: [
    { id: "M-101", name: "Union Station", status: "online", assignedTo: "You", nextServiceWindow: "11:30 AM", topItem: "Cold Brew" },
    { id: "M-120", name: "North Campus", status: "attention", assignedTo: "You", nextServiceWindow: "3:45 PM", topItem: "Sparkling Water" },
  ],
  routeHighlights: [
    "North Campus is flagged for a beverage refill.",
    "Your van inventory is sufficient for the remaining route.",
    "No new assignments have been pushed since 9:12 AM.",
  ],
};

export class MockDashboardRepository implements DashboardRepository {
  async getSnapshot(role: UserRole): Promise<DashboardSnapshot> {
    return new Promise((resolve) => {
      window.setTimeout(() => {
        resolve(role === "manager" ? managerSnapshot : employeeSnapshot);
      }, 420);
    });
  }
}