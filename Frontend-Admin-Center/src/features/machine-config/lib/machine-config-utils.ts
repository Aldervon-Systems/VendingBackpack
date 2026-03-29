import type {
  MachineConfigRow,
  MachineConfigSlot,
  MachineConfigStatus,
  MachineConfigSummary,
  MachineMetadata,
  SlotStatus,
  ValidationIssue,
} from "@/features/machine-config/lib/types";

function fallbackId(prefix: string) {
  return `${prefix}-${Math.random().toString(36).slice(2, 10)}`;
}

export function createClientId(prefix: string) {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return `${prefix}-${crypto.randomUUID()}`;
  }

  return fallbackId(prefix);
}

function swapSlotPayload(source: MachineConfigSlot, target: MachineConfigSlot) {
  return {
    sku: target.sku,
    itemName: target.itemName,
    capacity: target.capacity,
    parLevel: target.parLevel,
    serialChannel: target.serialChannel,
    actualSku: target.actualSku,
    actualQuantity: target.actualQuantity,
    note: target.note,
  };
}

function classifySlot(slot: MachineConfigSlot): SlotStatus {
  if (!slot.sku.trim() && !slot.itemName.trim()) {
    return "empty";
  }

  if (slot.actualSku.trim() && slot.sku.trim() && slot.actualSku.trim().toLowerCase() !== slot.sku.trim().toLowerCase()) {
    return "mismatch";
  }

  if (!slot.serialChannel.trim() || slot.capacity <= 0 || slot.parLevel <= 0) {
    return "review";
  }

  return "configured";
}

export function createSlotCode(rowIndex: number, slotIndex: number) {
  return `${String.fromCharCode(65 + rowIndex)}${slotIndex + 1}`;
}

export function normalizeRows(rows: MachineConfigRow[]): MachineConfigRow[] {
  return rows.map((row, rowIndex) => ({
    ...row,
    label: row.label || `Shelf ${rowIndex + 1}`,
    slots: row.slots.map((slot, slotIndex) => {
      const normalizedSlot = {
        ...slot,
        rowId: row.id,
        code: createSlotCode(rowIndex, slotIndex),
      };

      return {
        ...normalizedSlot,
        status: classifySlot(normalizedSlot),
      };
    }),
  }));
}

export function cloneRows(rows: MachineConfigRow[]) {
  return normalizeRows(JSON.parse(JSON.stringify(rows)) as MachineConfigRow[]);
}

export function findFirstSlotId(rows: MachineConfigRow[]) {
  return rows.flatMap((row) => row.slots)[0]?.id ?? "";
}

export function buildValidationIssues(rows: MachineConfigRow[]): ValidationIssue[] {
  const issues: ValidationIssue[] = [];
  const serialOwners = new Map<string, string>();

  rows.forEach((row) => {
    if (row.slots.length === 0) {
      issues.push({
        id: `row-empty-${row.id}`,
        severity: "warning",
        title: `${row.label} has no slots`,
        detail: "Add at least one slot before this shelf can be published.",
      });
    }

    row.slots.forEach((slot) => {
      const trimmedSku = slot.sku.trim();
      const trimmedName = slot.itemName.trim();
      const trimmedSerial = slot.serialChannel.trim();

      if (!trimmedSku || !trimmedName) {
        issues.push({
          id: `slot-missing-item-${slot.id}`,
          severity: "critical",
          title: `${slot.code} is incomplete`,
          detail: "Every configured slot needs both an SKU and a display name.",
          slotCode: slot.code,
        });
      }

      if (slot.capacity <= 0 || slot.parLevel <= 0) {
        issues.push({
          id: `slot-capacity-${slot.id}`,
          severity: "warning",
          title: `${slot.code} needs capacity targets`,
          detail: "Capacity and par level must both be greater than zero for refill planning.",
          slotCode: slot.code,
        });
      }

      if (!trimmedSerial) {
        issues.push({
          id: `slot-serial-${slot.id}`,
          severity: "warning",
          title: `${slot.code} is missing a serial channel`,
          detail: "Serial channel mapping is required to reconcile machine telemetry against stock configuration.",
          slotCode: slot.code,
        });
      } else if (serialOwners.has(trimmedSerial)) {
        issues.push({
          id: `slot-duplicate-serial-${slot.id}`,
          severity: "critical",
          title: `${slot.code} duplicates serial channel ${trimmedSerial}`,
          detail: `Serial channel ${trimmedSerial} is already assigned to ${serialOwners.get(trimmedSerial)}.`,
          slotCode: slot.code,
        });
      } else {
        serialOwners.set(trimmedSerial, slot.code);
      }

      if (slot.actualSku.trim() && trimmedSku && slot.actualSku.trim().toLowerCase() !== trimmedSku.toLowerCase()) {
        issues.push({
          id: `slot-mismatch-${slot.id}`,
          severity: "critical",
          title: `${slot.code} mismatches stocked inventory`,
          detail: `Expected ${trimmedSku}, but the latest stocked SKU is ${slot.actualSku}.`,
          slotCode: slot.code,
        });
      }
    });
  });

  return issues;
}

export function computeSummaryMetrics(rows: MachineConfigRow[]) {
  const slots = rows.flatMap((row) => row.slots);
  const slotCount = slots.length;
  const configuredCount = slots.filter((slot) => slot.status === "configured").length;
  const mismatchCount = slots.filter((slot) => slot.status === "mismatch").length;
  const serialMappedCount = slots.filter((slot) => slot.serialChannel.trim()).length;
  const serialCoverage = slotCount ? Math.round((serialMappedCount / slotCount) * 100) : 0;

  return {
    slotCount,
    configuredCount,
    mismatchCount,
    serialCoverage,
  };
}

export function deriveMachineStatus(
  rows: MachineConfigRow[],
  issues: ValidationIssue[],
  isDirty: boolean,
): MachineConfigStatus {
  const metrics = computeSummaryMetrics(rows);

  if (metrics.mismatchCount > 0 || issues.some((issue) => issue.severity === "critical")) {
    return "Mismatch";
  }

  if (isDirty) {
    return "Draft";
  }

  if (issues.length > 0) {
    return "Needs Review";
  }

  return "Healthy";
}

export function buildMachineSummary(
  metadata: MachineMetadata,
  rows: MachineConfigRow[],
  publishedRows: MachineConfigRow[],
  issues: ValidationIssue[],
  publishedAt: string,
  draftUpdatedAt: string,
): MachineConfigSummary {
  const metrics = computeSummaryMetrics(rows);
  const isDirty = JSON.stringify(rows) !== JSON.stringify(publishedRows);

  return {
    id: metadata.id,
    name: metadata.name,
    organization: metadata.organization,
    location: metadata.location,
    model: metadata.model,
    status: deriveMachineStatus(rows, issues, isDirty),
    lastPublishedAt: publishedAt,
    draftUpdatedAt,
    slotCount: metrics.slotCount,
    configuredCount: metrics.configuredCount,
    mismatchCount: metrics.mismatchCount,
    serialCoverage: metrics.serialCoverage,
    note: metadata.note,
  };
}

export function createEmptySlot(rowId: string): MachineConfigSlot {
  return {
    id: createClientId("slot"),
    rowId,
    code: "",
    sku: "",
    itemName: "",
    capacity: 0,
    parLevel: 0,
    serialChannel: "",
    actualSku: "",
    actualQuantity: 0,
    status: "empty",
    note: "",
  };
}

export function createEmptyRow() {
  const rowId = createClientId("row");

  return {
    id: rowId,
    label: "",
    slots: [createEmptySlot(rowId)],
  };
}

export function updateSlot(rows: MachineConfigRow[], slotId: string, patch: Partial<MachineConfigSlot>) {
  return normalizeRows(
    rows.map((row) => ({
      ...row,
      slots: row.slots.map((slot) => (slot.id === slotId ? { ...slot, ...patch } : slot)),
    })),
  );
}

export function addRow(rows: MachineConfigRow[]) {
  return normalizeRows([...rows, createEmptyRow()]);
}

export function removeRow(rows: MachineConfigRow[], rowId: string) {
  if (rows.length <= 1) {
    return rows;
  }

  return normalizeRows(rows.filter((row) => row.id !== rowId));
}

export function addSlot(rows: MachineConfigRow[], rowId: string) {
  return normalizeRows(
    rows.map((row) =>
      row.id === rowId
        ? {
            ...row,
            slots: [...row.slots, createEmptySlot(row.id)],
          }
        : row,
    ),
  );
}

export function removeSlot(rows: MachineConfigRow[], rowId: string, slotId: string) {
  return normalizeRows(
    rows.map((row) => {
      if (row.id !== rowId) {
        return row;
      }

      if (row.slots.length <= 1) {
        return row;
      }

      return {
        ...row,
        slots: row.slots.filter((slot) => slot.id !== slotId),
      };
    }),
  );
}

export function swapSlots(rows: MachineConfigRow[], sourceId: string, targetId: string) {
  let sourceSlot: MachineConfigSlot | null = null;
  let targetSlot: MachineConfigSlot | null = null;

  rows.forEach((row) => {
    row.slots.forEach((slot) => {
      if (slot.id === sourceId) {
        sourceSlot = slot;
      }

      if (slot.id === targetId) {
        targetSlot = slot;
      }
    });
  });

  if (!sourceSlot || !targetSlot || sourceId === targetId) {
    return rows;
  }

  return normalizeRows(
    rows.map((row) => ({
      ...row,
      slots: row.slots.map((slot) => {
        if (slot.id === sourceId) {
          return { ...slot, ...swapSlotPayload(slot, targetSlot as MachineConfigSlot) };
        }

        if (slot.id === targetId) {
          return { ...slot, ...swapSlotPayload(slot, sourceSlot as MachineConfigSlot) };
        }

        return slot;
      }),
    })),
  );
}
