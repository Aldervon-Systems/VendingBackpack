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