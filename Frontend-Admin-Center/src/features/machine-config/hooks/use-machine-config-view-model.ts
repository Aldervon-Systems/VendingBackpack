"use client";

import { startTransition, useDeferredValue, useEffect, useMemo, useState } from "react";
import type { MachineConfigRepository } from "@/features/machine-config/lib/machine-config-repository";
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

export function useMachineConfigViewModel(repository: MachineConfigRepository) {
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
    const summaries = await repository.listMachines();
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
        const summaries = await repository.listMachines();
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
  }, [repository]);

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
        const nextDetail = await repository.getMachineConfig(activeMachineId);
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
  }, [activeMachineId, repository]);

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
          ? await repository.saveDraft(detail.summary.id, detail.draftRows)
          : mode === "reset"
            ? await repository.resetDraft(detail.summary.id)
            : await repository.publishDraft(detail.summary.id, detail.draftRows);

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

  function updateSelectedSlot(patch: Partial<MachineConfigSlot>) {
    if (!selectedSlot) {
      return;
    }

    commitDraft(updateSlot(detail?.draftRows ?? [], selectedSlot.id, patch));
  }

  return {
    machineSummaries,
    activeMachineId,
    detail,
    selectedSlotId,
    selectedSlot,
    searchQuery,
    statusFilter,
    activeTab,
    isLoading,
    notice,
    error,
    filteredMachines,
    isDirty,
    criticalIssueCount,
    serializeRows: serializeRows(detail),
    setActiveTab,
    setSearchQuery,
    setStatusFilter,
    setSelectedSlotId,
    refreshMachineList: (nextMachineId?: string) => refreshMachineList(nextMachineId),
    handleSelectMachine,
    addRow: () => detail && commitDraft(addRow(detail.draftRows), "Added a new irregular shelf to the draft layout."),
    removeRow: (rowId: string) => {
      if (!detail) {
        return;
      }

      const nextRows = removeRow(detail.draftRows, rowId);
      commitDraft(nextRows, "Removed a shelf from the draft layout.");
      setSelectedSlotId(findFirstSlotId(nextRows));
    },
    addSlot: (rowId: string) => {
      if (!detail) {
        return;
      }

      const nextRows = addSlot(detail.draftRows, rowId);
      commitDraft(nextRows, "Added a new slot position to the selected shelf.");
    },
    removeSlot: (rowId: string, slotId: string) => {
      if (!detail) {
        return;
      }

      const nextRows = removeSlot(detail.draftRows, rowId, slotId);
      commitDraft(nextRows, "Removed a slot from the selected shelf.");
      setSelectedSlotId((current) => (current === slotId ? findFirstSlotId(nextRows) : current));
    },
    swapSlots: (sourceId: string, targetId: string) => {
      if (!detail) {
        return;
      }

      commitDraft(swapSlots(detail.draftRows, sourceId, targetId), "Swapped slot payloads in the visual layout.");
    },
    updateSelectedSlot,
    persistDraft,
  };
}
