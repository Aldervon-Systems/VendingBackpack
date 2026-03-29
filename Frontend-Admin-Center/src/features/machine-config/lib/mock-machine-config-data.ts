import type { MachineConfigRow, MachineMetadata, PublishRecord } from "@/features/machine-config/lib/types";
import { normalizeRows } from "@/features/machine-config/lib/machine-config-utils";

export type MachineConfigRecord = {
  metadata: MachineMetadata;
  publishedVersion: string;
  publishedAt: string;
  draftUpdatedAt: string;
  publishedRows: MachineConfigRow[];
  draftRows: MachineConfigRow[];
  history: PublishRecord[];
};

function createSlot(
  id: string,
  sku: string,
  itemName: string,
  capacity: number,
  parLevel: number,
  serialChannel: string,
  actualSku: string,
  actualQuantity: number,
  note = "",
) {
  return {
    id,
    rowId: "",
    code: "",
    sku,
    itemName,
    capacity,
    parLevel,
    serialChannel,
    actualSku,
    actualQuantity,
    status: "configured" as const,
    note,
  };
}

function createRow(id: string, label: string, slots: ReturnType<typeof createSlot>[]) {
  return {
    id,
    label,
    slots,
  };
}

const northPierPublished = normalizeRows([
  createRow("bos-row-1", "Shelf 1", [
    createSlot("bos-slot-1", "SPRK_WTR", "Sparkling Water", 10, 8, "A-01", "SPRK_WTR", 8),
    createSlot("bos-slot-2", "CLD_BRW", "Cold Brew", 8, 6, "A-02", "CLD_BRW", 5),
    createSlot("bos-slot-3", "NTRL_BAR", "Granola Bar", 12, 10, "A-03", "NTRL_BAR", 9),
    createSlot("bos-slot-4", "TRAIL_MIX", "Trail Mix", 12, 9, "A-04", "TRAIL_MIX", 10),
  ]),
  createRow("bos-row-2", "Shelf 2", [
    createSlot("bos-slot-5", "SODA_ZERO", "Soda Zero", 9, 7, "B-01", "SODA_ZERO", 6),
    createSlot("bos-slot-6", "ICE_TEA", "Iced Tea", 9, 7, "B-02", "ICE_TEA", 4),
    createSlot("bos-slot-7", "PROTEIN", "Protein Bar", 10, 8, "B-03", "PROTEIN", 6),
  ]),
  createRow("bos-row-3", "Shelf 3", [
    createSlot("bos-slot-8", "CHPS_SEA", "Sea Salt Chips", 8, 6, "C-01", "CHPS_SEA", 5),
    createSlot("bos-slot-9", "CHOC_BITE", "Chocolate Bites", 10, 7, "C-02", "CHOC_BITE", 6),
    createSlot("bos-slot-10", "NUTS_MIX", "Mixed Nuts", 8, 6, "C-03", "NUTS_MIX", 7),
    createSlot("bos-slot-11", "GUM_MINT", "Mint Gum", 12, 9, "C-04", "GUM_MINT", 8),
    createSlot("bos-slot-12", "COOKIE", "Oat Cookie", 8, 6, "C-05", "COOKIE", 4),
  ]),
]);

const northPierDraft = normalizeRows([
  createRow("bos-row-1", "Shelf 1", [
    createSlot("bos-slot-1", "SPRK_WTR", "Sparkling Water", 10, 8, "A-01", "SPRK_WTR", 8),
    createSlot("bos-slot-2", "CLD_BRW", "Cold Brew", 8, 6, "A-02", "CLD_BRW", 5),
    createSlot("bos-slot-3", "NTRL_BAR", "Granola Bar", 12, 10, "A-03", "NTRL_BAR", 9),
    createSlot("bos-slot-4", "TRAIL_MIX", "Trail Mix", 12, 9, "A-04", "TRAIL_MIX", 10),
  ]),
  createRow("bos-row-2", "Shelf 2", [
    createSlot("bos-slot-5", "SODA_ZERO", "Soda Zero", 9, 7, "B-01", "SODA_ZERO", 6),
    createSlot("bos-slot-6", "ICE_TEA", "Iced Tea", 9, 7, "B-02", "ICE_TEA", 4),
    createSlot("bos-slot-7", "PROTEIN", "Protein Bar", 10, 8, "B-02", "CHOC_SHAKE", 6, "Serial channel reused during rebuild."),
  ]),
  createRow("bos-row-3", "Shelf 3", [
    createSlot("bos-slot-8", "CHPS_SEA", "Sea Salt Chips", 8, 6, "C-01", "CHPS_SEA", 5),
    createSlot("bos-slot-9", "", "", 10, 7, "C-02", "", 0, "Awaiting final SKU confirmation from operations."),
    createSlot("bos-slot-10", "NUTS_MIX", "Mixed Nuts", 8, 6, "C-03", "NUTS_MIX", 7),
    createSlot("bos-slot-11", "GUM_MINT", "Mint Gum", 12, 9, "C-04", "GUM_MINT", 8),
    createSlot("bos-slot-12", "COOKIE", "Oat Cookie", 8, 6, "", "COOKIE", 4, "Serial channel not yet assigned."),
  ]),
]);

const summitPublished = normalizeRows([
  createRow("sum-row-1", "Shelf 1", [
    createSlot("sum-slot-1", "WATER", "Still Water", 12, 10, "A-11", "WATER", 10),
    createSlot("sum-slot-2", "ELECTRO", "Electrolyte Drink", 10, 8, "A-12", "ELECTRO", 6),
    createSlot("sum-slot-3", "PRO_BAR", "Protein Bar", 8, 6, "A-13", "PRO_BAR", 5),
  ]),
  createRow("sum-row-2", "Shelf 2", [
    createSlot("sum-slot-4", "NUT_PACK", "Nut Pack", 8, 6, "B-11", "NUT_PACK", 6),
    createSlot("sum-slot-5", "FRUIT_CUP", "Fruit Cup", 8, 6, "B-12", "FRUIT_CUP", 5),
  ]),
]);

const summitDraft = normalizeRows([
  createRow("sum-row-1", "Shelf 1", [
    createSlot("sum-slot-1", "WATER", "Still Water", 12, 10, "A-11", "WATER", 10),
    createSlot("sum-slot-2", "ELECTRO", "Electrolyte Drink", 10, 8, "A-12", "ELECTRO", 6),
    createSlot("sum-slot-3", "PRO_BAR", "Protein Bar", 8, 6, "A-13", "PRO_BAR", 5),
  ]),
  createRow("sum-row-2", "Shelf 2", [
    createSlot("sum-slot-4", "NUT_PACK", "Nut Pack", 8, 6, "B-11", "NUT_PACK", 6),
    createSlot("sum-slot-5", "FRUIT_CUP", "Fruit Cup", 8, 6, "B-12", "FRUIT_CUP", 5),
  ]),
]);

const aldervonPublished = normalizeRows([
  createRow("ald-row-1", "Shelf 1", [
    createSlot("ald-slot-1", "ESPRESSO", "Espresso Can", 8, 6, "A-21", "ESPRESSO", 4),
    createSlot("ald-slot-2", "MATCHA", "Matcha Latte", 8, 6, "A-22", "MATCHA", 4),
    createSlot("ald-slot-3", "CHIPS", "Kettle Chips", 10, 8, "A-23", "CHIPS", 7),
    createSlot("ald-slot-4", "COOKIE", "Oat Cookie", 10, 8, "A-24", "COOKIE", 7),
    createSlot("ald-slot-5", "GUM", "Mint Gum", 16, 10, "A-25", "GUM", 10),
  ]),
  createRow("ald-row-2", "Shelf 2", [
    createSlot("ald-slot-6", "ICED_COF", "Iced Coffee", 8, 6, "B-21", "ICED_COF", 5),
    createSlot("ald-slot-7", "TEA_LEMON", "Lemon Tea", 8, 6, "B-22", "TEA_LEMON", 5),
    createSlot("ald-slot-8", "ALMOND", "Roasted Almonds", 8, 6, "B-23", "ALMOND", 5),
    createSlot("ald-slot-9", "JERKY", "Turkey Jerky", 8, 6, "B-24", "JERKY", 5),
  ]),
]);

export const MACHINE_CONFIG_RECORDS: MachineConfigRecord[] = [
  {
    metadata: {
      id: "machine-bos-014",
      name: "UNIT-BOS-014",
      organization: "North Pier Foods",
      location: "Harbor District",
      model: "Crane BevMax 4",
      serialProvider: "DEX / Serial Bus",
      hardwareProfile: "4 shelves / mixed-width spirals",
      lastAuditBy: "Marcus Reed",
      lastAuditAt: "Mar 28, 2026 09:48 ET",
      note: "Boston harbor machine with mixed snack and beverage spirals.",
    },
    publishedVersion: "v3.1",
    publishedAt: "Mar 26, 2026 15:10 ET",
    draftUpdatedAt: "Mar 28, 2026 10:04 ET",
    publishedRows: northPierPublished,
    draftRows: northPierDraft,
    history: [
      {
        id: "hist-bos-1",
        action: "Published",
        actor: "Ivy Chen",
        timestamp: "Mar 26, 2026 15:10 ET",
        detail: "Published harbor district spring reset after coil replacement.",
      },
      {
        id: "hist-bos-2",
        action: "Draft Saved",
        actor: "Marcus Reed",
        timestamp: "Mar 28, 2026 10:04 ET",
        detail: "Staged slot corrections for serial reconciliation before lunch recovery.",
      },
    ],
  },
  {
    metadata: {
      id: "machine-sum-103",
      name: "UNIT-SUM-103",
      organization: "Summit Health",
      location: "Clinical Tower Lobby",
      model: "AMS Sensit 3",
      serialProvider: "Telemetry Gateway",
      hardwareProfile: "2 shelves / reduced snack footprint",
      lastAuditBy: "Nina Patel",
      lastAuditAt: "Mar 27, 2026 16:20 ET",
      note: "Clinical deployment with compliance-approved healthy assortment.",
    },
    publishedVersion: "v1.8",
    publishedAt: "Mar 27, 2026 16:20 ET",
    draftUpdatedAt: "Mar 27, 2026 16:20 ET",
    publishedRows: summitPublished,
    draftRows: summitDraft,
    history: [
      {
        id: "hist-sum-1",
        action: "Reviewed",
        actor: "Nina Patel",
        timestamp: "Mar 27, 2026 16:20 ET",
        detail: "Compliance review completed. No mismatches detected.",
      },
    ],
  },
  {
    metadata: {
      id: "machine-ald-219",
      name: "UNIT-BHX-019",
      organization: "Aldervon Systems",
      location: "Assembly Annex",
      model: "Crane Merchant 6",
      serialProvider: "DEX / Serial Bus",
      hardwareProfile: "2 shelves / wide beverage front",
      lastAuditBy: "Morgan Sloane",
      lastAuditAt: "Mar 25, 2026 13:02 ET",
      note: "Internal reference machine used as the clean publish baseline.",
    },
    publishedVersion: "v5.0",
    publishedAt: "Mar 25, 2026 13:02 ET",
    draftUpdatedAt: "Mar 25, 2026 13:02 ET",
    publishedRows: aldervonPublished,
    draftRows: aldervonPublished,
    history: [
      {
        id: "hist-ald-1",
        action: "Imported",
        actor: "Morgan Sloane",
        timestamp: "Mar 24, 2026 09:05 ET",
        detail: "Imported floor-audit spreadsheet into the new machine shell baseline.",
      },
      {
        id: "hist-ald-2",
        action: "Published",
        actor: "Morgan Sloane",
        timestamp: "Mar 25, 2026 13:02 ET",
        detail: "Published validated Aldervon baseline for future machine templates.",
      },
    ],
  },
];
