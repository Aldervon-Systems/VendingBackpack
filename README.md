[![Docs](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/docs_workflow.yml/badge.svg)](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/docs_workflow.yml)
[![Hardware](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/hardware_workflow.yml/badge.svg)](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/hardware_workflow.yml)
[![Firmware](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/firmware_workflow.yml/badge.svg)](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/firmware_workflow.yml)

# VendingBackpack

![Banner](Static/Banner.png)

VendingBackpack is a monorepo that contains the **hardware**, **firmware**, and **software** needed to develop the VendingBackpack system.

The current production target is the Rails backend plus the `Frontend-Next` web client. The Flutter app remains in the repo as a legacy surface and is no longer treated as the operational release client.

## Repository Layout

- `Backend/` — **Backend API** (Ruby on Rails)
- `Frontend/` — **Frontend App** (Flutter)
- `Frontend-Next/` — **Primary Web Frontend** (Next.js static export via nginx)
- `docker-compose.yml` — **Docker Stack**: Rails API + nginx (serving the Next web frontend)
- `Firmware/` — PlatformIO Arduino firmware
- `Hardware/` — KiCad PCB project(s)
- `CAD/` — FreeCAD models
- `Docs/` — Documentation and deployment notes

## Prerequisites

- Docker Desktop (recommended for running the stack)
- Flutter SDK with Dart **>= 3.0.0** (if rebuilding the web UI)
- Ruby **3.3.10** (for local backend development)

## Quick Start

1. Start the local stack with SQL-seeded staging accounts:

```bash
SEED_DEMO_DATA=true docker compose up -d --build backend frontend
```

2. Open:
- UI: `http://localhost:9100`
- Backend Health: `http://localhost:9090/health`
- Frontend Health: `http://localhost:9100/__frontend_health`
- Corporate View: `http://localhost:9100/corporate`

3. Use the seeded preview accounts:
- Manager: `renee@aldervon.com`
- Employee: `amanda.jones@example.com`
- Organization search: `Aldervon Systems`
- Password: `password123`

## Local Development (No Docker)

### Backend (Rails)

```bash
cd Backend
bundle install
bin/rails server -b 0.0.0.0 -p 9090
```

### Frontend (Flutter, legacy)

```bash
cd Frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:9090/api
```

## Configuration

The stack uses environment variables for configuration. See `docker-compose.yml` for details.
- `RAILS_ENV`: set to `production` or `development`
- `SECRET_KEY_BASE`: required for production mode
- `SEED_DEMO_DATA`: seeds the local backend on container boot
- `FRONTEND_IMAGE`: defaults to `ghcr.io/aldervon-systems/vendingbackpack/frontend-next:latest`
- `BACKEND_IMAGE`: defaults to `ghcr.io/aldervon-systems/vendingbackpack/backend:latest`

## Current Release Notes

- Operational contract docs: [Docs/BACKEND_API.md](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/BACKEND_API.md)
- Implementation intention and validation summary: [MASTER_INTENTION_PLAN.md](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/MASTER_INTENTION_PLAN.md)
- Data consistency plan and gated checklist: [Docs/data-consistency-plan/master_plan.md](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/data-consistency-plan/master_plan.md)
