"use client";

import { useMemo, useState } from "react";
import { LocalOrganizationsRepository } from "@/features/organizations/lib/local-organizations-repository";

export type OrganizationHealthFilter = "All" | "Healthy" | "Watch" | "Escalated" | "Review" | "Launching";

const organizationsRepository = new LocalOrganizationsRepository();

export function useOrganizationsViewModel() {
  const [healthFilter, setHealthFilter] = useState<OrganizationHealthFilter>("All");
  const [query, setQuery] = useState("");
  const snapshot = useMemo(() => organizationsRepository.listOrganizations(), []);

  const filteredOrganizations = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase();

    return snapshot.organizations.filter((organization) => {
      const matchesHealth = healthFilter === "All" || organization.health === healthFilter;
      const matchesQuery =
        normalizedQuery.length === 0 ||
        organization.name.toLowerCase().includes(normalizedQuery) ||
        organization.region.toLowerCase().includes(normalizedQuery) ||
        organization.plan.toLowerCase().includes(normalizedQuery);

      return matchesHealth && matchesQuery;
    });
  }, [healthFilter, query, snapshot.organizations]);

  return {
    healthFilter,
    query,
    filteredOrganizations,
    onboardingQueue: snapshot.onboardingQueue,
    setHealthFilter,
    setQuery,
    clearQuery() {
      setQuery("");
    },
  };
}
