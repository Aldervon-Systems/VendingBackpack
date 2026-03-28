"use client";

import { type ReactNode, useEffect, useRef, useState } from "react";
import { ArrowDown, ArrowUp, CircleDollarSign, Eye, EyeOff, LaptopMinimal, Radio, TriangleAlert } from "lucide-react";
import { ParityCard } from "@/components/parity/parity-card";
import { ParitySectionHeader } from "@/components/parity/parity-section-header";
import { LoadingScreen } from "@/components/primitives/loading-screen";
import { StatusPill } from "@/components/primitives/status-pill";
import { ApiDashboardRepository } from "@/lib/api/repositories/api-dashboard-repository";
import { useAuth } from "@/providers/auth-provider";
import {
  createDefaultDashboardViewPreferences,
  normalizeDashboardViewPreferences,
} from "@/features/dashboard/lib/dashboard-preferences";
import type {
  DashboardSectionId,
  DashboardSnapshot,
  DashboardViewPreferences,
} from "@/types/dashboard";

const dashboardRepository = new ApiDashboardRepository();

const SECTION_TITLES: Record<DashboardSectionId, string> = {
  systemOverview: "System Overview",
  networkNodes: "Network Nodes",
  routeNotes: "Route Notes",
};

export function DashboardScreen() {
  const { effectiveRole, isRestoring, session } = useAuth();
  const [snapshot, setSnapshot] = useState<DashboardSnapshot | null>(null);
  const [preferences, setPreferences] = useState<DashboardViewPreferences>(createDefaultDashboardViewPreferences);
  const [preferencesReady, setPreferencesReady] = useState(false);
  const [preferencesError, setPreferencesError] = useState("");
  const lastSavedPreferencesRef = useRef<string | null>(null);

  const userId = session?.user.id ?? null;

  useEffect(() => {
    let active = true;
    const role = effectiveRole;

    if (!role) {
      return () => {
        active = false;
      };
    }

    dashboardRepository.getSnapshot(role).then((nextSnapshot) => {
      if (active) {
        setSnapshot(nextSnapshot);
      }
    });

    return () => {
      active = false;
    };
  }, [effectiveRole]);

  useEffect(() => {
    let active = true;

    if (isRestoring) {
      return () => {
        active = false;
      };
    }

    if (!userId) {
      const defaults = createDefaultDashboardViewPreferences();
      setPreferences(defaults);
      setPreferencesReady(false);
      setPreferencesError("");
      lastSavedPreferencesRef.current = JSON.stringify(defaults);
      return () => {
        active = false;
      };
    }

    setPreferencesReady(false);
    setPreferencesError("");

    dashboardRepository.getPreferences()
      .then((nextPreferences) => {
        if (!active) {
          return;
        }

        const normalized = normalizeDashboardViewPreferences(nextPreferences);
        setPreferences(normalized);
        lastSavedPreferencesRef.current = JSON.stringify(normalized);
      })
      .catch(() => {
        if (!active) {
          return;
        }

        const fallback = createDefaultDashboardViewPreferences();
        setPreferences(fallback);
        setPreferencesError("Dashboard layout preferences could not be loaded. Using defaults for this session.");
        lastSavedPreferencesRef.current = JSON.stringify(fallback);
      })
      .finally(() => {
        if (active) {
          setPreferencesReady(true);
        }
      });

    return () => {
      active = false;
    };
  }, [isRestoring, userId]);

  useEffect(() => {
    if (!userId || !preferencesReady) {
      return;
    }

    const serialized = JSON.stringify(preferences);
    if (serialized === lastSavedPreferencesRef.current) {
      return;
    }

    const timeoutId = window.setTimeout(() => {
      dashboardRepository.savePreferences(preferences)
        .then((savedPreferences) => {
          const normalized = normalizeDashboardViewPreferences(savedPreferences);
          lastSavedPreferencesRef.current = JSON.stringify(normalized);
          setPreferences(normalized);
          setPreferencesError("");
        })
        .catch((nextError) => {
          setPreferencesError(nextError instanceof Error ? nextError.message : "Dashboard layout preferences could not be saved.");
        });
    }, 500);

    return () => {
      window.clearTimeout(timeoutId);
    };
  }, [preferences, preferencesReady, userId]);

  if (!snapshot) {
    return <LoadingScreen label="Loading dashboard snapshot" />;
  }

  const metricIcons = [LaptopMinimal, Radio, CircleDollarSign];
  const sectionTitle = effectiveRole === "manager" ? "ALL NETWORK NODES" : "ASSIGNED ROUTE NODES";
  const orderedVisibleSections = preferences.sectionOrder.filter((sectionId) => preferences.visibleSections.includes(sectionId));
  const sections: Record<DashboardSectionId, ReactNode> = {
    systemOverview: (
      <section className="dashboard-block">
        <ParitySectionHeader title="SYSTEM OVERVIEW" subtitle="LIVE ENVIRONMENT METRICS" />
        <div className="dashboard-metrics">
          {snapshot.kpis.map((kpi, index) => {
            const Icon = metricIcons[index] ?? TriangleAlert;

            return (
              <ParityCard key={kpi.label} className="metric-card">
                <div className="metric-card__label">
                  <Icon size={14} />
                  <span>{kpi.label.toUpperCase()}</span>
                </div>
                <div className="metric-card__value">{kpi.value}</div>
              </ParityCard>
            );
          })}
        </div>
      </section>
    ),
    networkNodes: (
      <section className="dashboard-block">
        <ParitySectionHeader title={sectionTitle} subtitle="REAL-TIME STATUS & PAYLOAD" />
        <div className="machine-card-list">
          {snapshot.machineSummaries.map((machine) => (
            <ParityCard key={machine.id} className="machine-stop-card">
              <div className="machine-stop-card__header">
                <div>
                  <div className="machine-stop-card__title">UNIT {machine.id}</div>
                  <div className="machine-stop-card__meta">{machine.name.toUpperCase()}</div>
                </div>
                <StatusPill label={machine.status === "online" ? "ONLINE" : "ATTENTION"} tone={machine.status === "online" ? "success" : "warning"} />
              </div>
              <div className="machine-stop-card__details">
                <div className="machine-stop-card__row">
                  <span>OPERATIVE</span>
                  <strong>{machine.assignedTo.toUpperCase()}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>WINDOW</span>
                  <strong>{machine.nextServiceWindow}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>TOP ITEM</span>
                  <strong>{machine.topItem.toUpperCase()}</strong>
                </div>
              </div>
            </ParityCard>
          ))}
        </div>
      </section>
    ),
    routeNotes: (
      <section className="dashboard-block">
        <ParitySectionHeader title="ROUTE NOTES" subtitle="LIVE OPERATIONS SIGNALS" />
        <div className="notes-list">
          {snapshot.routeHighlights.map((highlight) => (
            <ParityCard key={highlight} className="note-row">
              {highlight}
            </ParityCard>
          ))}
        </div>
      </section>
    ),
  };

  function toggleSection(sectionId: DashboardSectionId) {
    setPreferences((current) => ({
      ...current,
      visibleSections: current.visibleSections.includes(sectionId)
        ? current.visibleSections.filter((currentId) => currentId !== sectionId)
        : [...current.visibleSections, sectionId],
    }));
  }

  function moveSection(sectionId: DashboardSectionId, direction: -1 | 1) {
    setPreferences((current) => {
      const index = current.sectionOrder.indexOf(sectionId);
      const nextIndex = index + direction;

      if (index < 0 || nextIndex < 0 || nextIndex >= current.sectionOrder.length) {
        return current;
      }

      const sectionOrder = [...current.sectionOrder];
      [sectionOrder[index], sectionOrder[nextIndex]] = [sectionOrder[nextIndex], sectionOrder[index]];

      return {
        ...current,
        sectionOrder,
      };
    });
  }

  return (
    <div className="dashboard-screen">
      <ParityCard kind="foundation" className="dashboard-layout-card">
        <div className="dashboard-layout-card__top">
          <div>
            <div className="dashboard-layout-card__eyebrow">PERSONALIZED DASHBOARD LAYOUT</div>
            <h1 className="dashboard-layout-card__title">{snapshot.heroLabel.toUpperCase()}</h1>
            <div className="dashboard-layout-card__copy">{snapshot.heroNote}</div>
          </div>
        </div>

        <div className="dashboard-layout-controls">
          {preferences.sectionOrder.map((sectionId, index) => {
            const isVisible = preferences.visibleSections.includes(sectionId);

            return (
              <div key={sectionId} className="dashboard-layout-control">
                <button
                  className="dashboard-layout-control__toggle"
                  type="button"
                  data-active={isVisible}
                  onClick={() => toggleSection(sectionId)}
                  disabled={!preferencesReady}
                >
                  {isVisible ? <Eye size={14} /> : <EyeOff size={14} />}
                  <span>{SECTION_TITLES[sectionId]}</span>
                </button>

                <div className="dashboard-layout-control__actions">
                  <button
                    className="dashboard-layout-control__move"
                    type="button"
                    onClick={() => moveSection(sectionId, -1)}
                    disabled={!preferencesReady || index === 0}
                    aria-label={`Move ${SECTION_TITLES[sectionId]} up`}
                  >
                    <ArrowUp size={14} />
                  </button>
                  <button
                    className="dashboard-layout-control__move"
                    type="button"
                    onClick={() => moveSection(sectionId, 1)}
                    disabled={!preferencesReady || index === preferences.sectionOrder.length - 1}
                    aria-label={`Move ${SECTION_TITLES[sectionId]} down`}
                  >
                    <ArrowDown size={14} />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </ParityCard>

      {preferencesError ? <div className="form-error form-error--compact corporate-inline-error">{preferencesError.toUpperCase()}</div> : null}

      {orderedVisibleSections.length ? (
        orderedVisibleSections.map((sectionId) => (
          <div key={sectionId}>{sections[sectionId]}</div>
        ))
      ) : (
        <ParityCard className="corporate-empty-state">
          <div className="corporate-empty-state__title">All dashboard sections are hidden</div>
          <div className="corporate-empty-state__copy">Use the layout controls above to re-enable the sections you want on this dashboard.</div>
        </ParityCard>
      )}
    </div>
  );
}
