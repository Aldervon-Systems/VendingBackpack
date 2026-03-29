import { OVERVIEW_METRICS, PRIORITY_QUEUE, RELEASE_RINGS, RECENT_ACTIONS, GUARDRAILS } from "@/admin-center-data";

export type OverviewMetric = (typeof OVERVIEW_METRICS)[number];
export type PriorityQueueItem = (typeof PRIORITY_QUEUE)[number];
export type ReleaseRing = (typeof RELEASE_RINGS)[number];
export type OverviewNote = (typeof RECENT_ACTIONS)[number];
export type Guardrail = (typeof GUARDRAILS)[number];

export type OverviewSnapshot = {
  metrics: OverviewMetric[];
  priorityQueue: PriorityQueueItem[];
  releaseRings: ReleaseRing[];
  recentActions: OverviewNote[];
  guardrails: Guardrail[];
};

export interface OverviewRepository {
  getOverview(): OverviewSnapshot;
}
