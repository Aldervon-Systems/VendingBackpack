"use client";

import { useEffect, useState } from "react";
import { ArrowDown, ArrowUp, Eye, EyeOff, Printer, RefreshCcw } from "lucide-react";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityCard } from "@/components/parity/parity-card";
import { ParitySectionHeader } from "@/components/parity/parity-section-header";
import { LoadingScreen } from "@/components/primitives/loading-screen";
import { ApiCorporateRepository } from "@/lib/api/repositories/api-corporate-repository";
import { useAuth } from "@/providers/auth-provider";
import {
  type BudgetVarianceRow,
  type CorporateSnapshot,
  type CorporateViewPreferences,
  type CorporateWidgetId,
  type MachineProfitRow,
  type ProfitSeriesPoint,
  type RollingSalesPoint,
  type SortDirection,
} from "@/types/corporate";
import {
  createDefaultCorporateViewPreferences,
  readCorporateViewPreferences,
  writeCorporateViewPreferences,
} from "@/features/corporate/lib/corporate-preferences";

const corporateRepository = new ApiCorporateRepository();

const WIDGET_DETAILS: Record<
  CorporateWidgetId,
  {
    label: string;
    subtitle: string;
    kind: "chart" | "table";
  }
> = {
  revenueBudget: {
    label: "Revenue vs Budget",
    subtitle: "Trailing period performance versus plan",
    kind: "chart",
  },
  profitByMachine: {
    label: "Gross Profit Leaders",
    subtitle: "Top fleet performers by gross profit",
    kind: "chart",
  },
  rollingSales: {
    label: "Rolling Sales Average",
    subtitle: "Observed averages with forecast extension",
    kind: "chart",
  },
  budgetVariance: {
    label: "Budget Variance Table",
    subtitle: "Variance detail across the reporting periods",
    kind: "table",
  },
  machineProfit: {
    label: "Machine Profit Table",
    subtitle: "Revenue, cost, profit, and margin by machine",
    kind: "table",
  },
};

export function CorporateScreen() {
  const { session } = useAuth();
  const [snapshot, setSnapshot] = useState<CorporateSnapshot | null>(null);
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [refreshToken, setRefreshToken] = useState(0);
  const [preferences, setPreferences] = useState<CorporateViewPreferences>(createDefaultCorporateViewPreferences);
  const [preferencesReady, setPreferencesReady] = useState(false);

  const userId = session?.user.id ?? null;

  useEffect(() => {
    if (!userId) {
      setPreferences(createDefaultCorporateViewPreferences());
      setPreferencesReady(false);
      return;
    }

    setPreferences(readCorporateViewPreferences(userId));
    setPreferencesReady(true);
  }, [userId]);

  useEffect(() => {
    if (!userId || !preferencesReady) {
      return;
    }

    writeCorporateViewPreferences(userId, preferences);
  }, [preferences, preferencesReady, userId]);

  useEffect(() => {
    let active = true;

    async function loadSnapshot() {
      setIsLoading(true);
      setError("");

      try {
        const nextSnapshot = await corporateRepository.getSnapshot();
        if (!active) {
          return;
        }

        setSnapshot(nextSnapshot);
      } catch (nextError) {
        if (!active) {
          return;
        }

        setError(nextError instanceof Error ? nextError.message : "Corporate analytics request failed");
      } finally {
        if (active) {
          setIsLoading(false);
        }
      }
    }

    void loadSnapshot();

    return () => {
      active = false;
    };
  }, [refreshToken]);

  if (!snapshot && isLoading) {
    return <LoadingScreen label="Loading corporate analytics" />;
  }

  if (!snapshot) {
    return (
      <ParityCard className="corporate-empty-state">
        <div className="corporate-empty-state__title">Corporate analytics unavailable</div>
        <div className="corporate-empty-state__copy">{error || "No corporate snapshot could be loaded for this session."}</div>
        <div data-print-hidden="true">
          <ParityButton onClick={() => setRefreshToken((current) => current + 1)}>Retry</ParityButton>
        </div>
      </ParityCard>
    );
  }

  const orderedVisibleWidgets = preferences.widgetOrder.filter((widgetId) => preferences.visibleWidgets.includes(widgetId));
  const budgetVarianceRows = sortBudgetVarianceRows(snapshot.budgetVarianceRows, preferences.tableSorts.budgetVariance);
  const machineProfitRows = sortMachineProfitRows(snapshot.machineProfitRows, preferences.tableSorts.machineProfit);

  function toggleWidget(widgetId: CorporateWidgetId) {
    setPreferences((current) => {
      const visibleWidgets = current.visibleWidgets.includes(widgetId)
        ? current.visibleWidgets.filter((currentId) => currentId !== widgetId)
        : [...current.visibleWidgets, widgetId];

      return {
        ...current,
        visibleWidgets,
      };
    });
  }

  function moveWidget(widgetId: CorporateWidgetId, direction: -1 | 1) {
    setPreferences((current) => {
      const index = current.widgetOrder.indexOf(widgetId);
      const nextIndex = index + direction;

      if (index < 0 || nextIndex < 0 || nextIndex >= current.widgetOrder.length) {
        return current;
      }

      const widgetOrder = [...current.widgetOrder];
      [widgetOrder[index], widgetOrder[nextIndex]] = [widgetOrder[nextIndex], widgetOrder[index]];

      return {
        ...current,
        widgetOrder,
      };
    });
  }

  function updateBudgetVarianceSort(column: CorporateViewPreferences["tableSorts"]["budgetVariance"]["column"]) {
    setPreferences((current) => ({
      ...current,
      tableSorts: {
        ...current.tableSorts,
        budgetVariance: toggleSort(current.tableSorts.budgetVariance, column),
      },
    }));
  }

  function updateMachineProfitSort(column: CorporateViewPreferences["tableSorts"]["machineProfit"]["column"]) {
    setPreferences((current) => ({
      ...current,
      tableSorts: {
        ...current.tableSorts,
        machineProfit: toggleSort(current.tableSorts.machineProfit, column),
      },
    }));
  }

  return (
    <div className="corporate-screen">
      <ParityCard kind="foundation" className="corporate-toolbar">
        <div className="corporate-toolbar__top">
          <div className="corporate-toolbar__copy">
            <div className="corporate-toolbar__eyebrow">CORPORATE REPORT / MANAGER VIEW</div>
            <h1 className="corporate-toolbar__title">{snapshot.meta.organizationName}</h1>
            <div className="corporate-toolbar__subtitle">Fleet analytics, budget tracking, and sales forecasting in a single manager-facing report.</div>
          </div>

          <div className="corporate-toolbar__actions" data-print-hidden="true">
            <ParityButton tone="ghost" onClick={() => setRefreshToken((current) => current + 1)}>
              <RefreshCcw size={15} />
              <span>REFRESH</span>
            </ParityButton>
            <ParityButton onClick={() => window.print()}>
              <Printer size={15} />
              <span>PRINT PDF</span>
            </ParityButton>
          </div>
        </div>

        <div className="corporate-toolbar__meta">
          <span>Reporting Period: {snapshot.meta.reportingPeriod}</span>
          <span>Generated: {formatTimestamp(snapshot.meta.generatedAt)}</span>
          <span>Fleet Count: {snapshot.meta.machineCount}</span>
        </div>

        <div className="corporate-toolbar__layout" data-print-hidden="true">
          <div className="corporate-toolbar__layout-title">PERSONALIZED REPORT LAYOUT</div>
          <div className="corporate-widget-controls">
            {preferences.widgetOrder.map((widgetId, index) => {
              const widget = WIDGET_DETAILS[widgetId];
              const isVisible = preferences.visibleWidgets.includes(widgetId);

              return (
                <div key={widgetId} className="corporate-widget-control">
                  <button
                    className="corporate-widget-control__toggle"
                    type="button"
                    data-active={isVisible}
                    onClick={() => toggleWidget(widgetId)}
                  >
                    {isVisible ? <Eye size={14} /> : <EyeOff size={14} />}
                    <span>{widget.label}</span>
                  </button>

                  <div className="corporate-widget-control__actions">
                    <button
                      className="corporate-widget-control__move"
                      type="button"
                      onClick={() => moveWidget(widgetId, -1)}
                      disabled={index === 0}
                      aria-label={`Move ${widget.label} up`}
                    >
                      <ArrowUp size={14} />
                    </button>
                    <button
                      className="corporate-widget-control__move"
                      type="button"
                      onClick={() => moveWidget(widgetId, 1)}
                      disabled={index === preferences.widgetOrder.length - 1}
                      aria-label={`Move ${widget.label} down`}
                    >
                      <ArrowDown size={14} />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </ParityCard>

      {error ? <div className="form-error form-error--compact corporate-inline-error">{error.toUpperCase()}</div> : null}

      {orderedVisibleWidgets.length ? (
        <div className="corporate-widget-grid">
          {orderedVisibleWidgets.map((widgetId) => {
            const widget = WIDGET_DETAILS[widgetId];

            return (
              <ParityCard key={widgetId} className="corporate-widget" data-kind={widget.kind}>
                <div className="corporate-widget__header">
                  <ParitySectionHeader title={widget.label.toUpperCase()} subtitle={widget.subtitle.toUpperCase()} />
                </div>

                {widgetId === "revenueBudget" ? <RevenueBudgetChart snapshot={snapshot} /> : null}
                {widgetId === "profitByMachine" ? <ProfitByMachineChart series={snapshot.profitSeries} /> : null}
                {widgetId === "rollingSales" ? <RollingSalesChart series={snapshot.rollingSalesSeries} /> : null}
                {widgetId === "budgetVariance" ? (
                  <BudgetVarianceTable
                    rows={budgetVarianceRows}
                    sort={preferences.tableSorts.budgetVariance}
                    onSort={updateBudgetVarianceSort}
                  />
                ) : null}
                {widgetId === "machineProfit" ? (
                  <MachineProfitTable
                    rows={machineProfitRows}
                    sort={preferences.tableSorts.machineProfit}
                    onSort={updateMachineProfitSort}
                  />
                ) : null}
              </ParityCard>
            );
          })}
        </div>
      ) : (
        <ParityCard className="corporate-empty-state">
          <div className="corporate-empty-state__title">All report widgets are hidden</div>
          <div className="corporate-empty-state__copy">Use the layout controls above to re-enable the sections you want in this manager report.</div>
        </ParityCard>
      )}
    </div>
  );
}

function RevenueBudgetChart({ snapshot }: { snapshot: CorporateSnapshot }) {
  const chartHeight = 252;
  const baselineY = 208;
  const topPadding = 24;
  const chartWidth = snapshot.revenueBudgetSeries.length * 92 + 44;
  const maxValue = Math.max(...snapshot.revenueBudgetSeries.flatMap((point) => [point.budget, point.revenue]), 1);

  return (
    <div className="corporate-chart-shell">
      <svg className="corporate-chart-svg" viewBox={`0 0 ${chartWidth} ${chartHeight}`} role="img" aria-label="Revenue versus budget chart">
        {[0, 1, 2, 3].map((lineIndex) => {
          const y = topPadding + ((baselineY - topPadding) / 3) * lineIndex;
          return <line key={lineIndex} x1="20" y1={y} x2={chartWidth - 16} y2={y} className="corporate-chart-grid" />;
        })}

        {snapshot.revenueBudgetSeries.map((point, index) => {
          const groupX = 34 + index * 92;
          const budgetHeight = ((baselineY - topPadding) * point.budget) / maxValue;
          const revenueHeight = ((baselineY - topPadding) * point.revenue) / maxValue;

          return (
            <g key={point.period}>
              <rect className="corporate-chart-bar corporate-chart-bar--budget" x={groupX} y={baselineY - budgetHeight} width="24" height={budgetHeight} rx="6" />
              <rect className="corporate-chart-bar corporate-chart-bar--revenue" x={groupX + 32} y={baselineY - revenueHeight} width="24" height={revenueHeight} rx="6" />
              <text className="corporate-chart-label" x={groupX + 28} y="232" textAnchor="middle">
                {point.period}
              </text>
            </g>
          );
        })}
      </svg>

      <div className="corporate-chart-legend">
        <span><i className="corporate-chart-swatch corporate-chart-swatch--budget" />Budget</span>
        <span><i className="corporate-chart-swatch corporate-chart-swatch--revenue" />Revenue</span>
      </div>
    </div>
  );
}

function ProfitByMachineChart({ series }: { series: ProfitSeriesPoint[] }) {
  const maxProfit = Math.max(...series.map((point) => point.grossProfit), 1);

  return (
    <div className="corporate-profit-chart">
      {series.map((point) => (
        <div key={point.machineId} className="corporate-profit-chart__row">
          <div className="corporate-profit-chart__meta">
            <strong>{point.machineName}</strong>
            <span>{point.location}</span>
          </div>

          <div className="corporate-profit-chart__track">
            <div
              className="corporate-profit-chart__bar"
              style={{ width: `${(point.grossProfit / maxProfit) * 100}%` }}
            />
          </div>

          <div className="corporate-profit-chart__value">
            <strong>{formatCurrency(point.grossProfit)}</strong>
            <span>{formatPercent(point.marginPercent)}</span>
          </div>
        </div>
      ))}
    </div>
  );
}

function RollingSalesChart({ series }: { series: RollingSalesPoint[] }) {
  const chartWidth = series.length * 82 + 24;
  const chartHeight = 250;
  const topPadding = 28;
  const bottomPadding = 48;
  const values = series.flatMap((point) => [point.averageSales, point.forecastSales]).filter((value): value is number => value !== null);
  const minValue = Math.min(...values);
  const maxValue = Math.max(...values);
  const range = maxValue === minValue ? 1 : maxValue - minValue;

  const actualPoints = series
    .map((point, index) => {
      if (point.averageSales === null) {
        return null;
      }

      return {
        key: `${point.period}-actual`,
        x: 18 + index * 82,
        y: topPadding + ((maxValue - point.averageSales) / range) * (chartHeight - topPadding - bottomPadding),
      };
    })
    .filter((point): point is { key: string; x: number; y: number } => point !== null);

  const forecastOnlyPoints = series
    .map((point, index) => {
      if (point.forecastSales === null) {
        return null;
      }

      return {
        key: `${point.period}-forecast`,
        x: 18 + index * 82,
        y: topPadding + ((maxValue - point.forecastSales) / range) * (chartHeight - topPadding - bottomPadding),
      };
    })
    .filter((point): point is { key: string; x: number; y: number } => point !== null);

  const forecastPoints = actualPoints.length ? [actualPoints[actualPoints.length - 1], ...forecastOnlyPoints] : forecastOnlyPoints;

  return (
    <div className="corporate-chart-shell">
      <svg className="corporate-chart-svg" viewBox={`0 0 ${chartWidth} ${chartHeight}`} role="img" aria-label="Rolling sales average forecast chart">
        {[0, 1, 2, 3].map((lineIndex) => {
          const y = topPadding + (((chartHeight - topPadding - bottomPadding) / 3) * lineIndex);
          return <line key={lineIndex} x1="16" y1={y} x2={chartWidth - 16} y2={y} className="corporate-chart-grid" />;
        })}

        <path className="corporate-line corporate-line--actual" d={buildLinePath(actualPoints)} />
        <path className="corporate-line corporate-line--forecast" d={buildLinePath(forecastPoints)} />

        {actualPoints.map((point) => (
          <circle key={point.key} className="corporate-line-point corporate-line-point--actual" cx={point.x} cy={point.y} r="4" />
        ))}

        {forecastOnlyPoints.map((point) => (
          <circle key={point.key} className="corporate-line-point corporate-line-point--forecast" cx={point.x} cy={point.y} r="4" />
        ))}

        {series.map((point, index) => (
          <text key={point.period} className="corporate-chart-label" x={18 + index * 82} y={226} textAnchor="middle">
            {point.period}
          </text>
        ))}
      </svg>

      <div className="corporate-chart-legend">
        <span><i className="corporate-chart-swatch corporate-chart-swatch--actual" />Observed</span>
        <span><i className="corporate-chart-swatch corporate-chart-swatch--forecast" />Forecast</span>
      </div>
    </div>
  );
}

function BudgetVarianceTable({
  rows,
  sort,
  onSort,
}: {
  rows: BudgetVarianceRow[];
  sort: CorporateViewPreferences["tableSorts"]["budgetVariance"];
  onSort: (column: CorporateViewPreferences["tableSorts"]["budgetVariance"]["column"]) => void;
}) {
  return (
    <div className="corporate-table-wrap">
      <table className="corporate-table">
        <thead>
          <tr>
            <th><SortHeader label="Period" active={sort.column === "period"} direction={sort.direction} onClick={() => onSort("period")} /></th>
            <th><SortHeader label="Budget" active={sort.column === "budget"} direction={sort.direction} onClick={() => onSort("budget")} /></th>
            <th><SortHeader label="Revenue" active={sort.column === "revenue"} direction={sort.direction} onClick={() => onSort("revenue")} /></th>
            <th><SortHeader label="Variance" active={sort.column === "variance"} direction={sort.direction} onClick={() => onSort("variance")} /></th>
            <th><SortHeader label="Variance %" active={sort.column === "variancePercent"} direction={sort.direction} onClick={() => onSort("variancePercent")} /></th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.period}>
              <td>{row.period}</td>
              <td>{formatCurrency(row.budget)}</td>
              <td>{formatCurrency(row.revenue)}</td>
              <td data-tone={row.variance >= 0 ? "positive" : "negative"}>{formatSignedCurrency(row.variance)}</td>
              <td data-tone={row.variancePercent >= 0 ? "positive" : "negative"}>{formatSignedPercent(row.variancePercent)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function MachineProfitTable({
  rows,
  sort,
  onSort,
}: {
  rows: MachineProfitRow[];
  sort: CorporateViewPreferences["tableSorts"]["machineProfit"];
  onSort: (column: CorporateViewPreferences["tableSorts"]["machineProfit"]["column"]) => void;
}) {
  return (
    <div className="corporate-table-wrap">
      <table className="corporate-table">
        <thead>
          <tr>
            <th><SortHeader label="Machine" active={sort.column === "machineName"} direction={sort.direction} onClick={() => onSort("machineName")} /></th>
            <th><SortHeader label="Location" active={sort.column === "location"} direction={sort.direction} onClick={() => onSort("location")} /></th>
            <th><SortHeader label="Revenue" active={sort.column === "revenue"} direction={sort.direction} onClick={() => onSort("revenue")} /></th>
            <th><SortHeader label="Est. Cost" active={sort.column === "estimatedCost"} direction={sort.direction} onClick={() => onSort("estimatedCost")} /></th>
            <th><SortHeader label="Gross Profit" active={sort.column === "grossProfit"} direction={sort.direction} onClick={() => onSort("grossProfit")} /></th>
            <th><SortHeader label="Margin %" active={sort.column === "marginPercent"} direction={sort.direction} onClick={() => onSort("marginPercent")} /></th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.machineId}>
              <td>{row.machineName}</td>
              <td>{row.location}</td>
              <td>{formatCurrency(row.revenue)}</td>
              <td>{formatCurrency(row.estimatedCost)}</td>
              <td>{formatCurrency(row.grossProfit)}</td>
              <td>{formatPercent(row.marginPercent)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function SortHeader({
  label,
  active,
  direction,
  onClick,
}: {
  label: string;
  active: boolean;
  direction: SortDirection;
  onClick: () => void;
}) {
  return (
    <button className="corporate-table__sort" type="button" data-active={active} onClick={onClick}>
      <span>{label}</span>
      <span className="corporate-table__sort-direction">{active ? (direction === "desc" ? "↓" : "↑") : "↕"}</span>
    </button>
  );
}

function toggleSort<Column extends string>(
  current: { column: Column; direction: SortDirection },
  column: Column,
): { column: Column; direction: SortDirection } {
  if (current.column !== column) {
    return { column, direction: "desc" };
  }

  return {
    column,
    direction: current.direction === "desc" ? "asc" : "desc",
  };
}

function sortBudgetVarianceRows(
  rows: BudgetVarianceRow[],
  sort: CorporateViewPreferences["tableSorts"]["budgetVariance"],
) {
  const sortedRows = [...rows];
  const periodOrder = new Map(rows.map((row, index) => [row.period, index]));

  sortedRows.sort((left, right) => {
    if (sort.column === "period") {
      const comparison = (periodOrder.get(left.period) ?? 0) - (periodOrder.get(right.period) ?? 0);
      return sort.direction === "asc" ? comparison : -comparison;
    }

    const comparison = compareValues(left[sort.column], right[sort.column]);
    return sort.direction === "asc" ? comparison : -comparison;
  });

  return sortedRows;
}

function sortMachineProfitRows(
  rows: MachineProfitRow[],
  sort: CorporateViewPreferences["tableSorts"]["machineProfit"],
) {
  const sortedRows = [...rows];

  sortedRows.sort((left, right) => {
    const comparison = compareValues(left[sort.column], right[sort.column]);
    return sort.direction === "asc" ? comparison : -comparison;
  });

  return sortedRows;
}

function compareValues(left: string | number, right: string | number) {
  if (typeof left === "number" && typeof right === "number") {
    return left - right;
  }

  return String(left).localeCompare(String(right));
}

function buildLinePath(points: Array<{ x: number; y: number }>) {
  if (!points.length) {
    return "";
  }

  return points.map((point, index) => `${index === 0 ? "M" : "L"} ${point.x} ${point.y}`).join(" ");
}

function formatCurrency(value: number) {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(value);
}

function formatPercent(value: number) {
  return `${value.toFixed(1)}%`;
}

function formatSignedCurrency(value: number) {
  const prefix = value > 0 ? "+" : "";
  return `${prefix}${formatCurrency(value)}`;
}

function formatSignedPercent(value: number) {
  const prefix = value > 0 ? "+" : "";
  return `${prefix}${value.toFixed(1)}%`;
}

function formatTimestamp(value: string) {
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(new Date(value));
}
