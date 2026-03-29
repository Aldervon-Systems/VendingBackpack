"use client";

import {
  CheckCircle2,
  Clock3,
  History,
  LayoutGrid,
  RefreshCcw,
  Save,
  Search,
  Server,
} from "lucide-react";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityCard } from "@/components/parity/parity-card";
import { ParityField } from "@/components/parity/parity-field";
import { ParitySectionHeader } from "@/components/parity/parity-section-header";
import { StatusPill } from "@/components/primitives/status-pill";
import { MachineConfigTabs } from "@/features/machine-config/components/machine-config-tabs";
import { SlotInspectorPanel } from "@/features/machine-config/components/slot-inspector-panel";
import { VendingLayoutEditor } from "@/features/machine-config/components/vending-layout-editor";
import { useMachineConfigViewModel } from "@/features/machine-config/hooks/use-machine-config-view-model";
import { MockMachineConfigRepository } from "@/features/machine-config/lib/mock-machine-config-repository";
import type { MachineConfigStatus, MachineConfigTabId } from "@/features/machine-config/lib/types";

const machineConfigRepository = new MockMachineConfigRepository();

const STATUS_FILTER_OPTIONS: Array<MachineConfigStatus | "All"> = ["All", "Healthy", "Draft", "Mismatch", "Needs Review"];

const TAB_OPTIONS: Array<{ id: MachineConfigTabId; label: string }> = [
  { id: "summary", label: "Summary" },
  { id: "layout", label: "Visual Layout" },
  { id: "serial", label: "Serial Mapping" },
  { id: "validation", label: "Validation" },
  { id: "history", label: "History" },
];

function toneForMachineStatus(status: MachineConfigStatus) {
  if (status === "Healthy") {
    return "success" as const;
  }

  if (status === "Mismatch" || status === "Needs Review") {
    return "warning" as const;
  }

  return "default" as const;
}

function toneForSeverity(severity: "critical" | "warning" | "info") {
  if (severity === "info") {
    return "default" as const;
  }

  return "warning" as const;
}

export function MachineConfigScreen() {
  const {
    activeMachineId,
    activeTab,
    detail,
    error,
    filteredMachines,
    handleSelectMachine,
    isDirty,
    isLoading,
    notice,
    criticalIssueCount,
    searchQuery,
    selectedSlot,
    selectedSlotId,
    serializeRows,
    setActiveTab,
    setSearchQuery,
    setSelectedSlotId,
    setStatusFilter,
    statusFilter,
    refreshMachineList,
    addRow,
    removeRow,
    addSlot,
    removeSlot,
    swapSlots,
    updateSelectedSlot,
    persistDraft,
  } = useMachineConfigViewModel(machineConfigRepository);

  if (!filteredMachines.length && isLoading) {
    return (
      <div className="dashboard-screen">
        <ParityCard className="corporate-empty-state">
          <div className="corporate-empty-state__title">Loading machine configuration shell</div>
          <div className="corporate-empty-state__copy">
            Preparing the machine directory, current drafts, and serial mapping workspace.
          </div>
        </ParityCard>
      </div>
    );
  }

  return (
    <div className="machine-config-screen">
      <ParityCard kind="foundation" className="corporate-toolbar">
        <div className="corporate-toolbar__top">
          <div className="corporate-toolbar__copy">
            <div className="corporate-toolbar__eyebrow">MACHINE CONFIGURATION TOOLING</div>
            <h1 className="corporate-toolbar__title">Digital planograms for irregular vending machines</h1>
            <div className="corporate-toolbar__subtitle">
              Configure specific machines so serial telemetry, slot bindings, and stocked inventory stay aligned before
              backend integration lands.
            </div>
          </div>

          <div className="machine-config-header__actions">
            <ParityButton tone="ghost" onClick={() => void refreshMachineList()}>
              <RefreshCcw size={16} />
              Refresh shell
            </ParityButton>
          </div>
        </div>

        <div className="corporate-toolbar__layout">
          <div className="corporate-toolbar__layout-title">DIRECTORY FILTERS</div>
          <div className="machine-config-toolbar">
            <ParityField
              id="machine-config-search"
              label="SEARCH MACHINES"
              value={searchQuery}
              onChange={(event) => setSearchQuery(event.target.value)}
              placeholder="Search by machine, organization, location, or model"
              suffix={<Search size={14} />}
            />
            <ParityField
              as="select"
              id="machine-config-status"
              label="STATUS FILTER"
              value={statusFilter}
              onChange={(value) => setStatusFilter(value as MachineConfigStatus | "All")}
              options={STATUS_FILTER_OPTIONS.map((option) => ({ value: option, label: option }))}
            />
          </div>
          <div className="corporate-toolbar__meta">
            <span>{filteredMachines.length} machines in view</span>
            <span>{criticalIssueCount} critical issues on the active draft</span>
            <span>{detail?.backendState ?? "Ready"}</span>
          </div>
        </div>
      </ParityCard>

      {error ? <div className="form-error">{error}</div> : null}
      {notice ? <div className="machine-config-notice">{notice}</div> : null}

      <div className="machine-config-workspace">
        <ParityCard className="machine-directory">
          <div className="machine-directory__header">
            <div>
              <div className="parity-section-header__title">MACHINE DIRECTORY</div>
              <div className="parity-section-header__subtitle">ACTIVE CONFIGURATION TARGETS</div>
            </div>
          </div>

          <div className="machine-directory__list">
            {filteredMachines.map((machine) => (
              <button
                key={machine.id}
                className="machine-directory__row"
                type="button"
                data-active={machine.id === activeMachineId}
                onClick={() => handleSelectMachine(machine.id)}
              >
                <div>
                  <strong>{machine.name}</strong>
                  <div>{machine.organization}</div>
                  <div>{machine.location}</div>
                </div>
                <div className="machine-directory__meta">
                  <StatusPill label={machine.status} tone={toneForMachineStatus(machine.status)} />
                  <span>{machine.slotCount} slots</span>
                </div>
              </button>
            ))}
          </div>
        </ParityCard>

        <div className="machine-config-main">
          {detail ? (
            <>
              <ParityCard className="machine-config-focus">
                <div className="machine-config-focus__header">
                  <div>
                    <div className="parity-section-header__title">ACTIVE MACHINE</div>
                    <div className="machine-config-focus__title">{detail.metadata.name}</div>
                    <div className="machine-config-focus__subtitle">
                      {detail.metadata.organization} · {detail.metadata.location} · {detail.metadata.model}
                    </div>
                  </div>

                  <div className="machine-config-focus__meta">
                    <StatusPill label={detail.summary.status} tone={toneForMachineStatus(detail.summary.status)} />
                    <span>{detail.publishedVersion}</span>
                    <span>{detail.backendState}</span>
                  </div>
                </div>

                <MachineConfigTabs tabs={TAB_OPTIONS} activeTab={activeTab} onChange={setActiveTab} />
              </ParityCard>

              {activeTab === "summary" ? (
                <div className="machine-config-tab machine-config-tab--summary">
                  <section className="dashboard-block">
                    <ParitySectionHeader title="CONFIGURATION SUMMARY" subtitle="DRAFT HEALTH AND READINESS" />
                    <div className="dashboard-metrics">
                      <ParityCard className="metric-card">
                        <div className="metric-card__label">
                          <span>Total slots</span>
                        </div>
                        <div className="metric-card__value">{detail.summary.slotCount}</div>
                        <div className="metric-card__meta">Current irregular machine footprint</div>
                      </ParityCard>
                      <ParityCard className="metric-card">
                        <div className="metric-card__label">
                          <span>Configured</span>
                        </div>
                        <div className="metric-card__value">{detail.summary.configuredCount}</div>
                        <div className="metric-card__meta">Slots ready for publish</div>
                      </ParityCard>
                      <ParityCard className="metric-card">
                        <div className="metric-card__label">
                          <span>Serial coverage</span>
                        </div>
                        <div className="metric-card__value">{detail.summary.serialCoverage}%</div>
                        <div className="metric-card__meta">Serial channels assigned</div>
                      </ParityCard>
                    </div>
                  </section>

                  <div className="machine-config-summary-grid">
                    <ParityCard className="machine-config-summary-card">
                      <div className="parity-section-header__title">MACHINE METADATA</div>
                      <div className="machine-config-summary-card__rows">
                        <div>
                          <span>Hardware profile</span>
                          <strong>{detail.metadata.hardwareProfile}</strong>
                        </div>
                        <div>
                          <span>Serial provider</span>
                          <strong>{detail.metadata.serialProvider}</strong>
                        </div>
                        <div>
                          <span>Last audit</span>
                          <strong>
                            {detail.metadata.lastAuditBy} · {detail.metadata.lastAuditAt}
                          </strong>
                        </div>
                        <div>
                          <span>Last published</span>
                          <strong>{detail.summary.lastPublishedAt}</strong>
                        </div>
                      </div>
                    </ParityCard>

                    <ParityCard className="machine-config-summary-card">
                      <div className="parity-section-header__title">READINESS NOTES</div>
                      <div className="machine-config-summary-card__copy">{detail.metadata.note}</div>
                      <div className="machine-config-summary-card__signal">
                        <Server size={16} />
                        <span>Backend status: {detail.backendState}</span>
                      </div>
                    </ParityCard>
                  </div>
                </div>
              ) : null}

              {activeTab === "layout" ? (
                <div className="machine-config-tab machine-config-tab--layout">
                  <VendingLayoutEditor
                    rows={detail.draftRows}
                    selectedSlotId={selectedSlotId}
                    onSelectSlot={setSelectedSlotId}
                    onAddRow={addRow}
                    onRemoveRow={removeRow}
                    onAddSlot={addSlot}
                    onRemoveSlot={removeSlot}
                    onSwapSlots={swapSlots}
                  />

                  <SlotInspectorPanel slot={selectedSlot} onChange={updateSelectedSlot} />
                </div>
              ) : null}

              {activeTab === "serial" ? (
                <div className="machine-config-tab">
                  <ParityCard className="corporate-widget">
                    <ParitySectionHeader title="SERIAL MAPPING TABLE" subtitle="EXPECTED VS STOCKED STATE" />
                    <div className="corporate-table-wrap">
                      <table className="corporate-table machine-config-serial-table">
                        <thead>
                          <tr>
                            <th>Slot</th>
                            <th>Expected SKU</th>
                            <th>Actual SKU</th>
                            <th>Serial channel</th>
                            <th>Actual qty</th>
                            <th>Status</th>
                          </tr>
                        </thead>
                        <tbody>
                          {detail.draftRows.flatMap((row) => row.slots).map((slot) => (
                            <tr key={slot.id}>
                              <td>
                                <strong>{slot.code}</strong>
                              </td>
                              <td>{slot.sku || "Unassigned"}</td>
                              <td>{slot.actualSku || "None"}</td>
                              <td>{slot.serialChannel || "Missing"}</td>
                              <td>{slot.actualQuantity}</td>
                              <td>
                                <button
                                  className="machine-config-inline-chip"
                                  type="button"
                                  onClick={() => {
                                    setSelectedSlotId(slot.id);
                                    setActiveTab("layout");
                                  }}
                                >
                                  {slot.status}
                                </button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </ParityCard>
                </div>
              ) : null}

              {activeTab === "validation" ? (
                <div className="machine-config-tab">
                  <ParityCard className="corporate-widget">
                    <ParitySectionHeader title="VALIDATION QUEUE" subtitle="PUBLISH GATES AND WARNINGS" />
                    <div className="machine-validation-list">
                      {detail.validationIssues.length ? (
                        detail.validationIssues.map((issue) => (
                          <button
                            key={issue.id}
                            className="machine-validation-row"
                            type="button"
                            onClick={() => {
                              if (issue.slotCode) {
                                const matchingSlot = detail.draftRows
                                  .flatMap((row) => row.slots)
                                  .find((slot) => slot.code === issue.slotCode);

                                if (matchingSlot) {
                                  setSelectedSlotId(matchingSlot.id);
                                  setActiveTab("layout");
                                }
                              }
                            }}
                          >
                            <div className="machine-validation-row__title">
                              <StatusPill label={issue.severity} tone={toneForSeverity(issue.severity)} />
                              <strong>{issue.title}</strong>
                            </div>
                            <div className="machine-validation-row__detail">{issue.detail}</div>
                          </button>
                        ))
                      ) : (
                        <div className="machine-validation-empty">
                          <CheckCircle2 size={18} />
                          <span>No validation issues remain on the draft.</span>
                        </div>
                      )}
                    </div>
                  </ParityCard>
                </div>
              ) : null}

              {activeTab === "history" ? (
                <div className="machine-config-tab">
                  <ParityCard className="corporate-widget">
                    <ParitySectionHeader title="CONFIGURATION HISTORY" subtitle="AUDIT TRAIL PLACEHOLDERS" />
                    <div className="machine-history-list">
                      {detail.history.map((event) => (
                        <div key={event.id} className="machine-history-row">
                          <div className="machine-history-row__icon">
                            {event.action === "Published" ? (
                              <CheckCircle2 size={16} />
                            ) : event.action === "Draft Saved" ? (
                              <Save size={16} />
                            ) : (
                              <History size={16} />
                            )}
                          </div>
                          <div>
                            <strong>{event.action}</strong>
                            <div>{event.detail}</div>
                            <div>
                              {event.actor} · {event.timestamp}
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </ParityCard>
                </div>
              ) : null}
            </>
          ) : null}
        </div>
      </div>

      {detail ? (
        <ParityCard className="machine-config-draft-bar" kind="surface">
          <div className="machine-config-draft-bar__copy">
            <div className="machine-config-draft-bar__title">Draft state</div>
            <div className="machine-config-draft-bar__meta">
              <span>{isDirty ? "Unsaved changes" : "Draft matches published version"}</span>
              <span>{criticalIssueCount} critical issues</span>
              <span>Last published {detail.summary.lastPublishedAt}</span>
            </div>
          </div>

          <div className="machine-config-draft-bar__actions">
            <ParityButton tone="ghost" onClick={() => void persistDraft("reset")} disabled={!isDirty || isLoading}>
              <RefreshCcw size={16} />
              Reset draft
            </ParityButton>
            <ParityButton tone="dark" onClick={() => void persistDraft("save")} disabled={!isDirty || isLoading}>
              <Save size={16} />
              Save draft
            </ParityButton>
            <ParityButton
              onClick={() => void persistDraft("publish")}
              disabled={isLoading || criticalIssueCount > 0 || serializeRows === ""}
            >
              <LayoutGrid size={16} />
              Publish shell
            </ParityButton>
          </div>
        </ParityCard>
      ) : null}

      {isLoading ? (
        <div className="machine-config-loading">
          <Clock3 size={16} />
          <span>Synchronizing machine configuration shell</span>
        </div>
      ) : null}
    </div>
  );
}
