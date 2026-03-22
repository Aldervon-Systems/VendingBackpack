"use client";

import {
  CORPORATE_WIDGET_IDS,
  isBudgetVarianceSortColumn,
  isCorporateWidgetId,
  isMachineProfitSortColumn,
  isSortDirection,
  type CorporateViewPreferences,
  type CorporateWidgetId,
} from "@/types/corporate";

const STORAGE_PREFIX = "vb.next.corporate.preferences";

type StoredEnvelope<T> = {
  version: 1;
  value: T;
};

export function createDefaultCorporateViewPreferences(): CorporateViewPreferences {
  return {
    visibleWidgets: [...CORPORATE_WIDGET_IDS],
    widgetOrder: [...CORPORATE_WIDGET_IDS],
    tableSorts: {
      budgetVariance: {
        column: "variance",
        direction: "desc",
      },
      machineProfit: {
        column: "grossProfit",
        direction: "desc",
      },
    },
  };
}

export function getCorporatePreferencesStorageKey(userId: string) {
  return `${STORAGE_PREFIX}.${userId}`;
}

export function readCorporateViewPreferences(userId: string): CorporateViewPreferences {
  if (typeof window === "undefined") {
    return createDefaultCorporateViewPreferences();
  }

  const raw = window.localStorage.getItem(getCorporatePreferencesStorageKey(userId));
  if (!raw) {
    return createDefaultCorporateViewPreferences();
  }

  try {
    const parsed = JSON.parse(raw) as StoredEnvelope<unknown> | Partial<CorporateViewPreferences>;
    const value = typeof parsed === "object" && parsed !== null && "value" in parsed ? parsed.value : parsed;
    return normalizeCorporateViewPreferences(value);
  } catch {
    return createDefaultCorporateViewPreferences();
  }
}

export function writeCorporateViewPreferences(userId: string, preferences: CorporateViewPreferences) {
  if (typeof window === "undefined") {
    return;
  }

  const envelope: StoredEnvelope<CorporateViewPreferences> = {
    version: 1,
    value: normalizeCorporateViewPreferences(preferences),
  };

  window.localStorage.setItem(getCorporatePreferencesStorageKey(userId), JSON.stringify(envelope));
}

function normalizeCorporateViewPreferences(value: unknown): CorporateViewPreferences {
  const defaults = createDefaultCorporateViewPreferences();

  if (typeof value !== "object" || value === null) {
    return defaults;
  }

  const candidate = value as Partial<CorporateViewPreferences>;
  const visibleWidgets = normalizeVisibleWidgets(candidate.visibleWidgets);
  const widgetOrder = normalizeWidgetOrder(candidate.widgetOrder);
  const tableSorts = normalizeTableSorts(candidate.tableSorts);

  return {
    visibleWidgets,
    widgetOrder,
    tableSorts,
  };
}

function normalizeVisibleWidgets(value: unknown): CorporateWidgetId[] {
  if (!Array.isArray(value)) {
    return [...CORPORATE_WIDGET_IDS];
  }

  return uniqueWidgetIds(value);
}

function normalizeWidgetOrder(value: unknown): CorporateWidgetId[] {
  const normalized = Array.isArray(value) ? uniqueWidgetIds(value) : [];

  return [...normalized, ...CORPORATE_WIDGET_IDS.filter((widgetId) => !normalized.includes(widgetId))];
}

function normalizeTableSorts(value: unknown): CorporateViewPreferences["tableSorts"] {
  const defaults = createDefaultCorporateViewPreferences().tableSorts;

  if (typeof value !== "object" || value === null) {
    return defaults;
  }

  const candidate = value as Partial<CorporateViewPreferences["tableSorts"]>;

  return {
    budgetVariance: {
      column: isBudgetVarianceSortColumn(candidate.budgetVariance?.column)
        ? candidate.budgetVariance.column
        : defaults.budgetVariance.column,
      direction: isSortDirection(candidate.budgetVariance?.direction)
        ? candidate.budgetVariance.direction
        : defaults.budgetVariance.direction,
    },
    machineProfit: {
      column: isMachineProfitSortColumn(candidate.machineProfit?.column)
        ? candidate.machineProfit.column
        : defaults.machineProfit.column,
      direction: isSortDirection(candidate.machineProfit?.direction)
        ? candidate.machineProfit.direction
        : defaults.machineProfit.direction,
    },
  };
}

function uniqueWidgetIds(values: unknown[]): CorporateWidgetId[] {
  const seen = new Set<CorporateWidgetId>();
  const result: CorporateWidgetId[] = [];

  values.forEach((value) => {
    if (!isCorporateWidgetId(value) || seen.has(value)) {
      return;
    }

    seen.add(value);
    result.push(value);
  });

  return result;
}
