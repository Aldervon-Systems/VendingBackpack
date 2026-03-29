"use client";

import { useMemo, useState } from "react";
import type { BroadcastRecord } from "@/admin-center-data";
import { LocalBroadcastsRepository } from "@/features/broadcasts/lib/local-broadcasts-repository";

type BroadcastState = "Scheduled" | "Draft" | "Sent";

type BroadcastEntry = BroadcastRecord & {
  state: BroadcastState;
};

const broadcastsRepository = new LocalBroadcastsRepository();

export function useBroadcastsViewModel() {
  const defaultComposer = useMemo(() => broadcastsRepository.getDefaultComposer(), []);
  const [composer, setComposer] = useState(defaultComposer);
  const [broadcastQueue, setBroadcastQueue] = useState<BroadcastEntry[]>(() =>
    broadcastsRepository.listScheduledBroadcasts().map((broadcast) => ({
      ...broadcast,
      state: broadcast.state as BroadcastState,
    })),
  );

  return {
    composer,
    broadcastQueue,
    queueCount: broadcastQueue.length,
    draftCount: broadcastQueue.filter((broadcast) => broadcast.state === "Draft").length,
    sentCount: broadcastQueue.filter((broadcast) => broadcast.state === "Sent").length,
    setComposer,
    resetComposer() {
      setComposer(defaultComposer);
    },
    queueBroadcast() {
      const nextBroadcast: BroadcastEntry = {
        title: composer.title.trim() || "Untitled broadcast",
        audience: composer.audience.trim() || "Tenant admins",
        state: "Draft",
        sendAt: "Queued",
        body: composer.body.trim() || "No body text provided.",
      };

      setBroadcastQueue((current) => [nextBroadcast, ...current]);
      setComposer(defaultComposer);
    },
  };
}
