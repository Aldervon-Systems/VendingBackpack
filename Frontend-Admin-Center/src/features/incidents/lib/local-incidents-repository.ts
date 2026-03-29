import { INCIDENTS, PLAYBOOK } from "@/admin-center-data";
import type { IncidentsRepository } from "@/features/incidents/lib/incidents-repository";

export class LocalIncidentsRepository implements IncidentsRepository {
  getIncidentsSnapshot() {
    return {
      incidents: INCIDENTS,
      playbook: PLAYBOOK,
    };
  }
}
