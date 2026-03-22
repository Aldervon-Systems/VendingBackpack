"use client";

import { useMemo, useState } from "react";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityCard } from "@/components/parity/parity-card";
import { ParityField } from "@/components/parity/parity-field";
import { ParitySectionHeader } from "@/components/parity/parity-section-header";
import { StatusPill } from "@/components/primitives/status-pill";
import { SCHEDULED_BROADCASTS } from "@/admin-center-data";

type BroadcastState = "Scheduled" | "Draft" | "Sent";

type BroadcastEntry = {
  title: string;
  audience: string;
  state: BroadcastState;
  sendAt: string;
  body: string;
};

const defaultComposer = {
  title: "Platform status update for tenant admins",
  audience: "Tenant admins",
  body:
    "Admin center update:\n- Harbor Point Coffee remains in billing watch until the retry window closes.\n- North Pier Foods is under active fleet recovery with field dispatch in motion.\n- Manager traffic stays in Frontend-Next while platform operators complete cross-tenant actions.",
};

function toneForState(state: BroadcastState) {
  if (state === "Sent") {
    return "success" as const;
  }

  if (state === "Draft") {
    return "warning" as const;
  }

  return "default" as const;
}

export function BroadcastsScreen() {
  const [composer, setComposer] = useState(defaultComposer);
  const [broadcastQueue, setBroadcastQueue] = useState<BroadcastEntry[]>(
    SCHEDULED_BROADCASTS.map((broadcast) => ({ ...broadcast, state: "Scheduled" as const })),
  );

  const queueCount = useMemo(() => broadcastQueue.length, [broadcastQueue.length]);

  function handleQueueBroadcast() {
    const nextBroadcast: BroadcastEntry = {
      title: composer.title.trim() || "Untitled broadcast",
      audience: composer.audience.trim() || "Tenant admins",
      state: "Draft",
      sendAt: "Queued locally",
      body: composer.body.trim() || "No body text provided.",
    };

    setBroadcastQueue((current) => [nextBroadcast, ...current]);
    setComposer(defaultComposer);
  }

  return (
    <div className="dashboard-screen">
      <section className="dashboard-block">
        <ParitySectionHeader title="BROADCASTS" subtitle="PLATFORM NOTICES AND RELEASE MESSAGES" />
        <div className="dashboard-metrics">
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>QUEUED</span>
            </div>
            <div className="metric-card__value">{queueCount}</div>
            <div className="metric-card__meta">Broadcasts in the platform queue</div>
          </ParityCard>
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>DRAFTS</span>
            </div>
            <div className="metric-card__value">
              {broadcastQueue.filter((broadcast) => broadcast.state === "Draft").length}
            </div>
            <div className="metric-card__meta">Locally staged notices</div>
          </ParityCard>
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>SENT</span>
            </div>
            <div className="metric-card__value">
              {broadcastQueue.filter((broadcast) => broadcast.state === "Sent").length}
            </div>
            <div className="metric-card__meta">Completed communications</div>
          </ParityCard>
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="DRAFT THE NEXT PLATFORM NOTICE" subtitle="WHAT OPERATORS WILL READ" />
        <ParityCard className="corporate-toolbar" kind="foundation">
          <div className="corporate-toolbar__layout">
            <div className="corporate-toolbar__layout-title">MESSAGE COMPOSER</div>
            <div className="modal-form">
              <ParityField
                id="broadcast-title"
                label="TITLE"
                value={composer.title}
                onChange={(event) => setComposer((current) => ({ ...current, title: event.target.value }))}
                placeholder="Broadcast title"
              />
              <ParityField
                id="broadcast-audience"
                label="AUDIENCE"
                value={composer.audience}
                onChange={(event) => setComposer((current) => ({ ...current, audience: event.target.value }))}
                placeholder="Tenant admins"
              />
              <ParityField
                as="textarea"
                id="broadcast-body"
                label="BODY"
                value={composer.body}
                onChange={(event) => setComposer((current) => ({ ...current, body: event.target.value }))}
                rows={8}
              />
            </div>
            <div className="modal-actions">
              <ParityButton onClick={handleQueueBroadcast}>QUEUE BROADCAST</ParityButton>
              <ParityButton tone="ghost" onClick={() => setComposer(defaultComposer)}>
                LOAD TEMPLATE
              </ParityButton>
            </div>
          </div>
        </ParityCard>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="MESSAGE QUEUE" subtitle="SCHEDULED BROADCASTS" />
        <div className="machine-card-list">
          {broadcastQueue.map((broadcast) => (
            <ParityCard key={`${broadcast.title}-${broadcast.sendAt}`} className="machine-stop-card">
              <div className="machine-stop-card__header">
                <div>
                  <div className="machine-stop-card__title">{broadcast.title}</div>
                  <div className="machine-stop-card__meta">{broadcast.audience}</div>
                </div>
                <StatusPill label={broadcast.state.toUpperCase()} tone={toneForState(broadcast.state)} />
              </div>
              <div className="machine-stop-card__details">
                <div className="machine-stop-card__row">
                  <span>SEND AT</span>
                  <strong>{broadcast.sendAt}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>BODY</span>
                  <strong>{broadcast.body}</strong>
                </div>
              </div>
            </ParityCard>
          ))}
        </div>
      </section>
    </div>
  );
}
