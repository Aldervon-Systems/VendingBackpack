import { Building2, LayoutGrid, Megaphone, Radar, ShieldCheck, TriangleAlert } from "lucide-react";
import { APP_ROUTES } from "@/lib/routes";

export type NavItem = {
  href: string;
  label: string;
  icon: React.ComponentType<{ size?: number }>;
};

export function getNavItems(): NavItem[] {
  return [
    { href: APP_ROUTES.overview, label: "Overview", icon: LayoutGrid },
    { href: APP_ROUTES.organizations, label: "Organizations", icon: Building2 },
    { href: APP_ROUTES.access, label: "Access", icon: ShieldCheck },
    { href: APP_ROUTES.fleet, label: "Fleet", icon: Radar },
    { href: APP_ROUTES.incidents, label: "Incidents", icon: TriangleAlert },
    { href: APP_ROUTES.broadcasts, label: "Broadcasts", icon: Megaphone },
  ];
}
