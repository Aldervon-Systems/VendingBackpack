import { SCHEDULED_BROADCASTS } from "@/admin-center-data";
import type { BroadcastsRepository } from "@/features/broadcasts/lib/broadcasts-repository";

const defaultComposer = {
  title: "Platform status update for tenant admins",
  audience: "Tenant admins",
  body:
    "Admin center update:\n- Harbor Point Coffee remains in billing watch until the retry window closes.\n- North Pier Foods is under active fleet recovery with field dispatch in motion.\n- Manager traffic stays in Frontend-Next while platform operators complete cross-tenant actions.",
};

export class LocalBroadcastsRepository implements BroadcastsRepository {
  getDefaultComposer() {
    return { ...defaultComposer };
  }

  listScheduledBroadcasts() {
    return SCHEDULED_BROADCASTS;
  }
}
