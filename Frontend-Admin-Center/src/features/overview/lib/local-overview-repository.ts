import {
  GUARDRAILS,
  OVERVIEW_METRICS,
  PRIORITY_QUEUE,
  RECENT_ACTIONS,
  RELEASE_RINGS,
} from "@/admin-center-data";
import type { OverviewRepository } from "@/features/overview/lib/overview-repository";

export class LocalOverviewRepository implements OverviewRepository {
  getOverview() {
    return {
      metrics: OVERVIEW_METRICS,
      priorityQueue: PRIORITY_QUEUE,
      releaseRings: RELEASE_RINGS,
      recentActions: RECENT_ACTIONS,
      guardrails: GUARDRAILS,
    };
  }
}
