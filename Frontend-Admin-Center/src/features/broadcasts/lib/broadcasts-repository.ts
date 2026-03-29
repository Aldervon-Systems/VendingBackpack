import type { BroadcastRecord } from "@/admin-center-data";

export type BroadcastComposer = {
  title: string;
  audience: string;
  body: string;
};

export interface BroadcastsRepository {
  getDefaultComposer(): BroadcastComposer;
  listScheduledBroadcasts(): BroadcastRecord[];
}
