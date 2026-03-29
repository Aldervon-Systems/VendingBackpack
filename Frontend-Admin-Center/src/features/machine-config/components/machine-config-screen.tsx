"use client";

import { startTransition, useDeferredValue, useEffect, useMemo, useState } from "react";
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
import { MockMachineConfigRepository } from "@/features/machine-config/lib/mock-machine-config-repository";
import {
  addRow,
  addSlot,
  buildMachineSummary,
  buildValidationIssues,
  cloneRows,
  findFirstSlotId,
  removeRow,
  removeSlot,
  swapSlots,
  updateSlot,
} from "@/features/machine-config/lib/machine-config-utils";
import type {
  MachineConfigDetail,
  MachineConfigStatus,
  MachineConfigSummary,
  MachineConfigTabId,
  MachineConfigSlot,
} from "@/features/machine-config/lib/types";

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

  return severity === "warning" ? "warning" : "warning";
}

function summarizeCriticalCount(detail: MachineConfigDetail | null) {
  return detail?.validationIssues.filter((issue) => issue.severity === "critical").length ?? 0;
}

function serializeRows(detail: MachineConfigDetail | null) {
  if (!detail) {
    return "";
  }

  return JSON.stringify(detail.draftRows);
}

function findSlot(detail: MachineConfigDetail | null, slotId: string) {
  return detail?.draftRows.flatMap((row) => row.slots).find((slot) => slot.id === slotId) ?? null;
}

export function MachineConfigScreen() {
  const [machineSummaries, setMachineSummaries] = useState<MachineConfigSummary[]>([]);
  const [activeMachineId, setActiveMachineId] = useState("");
  const [detail, setDetail] = useState<MachineConfigDetail | null>(null);
  const [selectedSlotId, setSelectedSlotId] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<MachineConfigStatus | "All">("All");
  const [activeTab, setActiveTab] = useState<MachineConfigTabId>("layout");
  const [isLoading, setIsLoading] = useState(true);
  const [notice, setNotice] = useState("");
  const [error, setError] = useState("");

  const deferredSearchQuery = useDeferredValue(searchQuery);
  const selectedSlot = findSlot(detail, selectedSlotId);
  const isDirty = detail ? JSON.stringify(detail.draftRows) !== JSON.stringify(detail.publishedRows) : false;
  const criticalIssueCount = summarizeCriticalCount(detail);

  const filteredMachines = useMemo(() => {
    const query = deferredSearchQuery.trim().toLowerCase();

    return machineSummaries.filter((machine) => {
      const matchesFilter = statusFilter === "All" || machine.status === statusFilter;
      const matchesQuery =
        !query ||
        machine.name.toLowerCase().includes(query) ||
        machine.organization.toLowerCase().includes(query) ||
        machine.location.toLowerCase().includes(query) ||
        machine.model.toLowerCase().includes(query);

      return matchesFilter && matchesQuery;
    });
  }, [deferredSearchQuery, machineSummaries, statusFilter]);

  async function refreshMachineList(nextMachineId?: string) {
    const summaries = await machineConfigRepository.listMachines();
    setMachineSummaries(summaries);

    if (!activeMachineId || nextMachineId) {
      setActiveMachineId(nextMachineId ?? summaries[0]?.id ?? "");
    }
  }

  useEffect(() => {
    let active = true;

    async function loadMachines() {
      setIsLoading(true);
      setError("");

      try {
        const summaries = await machineConfigRepository.listMachines();
        if (!active) {
          return;
        }

        setMachineSummaries(summaries);
        setActiveMachineId(summaries[0]?.id ?? "");
      } catch (nextError) {
        if (!active) {
          return;
        }

        setError(nextError instanceof Error ? nextError.message : "Machine configuration shell could not be loaded.");
      } finally {
        if (active) {
          setIsLoading(false);
        }
      }
    }

    void loadMachines();

    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    let active = true;

    if (!activeMachineId) {
      setDetail(null);
      setSelectedSlotId("");
      return () => {
        active = false;
      };
    }

    async function loadDetail() {
      setIsLoading(true);
      setError("");

      try {
        const nextDetail = await machineConfigRepository.getMachineConfig(activeMachineId);
        if (!active) {
          return;
        }

        setDetail(nextDetail);
        setSelectedSlotId(findFirstSlotId(nextDetail.draftRows));
      } catch (nextError) {
        if (!active) {
          return;
        }

        setError(nextError instanceof Error ? nextError.message : "Machine draft could not be loaded.");
      } finally {
        if (active) {
          setIsLoading(false);
        }
      }
    }

    void loadDetail();

    return () => {
      active = false;
    };
  }, [activeMachineId]);

  function commitDraft(nextRows: MachineConfigDetail["draftRows"], nextNotice?: string) {
    setDetail((current) => {
      if (!current) {
        return current;
      }

      const draftRows = cloneRows(nextRows);
      const validationIssues = buildValidationIssues(draftRows);

      return {
        ...current,
        draftRows,
        validationIssues,
        summary: buildMachineSummary(
          current.metadata,
          draftRows,
          current.publishedRows,
          validationIssues,
          current.summary.lastPublishedAt,
          "Unsaved changes",
        ),
      };
    });

    if (nextNotice) {
      setNotice(nextNotice);
    }
  }

  async function persistDraft(mode: "save" | "reset" | "publish") {
    if (!detail) {
      return;
    }

    setIsLoading(true);
    setError("");

    try {
      const nextDetail =
        mode === "save"
          ? await machineConfigRepository.saveDraft(detail.summary.id, detail.draftRows)
          : mode === "reset"
            ? await machineConfigRepository.resetDraft(detail.summary.id)
            : await machineConfigRepository.publishDraft(detail.summary.id, detail.draftRows);

      setDetail(nextDetail);
      setSelectedSlotId((current) => current || findFirstSlotId(nextDetail.draftRows));
      await refreshMachineList(detail.summary.id);
      setNotice(
        mode === "save"
          ? "Draft saved locally and ready for backend hookup."
          : mode === "reset"
            ? "Draft reset to the latest published layout."
            : "Draft published through the shell placeholder flow.",
      );
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : "Machine configuration action failed.");
    } finally {
      setIsLoading(false);
    }
  }

  function handleSelectMachine(machineId: string) {
    if (machineId === activeMachineId) {
      return;
    }

    if (isDirty && typeof window !== "undefined") {
      const shouldContinue = window.confirm("This machine has unsaved draft edits. Switch machines and discard local changes?");
      if (!shouldContinue) {
        return;
      }
    }

    startTransition(() => {
      setActiveMachineId(machineId);
      setNotice("");
    });
  }

  if (!machineSummaries.length && isLoading) {
    return (
      <div className="dashboard-screen">
        <ParityCard className="corporate-empty-state">
          <div className="corporate-empty-state__title">Loading machine configuration shell</div>
          <div className="corporate-empty-state__copy">Preparing the machine directory, current drafts, and serial mapping workspace.</div>
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
              Configure specific machines so serial telemetry, slot bindings, and stocked inventory stay aligned before backend integration lands.
            </div>
          </div>

          <div className="machine-config-header__actions">
            <ParityButton tone="ghost" onClick={() => void refreshMachineList(activeMachineId)}>
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
            <span>{detail?.backendState ?? "Mock Ready"}</span>
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
                        <div className="metric-card__label"><span>Total slots</span></div>
                        <div className="metric-card__value">{detail.summary.slotCount}</div>
                        <div className="metric-card__meta">Current irregular machine footprint</div>
                      </ParityCard>
                      <ParityCard className="metric-card">
                        <div className="metric-card__label"><span>Configured</span></div>
                        <div className="metric-card__value">{detail.summary.configuredCount}</div>
                        <div className="metric-card__meta">Slots ready for publish</div>
                      </ParityCard>
                      <ParityCard className="metric-card">
                        <div className="metric-card__label"><span>Serial coverage</span></div>
                        <div className="metric-card__value">{detail.summary.serialCoverage}%</div>
                        <div className="metric-card__meta">Serial channels assigned</div>
                      </ParityCard>
                    </div>
                  </section>

                  <div className="machine-config-summary-grid">
                    <ParityCard className="machine-config-summary-card">
                      <div className="parity-section-header__title">MACHINE METADATA</div>
                      <div className="machine-config-summary-card__rows">
                        <div><span>Hardware profile</span><strong>{detail.metadata.hardwareProfile}</strong></div>
                        <div><span>Serial provider</span><strong>{detail.metadata.serialProvider}</strong></div>
                        <div><span>Last audit</span><strong>{detail.metadata.lastAuditBy} · {detail.metadata.lastAuditAt}</strong></div>
                        <div><span>Last published</span><strong>{detail.summary.lastPublishedAt}</strong></div>
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
                    onAddRow={() => {
                      commitDraft(addRow(detail.draftRows), "Added a new irregular shelf to the draft layout.");
                    }}
                    onRemoveRow={(rowId) => {
                      const nextRows = removeRow(detail.draftRows, rowId);
                      commitDraft(nextRows, "Removed a shelf from the draft layout.");
                      setSelectedSlotId(findFirstSlotId(nextRows));
                    }}
                    onAddSlot={(rowId) => {
                      const nextRows = addSlot(detail.draftRows, rowId);
                      commitDraft(nextRows, "Added a new slot position to the selected shelf.");
                    }}
                    onRemoveSlot={(rowId, slotId) => {
                      const nextRows = removeSlot(detail.draftRows, rowId, slotId);
                      commitDraft(nextRows, "Removed a slot from the selected shelf.");
                      setSelectedSlotId((current) => (current === slotId ? findFirstSlotId(nextRows) : current));
                    }}
                    onSwapSlots={(sourceId, targetId) => {
                      commitDraft(swapSlots(detail.draftRows, sourceId, targetId), "Swapped slot payloads in the visual layout.");
                    }}
                  />

                  <SlotInspectorPanel
                    slot={selectedSlot}
                    onChange={(patch) => {
                      if (!selectedSlot) {
                        return;
                      }

                      commitDraft(updateSlot(detail.draftRows, selectedSlot.id, patch));
                    }}
                  />
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
                              <td><strong>{slot.code}</strong></td>
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
                                const matchingSlot = detail.draftRows.flatMap((row) => row.slots).find((slot) => slot.code === issue.slotCode);
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
                            {event.action === "Published" ? <CheckCircle2 size={16} /> : event.action === "Draft Saved" ? <Save size={16} /> : <History size={16} />}
                          </div>
                          <div>
                            <strong>{event.action}</strong>
                            <div>{event.detail}</div>
                            <div>{event.actor} · {event.timestamp}</div>
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
            <ParityButton onClick={() => void persistDraft("publish")} disabled={isLoading || criticalIssueCount > 0 || serializeRows(detail) === ""}>
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
