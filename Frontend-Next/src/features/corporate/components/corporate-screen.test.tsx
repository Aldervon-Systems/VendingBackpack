import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  useAuth: vi.fn(),
  corporateRepository: {
    getSnapshot: vi.fn(),
    getPreferences: vi.fn(),
    savePreferences: vi.fn(),
  },
}));

vi.mock("@/providers/auth-provider", () => ({
  useAuth: mocks.useAuth,
}));

vi.mock("@/lib/api/repositories/api-corporate-repository", () => ({
  ApiCorporateRepository: class {
    getSnapshot = mocks.corporateRepository.getSnapshot;
    getPreferences = mocks.corporateRepository.getPreferences;
    savePreferences = mocks.corporateRepository.savePreferences;
  },
}));

import { CorporateScreen } from "@/features/corporate/components/corporate-screen";

const snapshot = {
  meta: {
    organizationName: "Aldervon Systems",
    generatedAt: "2026-03-22T12:00:00.000Z",
    reportingPeriod: "January-March 2026",
    machineCount: 6,
  },
  revenueBudgetSeries: [
    { period: "Jan", budget: 1000, revenue: 1100 },
    { period: "Feb", budget: 1200, revenue: 1250 },
  ],
  profitSeries: [
    {
      machineId: "M-101",
      machineName: "Union Station",
      location: "Concourse",
      revenue: 1000,
      estimatedCost: 400,
      grossProfit: 600,
      marginPercent: 60,
    },
  ],
  rollingSalesSeries: [
    { period: "Jan", averageSales: 900, forecastSales: null },
    { period: "Feb", averageSales: 950, forecastSales: 980 },
  ],
  budgetVarianceRows: [
    { period: "Jan", budget: 1000, revenue: 1100, variance: 100, variancePercent: 10 },
  ],
  machineProfitRows: [
    {
      machineId: "M-101",
      machineName: "Union Station",
      location: "Concourse",
      revenue: 1000,
      estimatedCost: 400,
      grossProfit: 600,
      marginPercent: 60,
    },
  ],
};

describe("CorporateScreen", () => {
  beforeEach(() => {
    mocks.useAuth.mockReturnValue({
      isRestoring: false,
      session: {
        user: {
          id: "user_admin",
          role: "manager",
        },
      },
    });
    mocks.corporateRepository.getSnapshot.mockResolvedValue(snapshot);
    mocks.corporateRepository.getPreferences.mockResolvedValue({
      visibleWidgets: ["revenueBudget", "profitByMachine", "rollingSales", "budgetVariance", "machineProfit"],
      widgetOrder: ["revenueBudget", "profitByMachine", "rollingSales", "budgetVariance", "machineProfit"],
      tableSorts: {
        budgetVariance: { column: "variance", direction: "desc" },
        machineProfit: { column: "grossProfit", direction: "desc" },
      },
    });
    mocks.corporateRepository.savePreferences.mockImplementation(async (preferences) => preferences);
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it("loads preferences from the API and saves full replacement updates", async () => {
    render(<CorporateScreen />);

    await screen.findByText("Aldervon Systems");
    expect(mocks.corporateRepository.getPreferences).toHaveBeenCalledTimes(1);

    fireEvent.click(screen.getAllByRole("button", { name: /Machine Profit Table/i })[0]);

    await waitFor(() => {
      expect(mocks.corporateRepository.savePreferences).toHaveBeenCalledWith(
        expect.objectContaining({
          visibleWidgets: ["revenueBudget", "profitByMachine", "rollingSales", "budgetVariance"],
          widgetOrder: ["revenueBudget", "profitByMachine", "rollingSales", "budgetVariance", "machineProfit"],
        }),
      );
    }, { timeout: 1500 });
  });

  it("falls back to defaults when the API returns an invalid payload", async () => {
    mocks.corporateRepository.getPreferences.mockResolvedValue(undefined);

    render(<CorporateScreen />);

    await screen.findByText("Aldervon Systems");
    expect(await screen.findByText("REVENUE VS BUDGET")).toBeInTheDocument();
    expect(screen.queryByText("All report widgets are hidden")).not.toBeInTheDocument();
  });
});
