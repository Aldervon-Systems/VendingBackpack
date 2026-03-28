export const DASHBOARD_SECTION_IDS = [
  "systemOverview",
  "networkNodes",
  "routeNotes",
] as const;

export type DashboardSectionId = (typeof DASHBOARD_SECTION_IDS)[number];

export type KpiCard = {
  label: string;
  value: string;
  tone: "default" | "success" | "warning";
};

export type MachineSummary = {
  id: string;
  name: string;
  status: "online" | "attention";
  assignedTo: string;
  nextServiceWindow: string;
  topItem: string;
};

export type DashboardSnapshot = {
  heroLabel: string;
  heroValue: string;
  heroNote: string;
  kpis: KpiCard[];
  machineSummaries: MachineSummary[];
  routeHighlights: string[];
};

export type DashboardViewPreferences = {
  visibleSections: DashboardSectionId[];
  sectionOrder: DashboardSectionId[];
};

export function isDashboardSectionId(value: unknown): value is DashboardSectionId {
  return typeof value === "string" && DASHBOARD_SECTION_IDS.includes(value as DashboardSectionId);
}
