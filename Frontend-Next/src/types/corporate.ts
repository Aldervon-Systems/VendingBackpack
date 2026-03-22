export const CORPORATE_WIDGET_IDS = [
  "revenueBudget",
  "profitByMachine",
  "rollingSales",
  "budgetVariance",
  "machineProfit",
] as const;

export const BUDGET_VARIANCE_SORT_COLUMNS = ["period", "budget", "revenue", "variance", "variancePercent"] as const;
export const MACHINE_PROFIT_SORT_COLUMNS = ["machineName", "location", "revenue", "estimatedCost", "grossProfit", "marginPercent"] as const;

export type CorporateWidgetId = (typeof CORPORATE_WIDGET_IDS)[number];
export type BudgetVarianceSortColumn = (typeof BUDGET_VARIANCE_SORT_COLUMNS)[number];
export type MachineProfitSortColumn = (typeof MACHINE_PROFIT_SORT_COLUMNS)[number];
export type SortDirection = "asc" | "desc";

export type CorporateSnapshot = {
  meta: {
    organizationName: string;
    generatedAt: string;
    reportingPeriod: string;
    machineCount: number;
  };
  revenueBudgetSeries: RevenueBudgetPoint[];
  profitSeries: ProfitSeriesPoint[];
  rollingSalesSeries: RollingSalesPoint[];
  budgetVarianceRows: BudgetVarianceRow[];
  machineProfitRows: MachineProfitRow[];
};

export type RevenueBudgetPoint = {
  period: string;
  budget: number;
  revenue: number;
};

export type ProfitSeriesPoint = {
  machineId: string;
  machineName: string;
  location: string;
  revenue: number;
  estimatedCost: number;
  grossProfit: number;
  marginPercent: number;
};

export type RollingSalesPoint = {
  period: string;
  averageSales: number | null;
  forecastSales: number | null;
};

export type BudgetVarianceRow = {
  period: string;
  budget: number;
  revenue: number;
  variance: number;
  variancePercent: number;
};

export type MachineProfitRow = {
  machineId: string;
  machineName: string;
  location: string;
  revenue: number;
  estimatedCost: number;
  grossProfit: number;
  marginPercent: number;
};

export type CorporateViewPreferences = {
  visibleWidgets: CorporateWidgetId[];
  widgetOrder: CorporateWidgetId[];
  tableSorts: {
    budgetVariance: {
      column: BudgetVarianceSortColumn;
      direction: SortDirection;
    };
    machineProfit: {
      column: MachineProfitSortColumn;
      direction: SortDirection;
    };
  };
};

export function isCorporateWidgetId(value: unknown): value is CorporateWidgetId {
  return typeof value === "string" && CORPORATE_WIDGET_IDS.includes(value as CorporateWidgetId);
}

export function isBudgetVarianceSortColumn(value: unknown): value is BudgetVarianceSortColumn {
  return typeof value === "string" && BUDGET_VARIANCE_SORT_COLUMNS.includes(value as BudgetVarianceSortColumn);
}

export function isMachineProfitSortColumn(value: unknown): value is MachineProfitSortColumn {
  return typeof value === "string" && MACHINE_PROFIT_SORT_COLUMNS.includes(value as MachineProfitSortColumn);
}

export function isSortDirection(value: unknown): value is SortDirection {
  return value === "asc" || value === "desc";
}
