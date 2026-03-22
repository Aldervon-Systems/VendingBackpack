"use client";

import { useMemo, useState } from "react";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityCard } from "@/components/parity/parity-card";
import { ParityField } from "@/components/parity/parity-field";
import { ParitySectionHeader } from "@/components/parity/parity-section-header";
import { StatusPill } from "@/components/primitives/status-pill";
import { ONBOARDING_QUEUE, ORGANIZATIONS } from "@/admin-center-data";

type OrganizationHealthFilter = "All" | "Healthy" | "Watch" | "Escalated" | "Review" | "Launching";

function toneForHealth(health: OrganizationHealthFilter | string) {
  if (health === "Healthy") {
    return "success" as const;
  }

  if (health === "Watch" || health === "Escalated" || health === "Review" || health === "Launching") {
    return "warning" as const;
  }

  return "default" as const;
}

export function OrganizationsScreen() {
  const [healthFilter, setHealthFilter] = useState<OrganizationHealthFilter>("All");
  const [query, setQuery] = useState("");

  const filteredOrganizations = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase();

    return ORGANIZATIONS.filter((organization) => {
      const matchesHealth = healthFilter === "All" || organization.health === healthFilter;
      const matchesQuery =
        normalizedQuery.length === 0 ||
        organization.name.toLowerCase().includes(normalizedQuery) ||
        organization.region.toLowerCase().includes(normalizedQuery) ||
        organization.plan.toLowerCase().includes(normalizedQuery);

      return matchesHealth && matchesQuery;
    });
  }, [healthFilter, query]);

  return (
    <div className="corporate-screen">
      <ParityCard kind="foundation" className="corporate-toolbar">
        <div className="corporate-toolbar__top">
          <div className="corporate-toolbar__copy">
            <div className="corporate-toolbar__eyebrow">TENANT PORTFOLIO</div>
            <h1 className="corporate-toolbar__title">Organizations under platform care</h1>
            <div className="corporate-toolbar__subtitle">
              Search by tenant, plan, or region and focus the queue by health state.
            </div>
          </div>
        </div>

        <div className="corporate-toolbar__layout">
          <div className="corporate-toolbar__layout-title">FILTERS</div>
          <div className="modal-form">
            <ParityField
              id="organization-search"
              label="SEARCH ORGANIZATIONS"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search organizations, regions, or plans"
            />
            <ParityField
              as="select"
              id="organization-health"
              label="HEALTH FILTER"
              value={healthFilter}
              onChange={(value) => setHealthFilter(value as OrganizationHealthFilter)}
              options={[
                { value: "All", label: "All" },
                { value: "Healthy", label: "Healthy" },
                { value: "Watch", label: "Watch" },
                { value: "Escalated", label: "Escalated" },
                { value: "Review", label: "Review" },
                { value: "Launching", label: "Launching" },
              ]}
            />
          </div>

          <div className="corporate-toolbar__meta">
            <span>{filteredOrganizations.length} organizations in view</span>
            <ParityButton tone="ghost" onClick={() => setQuery("")}>
              CLEAR SEARCH
            </ParityButton>
          </div>
        </div>
      </ParityCard>

      <section className="dashboard-block">
        <ParitySectionHeader title="TENANT GRID" subtitle="ORGANIZATIONS IN VIEW" />
        <div className="corporate-table-wrap">
          <table className="corporate-table">
            <thead>
              <tr>
                <th>Organization</th>
                <th>Health</th>
                <th>Machines</th>
                <th>Admins</th>
                <th>Billing</th>
                <th>Next action</th>
              </tr>
            </thead>
            <tbody>
              {filteredOrganizations.map((organization) => (
                <tr key={organization.name}>
                  <td>
                    <strong>{organization.name}</strong>
                    <span>
                      {organization.region}
                      <br />
                      {organization.plan}
                    </span>
                  </td>
                  <td>
                    <StatusPill label={organization.health.toUpperCase()} tone={toneForHealth(organization.health)} />
                  </td>
                  <td>{organization.machines}</td>
                  <td>{organization.admins}</td>
                  <td>{organization.billing}</td>
                  <td>{organization.nextAction}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="LAUNCH READINESS" subtitle="ONBOARDING QUEUE" />
        <div className="sheet-panel__list">
          {ONBOARDING_QUEUE.map((item) => (
            <ParityCard key={item.title} className="sheet-panel__row">
              <div>
                <strong>{item.title}</strong>
                <div>{item.copy}</div>
              </div>
            </ParityCard>
          ))}
        </div>
      </section>
    </div>
  );
}
