[![Docs](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/docs_workflow.yml/badge.svg)](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/docs_workflow.yml)
[![Hardware](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/hardware_workflow.yml/badge.svg)](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/hardware_workflow.yml)
[![Firmware](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/firmware_workflow.yml/badge.svg)](https://github.com/KenwoodFox/VendingBackpack/actions/workflows/firmware_workflow.yml)

# VendingBackpack

![Banner](Static/Banner.png)

VendingBackpack is a monorepo that contains the **hardware**, **firmware**, and **software** needed to develop the VendingBackpack system.

## Repository Layout

- `Backend/` — **Backend API** (Ruby on Rails)
- `Frontend/` — **Frontend App** (Flutter)
- `docker-compose.yml` — **Docker Stack**: Rails API + Nginx (serving Flutter web)
- `Firmware/` — PlatformIO Arduino firmware
- `Hardware/` — KiCad PCB project(s)
- `CAD/` — FreeCAD models
- `Docs/` — Documentation and deployment notes

## Prerequisites

- Docker Desktop (recommended for running the stack)
- Flutter SDK with Dart **>= 3.0.0** (if rebuilding the web UI)
- Ruby **3.3.10** (for local backend development)

## Quick Start

1) Start the stack:

```bash
docker compose up -d --build
```

2) Open:
- UI: `http://localhost:9100`
- Backend Health: `http://localhost:9090/health`

## Local Development (No Docker)

### Backend (Rails)

```bash
cd Backend
bundle install
bin/rails server -b 0.0.0.0 -p 9090
```

### Frontend (Flutter)

```bash
cd Frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:9090/api
```

## Configuration

The stack uses environment variables for configuration. See `docker-compose.yml` for details.
- `RAILS_ENV`: set to `production` or `development`
- `SECRET_KEY_BASE`: required for production mode

## Login Credentials (Default)

- **Admin**: `admin@vbp.com` / `password123`
