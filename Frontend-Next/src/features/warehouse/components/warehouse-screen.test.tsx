import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  useAuth: vi.fn(),
  apiRequest: vi.fn(),
}));

vi.mock("@/providers/auth-provider", () => ({
  useAuth: mocks.useAuth,
}));

vi.mock("@/lib/api/api-client", () => ({
  apiRequest: mocks.apiRequest,
}));

import { WarehouseScreen } from "@/features/warehouse/components/warehouse-screen";

describe("WarehouseScreen", () => {
  beforeEach(() => {
    mocks.apiRequest.mockReset();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it("keeps scanner access manager-only and skips shipment loading for employees", async () => {
    mocks.useAuth.mockReturnValue({
      effectiveRole: "employee",
    });
    mocks.apiRequest.mockImplementation(async (path: string) => {
      if (path === "/warehouse") {
        return [{ sku: "SKU-1", name: "Cold Brew", qty: 8, barcode: "111" }];
      }

      return [];
    });

    render(<WarehouseScreen />);

    await screen.findByText("Cold Brew");
    expect(screen.queryByRole("button", { name: "Open scanner" })).not.toBeInTheDocument();
    expect(mocks.apiRequest).not.toHaveBeenCalledWith("/warehouse/shipments");
  });

  it("surfaces live warehouse load failures without falling back to demo shipments", async () => {
    mocks.useAuth.mockReturnValue({
      effectiveRole: "manager",
    });
    mocks.apiRequest.mockRejectedValue(new Error("Gateway unavailable"));

    render(<WarehouseScreen />);

    await waitFor(() => {
      expect(screen.getByText("LIVE WAREHOUSE INVENTORY AND SHIPMENT SCHEDULE COULD NOT BE LOADED")).toBeInTheDocument();
    });

    fireEvent.click(screen.getByRole("button", { name: "Open shipments" }));

    expect(screen.getByText("No scheduled shipments are currently available.")).toBeInTheDocument();
    expect(screen.queryByText(/DOWNTOWN RESTOCK WAVE/i)).not.toBeInTheDocument();
  });
});
