# Portainer Deployment Guide

This repository now ships a single GHCR-based Portainer stack contract for the web app and backend.

Use these as the current sources of truth:
- [deploy/portainer-stack.yml](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/deploy/portainer-stack.yml)
- [FRONTEND_NEXT_CUTOVER.md](/Users/crimsonwheeler/Documents/GitHub/VendingBackpack/Docs/FRONTEND_NEXT_CUTOVER.md)

## Current deployment model

- `frontend` is an nginx container on `9100:80`
- the frontend image is a static-exported build
- browser API traffic stays same-origin on `/api/*`
- nginx proxies `/api/*` and `/health` to `backend:9090`
- Portainer should pull GHCR images; it should not build the Next app from source

## Required Portainer variables

- `SECRET_KEY_BASE=<production secret>`
- `FRONTEND_IMAGE=ghcr.io/aldervon-systems/vendingbackpack/frontend-next:sha-<approved-shortsha>`

Optional:
- `BACKEND_IMAGE=ghcr.io/aldervon-systems/vendingbackpack/backend:latest`

## Validation

After deploy, verify:
- `https://app.aldervon.com/__frontend_health`
- `https://app.aldervon.com/health`
- `https://app.aldervon.com/auth/login`
- `https://app.aldervon.com/dashboard`

## Notes

- The older Portainer docs in this repo were written for previous image names and older runtime assumptions.
- Use the stack file and cutover document above for current production changes.

### Viewing Logs

1. Go to **Containers**
2. Click on the container you want to inspect
3. Click **Logs**
4. Use the search and filter options to find specific log entries

### Restarting Containers

1. Go to **Containers**
2. Select the container(s) to restart
3. Click **Restart**

> [!NOTE]
> Restarting the database container will briefly interrupt backend connections, but they should reconnect automatically.

---

## Troubleshooting

### Backend Can't Connect to Database

**Symptoms:** Backend logs show connection errors

**Solutions:**
1. Verify both containers are on the same network (`vending_network`)
2. Check the `DATABASE_URL` environment variable is correct
3. Ensure the database container name matches what's in the connection string
4. Verify the database password matches in both containers

### Database Data Lost After Restart

**Symptoms:** Data disappears when container restarts

**Solutions:**
1. Verify the volume is properly mounted to `/var/lib/postgresql/data`
2. Check that you're using a **named volume**, not a bind mount
3. Go to **Volumes** and verify `postgres_data` exists and has data

### Port Already in Use

**Symptoms:** Can't start backend container, port conflict error

**Solutions:**
1. Change the **host port** in port mapping (e.g., `8080` → `8081`)
2. Stop any other services using that port
3. Check for zombie containers: `docker ps -a`

### Container Keeps Restarting

**Symptoms:** Container status shows constantly restarting

**Solutions:**
1. Check container logs for error messages
2. Verify environment variables are correct
3. Ensure the database is healthy before backend starts (use `depends_on` in compose)

---

## Security Best Practices

> [!CAUTION]
> Follow these security guidelines for production deployments:

1. **Use Strong Passwords**
   - Generate random passwords for `POSTGRES_PASSWORD`
   - Don't use default or simple passwords

2. **Use Portainer Secrets**
   - Store sensitive values in Portainer secrets instead of environment variables
   - Reference secrets in your compose file

3. **Limit Port Exposure**
   - Don't expose PostgreSQL port (5432) to the host
   - Only expose backend ports that need external access

4. **Regular Backups**
   - Set up automated database backups
   - Test restore procedures regularly

5. **Update Images**
   - Regularly update to latest stable PostgreSQL and backend images
   - Monitor for security vulnerabilities

6. **Network Isolation**
   - Use dedicated networks for different applications
   - Don't use the default bridge network

---

## Additional Resources

- [Portainer Documentation](https://docs.portainer.io/)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

## Support

If you encounter issues not covered in this guide:
1. Check container logs in Portainer
2. Verify network connectivity between containers
3. Ensure all environment variables are correctly set
4. Review the troubleshooting section above
