"use client";

import { useMemo } from "react";
import { LocalIncidentsRepository } from "@/features/incidents/lib/local-incidents-repository";

const incidentsRepository = new LocalIncidentsRepository();

export function useIncidentsViewModel() {
  const snapshot = useMemo(() => incidentsRepository.getIncidentsSnapshot(), []);

  return {
    ...snapshot,
    openCount: snapshot.incidents.length,
    criticalCount: snapshot.incidents.filter((incident) => incident.severity === "Critical").length,
    highCount: snapshot.incidents.filter((incident) => incident.severity === "High").length,
    mediumCount: snapshot.incidents.filter((incident) => incident.severity === "Medium").length,
  };
}
