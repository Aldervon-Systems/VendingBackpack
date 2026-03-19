import { LayoutGrid, Map, ShieldCheck, Warehouse } from "lucide-react";
import { APP_ROUTES } from "@/lib/routes";
import type { UserRole } from "@/types/auth";

export type NavItem = {
  href: string;
  label: string;
  icon: React.ComponentType<{ size?: number }>;
};

export function getNavItems(role: UserRole | null): NavItem[] {
  const items: NavItem[] = [
    { href: APP_ROUTES.dashboard, label: "Dashboard", icon: LayoutGrid },
    { href: APP_ROUTES.routes, label: "Routes", icon: Map },
    { href: APP_ROUTES.warehouse, label: "Warehouse", icon: Warehouse },
  ];

  if (role === "manager") {
    items.push({ href: APP_ROUTES.admin, label: "Admin", icon: ShieldCheck });
  }

  return items;
}
