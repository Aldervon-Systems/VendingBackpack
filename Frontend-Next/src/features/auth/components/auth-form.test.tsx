import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  useAuth: vi.fn(),
  router: {
    replace: vi.fn(),
  },
  login: vi.fn(),
  signup: vi.fn(),
  searchOrganizations: vi.fn(),
}));

vi.mock("next/navigation", () => ({
  useRouter: () => mocks.router,
}));

vi.mock("@/providers/auth-provider", () => ({
  useAuth: mocks.useAuth,
}));

import { AuthForm } from "@/features/auth/components/auth-form";

describe("AuthForm", () => {
  beforeEach(() => {
    mocks.login.mockReset();
    mocks.signup.mockReset();
    mocks.searchOrganizations.mockReset();
    mocks.router.replace.mockReset();

    mocks.searchOrganizations.mockResolvedValue([]);
    mocks.useAuth.mockReturnValue({
      login: mocks.login,
      signup: mocks.signup,
      searchOrganizations: mocks.searchOrganizations,
      sessionExpired: false,
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it("renders backend login failures in the existing shell", async () => {
    mocks.login.mockRejectedValue(new Error("Invalid credentials"));

    render(<AuthForm mode="login" />);

    fireEvent.change(screen.getByLabelText("EMAIL ADDRESS"), {
      target: { value: "manager@aldervon.com" },
    });
    fireEvent.change(screen.getByLabelText("PASSWORD"), {
      target: { value: "wrongpass" },
    });
    fireEvent.click(screen.getByRole("button", { name: "AUTHENTICATE" }));

    await waitFor(() => {
      expect(screen.getByText("INVALID CREDENTIALS")).toBeInTheDocument();
    });

    expect(mocks.router.replace).not.toHaveBeenCalled();
  });
});
