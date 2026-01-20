# Development Setup

This doc covers the Flutter SDK requirement and how to run both the deprecated and new stacks.

## Prerequisites
- Docker Desktop (for the backend + nginx hosting).
- Flutter SDK with Dart >= 3.8.1.

Verify your Flutter SDK:
```
flutter --version
```
Expected: Dart 3.8.1 or newer (for both `Frontend` and `Frontend_Deprecated`).

## Build the Flutter web outputs

Deprecated frontend output (served from `Frontend_Deprecated/build/web`):
```
./Frontend_Deprecated/scripts/build_web.sh
```

New frontend output (copied to `deploy/frontend`):
```
./Frontend/scripts/build_web.sh
```

## Run stacks

Deprecated stack (FastAPI + Frontend_Deprecated):
```
docker compose -f docker-compose-deprecated.yml up -d
```

New stack (Rails + Frontend):
```
docker compose -f docker-compose.yml up -d
```

Run both stacks in order (backends first, then frontends):
```
./scripts/run_all.sh
```

## URLs
- Deprecated UI: `http://localhost`
- Deprecated backend: `http://localhost:8080/health`
- New UI: `http://localhost:8082`
- New backend: `http://localhost:9090/health`

## API failover (proxy)
Both nginx configs now support a primary API + fallback API.

Defaults (local):
- `API_SCHEME=http`
- `API_PRIMARY_HOST=backend:8080` (deprecated) / `backend_new:9090` (new)
- `API_FALLBACK_HOST` defaults to the same value

Override for public + demo:
```
API_SCHEME=https \
API_PRIMARY_HOST=api.example.com \
API_FALLBACK_HOST=demo-api.example.com \
docker compose -f docker-compose.yml up -d
```

## Demo logins
- Manager: `Simon.swartout@gmail.com` / `test123`
- Employee: `amanda.jones@example.com` / `employee123`
