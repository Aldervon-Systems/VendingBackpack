import { MACHINE_ALERTS, RELEASE_RINGS } from "@/admin-center-data";
import type { FleetRepository } from "@/features/fleet/lib/fleet-repository";

export class LocalFleetRepository implements FleetRepository {
  getFleetSnapshot() {
    return {
      machineAlerts: MACHINE_ALERTS,
      releaseRings: RELEASE_RINGS,
    };
  }
}
