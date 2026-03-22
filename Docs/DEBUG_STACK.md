
# 🛠️ Debug Strategy: The SQLite Isolation Test

Since we are flying blind without logs, we need to know: **Is the App crashing, or is the Database blocking it?**

This Stack removes the Database Service entirely and runs the App with a simple local file database (SQLite).

## Instructions

1.  **Copy this YAML** below.
2.  Go to **Portainer -> Stacks -> vending-backpack -> Editor**.
3.  **Replace Everything** with this YAML.
4.  **Update the Stack** (Ensure "Re-pull image" is ON).

```yaml
version: '3.8'

services:
  # FAIL-SAFE BACKEND (Uses SQLite, No Postgres Dependency)
  backend:
    image: ghcr.io/aldervon-systems/vendingbackpack:latest
    container_name: vending_backpack_backend
    restart: unless-stopped
    ports:
      # Trying to fix the port mismatch (Host 9101 -> Container 8080)
      - "9101:8080" 
    environment:
      # BYPASS POSTGRES: Use a local file database
      DATABASE_URL: "sqlite:///./debug_vending.db"
      DEMO_MODE: "true"
      DEBUG: "true"
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
    depends_on:
      - backend

networks:
  vending_network:
    driver: bridge
```

## Verification

After deploying this, wait 20 seconds and run:

`curl -s https://app.aldervon.com/health`

### Interpreting the Result:
*   **If it returns 200 OK**: The Code is PERFECT. The problem was specifically your Postgres Password/Host configuration.
*   **If it returns 502 Error**: The Code/Image is BROKEN. (e.g. Missing dependency, syntax error).
