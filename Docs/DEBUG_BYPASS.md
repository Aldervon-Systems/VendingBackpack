
# 🔓 Bypass Debug Mode

The fact that you **cannot access the console** means the Backend Container is **waiting for the Database** and never actually starting.
The "Health Check" on the database is failing (or too slow), so the Backend sits in "Pending" forever -> 502 Error.

We need to **Force Start** the backend, skipping the wait.

## Instructions

1.  **Copy this YAML** into Local Portainer Stack Editor (Replace all).
2.  **Update the Stack.**

```yaml
services:
  postgres:
    image: postgres:15-alpine
    container_name: vending_db
    restart: unless-stopped
    environment:
      POSTGRES_DB: vending
      POSTGRES_USER: vending_user
      POSTGRES_PASSWORD: iq200196Qr51
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - vending_network
    # We keep the check, but backend won't wait for it anymore
    healthcheck:
      test: [ "CMD-SHELL", "pg_isready -U vending_user -d vending" ]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    image: ghcr.io/aldervon-systems/vendingbackpack:latest
    container_name: vending_backpack_backend
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "9101:8080"
    environment:
      DATABASE_URL: postgresql://vending_user:iq200196Qr51@postgres:5432/vending
      DEMO_MODE: "true"
      ENVIRONMENT: production
    # CRITICAL CHANGE: Removed 'depends_on' so it starts IMMEDIATELY
    # Also added a "Safety Net" so it doesn't close if it crashes
    command: /bin/sh -c "uvicorn app.main:app --host 0.0.0.0 --port 8080 || echo '❌ APP CRASHED - STAYING ALIVE FOR DEBUG' && sleep 3600"
    networks:
      - vending_network

  frontend:
    image: ghcr.io/aldervon-systems/vendingbackpack/frontend-flutter:latest
    container_name: vending_frontend
    restart: unless-stopped
    ports:
      - "80:80"
    networks:
      - vending_network

volumes:
  postgres_data:
    driver: local

networks:
  vending_network:
    driver: bridge
```

## Verification
1.  **Update Stack.**
2.  Wait 15 seconds.
3.  Go to **Containers** -> **backend** -> **Logs**.
4.  **TELL ME WHAT THE LOGS SAY.**
    *   It will either show the app starting up.
    *   OR it will show the `❌ APP CRASHED` message and the specific Python error above it.
