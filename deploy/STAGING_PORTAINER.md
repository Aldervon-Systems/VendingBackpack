# Staging Deployment via Portainer

This stack provides an isolated staging environment for the web application and RDFM services.

It intentionally does not modify or replace:
- Keycloak
- firmware tooling and related workflows
- the host-level Caddy configuration

Use [deploy/portainer-stack.staging.yml](/C:/GitHub/VendingBackpackv3/deploy/portainer-stack.staging.yml) as the staging stack contract in Portainer.

## Recommended topology

- Production and staging should be separate Portainer stacks.
- Staging should use separate named volumes, network, secrets, and image tags.
- Route traffic to staging with a dedicated hostname through your existing host-level Caddy reverse proxy.
- Promote the same tested image tag from staging to production after verification.

Suggested hostnames:
- `staging.aldervon.com` -> frontend
- `staging.aldervon.com/device` -> RDFM route via your reverse proxy

## How staging reaches Caddy

Because Caddy runs on the host rather than in Docker, the staging containers still need host port bindings so Caddy has something stable to proxy to.

These bindings are intentionally limited to loopback by default:
- frontend -> `127.0.0.1:9100`
- backend -> `127.0.0.1:19101`
- landing -> `127.0.0.1:19060`
- RDFM -> `127.0.0.1:15010`

That means:
- the services are not exposed publicly on all interfaces
- only processes on the host, such as Caddy, can reach them directly
- users should access staging through the Cloudflare/Caddy hostname, not by port

## What stays shared

Per your request, this staging setup does not change the existing Keycloak or firmware setup.

That means:
- Keycloak continues to be managed outside this stack.
- Firmware-related services remain outside this stack.
- Staging app services can still point at the existing Keycloak endpoints and clients you already operate.

## Required Portainer variables

- `BACKEND_IMAGE=ghcr.io/aldervon-systems/vendingbackpack/backend:sha-<approved-shortsha>`
- `FRONTEND_IMAGE=ghcr.io/aldervon-systems/vendingbackpack/frontend-next:sha-<approved-shortsha>`
- `SECRET_KEY_BASE=<staging secret>`
- `RDFM_DB_PASSWORD=<staging rdfm db password>`
- `RDFM_JWT_SECRET=<staging rdfm jwt secret>`
- `RDFM_OAUTH_CLIENT_SEC=<existing keycloak client secret>`

Optional:
- `LANDING_IMAGE=ghcr.io/aldervon-systems/vendingbackpack/landing:sha-<approved-shortsha>`
- `RDFM_SERVER_IMAGE=ghcr.io/aldervon-systems/rdfm-server:sha-<approved-shortsha>`
- `FRONTEND_BIND_ADDRESS=127.0.0.1`
- `BACKEND_BIND_ADDRESS=127.0.0.1`
- `LANDING_BIND_ADDRESS=127.0.0.1`
- `RDFM_BIND_ADDRESS=127.0.0.1`
- `FRONTEND_HOST_PORT=9100`
- `BACKEND_HOST_PORT=19101`
- `LANDING_HOST_PORT=19060`
- `RDFM_HOST_PORT=15010`
- `RDFM_FRONTEND_APP_URL=https://staging.aldervon.com/device`
- `RDFM_OAUTH_URL=https://keycloak.aldervon.com/keycloak/realms/master/protocol/openid-connect/token/introspect`
- `RDFM_OAUTH_CLIENT_ID=rdfm-server-introspection`

## Portainer steps

1. In Portainer, open **Stacks** and click **Add stack**.
2. Name the stack `vending-backpack-staging`.
3. Paste in [deploy/portainer-stack.staging.yml](/C:/GitHub/VendingBackpackv3/deploy/portainer-stack.staging.yml).
4. Add the environment variables above in the Portainer UI.
5. Deploy the stack.
6. Point your host-level Caddy configuration at the loopback staging ports.

## Validation checklist

After deploy, verify:
- `https://staging.aldervon.com`
- `http://127.0.0.1:9100/__frontend_health` from the host
- `http://127.0.0.1:9100/health` from the host
- frontend login flow still redirects to the existing Keycloak instance
- `https://staging.aldervon.com/device`
- RDFM responds on `http://127.0.0.1:15010` from the host
- staging data is isolated from production data

## Notes

- This stack avoids `container_name` so production and staging can coexist on the same Docker host.
- Use pinned image tags for staging. Avoid `:latest` for anything you may need to roll back.
- The default staging ports are internal host upstreams for Caddy, not public entrypoints for users.
