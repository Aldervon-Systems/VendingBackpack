"use client";

import { createContext, useContext, useMemo, useState } from "react";

type ShellContextValue = {
  settingsOpen: boolean;
  setSettingsOpen: (value: boolean) => void;
  adminVerificationOpen: boolean;
  setAdminVerificationOpen: (value: boolean) => void;
  adminVerified: boolean;
  setAdminVerified: (value: boolean) => void;
};

const ShellContext = createContext<ShellContextValue | null>(null);

export function ShellProvider({ children }: Readonly<{ children: React.ReactNode }>) {
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [adminVerificationOpen, setAdminVerificationOpen] = useState(false);
  const [adminVerified, setAdminVerified] = useState(false);

  const value = useMemo(
    () => ({
      settingsOpen,
      setSettingsOpen,
      adminVerificationOpen,
      setAdminVerificationOpen,
      adminVerified,
      setAdminVerified,
    }),
    [adminVerificationOpen, adminVerified, settingsOpen],
  );
  return <ShellContext.Provider value={value}>{children}</ShellContext.Provider>;
}

export function useShell() {
  const context = useContext(ShellContext);

  if (!context) {
    throw new Error("useShell must be used within ShellProvider");
  }

  return context;
}
