import { PLAYBOOK, type IncidentRecord } from "@/admin-center-data";

export type IncidentPlaybookStep = (typeof PLAYBOOK)[number];

export type IncidentsSnapshot = {
  incidents: IncidentRecord[];
  playbook: IncidentPlaybookStep[];
};

export interface IncidentsRepository {
  getIncidentsSnapshot(): IncidentsSnapshot;
}
