"use client";

import { useMemo } from "react";
import { LocalFleetRepository } from "@/features/fleet/lib/local-fleet-repository";

const fleetRepository = new LocalFleetRepository();

export function useFleetViewModel() {
  const snapshot = useMemo(() => fleetRepository.getFleetSnapshot(), []);

  return {
    ...snapshot,
    monitoredCount: snapshot.machineAlerts.length,
    healthyCount: snapshot.machineAlerts.filter((machine) => machine.status === "Healthy").length,
    watchCount: snapshot.machineAlerts.filter((machine) => machine.status === "Watch").length,
    offlineMaintenanceCount: snapshot.machineAlerts.filter(
      (machine) => machine.status === "Offline" || machine.status === "Maintenance",
    ).length,
  };
}
