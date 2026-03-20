# Deploying the Backend on Portainer

Use [portainer-stack.yml](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/deploy/portainer-stack.yml) to deploy the current backend and frontend stack in Portainer.

Steps:

1. In Portainer → Stacks → Add stack.
2. Name the stack `vending-backpack` and paste the contents of `deploy/portainer-stack.yml` into the Web editor.
3. Set the required environment variables in the Portainer UI:
   - `SECRET_KEY_BASE` — required Rails secret
   - `FRONTEND_IMAGE` — required live frontend tag
   - optional: `BACKEND_IMAGE` (defaults to `ghcr.io/aldervon-systems/vendingbackpack/backend:latest`)
4. Deploy the stack.
5. Monitor logs for `frontend` and `backend` and verify `/health` at `http://<host>:9100/health`.

Notes:
- The current frontend deployment model is static-exported assets in nginx with same-origin `/api` proxying.
- The frontend cutover and rollback flow is documented in [FRONTEND_NEXT_CUTOVER.md](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/FRONTEND_NEXT_CUTOVER.md).

Redeploying an updated image
----------------------------

When you publish a new frontend or backend image tag, redeploy in Portainer by editing the stack variables and changing `FRONTEND_IMAGE` or `BACKEND_IMAGE`, then clicking `Deploy the stack`.

If you use the same tag (for example `:latest`) Portainer may reuse a cached image on the host. To force Portainer to pull the latest image:

- Edit the stack in Portainer and enable the **Pull image** / **Force pull image** option if available (in the Web editor's advanced options), then deploy.
- Alternatively, under Images (Portainer → Images) use the **Pull** action for the exact GHCR image tag you want, then go to the stack and hit **Deploy the stack** with the **Recreate** or **Force recreate** option enabled.

After redeploying, check the backend logs and `/health` endpoint to confirm the new version started correctly.

CI / automated publishing
------------------------

This repository contains a GitHub Actions workflow at [.github/workflows/publish-ghcr.yml](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/.github/workflows/publish-ghcr.yml) that builds and pushes images to GHCR.

The frontend images published for cutover are:
- `ghcr.io/aldervon-systems/vendingbackpack/frontend-flutter`
- `ghcr.io/aldervon-systems/vendingbackpack/frontend-next`
