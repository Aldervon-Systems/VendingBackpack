import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  useAuth: vi.fn(),
  apiRequest: vi.fn(),
}));

vi.mock("next/dynamic", () => ({
  default: () =>
    function MockRouteMapCanvas() {
      return <div data-testid="routes-map-canvas" />;
    },
}));

vi.mock("@/providers/auth-provider", () => ({
  useAuth: mocks.useAuth,
}));

vi.mock("@/lib/api/api-client", () => ({
  apiRequest: mocks.apiRequest,
}));

import { RoutesScreen } from "@/features/routes/components/routes-screen";

describe("RoutesScreen", () => {
  beforeEach(() => {
    mocks.apiRequest.mockImplementation(async (path: string) => {
      if (path === "/routes") {
        return {
          locations: [
            { id: "M-101", name: "Union Station", lat: 42.3524, lng: -71.0552, location: "Downtown Loop" },
            { id: "M-120", name: "North Campus", lat: 42.3651, lng: -71.104, location: "Cambridge North" },
          ],
        };
      }

      if (path === "/employees") {
        return [
          { id: "emp-07", name: "Amanda Jones" },
          { id: "emp-11", name: "Luis Vega" },
        ];
      }

      if (path === "/employees/routes") {
        return [
          { employee_id: "emp-07", employee_name: "Amanda Jones", stops: [{ id: "M-101" }] },
          { employee_id: "emp-11", employee_name: "Luis Vega", stops: [{ id: "M-120" }] },
        ];
      }

      if (path === "/employees/user_emp/routes") {
        return { stops: [{ id: "M-120" }] };
      }

      return {};
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it("updates the selected assignment details when the manager filter changes", async () => {
    mocks.useAuth.mockReturnValue({
      effectiveRole: "manager",
      session: {
        user: {
          id: "user_admin",
          name: "Admin Manager",
        },
      },
    });

    const { container } = render(<RoutesScreen />);

    await screen.findByText("SELECT OPERATIVE FOR UNION STATION");
    fireEvent.change(screen.getByRole("combobox"), { target: { value: "emp-11" } });

    await waitFor(() => {
      expect(screen.getByText("SELECT OPERATIVE FOR NORTH CAMPUS")).toBeInTheDocument();
    });

    expect(screen.getByText("Cambridge North")).toBeInTheDocument();
    expect(container.querySelector('.routes-sheet__row[data-active="true"]')).toHaveTextContent("Luis Vega");
  });

  it("shows the employee route sheet without manager assignment controls", async () => {
    mocks.useAuth.mockReturnValue({
      effectiveRole: "employee",
      session: {
        user: {
          id: "user_emp",
          name: "Luis Vega",
        },
      },
    });

    render(<RoutesScreen />);

    await screen.findByText("TODAY'S ACTIVE NODES");
    expect(screen.queryByText(/SELECT OPERATIVE FOR/i)).not.toBeInTheDocument();
    expect(screen.getByText(/M-120 \/ North Campus/i)).toBeInTheDocument();
  });
});
