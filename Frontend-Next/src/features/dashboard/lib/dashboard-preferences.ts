"use client";

import {
  DASHBOARD_SECTION_IDS,
  isDashboardSectionId,
  type DashboardSectionId,
  type DashboardViewPreferences,
} from "@/types/dashboard";

export function createDefaultDashboardViewPreferences(): DashboardViewPreferences {
  return {
    visibleSections: [...DASHBOARD_SECTION_IDS],
    sectionOrder: [...DASHBOARD_SECTION_IDS],
  };
}

export function normalizeDashboardViewPreferences(value: unknown): DashboardViewPreferences {
  const defaults = createDefaultDashboardViewPreferences();

  if (typeof value !== "object" || value === null) {
    return defaults;
  }

  const candidate = value as Partial<DashboardViewPreferences>;

  return {
    visibleSections: normalizeVisibleSections(candidate.visibleSections),
    sectionOrder: normalizeSectionOrder(candidate.sectionOrder),
  };
}

function normalizeVisibleSections(value: unknown): DashboardSectionId[] {
  if (!Array.isArray(value)) {
    return [...DASHBOARD_SECTION_IDS];
  }

  return uniqueSectionIds(value);
}

function normalizeSectionOrder(value: unknown): DashboardSectionId[] {
  const normalized = Array.isArray(value) ? uniqueSectionIds(value) : [];
  return [...normalized, ...DASHBOARD_SECTION_IDS.filter((sectionId) => !normalized.includes(sectionId))];
}

function uniqueSectionIds(values: unknown[]): DashboardSectionId[] {
  const seen = new Set<DashboardSectionId>();
  const result: DashboardSectionId[] = [];

  values.forEach((value) => {
    if (!isDashboardSectionId(value) || seen.has(value)) {
      return;
    }

    seen.add(value);
    result.push(value);
  });

  return result;
}
