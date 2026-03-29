# Staging Deployment via Portainer

This stack provides an isolated staging environment for the web application and RDFM services.

It intentionally does not modify or replace:
- Keycloak
- firmware tooling and related workflows

Use [deploy/portainer-stack.staging.yml](/C:/GitHub/VendingBackpackv3/deploy/portainer-stack.staging.yml) as the staging stack contract in Portainer.

## Recommended topology

- Production and staging should be separate Portainer stacks.
- Staging should use separate named volumes, network, secrets, and image tags.
- Route traffic to staging with a dedicated hostname through your existing reverse proxy.
- Promote the same tested image tag from staging to production after verification.

Suggested hostnames:
- `staging.app.aldervon.com` -> frontend
- `staging.api.aldervon.com` -> backend and RDFM routes via your reverse proxy

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
- `FRONTEND_HOST_PORT=19100`
- `BACKEND_HOST_PORT=19101`
- `LANDING_HOST_PORT=19060`
- `RDFM_HOST_PORT=15010`
- `RDFM_FRONTEND_APP_URL=https://staging.api.aldervon.com/device`
- `RDFM_OAUTH_URL=https://keycloak.aldervon.com/keycloak/realms/master/protocol/openid-connect/token/introspect`
- `RDFM_OAUTH_CLIENT_ID=rdfm-server-introspection`

## Portainer steps

1. In Portainer, open **Stacks** and click **Add stack**.
2. Name the stack `vending-backpack-staging`.
3. Paste in [deploy/portainer-stack.staging.yml](/C:/GitHub/VendingBackpackv3/deploy/portainer-stack.staging.yml).
4. Add the environment variables above in the Portainer UI.
5. Deploy the stack.
6. Point your reverse proxy at the staging host ports.

## Validation checklist

After deploy, verify:
- `http://<docker-host>:19100/__frontend_health`
- `http://<docker-host>:19100/health`
- frontend login flow still redirects to the existing Keycloak instance
- RDFM responds on `http://<docker-host>:15010`
- staging data is isolated from production data

## Notes

- This stack avoids `container_name` so production and staging can coexist on the same Docker host.
- Use pinned image tags for staging. Avoid `:latest` for anything you may need to roll back.
- If you later move staging behind host-based routing, you can remove most host port exposure and keep only the reverse proxy public.
