"use client";

import { GripVertical, Minus, Plus } from "lucide-react";
import { ParityCard } from "@/components/parity/parity-card";
import type { MachineConfigRow } from "@/features/machine-config/lib/types";

type VendingLayoutEditorProps = {
  rows: MachineConfigRow[];
  selectedSlotId: string;
  onSelectSlot: (slotId: string) => void;
  onAddRow: () => void;
  onRemoveRow: (rowId: string) => void;
  onAddSlot: (rowId: string) => void;
  onRemoveSlot: (rowId: string, slotId: string) => void;
  onSwapSlots: (sourceId: string, targetId: string) => void;
};

export function VendingLayoutEditor({
  rows,
  selectedSlotId,
  onSelectSlot,
  onAddRow,
  onRemoveRow,
  onAddSlot,
  onRemoveSlot,
  onSwapSlots,
}: VendingLayoutEditorProps) {
  return (
    <ParityCard className="machine-layout-shell">
      <div className="machine-layout-shell__header">
        <div>
          <div className="parity-section-header__title">VISUAL MACHINE</div>
          <div className="parity-section-header__subtitle">IRREGULAR SHELVES AND SLOT MAP</div>
        </div>
        <button className="machine-layout-shell__add-row" type="button" onClick={onAddRow}>
          <Plus size={16} />
          <span>Add shelf</span>
        </button>
      </div>

      <div className="machine-layout-frame">
        <div className="machine-layout-glass" />
        <div className="machine-layout-shelves">
          {rows.map((row) => (
            <section key={row.id} className="machine-shelf">
              <div className="machine-shelf__header">
                <div>
                  <div className="machine-shelf__label">{row.label}</div>
                  <div className="machine-shelf__meta">{row.slots.length} configured positions</div>
                </div>
                <div className="machine-shelf__actions">
                  <button className="machine-shelf__action" type="button" onClick={() => onAddSlot(row.id)} aria-label="Add slot">
                    <Plus size={16} />
                  </button>
                  <button
                    className="machine-shelf__action"
                    type="button"
                    onClick={() => onRemoveRow(row.id)}
                    aria-label="Remove shelf"
                  >
                    <Minus size={16} />
                  </button>
                </div>
              </div>

              <div className="machine-shelf__slots">
                {row.slots.map((slot) => (
                  <article
                    key={slot.id}
                    className="machine-slot"
                    draggable
                    data-active={slot.id === selectedSlotId}
                    data-status={slot.status}
                    onClick={() => onSelectSlot(slot.id)}
                    onDragStart={(event) => {
                      event.dataTransfer.setData("text/plain", slot.id);
                      event.dataTransfer.effectAllowed = "move";
                    }}
                    onDragOver={(event) => {
                      event.preventDefault();
                      event.dataTransfer.dropEffect = "move";
                    }}
                    onDrop={(event) => {
                      event.preventDefault();
                      const sourceId = event.dataTransfer.getData("text/plain");
                      onSwapSlots(sourceId, slot.id);
                    }}
                  >
                    <div className="machine-slot__drag">
                      <GripVertical size={14} />
                    </div>
                    <div className="machine-slot__code">{slot.code}</div>
                    <div className="machine-slot__sku">{slot.sku || "UNASSIGNED"}</div>
                    <div className="machine-slot__name">{slot.itemName || "Tap to configure"}</div>
                    <div className="machine-slot__footer">
                      <span>{slot.serialChannel || "NO SERIAL"}</span>
                      <button
                        className="machine-slot__remove"
                        type="button"
                        onClick={(event) => {
                          event.stopPropagation();
                          onRemoveSlot(row.id, slot.id);
                        }}
                        aria-label="Remove slot"
                      >
                        <Minus size={14} />
                      </button>
                    </div>
                  </article>
                ))}
              </div>
            </section>
          ))}
        </div>
      </div>
    </ParityCard>
  );
}
