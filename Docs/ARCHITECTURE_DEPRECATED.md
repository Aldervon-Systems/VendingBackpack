# Frontend_Deprecated <-> Backend_Deprecated Architecture (Deprecated)

This is a one-page, module-based overview with pillar-style sections so a junior dev can extend the project safely.

Pillar 1: Runtime and Docker
- docker-compose-deprecated.yml runs three services: postgres (DB), backend (FastAPI), frontend (Nginx + Flutter web).
- Backend container exposes port 8080 and connects to postgres via DATABASE_URL.
- Frontend container serves Frontend_Deprecated/build/web and proxies /api/* and /health to backend:8080.
- Build note: Frontend_Deprecated/Dockerfile assumes build/web already exists (run flutter build web before building the image).

Pillar 2: Frontend_Deprecated (Flutter web app)
Modules and responsibilities:
- lib/main.dart: app entry, theme, and root PagesLayout shell.
- lib/widgets/pages_layout.dart: layout + sign-in overlays + page routing (Dashboard, Routes, Warehouse).
- lib/pages/*: feature pages (dashboard_page, routes_page, warehouse_page, employee_dashboard, etc).
- lib/components/atoms|molecules|organisms: reusable UI pieces in atomic design tiers.
- lib/api/*: data access layer.
  - local_data.dart: defines the backend base URL and fetches machines, locations, history, status, inventory, daily_stats.
  - dashboard_repository.dart + dashboard_store.dart: compose data, caching, refresh logic.
  - warehouse_api.dart: warehouse CRUD and inventory updates.
  - employee_routes_repository.dart: route generation + persistence (also calls OSRM).
  - inventory_cache.dart: in-memory inventory shared between manager and employee views.
- src/data and assets: demo JSON and icons (some code still attempts asset fallback, but primary path is HTTP).

Data flow snapshot:
- UI -> DashboardStore/Repository -> LocalData -> HTTP endpoints.
- UI -> WarehouseApi -> HTTP endpoints.
- UI -> EmployeeRoutesRepository -> HTTP endpoints + external OSRM routing API.

Pillar 3: Backend_Deprecated (FastAPI API)
Modules and responsibilities:
- app/main.py: FastAPI app, CORS, includes routers with prefix /api.
- app/routers/auth.py: POST /api/token (mock auth).
- app/routers/warehouse.py: GET /api/warehouse, /api/items/{barcode}, /api/daily_stats (mock data).
- app/routers/routes.py: GET /api/routes and /api/employees (mock data).
- app/db/mock_db.py: in-memory users, employees, locations, inventory (source for current routes).
- app/database.py + app/models + app/schemas + app/services: SQLAlchemy, demo data, hardware services (not wired into main yet).

Pillar 4: Simulator backend for the UI (Frontend_Deprecated/backend)
- Flask server (server.py) on port 5000 and a simple HTTP server (simple_server.py) on port 5050.
- Endpoints include: /machines, /locations, /history, /status, /inventory, /daily_stats,
  /warehouse/items, /warehouse/item/{barcode}, /inventory/fill, /employee_routes, /inventory/machine/{id}, etc.
- Frontend_Deprecated currently targets this simulator via local_data.dart (base URL is hard-coded to http://10.0.0.19:5050).

Pillar 5: Integration contracts (what must line up)
Current frontend contract (baseUrl + paths):
- /machines, /locations, /history, /status
- /inventory, /inventory/fill, /inventory/machine/{id}
- /daily_stats
- /warehouse/items, /warehouse/item/{barcode}
- /employee_routes

Current Backend_Deprecated contract (behind /api):
- /api/warehouse
- /api/items/{barcode}
- /api/daily_stats
- /api/routes
- /api/employees
- /api/token

Implication:
- docker-compose serves the UI and proxies /api to Backend_Deprecated, but the UI does not call /api today.
- To wire Frontend_Deprecated to Backend_Deprecated, you must either:
  1) Change Frontend_Deprecated base URL to use relative /api and align endpoint paths, or
  2) Expand Nginx proxy rules and implement matching endpoints in Backend_Deprecated for /machines, /inventory, /warehouse/items, etc.

Pillar 6: Safe change guide for juniors
- Add a backend endpoint: create/extend a router in Backend_Deprecated/app/routers and include it in app/main.py.
- Keep JSON shapes stable (lists of maps, or map of machineId -> list of SKU rows) or update parsing in LocalData/DashboardRepository.
- If you change localDataBaseUrl() or any API path, rebuild Frontend_Deprecated/build/web before rebuilding the frontend Docker image.
- If you switch from mock_db to SQLAlchemy models, wire SessionLocal and init_db(), and confirm DEMO_MODE seeding paths.
- When adding new UI features, follow the module layering: pages -> components -> api, and update InventoryCache if state must be shared.
