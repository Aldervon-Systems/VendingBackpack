"use client";

import dynamic from "next/dynamic";
import { Sparkles } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { ParityButton } from "@/components/parity/parity-button";
import { ParityCard } from "@/components/parity/parity-card";
import { useAuth } from "@/providers/auth-provider";
import type { RouteMachine } from "@/features/routes/components/route-map-canvas";

const RouteMapCanvas = dynamic(
  () => import("@/features/routes/components/route-map-canvas").then((module) => module.RouteMapCanvas),
  { ssr: false },
);

const employees = [
  { id: "none", name: "NONE" },
  { id: "all", name: "ALL NODES" },
  { id: "emp-07", name: "Amanda Jones" },
  { id: "emp-11", name: "Luis Vega" },
  { id: "emp-13", name: "Maya Chen" },
];

const machineSeed: RouteMachine[] = [
  { id: "M-101", name: "Union Station", lat: 42.3524, lng: -71.0552, assignedTo: "Amanda Jones", zone: "Downtown Loop", serviceWindow: "11:30 AM" },
  { id: "M-114", name: "City Hall", lat: 42.3604, lng: -71.058, assignedTo: "Maya Chen", zone: "Civic Center", serviceWindow: "1:15 PM" },
  { id: "M-120", name: "North Campus", lat: 42.3651, lng: -71.104, assignedTo: "Luis Vega", zone: "Cambridge North", serviceWindow: "3:45 PM" },
  { id: "M-131", name: "South Station", lat: 42.3522, lng: -71.0554, assignedTo: "Amanda Jones", zone: "Harbor Edge", serviceWindow: "4:30 PM" },
];

export function RoutesScreen() {
  const { effectiveRole } = useAuth();
  const isManager = effectiveRole === "manager";
  const [filter, setFilter] = useState("none");
  const [assignments, setAssignments] = useState(machineSeed);
  const visibleLocations = useMemo(() => {
    if (!isManager) {
      return assignments.filter((machine) => machine.assignedTo === "Amanda Jones");
    }

    if (filter === "none" || filter === "all") {
      return assignments;
    }

    const selectedEmployee = employees.find((employee) => employee.id === filter)?.name;
    return assignments.filter((machine) => machine.assignedTo === selectedEmployee);
  }, [assignments, filter, isManager]);
  const [selectedId, setSelectedId] = useState<string | null>(visibleLocations[0]?.id ?? null);

  useEffect(() => {
    if (!visibleLocations.length) {
      setSelectedId(null);
      return;
    }

    if (!selectedId || !visibleLocations.some((location) => location.id === selectedId)) {
      setSelectedId(visibleLocations[0].id);
    }
  }, [selectedId, visibleLocations]);

  const selectedLocation = visibleLocations.find((location) => location.id === selectedId) ?? null;

  return (
    <div className="routes-screen">
      <div className="routes-map-shell">
        <RouteMapCanvas
          locations={visibleLocations}
          activeId={selectedId}
          onSelect={(location) => {
            setSelectedId(location.id);
          }}
        />

        <ParityCard className="routes-filter-pod">
          <div className="routes-filter-pod__label">FILTER //</div>
          {isManager ? (
            <>
              <select className="routes-filter-pod__select" value={filter} onChange={(event) => setFilter(event.target.value)}>
                {employees.map((employee) => (
                  <option key={employee.id} value={employee.id}>
                    {employee.name}
                  </option>
                ))}
              </select>
              <button className="routes-filter-pod__sparkle" type="button" aria-label="Autogenerate routes">
                <Sparkles size={16} />
              </button>
            </>
          ) : (
            <div className="routes-filter-pod__meta">MY ROUTE</div>
          )}
        </ParityCard>

        {isManager && selectedLocation ? (
          <div className="routes-sheet">
            <div className="routes-sheet__eyebrow">ASSIGNMENT / NODE {selectedLocation.id}</div>
            <div className="routes-sheet__title">SELECT OPERATIVE FOR {selectedLocation.name.toUpperCase()}</div>
            <div className="routes-sheet__list">
              {employees
                .filter((employee) => employee.id !== "none" && employee.id !== "all")
                .map((employee) => (
                  <button
                    key={employee.id}
                    className="routes-sheet__row"
                    type="button"
                    onClick={() =>
                      setAssignments((currentItems) =>
                        currentItems.map((machine) =>
                          machine.id === selectedLocation.id ? { ...machine, assignedTo: employee.name } : machine,
                        ),
                      )
                    }
                  >
                    <span>{employee.name}</span>
                    <strong>{employee.name === selectedLocation.assignedTo ? "ASSIGNED" : "SELECT"}</strong>
                  </button>
                ))}
            </div>
          </div>
        ) : (
          <div className="routes-sheet routes-sheet--employee">
            <div className="routes-sheet__eyebrow">ASSIGNED ROUTE</div>
            <div className="routes-sheet__title">TODAY&apos;S ACTIVE NODES</div>
            <div className="routes-sheet__list">
              {visibleLocations.map((location) => (
                <div key={location.id} className="routes-sheet__row routes-sheet__row--static">
                  <span>
                    {location.id} / {location.name}
                  </span>
                  <strong>{location.serviceWindow}</strong>
                </div>
              ))}
            </div>
            <div className="routes-sheet__footer-copy">Manager assignment controls stay hidden while employee context is active.</div>
          </div>
        )}
      </div>
    </div>
  );
}
