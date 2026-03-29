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

const baseEmployees = [
  { id: "none", name: "NONE" },
  { id: "all", name: "ALL NODES" },
];

function buildEmployeeLookup(employees: Array<{ id: string; name: string }>) {
  return new Map(employees.map((employee) => [employee.id, employee.name]));
}

function buildEmployeeOptions(employees: Array<{ id: string; name: string }>) {
  return employees.length
    ? [...baseEmployees, ...employees.map((employee) => ({ id: employee.id, name: employee.name }))]
    : baseEmployees;
}

function buildAssignmentMap(
  routes: Array<{ employee_id?: string; employeeId?: string; employee_name?: string; stops?: Array<{ id: string }> }>,
  employeeLookup: Map<string, string>,
) {
  const assignmentMap = new Map<string, string>();

  routes.forEach((route) => {
    const routeEmployeeId = route.employee_id ?? route.employeeId ?? "";
    const employeeName = route.employee_name ?? employeeLookup.get(routeEmployeeId) ?? "Assigned";
    route.stops?.forEach((stop) => {
      assignmentMap.set(stop.id, employeeName);
    });
  });

  return assignmentMap;
}

function normalizeLocations(
  backendLocations: Array<{ id: string; name: string; lat: number; lng: number; location?: string }>,
  assignmentMap: Map<string, string>,
): RouteMachine[] {
  if (!backendLocations.length) {
    return [];
  }

  return backendLocations.map((location) => {
    return {
      id: location.id,
      name: location.name,
      lat: location.lat,
      lng: location.lng,
      zone: location.location ?? "Assigned node",
      serviceWindow: "Pending",
      assignedTo: assignmentMap.get(location.id) ?? "Unassigned",
    };
  });
}

export function RoutesScreen() {
  const { session, effectiveRole } = useAuth();
  const isManager = effectiveRole === "manager";
  const [filter, setFilter] = useState("none");
  const [employees, setEmployees] = useState(baseEmployees);
  const [assignments, setAssignments] = useState<RouteMachine[]>([]);
  const [employeeRouteStops, setEmployeeRouteStops] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;

    async function loadRoutes() {
      setIsLoading(true);
      setError("");

      try {
        const [routesResult, employeesResult] = await Promise.allSettled([
          apiRequest<{ locations?: Array<{ id: string; name: string; lat: number; lng: number; location?: string }>; paths?: unknown[] }>("/routes"),
          apiRequest<Array<{ id: string; name: string }>>("/employees"),
        ]);
        const nextErrors: string[] = [];
        const routesResponse =
          routesResult.status === "fulfilled"
            ? routesResult.value
            : (nextErrors.push("route map"), { locations: [] });
        const employeesResponse =
          employeesResult.status === "fulfilled"
            ? employeesResult.value
            : (nextErrors.push("employee roster"), []);
        const employeeLookup = buildEmployeeLookup(employeesResponse ?? []);
        const nextEmployees = buildEmployeeOptions(employeesResponse ?? []);
        let currentRouteStops: string[] = [];
        let assignmentMap = new Map<string, string>();

        if (isManager) {
          try {
            const allRoutes = await apiRequest<Array<{ employee_id?: string; employeeId?: string; employee_name?: string; stops?: Array<{ id: string }> }>>(
              "/employees/routes",
            );
            assignmentMap = buildAssignmentMap(allRoutes, employeeLookup);
          } catch {
            nextErrors.push("route assignments");
          }
        } else if (session?.user.id) {
          try {
            const currentRouteResponse = await apiRequest<{ stops?: Array<{ id: string }> }>(`/employees/${session.user.id}/routes`);
            currentRouteStops = currentRouteResponse.stops?.map((stop) => stop.id) ?? [];
            currentRouteStops.forEach((stopId) => {
              assignmentMap.set(stopId, session?.user.name ?? "You");
            });
          } catch {
            nextErrors.push("assigned route");
          }
        }

        const backendLocations = normalizeLocations(routesResponse.locations ?? [], assignmentMap);

        if (active) {
          setAssignments(backendLocations);
          setEmployees(nextEmployees);
          setEmployeeRouteStops(currentRouteStops);
          setError(nextErrors.length ? `Live ${nextErrors.join(" and ")} could not be loaded` : "");
        }
      } catch (nextError) {
        if (active) {
          setAssignments([]);
          setEmployees(baseEmployees);
          setEmployeeRouteStops([]);
          setError(nextError instanceof Error ? nextError.message : "Routes could not be loaded");
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

  const [selectedId, setSelectedId] = useState<string | null>(null);

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
  const selectableEmployees = employees.filter((employee) => employee.id !== "none" && employee.id !== "all");

  async function autogenerateRoutes() {
    setIsLoading(true);
    setError("");

    try {
      await apiRequest("/routes/autogenerate", { method: "POST" });
      const [nextLocations, nextAllRoutes] = await Promise.all([
        apiRequest<{ locations?: Array<{ id: string; name: string; lat: number; lng: number; location?: string }> }>("/routes"),
        apiRequest<Array<{ employee_id?: string; employeeId?: string; employee_name?: string; stops?: Array<{ id: string }> }>>("/employees/routes"),
      ]);
      const employeeLookup = buildEmployeeLookup(selectableEmployees);
      const assignmentMap = buildAssignmentMap(nextAllRoutes, employeeLookup);
      setAssignments(normalizeLocations(nextLocations.locations ?? [], assignmentMap));
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : "Route autogeneration failed");
    } finally {
      setIsLoading(false);
    }
  }

  async function assignMachine(machineId: string, employeeId: string) {
    setError("");

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
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : "Assignment failed");
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
              <div className="routes-filter-pod__status">{visibleLocations.length} NODES</div>
              <button className="routes-filter-pod__sparkle" type="button" aria-label="Autogenerate routes" onClick={() => void autogenerateRoutes()}>
                <Sparkles size={16} />
              </button>
            </>
          ) : (
            <>
              <div className="routes-filter-pod__meta">MY ROUTE</div>
              <div className="routes-filter-pod__status">{visibleLocations.length} STOPS</div>
            </>
          )}
        </ParityCard>

        {isManager ? (
          <div className="routes-sheet">
            {selectedLocation ? (
              <>
                <div className="routes-sheet__eyebrow">ASSIGNMENT / NODE {selectedLocation.id}</div>
                <div className="routes-sheet__title">SELECT OPERATIVE FOR {selectedLocation.name.toUpperCase()}</div>
                <div className="routes-sheet__meta">
                  <div className="routes-sheet__meta-item">
                    <span>Zone</span>
                    <strong>{selectedLocation.zone}</strong>
                  </div>
                  <div className="routes-sheet__meta-item">
                    <span>Window</span>
                    <strong>{selectedLocation.serviceWindow}</strong>
                  </div>
                  <div className="routes-sheet__meta-item">
                    <span>Assigned</span>
                    <strong>{selectedLocation.assignedTo}</strong>
                  </div>
                </div>
                <div className="routes-sheet__list">
                  {selectableEmployees.length ? (
                    selectableEmployees.map((employee) => (
                      <button
                        key={employee.id}
                        className="routes-sheet__row"
                        data-active={employee.name === selectedLocation.assignedTo}
                        type="button"
                        onClick={() => {
                          void assignMachine(selectedLocation.id, employee.id);
                        }}
                      >
                        <span>{employee.name}</span>
                        <strong>{employee.name === selectedLocation.assignedTo ? "ASSIGNED" : "SELECT"}</strong>
                      </button>
                    ))
                  ) : (
                    <div className="routes-sheet__empty">No employees are currently available for assignment.</div>
                  )}
                </div>
              </>
            ) : (
              <>
                <div className="routes-sheet__eyebrow">ASSIGNMENT / NODE --</div>
                <div className="routes-sheet__title">NO NETWORK NODE SELECTED</div>
                <div className="routes-sheet__list">
                  <div className="routes-sheet__empty">
                    {error ? "Live route data could not be loaded for this session." : "No route nodes are currently available."}
                  </div>
                </div>
                <div className="routes-sheet__footer-copy">Assignment controls remain available once live nodes are loaded.</div>
              </>
            )}
          </div>
        ) : (
          <div className="routes-sheet routes-sheet--employee">
            <div className="routes-sheet__eyebrow">ASSIGNED ROUTE</div>
            <div className="routes-sheet__title">TODAY&apos;S ACTIVE NODES</div>
            <div className="routes-sheet__list">
              {visibleLocations.length ? (
                visibleLocations.map((location) => (
                  <div key={location.id} className="routes-sheet__row routes-sheet__row--static">
                    <span>
                      {location.id} / {location.name}
                    </span>
                    <strong>{location.serviceWindow}</strong>
                  </div>
                ))
              ) : (
                <div className="routes-sheet__empty">No stops are currently assigned to this session.</div>
              )}
            </div>
            <div className="routes-sheet__footer-copy">Manager assignment controls stay hidden while employee context is active.</div>
          </div>
        )}
      </div>
      {error ? <div className="form-error form-error--compact">{error.toUpperCase()}</div> : null}
    </div>
  );
}
