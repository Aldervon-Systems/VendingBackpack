import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  useAuth: vi.fn(),
  dashboardRepository: {
    getSnapshot: vi.fn(),
    getPreferences: vi.fn(),
    savePreferences: vi.fn(),
  },
}));

vi.mock("@/providers/auth-provider", () => ({
  useAuth: mocks.useAuth,
}));

vi.mock("@/lib/api/repositories/api-dashboard-repository", () => ({
  ApiDashboardRepository: class {
    getSnapshot = mocks.dashboardRepository.getSnapshot;
    getPreferences = mocks.dashboardRepository.getPreferences;
    savePreferences = mocks.dashboardRepository.savePreferences;
  },
}));

import { DashboardScreen } from "@/features/dashboard/components/dashboard-screen";

const snapshot = {
  heroLabel: "Fleet revenue today",
  heroValue: "$14,280",
  heroNote: "10 machines reporting, 2 restocks due before 4 PM",
  kpis: [
    { label: "Active machines", value: "18", tone: "success" as const },
    { label: "Employees", value: "7", tone: "default" as const },
    { label: "Revenue today", value: "$14,280", tone: "warning" as const },
  ],
  machineSummaries: [
    {
      id: "M-101",
      name: "Union Station",
      status: "online" as const,
      assignedTo: "Jordan Park",
      nextServiceWindow: "11:30 AM",
      topItem: "Cold Brew",
    },
  ],
  routeHighlights: ["Jordan is 2 stops ahead of schedule."],
};

describe("DashboardScreen", () => {
  beforeEach(() => {
    mocks.useAuth.mockReturnValue({
      effectiveRole: "manager",
      isRestoring: false,
      session: {
        user: {
          id: "user_admin",
          role: "manager",
        },
      },
    });
    mocks.dashboardRepository.getSnapshot.mockResolvedValue(snapshot);
    mocks.dashboardRepository.getPreferences.mockResolvedValue({
      visibleSections: ["systemOverview", "networkNodes", "routeNotes"],
      sectionOrder: ["systemOverview", "networkNodes", "routeNotes"],
    });
    mocks.dashboardRepository.savePreferences.mockImplementation(async (preferences) => preferences);
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it("loads saved layout preferences and persists section updates", async () => {
    render(<DashboardScreen />);

    await screen.findByText("FLEET REVENUE TODAY");
    expect(mocks.dashboardRepository.getPreferences).toHaveBeenCalledTimes(1);

    fireEvent.click(screen.getAllByRole("button", { name: /Route Notes/i })[0]);

    await waitFor(() => {
      expect(mocks.dashboardRepository.savePreferences).toHaveBeenCalledWith(
        expect.objectContaining({
          visibleSections: ["systemOverview", "networkNodes"],
          sectionOrder: ["systemOverview", "networkNodes", "routeNotes"],
        }),
      );
    }, { timeout: 1500 });
  });

  it("falls back to default layout when the API payload is invalid", async () => {
    mocks.dashboardRepository.getPreferences.mockResolvedValue(undefined);

    render(<DashboardScreen />);

    await screen.findByText("FLEET REVENUE TODAY");
    expect(await screen.findByText("SYSTEM OVERVIEW")).toBeInTheDocument();
    expect(await screen.findByText("ROUTE NOTES")).toBeInTheDocument();
  });
});
