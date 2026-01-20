[![Docs](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/docs_workflow.yml/badge.svg)](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/docs_workflow.yml)
[![Hardware](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/hardware_workflow.yml/badge.svg)](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/hardware_workflow.yml)
[![Firmware](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/firmware_workflow.yml/badge.svg)](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/firmware_workflow.yml)

# VendingBackpack

![Banner](Static/Banner.png)

VendingBackpack is a monorepo that contains the **hardware**, **firmware**, and **software** needed to demo and develop the VendingBackpack system.

If you're looking for release artifacts, see the GitHub Releases for your fork/upstream.

## Repository Layout

- `Backend/` — **New backend** (Ruby on Rails API; fixture-backed demo data)
- `Frontend/` — **New frontend** (Flutter app; builds a web bundle served by nginx)
- `docker-compose.yml` — **New stack**: `Backend/` + nginx hosting `deploy/frontend`
- `Backend_Deprecated/` — **Deprecated backend** (FastAPI; Postgres-ready, mock routes wired)
- `Frontend_Deprecated/` — **Deprecated frontend (v1)** (Flutter) + a legacy Python simulator backend
- `docker-compose-deprecated.yml` — **Deprecated compose stack**: Postgres + `Backend_Deprecated/` + nginx hosting `Frontend_Deprecated/build/web`
- `deploy/frontend/` — built web assets for the new frontend (output of `./Frontend/scripts/build_web.sh`)
- `Firmware/` — PlatformIO Arduino firmware
- `Hardware/` — KiCad PCB project(s)
- `CAD/` — FreeCAD models
- `Docs/` — Sphinx docs + deployment notes

## Prerequisites

- Docker Desktop (recommended for running the stacks via compose)
- Flutter SDK with Dart **>= 3.8.1** (only needed if you want to rebuild the web UIs)
- Optional for local (non-Docker) dev:
  - Ruby **3.3.10** (for `Backend/`)
  - Python **3.11+** (for `Backend_Deprecated/` and the legacy simulator)

## Quick Start (New Stack / Recommended)

The new stack is intended to be an end-to-end demo using:
- **Rails API** backed by JSON fixtures + in-memory “mutable” stores
- **Flutter web UI** served by nginx, which proxies `/api/*` and `/health` to the backend

1) (Optional) Rebuild the new frontend web bundle:

```bash
./Frontend/scripts/build_web.sh
```

If the UI doesn’t change after rebuilding, do a hard refresh (or clear the site data) — Flutter web can be cached via a service worker.

2) Start the stack:

```bash
docker compose -f docker-compose.yml up -d --build
```

3) Open:
- New UI: `http://localhost:8082`
- New backend health: `http://localhost:9090/health`

## Quick Start (Deprecated Compose Stack)

The deprecated compose stack brings up **Postgres + FastAPI + nginx**:

1) Create `.env` (DB password is required for Postgres):

```bash
cp .env.example .env
```

2) (Optional) Rebuild the deprecated frontend web bundle:

```bash
./Frontend_Deprecated/scripts/build_web.sh
```

3) Start the stack:

```bash
docker compose -f docker-compose-deprecated.yml up -d --build
```

4) Open:
- Deprecated UI: `http://localhost`
- Deprecated backend health: `http://localhost:8080/health`

Important note: `Frontend_Deprecated/` currently points at the **legacy simulator backend** (port `5050`) via `Frontend_Deprecated/lib/api/local_data.dart`. The nginx `/api` proxy in `docker-compose-deprecated.yml` is for `Backend_Deprecated/`; the Flutter v1 app won’t use it unless it is repointed to call `/api`.

## Run Both Stacks

To build both Flutter web bundles and start both compose stacks:

```bash
./scripts/run_all.sh
```

- Deprecated UI: `http://localhost`
- New UI: `http://localhost:8082`

## Docker Compose Tips

- Status: `docker compose -f docker-compose.yml ps`
- Logs: `docker compose -f docker-compose.yml logs -f`
- Stop: `docker compose -f docker-compose.yml down`
- Reset deprecated DB (destructive): `docker compose -f docker-compose-deprecated.yml down -v`

## Configuration (Ports + Proxy)

Both nginx frontends proxy `/api/*` and `/health` to a backend using these env vars:

- `API_SCHEME` (default: `http`)
- `API_PRIMARY_HOST` (defaults to the backend service inside Docker)
- `API_FALLBACK_HOST` (defaults to `API_PRIMARY_HOST`)

Failover only triggers on `502/503/504` from the primary upstream.

Common port overrides (set in `.env` or inline):

- New stack:
  - `FRONTEND_NEW_PORT` (default `8082`)
  - `BACKEND_NEW_PORT` (default `9090`)
- Deprecated stack:
  - `FRONTEND_PORT` (default `80`)
  - `BACKEND_PORT` (default `8080`)

## Demo Architecture (How the Web Demo Works)

At a high level, both web demos are set up the same way:

```
browser ──> nginx (serves Flutter web) ──> /api + /health ──> backend
```

Why nginx is in the middle:
- The browser calls same-origin `/api/...` so you don’t fight CORS.
- nginx can **fail over** from a primary API host to a fallback host on `502/503/504`.

New stack (`docker-compose.yml`):
- nginx container `frontend_new` serves `deploy/frontend/`
- `/api/*` and `/health` proxy to `backend_new:9090` by default
- Rails returns demo data from `Backend/data/fixtures/` + in-memory mutable stores

Deprecated stack (`docker-compose-deprecated.yml`):
- nginx container `frontend` serves `Frontend_Deprecated/build/web`
- `/api/*` and `/health` proxy to `backend:8080` by default (FastAPI)
- FastAPI can connect to Postgres, but the current Flutter v1 client primarily talks to the legacy simulator on port `5050` (see note above)

## Demo Data (New Backend)

The new Rails backend reads demo data from JSON fixtures under `Backend/data/fixtures/` (users, employees, locations, warehouse inventory, daily stats, etc).

Some endpoints (items, transactions, machines, employee routes) are backed by `Fixtures::MutableStore` and are **in-memory** (they reset when the backend restarts).

## Demo Logins

- Manager: `Simon.swartout@gmail.com` / `test123`
- Employee: `amanda.jones@example.com` / `employee123`

## Local Development (No Docker)

New backend (Rails):

```bash
cd Backend
bundle install
bin/rails server -b 0.0.0.0 -p 9090
```

New frontend (Flutter):

```bash
cd Frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:9090/api
```

Deprecated backend (FastAPI, local SQLite by default):

```bash
cd Backend_Deprecated
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
```

Legacy simulator backend for `Frontend_Deprecated/` (port `5050`):

```bash
python3 Frontend_Deprecated/backend/simple_server.py
```

## Firmware / Hardware

- Firmware (`Firmware/`): PlatformIO project (`make build`, `make flash`, `make monitor`)
- Hardware (`Hardware/`): KiCad project(s)
- CAD (`CAD/`): FreeCAD models

## More Docs

- Dev setup and stack URLs: `Docs/DEV_SETUP.md`
- Deprecated stack architecture notes: `Docs/ARCHITECTURE_DEPRECATED.md`
- Portainer stack deployment (backend + Postgres): `deploy/BACKEND_PORTAINER.md`
- Legacy deployment/troubleshooting notes live under `Docs/` (some may reference older folder/file names)
