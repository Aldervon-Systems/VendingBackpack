# Project status, current behavior, and demo guide ✅

## Overview 💡
**VendingBackpackv3** is a monorepo containing the hardware, firmware, and software required to demo and develop the VendingBackpack system. The important pieces are:

- `Backend/` — Rails API (new), serves demo data from JSON fixtures and in-memory mutable stores. Default port: `9090`.
- `Frontend/` — Flutter app (new), builds a web bundle served by nginx. Default UI port: `8082`.
- `Backend_Deprecated/` — FastAPI / Postgres (legacy, optional).
- `Frontend_Deprecated/` — legacy Flutter v1 app + simulator backend (optional).
- `Firmware/` and `Hardware/` — PlatformIO firmware and KiCad hardware files.

The repo contains `docker-compose.yml` (new stack) and `docker-compose-deprecated.yml` (legacy stack) and scripts to build the frontend bundles.

---

## Current behavior the project expresses 🎯
- End-to-end demo mode by default (new stack): **npm/rails serve JSON fixtures** and in-memory stores, so you can demo without a persistent DB.
- Browser → nginx (serves Flutter web) → `/api/*` → Rails backend. nginx reverses proxies and can fail-over between defined API hosts.
- Demo credentials and example data are included (see README). The system is designed for quick resets (in-memory stores or container restarts restore known demo state).
- Deprecated stack remains for legacy Postgres-backed flows and simulator-based demos.

---

## Running the project safely natively (Windows) 🔧⚠️
Short answer: Docker is recommended and safest. If you must run natively on Windows, prefer using **WSL2 (Ubuntu)** to avoid cross-OS tooling problems and to keep your host clean.

### Quick (recommended) — Docker (safe and isolated)
- Rebuild web bundle if needed:
  ```bash
  ./Frontend/scripts/build_web.sh
  ```
- Start the new stack:
  ```bash
  docker compose -f docker-compose.yml up -d --build
  ```
- Open demo UI: `http://localhost:8082`
- Backend health: `http://localhost:9090/health`

Why Docker: isolates dependencies, avoids installing Ruby/Python/Postgres on Windows, and is the most reproducible way to demo in person.

### Native (WSL2) — recommended path for "native" runs on Windows
1. Install WSL2 and a Linux distro (Ubuntu) and open a WSL shell.
2. Install the required runtimes inside WSL:
   - Ruby 3.3.10 (rbenv or other manager) + Bundler
   - Flutter SDK (or install Flutter on Windows directly and use `flutter run -d chrome` on Windows)
   - Optional: Python 3.11+ (deprecated services)
3. Backend (new Rails stack; runs without Postgres because it uses fixtures):
   ```bash
   cd Backend
   bundle install
   bin/rails server -b 0.0.0.0 -p 9090
   ```
4. Frontend (Flutter web):
   ```bash
   cd Frontend
   flutter pub get
   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:9090/api
   ```
5. Verify: `http://localhost:8082` (if you built the bundle and serve with nginx) or the `flutter run` served URL.

Important safety & networking notes:
- Run on a private/local network (or an isolated hotspot) when demoing in person; do **not** expose dev ports to public networks.
- Use firewall rules to restrict exposure of ports (Windows Firewall / host-only networks).
- Keep demo credentials in the repo fixture set and avoid using production secrets.

---

## In-person demo / showcase implementation checklist 🧾✅
Use this checklist to run a reliable in-person demo and reduce surprises.

1. Pre-demo local prep (do this at least once before the meeting)
   - `./Frontend/scripts/build_web.sh` (prebuild web bundle)
   - `docker compose -f docker-compose.yml up -d --build` (recommended)
   - Verify endpoints:
     - UI: `http://localhost:8082`
     - Backend health: `http://localhost:9090/health`
   - Test top user flows with demo accounts (Manager/Employee):
     - Manager: `Simon.swartout@gmail.com` / `test123`
     - Employee: `amanda.jones@example.com` / `employee123`
2. Hardware/firmware checks (if device will be present)
   - Battery / power OK, USB/serial cable present
   - `make flash` / `make monitor` (PlatformIO) to confirm firmware is responsive
   - Confirm device appears on the host (COM port or `/dev/ttyUSB*` in WSL)
3. Live demo plan (3–5 distinct scenes):
   - Scene 1 — Manager dashboard: show inventory, location staffing
   - Scene 2 — Employee route/transaction flow: simulate a sale or restock
   - Scene 3 — Device interaction: show serial logs or device update feel (if applicable)
   - Scene 4 — Failure and failover: bring down primary API container and show nginx fail-over to fallback (or simulate 502)
4. Contingencies:
   - Offline fallback: have a pre-recorded screen capture of the demo flows (video) or a prepared screenshot deck
   - Alternate: run the stack entirely via local `rails` + `flutter run` in WSL if Docker is unavailable
5. Security & privacy on-site:
   - Use an isolated Wi‑Fi or a mobile hotspot with no Internet access for the demo
   - Disable firewall rules that expose ports externally
   - Recreate demo state (restart stack) between sessions to ensure consistent initial conditions

---

## Suggested next steps (short, prioritized list) ▶️
1. Add a single `Docs/DEMO_PREP.md` that contains a shorter, one-page checklist derived from the above for quick handoff to presenters. ✅
2. Add a `make demo` or `scripts/demo.sh` wrapper that:
   - Builds `Frontend` bundle
   - Starts compose stack with `docker compose -f docker-compose.yml up -d --build`
   - Performs a smoke test of `/health` and the UI
3. Add an explicit `DEMO_MODE` toggle to the Rails backend to seed deterministic scenarios and test data (improves repeatability). ⚙️
4. Add an automated smoke-test (Playwright / Cypress) that runs against the deployed local stack to exercise the main demo flows.
5. Improve the demo experience: create a Wi‑Fi hotspot provisioning doc & include a one-click presentation script to open the right URLs and start log tail windows.

---

## Quick reference commands 🔍
- Build frontend: `./Frontend/scripts/build_web.sh`
- Start new stack (Docker): `docker compose -f docker-compose.yml up -d --build`
- Start new Rails locally: `cd Backend && bundle install && bin/rails server -b 0.0.0.0 -p 9090`
- Start new Flutter locally: `cd Frontend && flutter pub get && flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:9090/api`
- Stop stack: `docker compose -f docker-compose.yml down`

---

> Note: The repository README already has a comprehensive set of steps and example commands. This document is intended as a concise, demo-focused summary, plus actionable next steps to make in-person demos more reliable and secure.

If you'd like, I can also:
- Draft `Docs/DEMO_PREP.md` with a one-page front-of-house checklist, or
- Add `scripts/demo.sh` that automates build + smoke tests.

---

*Document created: {auto}*
