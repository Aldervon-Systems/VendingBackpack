"use client";

import { CircleMarker, MapContainer, TileLayer, Tooltip } from "react-leaflet";

export type RouteMachine = {
  id: string;
  name: string;
  lat: number;
  lng: number;
  assignedTo: string;
  zone: string;
  serviceWindow: string;
};

type RouteMapCanvasProps = {
  locations: RouteMachine[];
  activeId: string | null;
  onSelect: (location: RouteMachine) => void;
};

export function RouteMapCanvas({ locations, activeId, onSelect }: RouteMapCanvasProps) {
  const UnsafeMapContainer = MapContainer as any;
  const UnsafeTileLayer = TileLayer as any;
  const UnsafeCircleMarker = CircleMarker as any;
  const UnsafeTooltip = Tooltip as any;
  const bounds = locations.length
    ? (locations.map((location) => [location.lat, location.lng]) as [number, number][])
    : ([[42.349, -71.11], [42.37, -71.04]] as [number, number][]);

  return (
    <UnsafeMapContainer className="routes-map-canvas" bounds={bounds} boundsOptions={{ padding: [24, 24] }}>
      <UnsafeTileLayer url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png" />
      {locations.map((location) => (
        <UnsafeCircleMarker
          key={location.id}
          center={[location.lat, location.lng]}
          radius={activeId === location.id ? 12 : 10}
          pathOptions={{
            color: "#3B82F6",
            weight: activeId === location.id ? 3 : 2,
            fillColor: "#FFFFFF",
            fillOpacity: 1,
          }}
          eventHandlers={{ click: () => onSelect(location) }}
        >
          <UnsafeTooltip direction="top" offset={[0, -10]} opacity={1} permanent={activeId === location.id}>
            <div className="routes-map-tooltip">{location.name}</div>
          </UnsafeTooltip>
        </UnsafeCircleMarker>
      ))}
    </UnsafeMapContainer>
  );
}
