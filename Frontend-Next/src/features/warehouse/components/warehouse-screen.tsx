"use client";

import { CalendarPlus2, PackagePlus, ScanLine, Truck } from "lucide-react";
import { useState } from "react";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityField } from "@/components/parity/parity-field";
import { ParityModalFrame } from "@/components/parity/parity-modal-frame";
import { ParityOverlay } from "@/components/parity/parity-overlay";
import { useAuth } from "@/providers/auth-provider";

const shipments = [
  { id: "ship-01", description: "Downtown restock wave", amount: 120, date: "03/19/2026" },
  { id: "ship-02", description: "Cold beverage intake", amount: 48, date: "03/20/2026" },
];

export function WarehouseScreen() {
  const { effectiveRole } = useAuth();
  const isManager = effectiveRole === "manager";
  const [shipmentsOpen, setShipmentsOpen] = useState(false);
  const [scheduleOpen, setScheduleOpen] = useState(false);
  const [scannerOpen, setScannerOpen] = useState(false);
  const [description, setDescription] = useState("");
  const [units, setUnits] = useState("24");
  const [barcode, setBarcode] = useState("");
  const [itemName, setItemName] = useState("");
  const [quantity, setQuantity] = useState("1");

  return (
    <div className="warehouse-screen">
      <div className="warehouse-toolbar">
        <div className="warehouse-toolbar__title">WAREHOUSE / STOCK</div>
        {isManager ? (
          <button className="warehouse-toolbar__icon" type="button" onClick={() => setShipmentsOpen(true)} aria-label="Open shipments">
            <Truck size={22} />
          </button>
        ) : null}
      </div>

      <div className="warehouse-empty-state">NO INVENTORY DETECTED</div>

      <button className="warehouse-fab" type="button" aria-label="Open scanner" onClick={() => setScannerOpen(true)}>
        <ScanLine size={28} />
      </button>

      {shipmentsOpen ? (
        <ParityOverlay align="sheet" onBackdropClick={() => setShipmentsOpen(false)}>
          <div className="sheet-panel">
            <div className="sheet-panel__header">
              <div>
                <div className="parity-section-header__title">LOGISTICS / SHIPMENTS</div>
                <div className="parity-section-header__subtitle">MOCK SUMMARY</div>
              </div>
              <button className="sheet-panel__icon" type="button" onClick={() => setScheduleOpen(true)} aria-label="Schedule shipment">
                <CalendarPlus2 size={18} />
              </button>
            </div>
            <div className="sheet-panel__list">
              {shipments.map((shipment) => (
                <div key={shipment.id} className="sheet-panel__row">
                  <div>
                    <strong>{shipment.description.toUpperCase()}</strong>
                    <div>{shipment.date}</div>
                  </div>
                  <div className="sheet-panel__amount">
                    <strong>{shipment.amount}</strong>
                    <span>UNITS</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </ParityOverlay>
      ) : null}

      {scheduleOpen ? (
        <ParityOverlay onBackdropClick={() => setScheduleOpen(false)}>
          <ParityModalFrame title="SCHEDULE REFILL" onClose={() => setScheduleOpen(false)}>
            <div className="modal-form">
              <ParityField
                id="shipment-description"
                label="DESCRIPTION"
                value={description}
                onChange={(event) => setDescription(event.target.value)}
              />
              <ParityField
                id="shipment-units"
                label="UNIT COUNT"
                value={units}
                onChange={(event) => setUnits(event.target.value)}
                inputMode="numeric"
              />
              <div className="modal-actions">
                <ParityButton tone="ghost" onClick={() => setScheduleOpen(false)}>
                  CANCEL
                </ParityButton>
                <ParityButton onClick={() => setScheduleOpen(false)}>SCHEDULE</ParityButton>
              </div>
            </div>
          </ParityModalFrame>
        </ParityOverlay>
      ) : null}

      {scannerOpen ? (
        <ParityOverlay onBackdropClick={() => setScannerOpen(false)}>
          <ParityModalFrame title="REGISTER NEW SKU" subtitle="Mock scanner shell for mobile and desktop." onClose={() => setScannerOpen(false)}>
            <div className="modal-form">
              <ParityField
                id="barcode"
                label="BARCODE"
                value={barcode}
                onChange={(event) => setBarcode(event.target.value)}
              />
              <ParityField
                id="item-name"
                label="ITEM NAME"
                value={itemName}
                onChange={(event) => setItemName(event.target.value)}
              />
              <ParityField
                id="quantity"
                label="QUANTITY TO ADD"
                value={quantity}
                onChange={(event) => setQuantity(event.target.value)}
                inputMode="numeric"
              />
              <div className="modal-actions">
                <ParityButton tone="ghost" onClick={() => setScannerOpen(false)}>
                  CANCEL
                </ParityButton>
                <ParityButton onClick={() => setScannerOpen(false)}>
                  <PackagePlus size={16} />
                  <span>COMMIT</span>
                </ParityButton>
              </div>
            </div>
          </ParityModalFrame>
        </ParityOverlay>
      ) : null}
    </div>
  );
}
