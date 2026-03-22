import type { Metadata } from "next";
import "./globals.css";
import { AppProvider } from "@/providers/app-provider";

export const metadata: Metadata = {
  title: "Platform Admin Center",
  description: "Admin shell for cross-tenant platform operations",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>
        <AppProvider>{children}</AppProvider>
      </body>
    </html>
  );
}
