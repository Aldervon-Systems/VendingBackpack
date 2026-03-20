# Frontend Next Cutover

This document defines the exact deployment cutover from the current Flutter web frontend to the Next web frontend.

The production delivery model is static-exported Next content served by nginx, matching the current Flutter frontend contract:
- `next build` exports static assets into `out/`
- the image copies those assets into `/Deploy/frontend/`
- nginx serves the static frontend and proxies `/api/*` and `/health`
- Portainer pulls a pinned GHCR image; it does not build from source

## Live contracts that must not change

- Public frontend URL remains `http://<host>:9100`
- Compose service name remains `frontend`
- Backend remains `backend:9090`
- Browser API path remains same-origin `/api/*`
- Browser health path remains `/health`

## Image names

Next candidate image:
- `ghcr.io/aldervon-systems/vendingbackpack/frontend-next:sha-<approved-shortsha>`

Frozen Flutter rollback image:
- `ghcr.io/aldervon-systems/vendingbackpack/frontend-flutter:cutover-<yyyymmdd>-<shortsha>`

## Preview deployment on port 9101

Bring up backend if needed:

```bash
docker compose up -d backend
```

Bring up the candidate Next frontend on the preview port:

```bash
FRONTEND_NEXT_IMAGE=ghcr.io/aldervon-systems/vendingbackpack/frontend-next:sha-<approved-shortsha> \
docker compose -f docker-compose.yml -f docker-compose.frontend-next-preview.yml up -d frontend_next_candidate
```

Preview validation URLs:
- `http://localhost:9101/__frontend_health`
- `http://localhost:9101/auth/login`
- `http://localhost:9101/dashboard`
- `http://localhost:9101/routes`
- `http://localhost:9101/warehouse`
- `http://localhost:9101/admin`
- `http://localhost:9101/health`

## Portainer production stack

Use [deploy/portainer-stack.yml](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/deploy/portainer-stack.yml) as the Portainer stack source of truth.

Required Portainer environment variables:
- `SECRET_KEY_BASE=<production secret>`
- `FRONTEND_IMAGE=ghcr.io/aldervon-systems/vendingbackpack/frontend-next:sha-<approved-shortsha>`

Optional Portainer environment variable:
- `BACKEND_IMAGE=ghcr.io/aldervon-systems/vendingbackpack/backend:latest`

The live service contract stays:
- `frontend` serves the app on `9100:80`
- browser API traffic stays same-origin on `/api/*`
- nginx proxies `/health` to the Rails backend
- rollback is a single `FRONTEND_IMAGE` swap

## Live cutover on port 9100

The live cutover repoints the existing `frontend` service image without renaming the service.

Exact cutover command:

```bash
FRONTEND_IMAGE=ghcr.io/aldervon-systems/vendingbackpack/frontend-next:sha-<approved-shortsha> \
docker compose up -d frontend
```

Post-cutover validation URLs:
- `http://localhost:9100/__frontend_health`
- `http://localhost:9100/auth/login`
- `http://localhost:9100/dashboard`
- `http://localhost:9100/routes`
- `http://localhost:9100/warehouse`
- `http://localhost:9100/admin`
- `http://localhost:9100/health`

## Rollback

Rollback is a single image re-point on the same live `frontend` service.

Exact rollback command:

```bash
FRONTEND_IMAGE=ghcr.io/aldervon-systems/vendingbackpack/frontend-flutter:cutover-<yyyymmdd>-<shortsha> \
docker compose up -d frontend
```

The preview candidate can remain up until cutover is accepted:

```bash
FRONTEND_NEXT_IMAGE=ghcr.io/aldervon-systems/vendingbackpack/frontend-next:sha-<approved-shortsha> \
docker compose -f docker-compose.yml -f docker-compose.frontend-next-preview.yml rm -sf frontend_next_candidate
```

## Notes

- `docker-compose.yml` is left safe for current local use by defaulting `FRONTEND_IMAGE` to `frontend-flutter:latest`.
- The preview compose file forces an explicit `FRONTEND_NEXT_IMAGE` value so the candidate tag is always deliberate.
- The frontend container healthcheck accepts either the new `__frontend_health` artifact or the existing `/health` path, which allows the base compose file to work before and after cutover.
