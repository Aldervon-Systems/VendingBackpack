"use client";

import dynamic from "next/dynamic";
import { Sparkles } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { ParityCard } from "@/components/parity/parity-card";
import { apiRequest } from "@/lib/api/api-client";
import { useAuth } from "@/providers/auth-provider";
import type { RouteMachine } from "@/features/routes/components/route-map-canvas";

const RouteMapCanvas = dynamic(
  () => import("@/features/routes/components/route-map-canvas").then((module) => module.RouteMapCanvas),
  { ssr: false },
);

const fallbackEmployees = [
  { id: "none", name: "NONE" },
  { id: "all", name: "ALL NODES" },
  { id: "emp-07", name: "Amanda Jones" },
  { id: "emp-11", name: "Luis Vega" },
  { id: "emp-13", name: "Maya Chen" },
];

const fallbackMachines: RouteMachine[] = [
  { id: "M-101", name: "Union Station", lat: 42.3524, lng: -71.0552, assignedTo: "Amanda Jones", zone: "Downtown Loop", serviceWindow: "11:30 AM" },
  { id: "M-114", name: "City Hall", lat: 42.3604, lng: -71.058, assignedTo: "Maya Chen", zone: "Civic Center", serviceWindow: "1:15 PM" },
  { id: "M-120", name: "North Campus", lat: 42.3651, lng: -71.104, assignedTo: "Luis Vega", zone: "Cambridge North", serviceWindow: "3:45 PM" },
  { id: "M-131", name: "South Station", lat: 42.3522, lng: -71.0554, assignedTo: "Amanda Jones", zone: "Harbor Edge", serviceWindow: "4:30 PM" },
];

function normalizeLocations(
  backendLocations: Array<{ id: string; name: string; lat: number; lng: number; location?: string }>,
  assignmentMap: Map<string, string>,
): RouteMachine[] {
  if (!backendLocations.length) {
    return fallbackMachines;
  }

  const fallbackById = new Map(fallbackMachines.map((machine) => [machine.id, machine]));

  return backendLocations.map((location, index) => {
    const fallback = fallbackById.get(location.id);
    return {
      id: location.id,
      name: location.name,
      lat: location.lat,
      lng: location.lng,
      zone: fallback?.zone ?? location.location ?? "Assigned node",
      serviceWindow: fallback?.serviceWindow ?? `${11 + index}:30 AM`,
      assignedTo: assignmentMap.get(location.id) ?? fallback?.assignedTo ?? "Unassigned",
    };
  });
}

export function RoutesScreen() {
  const { session, effectiveRole } = useAuth();
  const isManager = effectiveRole === "manager";
  const [filter, setFilter] = useState("none");
  const [employees, setEmployees] = useState(fallbackEmployees);
  const [assignments, setAssignments] = useState<RouteMachine[]>(fallbackMachines);
  const [employeeRouteStops, setEmployeeRouteStops] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let active = true;

    async function loadRoutes() {
      setIsLoading(true);

      try {
        const [routesResponse, employeesResponse, currentRouteResponse] = await Promise.all([
          apiRequest<{ locations?: Array<{ id: string; name: string; lat: number; lng: number; location?: string }>; paths?: unknown[] }>("/routes"),
          apiRequest<Array<{ id: string; name: string }>>("/employees"),
          !isManager && session?.user.id ? apiRequest<{ stops?: Array<{ id: string }> }>(`/employees/${session.user.id}/routes`) : Promise.resolve({ stops: [] }),
        ]);

        const allRoutes = await apiRequest<Array<{ employee_id?: string; employeeId?: string; employee_name?: string; stops?: Array<{ id: string }> }>>("/employees/routes");
        const employeeLookup = new Map((employeesResponse ?? []).map((employee) => [employee.id, employee.name]));

        const assignmentMap = new Map<string, string>();
        allRoutes.forEach((route) => {
          const routeEmployeeId = route.employee_id ?? route.employeeId ?? "";
          const employeeName = route.employee_name ?? employeeLookup.get(routeEmployeeId) ?? "Assigned";
          route.stops?.forEach((stop) => {
            assignmentMap.set(stop.id, employeeName);
          });
        });

        const backendLocations = normalizeLocations(routesResponse.locations ?? [], assignmentMap);
        const nextEmployees = employeesResponse?.length
          ? [
              { id: "none", name: "NONE" },
              { id: "all", name: "ALL NODES" },
              ...employeesResponse.map((employee) => ({ id: employee.id, name: employee.name })),
            ]
          : fallbackEmployees;

        if (active) {
          setAssignments(backendLocations.length ? backendLocations : fallbackMachines);
          setEmployees(nextEmployees);
          setEmployeeRouteStops(currentRouteResponse.stops?.map((stop) => stop.id) ?? []);
        }
      } catch {
        if (active) {
          setAssignments(fallbackMachines);
          setEmployees(fallbackEmployees);
          setEmployeeRouteStops([]);
        }
      } finally {
        if (active) {
          setIsLoading(false);
        }
      }
    }

    void loadRoutes();

    return () => {
      active = false;
    };
  }, [isManager, session?.user.id]);

  const visibleLocations = useMemo(() => {
    if (!isManager) {
      if (employeeRouteStops.length) {
        return assignments.filter((machine) => employeeRouteStops.includes(machine.id));
      }

      return assignments.filter((machine) => machine.assignedTo === session?.user.name);
    }

    if (filter === "none" || filter === "all") {
      return assignments;
    }

    const selectedEmployee = employees.find((employee) => employee.id === filter)?.name;
    return assignments.filter((machine) => machine.assignedTo === selectedEmployee);
  }, [assignments, employeeRouteStops, employees, filter, isManager, session?.user.name]);

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

  async function autogenerateRoutes() {
    setIsLoading(true);

    try {
      await apiRequest("/routes/autogenerate", { method: "POST" });
      const nextLocations = await apiRequest<{ locations?: Array<{ id: string; name: string; lat: number; lng: number; location?: string }> }>("/routes");
      setAssignments(normalizeLocations(nextLocations.locations ?? [], new Map()));
    } catch {
      setAssignments(fallbackMachines);
    } finally {
      setIsLoading(false);
    }
  }

  async function assignMachine(machineId: string, employeeId: string) {
    try {
      await apiRequest(`/employees/${employeeId}/routes/assign`, {
        method: "POST",
        body: { machine_id: machineId },
      });

      setAssignments((currentAssignments) =>
        currentAssignments.map((machine) =>
          machine.id === machineId ? { ...machine, assignedTo: employees.find((employee) => employee.id === employeeId)?.name ?? machine.assignedTo } : machine,
        ),
      );
    } catch {
      // Keep local state stable if backend rejects the request.
    }
  }

  return (
    <div className="routes-screen">
      <div className="routes-map-shell" data-loading={isLoading}>
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
              <button className="routes-filter-pod__sparkle" type="button" aria-label="Autogenerate routes" onClick={() => void autogenerateRoutes()}>
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
                  onClick={() => {
                    void assignMachine(selectedLocation.id, employee.id);
                  }}
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
