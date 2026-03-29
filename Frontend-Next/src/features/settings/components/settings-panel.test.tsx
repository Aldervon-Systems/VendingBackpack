import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { APP_ROUTES } from "@/lib/routes";

const mocks = vi.hoisted(() => ({
  useAuth: vi.fn(),
  useShell: vi.fn(),
  router: {
    push: vi.fn(),
    replace: vi.fn(),
  },
  onClose: vi.fn(),
  logout: vi.fn(),
  setEmployeeView: vi.fn(),
  setAdminVerificationOpen: vi.fn(),
}));

vi.mock("next/navigation", () => ({
  useRouter: () => mocks.router,
}));

vi.mock("@/providers/auth-provider", () => ({
  useAuth: mocks.useAuth,
}));

vi.mock("@/providers/shell-provider", () => ({
  useShell: mocks.useShell,
}));

import { SettingsPanel } from "@/features/settings/components/settings-panel";

describe("SettingsPanel", () => {
  beforeEach(() => {
    mocks.logout.mockResolvedValue(undefined);
    mocks.setEmployeeView.mockResolvedValue(undefined);
    mocks.useShell.mockReturnValue({
      adminVerified: false,
      setAdminVerificationOpen: mocks.setAdminVerificationOpen,
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it("renders manager controls and routes provisioning through onboarding", async () => {
    mocks.useAuth.mockReturnValue({
      session: {
        user: {
          name: "Admin Manager",
          organizationName: "Aldervon Systems",
        },
      },
      actualRole: "manager",
      effectiveRole: "manager",
      logout: mocks.logout,
      setEmployeeView: mocks.setEmployeeView,
    });

    render(<SettingsPanel onClose={mocks.onClose} />);

    fireEvent.click(screen.getByRole("switch", { name: /employee simulation/i }));
    expect(mocks.setEmployeeView).toHaveBeenCalledWith(true);

    fireEvent.click(screen.getByRole("button", { name: "VERIFY" }));
    expect(mocks.setAdminVerificationOpen).toHaveBeenCalledWith(true);

    fireEvent.click(screen.getByRole("button", { name: "OPEN PROVISIONING" }));
    expect(mocks.onClose).toHaveBeenCalledTimes(1);
    expect(mocks.router.push).toHaveBeenCalledWith(APP_ROUTES.onboardingStep1);

    expect(screen.getByText("PROVISION NEW ORGANIZATION")).toBeInTheDocument();
    expect(screen.getByText("ORG ADMIN ACCESS")).toBeInTheDocument();
  });

  it("shows the restricted fallback state for employee users", () => {
    mocks.useAuth.mockReturnValue({
      session: {
        user: {
          name: "Luis Vega",
          organizationName: "Aldervon Systems",
        },
      },
      actualRole: "employee",
      effectiveRole: "employee",
      logout: mocks.logout,
      setEmployeeView: mocks.setEmployeeView,
    });

    render(<SettingsPanel onClose={mocks.onClose} />);

    expect(screen.getByText("NO CONFIGURABLE PARAMETERS FOR THIS SECURITY LEVEL")).toBeInTheDocument();
    expect(screen.queryByText("ORG ADMIN ACCESS")).not.toBeInTheDocument();
    expect(screen.queryByText("PROVISION NEW ORGANIZATION")).not.toBeInTheDocument();
    expect(screen.queryByRole("switch", { name: /employee simulation/i })).not.toBeInTheDocument();
  });

  it("signs out and routes back to login", async () => {
    mocks.useAuth.mockReturnValue({
      session: {
        user: {
          name: "Admin Manager",
          organizationName: "Aldervon Systems",
        },
      },
      actualRole: "manager",
      effectiveRole: "manager",
      logout: mocks.logout,
      setEmployeeView: mocks.setEmployeeView,
    });

    render(<SettingsPanel onClose={mocks.onClose} />);

    fireEvent.click(screen.getByRole("button", { name: "SIGN OUT" }));

    await waitFor(() => {
      expect(mocks.logout).toHaveBeenCalledTimes(1);
    });

    expect(mocks.onClose).toHaveBeenCalledTimes(1);
    expect(mocks.router.replace).toHaveBeenCalledWith(APP_ROUTES.login);
  });
});
