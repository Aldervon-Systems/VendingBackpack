import { RELEASE_RINGS, type MachineAlert } from "@/admin-center-data";

export type FleetReleaseRing = (typeof RELEASE_RINGS)[number];

export type FleetSnapshot = {
  machineAlerts: MachineAlert[];
  releaseRings: FleetReleaseRing[];
};

export interface FleetRepository {
  getFleetSnapshot(): FleetSnapshot;
}
