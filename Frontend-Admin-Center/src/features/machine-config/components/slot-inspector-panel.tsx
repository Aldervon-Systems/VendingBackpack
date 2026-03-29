"use client";

import { Package, ScanLine, Warehouse } from "lucide-react";
import { ParityCard } from "@/components/parity/parity-card";
import { ParityField } from "@/components/parity/parity-field";
import type { MachineConfigSlot } from "@/features/machine-config/lib/types";

type SlotInspectorPanelProps = {
  slot: MachineConfigSlot | null;
  onChange: (patch: Partial<MachineConfigSlot>) => void;
};

export function SlotInspectorPanel({ slot, onChange }: SlotInspectorPanelProps) {
  if (!slot) {
    return (
      <ParityCard className="slot-inspector slot-inspector--empty">
        <div className="slot-inspector__empty-title">Select a slot</div>
        <div className="slot-inspector__empty-copy">
          Pick any machine position to edit SKU binding, serial channel, capacity, and expected stocked quantity.
        </div>
      </ParityCard>
    );
  }

  return (
    <ParityCard className="slot-inspector">
      <div className="slot-inspector__header">
        <div>
          <div className="parity-section-header__title">SLOT INSPECTOR</div>
          <div className="parity-section-header__subtitle">{slot.code} / CURRENT DRAFT</div>
        </div>
      </div>

      <div className="slot-inspector__summary">
        <div className="slot-inspector__summary-item">
          <Package size={16} />
          <span>{slot.sku || "UNASSIGNED SKU"}</span>
        </div>
        <div className="slot-inspector__summary-item">
          <ScanLine size={16} />
          <span>{slot.serialChannel || "NO SERIAL CHANNEL"}</span>
        </div>
        <div className="slot-inspector__summary-item">
          <Warehouse size={16} />
          <span>{slot.actualSku || "NO STOCKED SKU"} / {slot.actualQuantity} units</span>
        </div>
      </div>

      <div className="slot-inspector__form">
        <ParityField id="slot-sku" label="EXPECTED SKU" value={slot.sku} onChange={(event) => onChange({ sku: event.target.value })} />
        <ParityField
          id="slot-name"
          label="DISPLAY NAME"
          value={slot.itemName}
          onChange={(event) => onChange({ itemName: event.target.value })}
        />
        <div className="admin-grid">
          <ParityField
            id="slot-capacity"
            label="CAPACITY"
            value={String(slot.capacity)}
            inputMode="numeric"
            onChange={(event) => onChange({ capacity: Number.parseInt(event.target.value || "0", 10) || 0 })}
          />
          <ParityField
            id="slot-par"
            label="PAR LEVEL"
            value={String(slot.parLevel)}
            inputMode="numeric"
            onChange={(event) => onChange({ parLevel: Number.parseInt(event.target.value || "0", 10) || 0 })}
          />
        </div>
        <ParityField
          id="slot-serial"
          label="SERIAL CHANNEL"
          value={slot.serialChannel}
          onChange={(event) => onChange({ serialChannel: event.target.value })}
          placeholder="A-01"
        />
        <div className="admin-grid">
          <ParityField
            id="slot-actual-sku"
            label="ACTUAL STOCKED SKU"
            value={slot.actualSku}
            onChange={(event) => onChange({ actualSku: event.target.value })}
          />
          <ParityField
            id="slot-actual-qty"
            label="ACTUAL QUANTITY"
            value={String(slot.actualQuantity)}
            inputMode="numeric"
            onChange={(event) => onChange({ actualQuantity: Number.parseInt(event.target.value || "0", 10) || 0 })}
          />
        </div>
        <ParityField
          as="textarea"
          id="slot-note"
          label="OPERATOR NOTE"
          value={slot.note}
          rows={5}
          onChange={(event) => onChange({ note: event.target.value })}
        />
      </div>
    </ParityCard>
  );
}
