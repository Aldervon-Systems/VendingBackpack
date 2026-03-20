
# 🛡️ The "Double Door" Fix

We have fixed the Database. Now we just need to let the traffic in.
I might have guessed the wrong Port (9101), so let's open **BOTH** ports to be sure.

## Instructions

1.  **Copy this YAML** into Portainer Stack Editor (Replace all).
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
      # OPEN BOTH PORTS (The "Shotgun" Fix)
      - "8080:8080"  # Standard Default
      - "9101:8080"  # Alternate Guess
    environment:
      DATABASE_URL: postgresql://vending_user:iq200196Qr51@postgres:5432/vending
      DEMO_MODE: "true"
      ENVIRONMENT: production
    depends_on:
      postgres:
        condition: service_healthy
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

volumes:
  postgres_data:
    driver: local

networks:
  vending_network:
    driver: bridge
```

## Verification
Wait 30s, then:
`curl -s https://app.aldervon.com/health`
