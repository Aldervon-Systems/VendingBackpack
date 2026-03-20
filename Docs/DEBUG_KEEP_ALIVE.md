
# 🕵️ Ultimate Debug: The "Keep Alive" Strategy

The application is crashing instantly, so we can't see why.
We will force the container to **stay alive** by doing nothing, so you can enter it and run the command manually to see the error.

## Step 1: Deploy this "Zombie" Stack

Copy this YAML into Portainer Editor (Replace all).
Update the stack.

```yaml
version: '3.8'

services:
  backend:
    image: ghcr.io/aldervon-systems/vendingbackpack:latest
    container_name: vending_backpack_backend
    restart: unless-stopped
    # OVERRIDE COMMAND: Do nothing, just stay alive
    command: ["tail", "-f", "/dev/null"]
    ports:
      - "8080:8080"
    environment:
      # Use SQLite to simplify
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

## Step 2: The Investigation

1.  Wait for the stack to update. The `backend` container should now show **Running** (Green) and stay green (it won't crash).
2.  Click on the **backend** container.
3.  Click **Console** button (usually >_ Console).
    *   Command: `/bin/bash` (or `/bin/sh`)
    *   User: `root`
    *   Click **Connect**.
4.  In the black terminal window, type this command and press Enter:

    ```bash
    uvicorn app.main:app --host 0.0.0.0 --port 8080
    ```

5.  **IT WILL CRASH.**
6.  **Take a screenshot** or copy the red text output and paste it here.

This is the only way to see the error message.
