# Deploying the Backend on Portainer

Use the included `portainer-stack.yml` to deploy the backend and a Postgres database as a Portainer stack.

Steps:

1. In Portainer → Stacks → Add stack.
2. Name the stack `vending-backpack` and paste the contents of `deploy/portainer-stack.yml` into the Web editor.
3. Set the required environment variables in the Portainer UI:
   - `DB_PASSWORD` — strong DB password (required)
   - optional: `IMAGE_TAG` (defaults to `latest`) and `BACKEND_PORT` (defaults to `8080`)
4. Deploy the stack.
5. Monitor logs for `postgres` and `backend` and verify `/health` at `http://<host>:<BACKEND_PORT>/health`.

Notes:
- If you prefer SQLite and do not want Postgres, deploy only the backend service and mount a volume to `/app/data`.
- To publish a new image, use `backend/publish.sh TAG` (this will push to `simonswartout/aldervon-vending-backend`) then update `IMAGE_TAG` in the stack to the desired tag and re-deploy.

Redeploying an updated image
----------------------------

When you publish a new image tag (recommended) you can redeploy in Portainer by editing the stack and changing the `IMAGE_TAG` value to the new tag, then clicking `Deploy the stack`.

If you use the same tag (for example `:latest`) Portainer may reuse a cached image on the host. To force Portainer to pull the latest image:

- Edit the stack in Portainer and enable the **Pull image** / **Force pull image** option if available (in the Web editor's advanced options), then deploy.
- Alternatively, under Images (Portainer → Images) use the **Pull** action for `simonswartout/aldervon-vending-backend:latest` to fetch the newest image, then go to the stack and hit **Deploy the stack** with the **Recreate** or **Force recreate** option enabled.

After redeploying, check the backend logs and `/health` endpoint to confirm the new version started correctly.

CI / automated publishing
------------------------

This repository contains a GitHub Actions workflow at `.github/workflows/publish-dockerhub.yml` that builds and pushes images to Docker Hub when you push a tag prefixed with `v` (for example `v2025.11.27`).

Setup required for the workflow:

- In the repository settings → Secrets, create `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` (a Docker Hub personal access token).
- Push a tag to trigger the workflow, e.g. `git tag v2025.11.27 && git push origin v2025.11.27`.

