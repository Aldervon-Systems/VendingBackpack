# Frontend-only Demo Mode (web build)

This repository includes a lightweight *frontend-only* demo/simulation that runs in the built Flutter web output (v1/build/web). The demo mode lives entirely inside the browser and does not touch the backend or the database.

Key points
- Demo code is injected into the built web files (no backend changes required).
- Toggle demo mode from the floating toggle in the bottom-right of the web app.
- When demo mode is ON the app intercepts calls destined for the backend (port :5050 or common paths like /inventory, /status, /daily_stats, /employee_routes) and returns simulated data.
- The repository also includes an optional container-hosted mock server that serves the static frontend and exposes persistent demo endpoints under `/__demo_api` (see below). This provides a more reliable demo run (persistent state across browsers and sessions) compared with browser-only localStorage.

How to use
1. Open your deployed frontend (the built web directory) in a browser.
2. Click the floating `Demo: OFF` button in the bottom-right to enable demo mode. The button toggles and will read `Demo: ON`.
3. Demo data will be loaded (from `mock_data/initial_db.json`) into localStorage and used for GET/POST requests to the usual backend paths.

Optional: run the persistent containerized demo server

1. Start the full stack using docker compose (from the repository root):

```bash
# bring up postgres, backend, and a frontend mock server that serves the web build + demo API
sudo docker compose up -d --build
```

2. The new frontend mock container will expose the site on host port 80 by default (use FRONTEND_PORT env var to change). When the demo-mode toggle is ON the client will prefer the persistent `__demo_api` endpoints served by this container.

3. To reset the persistent demo DB inside the container, edit `v1/mock_server/demo_db.json` (or rebuild the frontend container to re-copy the file) — whereas browser-only localStorage persists per browser session only.

Quick smoke test

1. Install jq (used by the helper script):

```bash
sudo apt install -y jq
```

2. Run the included smoke test (assumes the frontend container answers on localhost port 80):

```bash
cd v1/mock_server
chmod +x check_demo.sh
./check_demo.sh http://localhost
```

If that succeeds it demonstrates the persistent demo API endpoints are reachable and accept updates.

Notes and limitations
- Persistence is browser-local only (localStorage) — demo changes do not modify files on the server container.
- If you want to reset demo data, open DevTools > Application > Local Storage and delete the `vb_demo_db` key (or run `localStorage.removeItem('vb_demo_db')` from console). You can also turn demo off and back on to reload initial data.
- This approach is intentionally lightweight and avoids rebuilding the Flutter source. If you want a tighter integration (toggle inside the Flutter app or server-side mocked endpoints) the better approach is to modify the Flutter source and add a proper in-app toggle.

Files added
- v1/build/web/demo-mode.js — small client-side script that provides UI toggle and fetch interception
- v1/build/web/mock_data/initial_db.json — initial seed data used by the demo
- v1/build/web/index.html — modified to include demo-mode.js
