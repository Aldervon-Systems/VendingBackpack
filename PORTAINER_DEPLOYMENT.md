# Portainer Deployment Guide

This guide walks you through deploying the VendingBackpack application with PostgreSQL database using Portainer.

## Architecture Overview

The deployment consists of two separate Docker containers:
- **PostgreSQL Container**: Persistent database with named volume for data storage
- **Backend Container**: Flutter backend application that connects to PostgreSQL

Both containers communicate via a dedicated Docker network.

## Prerequisites

- Access to Portainer web interface
- Docker Compose file (see below)
- Backend Docker image built and available

## Deployment Method 1: Docker Compose Stack (Recommended)

This is the easiest method and allows you to manage both containers as a single unit.

### Step 1: Prepare the Docker Compose File

Create a `docker-compose.yml` file in your project root (already provided in this repository).

### Step 2: Deploy the Stack in Portainer

1. **Log into Portainer**
   - Navigate to your Portainer instance in your web browser
   - Log in with your credentials

2. **Navigate to Stacks**
   - Click on **Stacks** in the left sidebar
   - Click **+ Add stack** button

3. **Configure the Stack**
   - **Name**: `vending-backpack`
   - **Build method**: Choose one of the following:
     - **Web editor**: Copy and paste the contents of `docker-compose.yml`
     - **Upload**: Upload the `docker-compose.yml` file
     - **Repository**: Connect to your Git repository (recommended for updates)

4. **Set Environment Variables**
   
   Scroll down to the **Environment variables** section and add:
   
   | Name | Value |
   |------|-------|
   | `DB_PASSWORD` | Your secure database password |
   | `BACKEND_PORT` | `8080` (or your preferred port) |

   > [!IMPORTANT]
   > Use a strong password for `DB_PASSWORD`. This will be used by both the database and backend to authenticate.

5. **Deploy the Stack**
   - Click **Deploy the stack**
   - Wait for both containers to start (this may take a minute)

6. **Verify Deployment**
   - Go to **Containers** in the left sidebar
   - You should see two containers:
     - `vending-backpack-postgres-1` (or similar)
     - `vending-backpack-backend-1` (or similar)
   - Both should show status: **running** (green)

### Step 3: Access Your Application

- Your backend will be accessible at: `http://your-server-ip:8080`
- Replace `8080` with whatever port you configured

---

## Deployment Method 2: Manual Container Creation

If you prefer more granular control, you can create each container separately.

### Step 1: Create a Docker Network

1. Go to **Networks** in Portainer
2. Click **+ Add network**
3. **Name**: `vending_network`
4. **Driver**: `bridge`
5. Click **Create the network**

### Step 2: Deploy PostgreSQL Container

1. **Navigate to Containers**
   - Click **Containers** in the left sidebar
   - Click **+ Add container**

2. **Basic Configuration**
   - **Name**: `vending_backpack_db`
   - **Image**: `postgres:15-alpine`

3. **Network Configuration**
   - Scroll to **Network** section
   - Select `vending_network` from the dropdown

4. **Environment Variables**
   
   Click **+ add environment variable** for each:
   
   | Name | Value |
   |------|-------|
   | `POSTGRES_DB` | `vending_backpack` |
   | `POSTGRES_USER` | `vending_user` |
   | `POSTGRES_PASSWORD` | Your secure password |

5. **Volume Mapping**
   - Scroll to **Volumes** section
   - Click **+ map additional volume**
   - **Container**: `/var/lib/postgresql/data`
   - **Volume**: Click **+ volume** and create named volume `postgres_data`

6. **Restart Policy**
   - Scroll to **Restart policy**
   - Select **Unless stopped**

7. **Deploy Container**
   - Click **Deploy the container**
   - Wait for status to show **running**

### Step 3: Deploy Backend Container

1. **Navigate to Containers**
   - Click **Containers** in the left sidebar
   - Click **+ Add container**

2. **Basic Configuration**
   - **Name**: `vending_backpack_backend`
   - **Image**: Your backend image name (e.g., `your-registry/vending-backend:latest`)

3. **Network Configuration**
   - Scroll to **Network** section
   - Select `vending_network` (same network as database)

4. **Port Mapping**
   - Scroll to **Port mapping**
   - Click **+ publish a new network port**
   - **Host**: `8080` (external port)
   - **Container**: `8080` (internal port, adjust if different)

5. **Environment Variables**
   
   Click **+ add environment variable**:
   
   | Name | Value |
   |------|-------|
   | `DATABASE_URL` | `postgresql://vending_user:YOUR_PASSWORD@vending_backpack_db:5432/vending_backpack` |

   > [!WARNING]
   > Replace `YOUR_PASSWORD` with the same password you used for the PostgreSQL container.

6. **Restart Policy**
   - Select **Unless stopped**

7. **Deploy Container**
   - Click **Deploy the container**

---

## Post-Deployment Tasks

### Verify Database Connection

1. **Check Backend Logs**
   - Go to **Containers**
   - Click on `vending_backpack_backend`
   - Click **Logs**
   - Look for successful database connection messages

2. **Test Database Access** (Optional)
   - Click on `vending_backpack_db` container
   - Click **Console**
   - Click **Connect**
   - Run: `psql -U vending_user -d vending_backpack`
   - Type `\dt` to list tables (if migrations have run)

### Run Database Migrations

If your backend doesn't auto-migrate, you may need to run migrations manually:

1. Click on your backend container
2. Click **Console** → **Connect**
3. Run your migration command (depends on your backend framework)

---

## Managing Your Deployment

### Updating the Backend

**Using Stacks:**
1. Pull the latest image on the server
2. Go to **Stacks** → `vending-backpack`
3. Click **Update the stack**
4. Enable **Re-pull image and redeploy**
5. Click **Update**

**Using Manual Containers:**
1. Stop the backend container
2. Pull the latest image
3. Recreate the container with the same settings

> [!TIP]
> The database container doesn't need to be stopped when updating the backend.

### Backing Up the Database

1. **Via Portainer Console:**
   - Click on `vending_backpack_db` container
   - Click **Console** → **Connect**
   - Run: `pg_dump -U vending_user vending_backpack > /tmp/backup.sql`
   - Use **Exec Console** to copy the file out

2. **Via Volume Backup:**
   - Go to **Volumes**
   - Find `postgres_data` (or your stack's volume)
   - Use Portainer's backup feature or manually copy volume data

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
