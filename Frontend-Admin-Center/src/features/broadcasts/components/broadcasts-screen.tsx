"use client";

import { ParityButton } from "@/components/parity/parity-button";
import { ParityCard } from "@/components/parity/parity-card";
import { ParityField } from "@/components/parity/parity-field";
import { ParitySectionHeader } from "@/components/parity/parity-section-header";
import { StatusPill } from "@/components/primitives/status-pill";
import { useBroadcastsViewModel } from "@/features/broadcasts/hooks/use-broadcasts-view-model";

type BroadcastState = "Scheduled" | "Draft" | "Sent";

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
  const { composer, broadcastQueue, queueCount, draftCount, sentCount, setComposer, resetComposer, queueBroadcast } =
    useBroadcastsViewModel();

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
            <div className="metric-card__value">{draftCount}</div>
            <div className="metric-card__meta">Staged notices</div>
          </ParityCard>
          <ParityCard className="metric-card">
            <div className="metric-card__label">
              <span>SENT</span>
            </div>
            <div className="metric-card__value">{sentCount}</div>
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
              <ParityButton onClick={queueBroadcast}>QUEUE BROADCAST</ParityButton>
              <ParityButton tone="ghost" onClick={resetComposer}>
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
