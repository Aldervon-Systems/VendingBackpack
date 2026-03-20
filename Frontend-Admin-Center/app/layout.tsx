import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Admin Center",
  description: "Static bootstrap surface for the VendingBackpack Admin Center.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
