"use client";

import { ParityCard } from "@/components/parity/parity-card";
import { ParitySectionHeader } from "@/components/parity/parity-section-header";
import { StatusPill } from "@/components/primitives/status-pill";
import {
  GUARDRAILS,
  OVERVIEW_METRICS,
  PRIORITY_QUEUE,
  RECENT_ACTIONS,
  RELEASE_RINGS,
} from "@/admin-center-data";

function toneForQueueTag(tag: string) {
  const normalized = tag.toLowerCase();
  if (normalized.includes("critical") || normalized.includes("blocker")) {
    return "warning" as const;
  }

  return "success" as const;
}

function toneForRing(ringTone: string) {
  if (ringTone === "warning") {
    return "warning" as const;
  }

  if (ringTone === "signal") {
    return "default" as const;
  }

  return "success" as const;
}

export function OverviewScreen() {
  return (
    <div className="dashboard-screen">
      <section className="dashboard-block">
        <ParitySectionHeader title="SYSTEM OVERVIEW" subtitle="CROSS-TENANT POSTURE" />
        <div className="dashboard-metrics">
          {OVERVIEW_METRICS.map((metric) => (
            <ParityCard key={metric.label} className="metric-card">
              <div className="metric-card__label">
                <span>{metric.label.toUpperCase()}</span>
              </div>
              <div className="metric-card__value">{metric.value}</div>
              <div className="metric-card__meta">{metric.meta}</div>
            </ParityCard>
          ))}
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="CURRENT PLATFORM QUEUE" subtitle="IMMEDIATE PRIORITIES" />
        <div className="machine-card-list">
          {PRIORITY_QUEUE.map((item) => (
            <ParityCard key={item.title} className="machine-stop-card">
              <div className="machine-stop-card__header">
                <div>
                  <div className="machine-stop-card__title">{item.title}</div>
                  <div className="machine-stop-card__meta">Priority queue</div>
                </div>
              </div>
              <div className="machine-stop-card__details">
                <div className="machine-stop-card__row">
                  <span>SUMMARY</span>
                  <strong>{item.copy}</strong>
                </div>
                <div className="machine-stop-card__row">
                  <span>TAGS</span>
                  <strong>
                    {item.tags.map((tag, index) => (
                      <span key={tag}>
                        {index > 0 ? " " : null}
                        <StatusPill label={tag.toUpperCase()} tone={toneForQueueTag(tag)} />
                      </span>
                    ))}
                  </strong>
                </div>
              </div>
            </ParityCard>
          ))}
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="RING STATUS" subtitle="RELEASE POSTURE" />
        <div className="machine-card-list">
          {RELEASE_RINGS.map((ring) => (
            <ParityCard key={ring.title} className="machine-stop-card">
              <div className="machine-stop-card__header">
                <div>
                  <div className="machine-stop-card__title">{ring.title}</div>
                  <div className="machine-stop-card__meta">Cross-tenant rollout state</div>
                </div>
                <StatusPill label={ring.tone.toUpperCase()} tone={toneForRing(ring.tone)} />
              </div>
              <div className="machine-stop-card__details">
                <div className="machine-stop-card__row">
                  <span>STATUS</span>
                  <strong>{ring.copy}</strong>
                </div>
              </div>
            </ParityCard>
          ))}
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="RECENT ADMIN ACTIONS" subtitle="OPERATOR FEED" />
        <div className="notes-list">
          {RECENT_ACTIONS.map((item) => (
            <ParityCard key={item.title} className="note-row">
              <strong>{item.title}</strong>
              <p>{item.copy}</p>
            </ParityCard>
          ))}
        </div>
      </section>

      <section className="dashboard-block">
        <ParitySectionHeader title="BOUNDARY REMINDERS" subtitle="PLATFORM GUARDRAILS" />
        <div className="notes-list">
          {GUARDRAILS.map((item) => (
            <ParityCard key={item.title} className="note-row">
              <strong>{item.title}</strong>
              <p>{item.copy}</p>
            </ParityCard>
          ))}
        </div>
      </section>
    </div>
  );
}
