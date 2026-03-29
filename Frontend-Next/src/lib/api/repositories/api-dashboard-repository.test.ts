import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  apiRequest: vi.fn(),
}));

vi.mock("@/lib/api/api-client", () => ({
  apiRequest: mocks.apiRequest,
}));

import { ApiDashboardRepository } from "@/lib/api/repositories/api-dashboard-repository";

describe("ApiDashboardRepository", () => {
  beforeEach(() => {
    mocks.apiRequest.mockReset();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it("keeps live snapshot data and annotates partial feed failures", async () => {
    mocks.apiRequest.mockImplementation(async (path: string) => {
      if (path === "/inventory") {
        return {
          "M-101": [{ sku: "SKU-1", name: "Cold Brew", qty: 2, barcode: "111" }],
        };
      }

      if (path === "/employees") {
        throw new Error("Employees unavailable");
      }

      if (path === "/daily_stats") {
        return [{ amount: 420 }];
      }

      if (path === "/machines") {
        return [{ id: "M-101", name: "Union Station", status: "online" }];
      }

      return {};
    });

    const repository = new ApiDashboardRepository();
    const snapshot = await repository.getSnapshot("manager");

    expect(snapshot.heroValue).toBe("$420");
    expect(snapshot.machineSummaries[0]?.name).toBe("Union Station");
    expect(snapshot.routeHighlights).toContain("Unavailable live feeds: employees.");
  });

  it("returns a truthful unavailable snapshot when no live feeds load", async () => {
    mocks.apiRequest.mockRejectedValue(new Error("Gateway unavailable"));

    const repository = new ApiDashboardRepository();
    const snapshot = await repository.getSnapshot("manager");

    expect(snapshot.heroValue).toBe("$0");
    expect(snapshot.machineSummaries).toEqual([]);
    expect(snapshot.routeHighlights[0]).toContain("currently unavailable");
  });
});
