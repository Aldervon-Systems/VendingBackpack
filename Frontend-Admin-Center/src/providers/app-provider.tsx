"use client";

import { AuthProvider } from "@/providers/auth-provider";
import { ShellProvider } from "@/providers/shell-provider";

export function AppProvider({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <AuthProvider>
      <ShellProvider>{children}</ShellProvider>
    </AuthProvider>
  );
}