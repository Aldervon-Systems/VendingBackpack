"use client";

import { CalendarPlus2, PackagePlus, ScanLine, Truck } from "lucide-react";
import { useEffect, useState } from "react";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityCard } from "@/components/parity/parity-card";
import { ParityField } from "@/components/parity/parity-field";
import { ParityModalFrame } from "@/components/parity/parity-modal-frame";
import { ParityOverlay } from "@/components/parity/parity-overlay";
import { apiRequest } from "@/lib/api/api-client";
import { useAuth } from "@/providers/auth-provider";

type InventoryRow = {
  sku: string;
  name: string;
  qty: number;
  barcode: string;
};

type ShipmentRow = {
  id: string;
  description: string;
  amount: number;
  date: string;
  status: string;
};

const fallbackShipments: ShipmentRow[] = [
  { id: "ship-01", description: "Downtown restock wave", amount: 120, date: "03/19/2026", status: "scheduled" },
  { id: "ship-02", description: "Cold beverage intake", amount: 48, date: "03/20/2026", status: "scheduled" },
];

export function WarehouseScreen() {
  const { effectiveRole } = useAuth();
  const isManager = effectiveRole === "manager";
  const [inventoryRows, setInventoryRows] = useState<InventoryRow[]>([]);
  const [shipments, setShipments] = useState<ShipmentRow[]>(fallbackShipments);
  const [shipmentsOpen, setShipmentsOpen] = useState(false);
  const [scheduleOpen, setScheduleOpen] = useState(false);
  const [scannerOpen, setScannerOpen] = useState(false);
  const [description, setDescription] = useState("");
  const [units, setUnits] = useState("24");
  const [barcode, setBarcode] = useState("");
  const [itemName, setItemName] = useState("");
  const [quantity, setQuantity] = useState("1");
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);

  async function loadWarehouse() {
    setIsLoading(true);
    setError("");

    try {
      const [warehouseRows, shipmentRows] = await Promise.all([
        apiRequest<InventoryRow[]>("/warehouse"),
        apiRequest<ShipmentRow[]>("/warehouse/shipments"),
      ]);

      setInventoryRows(Array.isArray(warehouseRows) ? warehouseRows : []);
      setShipments(Array.isArray(shipmentRows) && shipmentRows.length ? shipmentRows : fallbackShipments);
    } catch {
      setInventoryRows([]);
      setShipments(fallbackShipments);
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    void loadWarehouse();
  }, []);

  async function handleCommitScan() {
    setIsLoading(true);
    setError("");

    try {
      let resolvedName = itemName.trim();

      if (barcode.trim()) {
        const lookup = await apiRequest<{ sku?: string; name?: string; qty?: number }>(`/items/${barcode.trim()}`);
        if (!resolvedName && lookup?.name) {
          resolvedName = lookup.name;
          setItemName(lookup.name);
        }
      }

      if (!barcode.trim()) {
        throw new Error("Barcode is required");
      }

      if (!resolvedName) {
        throw new Error("Item name is required");
      }

      const nextQty = Number.parseInt(quantity, 10);
      if (!Number.isFinite(nextQty) || nextQty <= 0) {
        throw new Error("Quantity must be greater than 0");
      }

      await apiRequest("/warehouse/add_stock", {
        method: "POST",
        body: {
          barcode: barcode.trim(),
          name: resolvedName,
          quantity: nextQty,
        },
      });

      setScannerOpen(false);
      setBarcode("");
      setItemName("");
      setQuantity("1");
      await loadWarehouse();
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : "Failed to add stock");
    } finally {
      setIsLoading(false);
    }
  }

  async function handleScheduleShipment() {
    setIsLoading(true);
    setError("");

    try {
      const amount = Number.parseInt(units, 10);
      if (!description.trim()) {
        throw new Error("Description is required");
      }

      if (!Number.isFinite(amount) || amount <= 0) {
        throw new Error("Units must be greater than 0");
      }

      await apiRequest("/warehouse/shipments", {
        method: "POST",
        body: {
          description: description.trim(),
          amount,
          date: new Date().toISOString(),
          status: "scheduled",
        },
      });

      setScheduleOpen(false);
      setDescription("");
      setUnits("24");
      await loadWarehouse();
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : "Failed to schedule shipment");
    } finally {
      setIsLoading(false);
    }
  }

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

      {inventoryRows.length ? (
        <div className="warehouse-list">
          {inventoryRows.map((row) => (
            <ParityCard key={`${row.sku}-${row.barcode}`} className="warehouse-list__row">
              <div>
                <div className="warehouse-list__name">{row.name}</div>
                <div className="warehouse-list__meta">
                  <span>{row.sku}</span>
                  <span>{row.barcode || "NO BARCODE"}</span>
                </div>
              </div>
              <div className="warehouse-list__qty">
                <strong>{row.qty}</strong>
                <span>UNITS</span>
              </div>
            </ParityCard>
          ))}
        </div>
      ) : (
        <div className="warehouse-empty-state">NO INVENTORY DETECTED</div>
      )}

      <button className="warehouse-fab" type="button" aria-label="Open scanner" onClick={() => setScannerOpen(true)}>
        <ScanLine size={28} />
      </button>

      {shipmentsOpen ? (
        <ParityOverlay align="sheet" onBackdropClick={() => setShipmentsOpen(false)}>
          <div className="sheet-panel">
            <div className="sheet-panel__header">
              <div>
                <div className="parity-section-header__title">LOGISTICS / SHIPMENTS</div>
                <div className="parity-section-header__subtitle">LIVE SUMMARY</div>
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
                <ParityButton onClick={() => void handleScheduleShipment()}>SCHEDULE</ParityButton>
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
                <ParityButton onClick={() => void handleCommitScan()}>
                  <PackagePlus size={16} />
                  <span>COMMIT</span>
                </ParityButton>
              </div>
            </div>
          </ParityModalFrame>
        </ParityOverlay>
      ) : null}

      {error ? <div className="form-error form-error--floating">{error.toUpperCase()}</div> : null}
      {isLoading ? <div className="warehouse-loading">SYNCING WAREHOUSE DATA</div> : null}
    </div>
  );
}
