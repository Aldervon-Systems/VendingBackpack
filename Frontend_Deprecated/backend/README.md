# Backend (Flask) for VM Simulator

This folder contains a small Flask server that exposes vending machine data to the Flutter app.

Quick start (Linux):

1. Activate the venv and run the server:

```bash
cd backend
source .venv/bin/activate
python server.py
```

2. The server listens on http://127.0.0.1:5000 with endpoints:
   - GET /machines
   - GET /locations
   - GET /history
   - GET /status

Notes:
- If a compiled `sales_sim` module exists in `backend/__pycache__`, the server will try to use it to provide live history.
- The Flutter app was updated to try these endpoints before falling back to bundled assets.
