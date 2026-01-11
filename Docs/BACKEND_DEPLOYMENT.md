# Backend Deployment Guide - Portainer GUI

This guide provides **step-by-step instructions** for deploying the VendingBackpack backend API using the Portainer web interface.

## Overview

You'll be deploying two containers:
1. **PostgreSQL Database** - Persistent data storage
2. **Backend API** - FastAPI application

## Prerequisites

- Access to Portainer web interface
- Backend Docker image built (see Building the Image section below)
- PostgreSQL password ready

---

## Part 1: Building the Backend Docker Image

Before deploying in Portainer, you need to build the Docker image.

### Option A: Build Locally and Push to Registry

1. **Build the image:**
   ```bash
   cd /path/to/VendingBackpack/backend
   docker build -t vending-backend:latest .
   ```

2. **Tag for your registry** (if using Docker Hub or private registry):
   ```bash
   docker tag vending-backend:latest your-username/vending-backend:latest
   ```

3. **Push to registry:**
   ```bash
   docker push your-username/vending-backend:latest
   ```

### Option B: Build on the Server

1. **Copy backend folder to server:**
   ```bash
   scp -r backend/ user@server-ip:/path/to/backend/
   ```

2. **SSH into server and build:**
   ```bash
   ssh user@server-ip
   cd /path/to/backend
   docker build -t vending-backend:latest .
   ```

---

## Part 2: Deploy PostgreSQL Database

### Step 1: Create Docker Network

1. **Log into Portainer** at `http://your-server-ip:9000`

2. **Navigate to Networks:**
   - Click **Networks** in the left sidebar
   - Click **+ Add network** button

3. **Configure Network:**
   - **Name:** `vending_network`
   - **Driver:** `bridge`
   - Leave other settings as default
   - Click **Create the network**

### Step 2: Create PostgreSQL Container

1. **Navigate to Containers:**
   - Click **Containers** in the left sidebar
   - Click **+ Add container** button

2. **Basic Configuration:**
   - **Name:** `vending_db`
   - **Image:** `postgres:15-alpine`
   - Click **Publish a new network port** if you want external access (optional, not recommended)

3. **Network Configuration:**
   - Scroll down to **Network** section
   - **Network:** Select `vending_network` from dropdown

4. **Environment Variables:**
   
   Scroll to **Environment variables** section and click **+ add environment variable** for each:
   
   | Name | Value |
   |------|-------|
   | `POSTGRES_DB` | `vending_db` |
   | `POSTGRES_USER` | `vending_user` |
   | `POSTGRES_PASSWORD` | `your_secure_password_here` |
   
   > [!IMPORTANT]
   > **Remember this password!** You'll need it for the backend container.

5. **Volume Mapping:**
   
   Scroll to **Volumes** section:
   - Click **+ map additional volume**
   - **Container path:** `/var/lib/postgresql/data`
   - **Volume:** Click the volume icon and select **Create new volume**
     - **Volume name:** `vending_db_data`
     - Click **Create**

6. **Restart Policy:**
   - Scroll to **Restart policy**
   - Select **Unless stopped**

7. **Deploy:**
   - Click **Deploy the container** at the bottom
   - Wait for status to show **running** (green)

8. **Verify Database:**
   - Click on the `vending_db` container
   - Click **Logs** tab
   - You should see: `database system is ready to accept connections`

---

## Part 3: Deploy Backend API Container

### Step 1: Create Backend Container

1. **Navigate to Containers:**
   - Click **Containers** in the left sidebar
   - Click **+ Add container**

2. **Basic Configuration:**
   - **Name:** `vending_backend`
   - **Image:** 
     - If using registry: `your-username/vending-backend:latest`
     - If built locally: `vending-backend:latest`

3. **Port Mapping:**
   
   Scroll to **Port mapping** section:
   - Click **+ publish a new network port**
   - **Host:** `8080` (external port)
   - **Container:** `8080` (internal port)
   - **Protocol:** `TCP`

4. **Network Configuration:**
   - Scroll to **Network** section
   - **Network:** Select `vending_network` (same as database!)

5. **Environment Variables:**
   
   Scroll to **Environment variables** and add:
   
   | Name | Value |
   |------|-------|
   | `DATABASE_URL` | `postgresql://vending_user:your_password@vending_db:5432/vending_db` |
   | `ENVIRONMENT` | `production` |
   | `DEBUG` | `False` |
   
   > [!WARNING]
   > Replace `your_password` with the **same password** you used for PostgreSQL!
   > 
   > Note: The hostname is `vending_db` (the database container name), not an IP address.

6. **Restart Policy:**
   - Select **Unless stopped**

7. **Deploy:**
   - Click **Deploy the container**
   - Wait for status to show **running**

### Step 2: Verify Backend is Running

1. **Check Logs:**
   - Click on `vending_backend` container
   - Click **Logs** tab
   - Look for:
     ```
     INFO:     Started server process
     INFO:     Waiting for application startup.
     INFO:     Application startup complete.
     ```

2. **Test API:**
   - Open browser to: `http://your-server-ip:8080`
   - You should see:
     ```json
     {
       "status": "healthy",
       "service": "VendingBackpack API",
       "version": "1.0.0",
       "database": "connected"
     }
     ```

3. **Access API Documentation:**
   - Swagger UI: `http://your-server-ip:8080/docs`
   - ReDoc: `http://your-server-ip:8080/redoc`

---

## Part 4: Testing the API

### Using Swagger UI

1. **Navigate to:** `http://your-server-ip:8080/docs`

2. **Create a Test Item:**
   - Expand `POST /api/items`
   - Click **Try it out**
   - Enter JSON:
     ```json
     {
       "name": "Coca Cola",
       "description": "Classic Coke 12oz",
       "price": 1.50,
       "quantity": 10,
       "slot_number": "A1",
       "is_available": true
     }
     ```
   - Click **Execute**
   - Should return `201 Created`

3. **Get All Items:**
   - Expand `GET /api/items`
   - Click **Try it out** → **Execute**
   - Should see your created item

---

## Managing Your Deployment

### Viewing Logs

**Database Logs:**
1. Go to **Containers**
2. Click `vending_db`
3. Click **Logs** tab

**Backend Logs:**
1. Go to **Containers**
2. Click `vending_backend`
3. Click **Logs** tab

### Restarting Containers

1. Go to **Containers**
2. Check the box next to container name
3. Click **Restart** button

> [!TIP]
> If you restart the database, the backend will automatically reconnect.

### Updating the Backend

1. **Build new image** with updated code
2. **Stop the backend container:**
   - Check box next to `vending_backend`
   - Click **Stop**
3. **Remove the container:**
   - Click **Remove**
4. **Recreate** following Part 3 steps with new image

> [!NOTE]
> The database container doesn't need to be touched when updating backend.

### Backing Up the Database

**Method 1: Using Portainer Console**

1. Click on `vending_db` container
2. Click **Console** tab
3. Click **Connect** (select `/bin/sh`)
4. Run:
   ```bash
   pg_dump -U vending_user vending_db > /tmp/backup.sql
   ```
5. Copy file out using `docker cp` from your server

**Method 2: Volume Backup**

1. Go to **Volumes**
2. Find `vending_db_data`
3. Use Portainer's backup feature or manually copy volume data

---

## Troubleshooting

### Backend Can't Connect to Database

**Check:**
1. Both containers are on `vending_network`
2. Database container name is `vending_db`
3. `DATABASE_URL` uses `vending_db` as hostname (not IP)
4. Password matches in both containers

**Fix:**
- View backend logs for specific error
- Verify database is running and healthy
- Check environment variables are correct

### Port 8080 Already in Use

**Solution:**
- Change host port to something else (e.g., `8081:8080`)
- Or stop the service using port 8080

### Container Keeps Restarting

**Check:**
1. View container logs for errors
2. Verify environment variables are correct
3. Ensure database is healthy before backend starts

**Common Issues:**
- Wrong database password
- Database not ready when backend starts (wait 30 seconds)
- Missing environment variables

### Database Data Lost

**Verify:**
1. Volume `vending_db_data` exists in **Volumes** section
2. Volume is mounted to `/var/lib/postgresql/data`
3. Using named volume, not bind mount

---

## Environment Variables Reference

### Backend Container

| Variable | Required | Example | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | Yes | `postgresql://user:pass@host:5432/db` | Full database connection string |
| `DB_URI` | No | Same as DATABASE_URL | Alternative to DATABASE_URL |
| `ENVIRONMENT` | No | `production` | Environment name |
| `DEBUG` | No | `True` | Enable debug logs |
| `DEMO_MODE` | No | `False` | Set to `true` to enable hardware simulation and demo data |
| `API_HOST` | No | `0.0.0.0` | Internal bind address |
| `API_PORT` | No | `8080` | API port (internal) |

### Database Container

| Variable | Required | Example | Description |
|----------|----------|---------|-------------|
| `POSTGRES_DB` | Yes | `vending_db` | Database name |
| `POSTGRES_USER` | Yes | `vending_user` | Database user |
| `POSTGRES_PASSWORD` | Yes | `secure_password` | Database password |

---

## Security Best Practices

> [!CAUTION]
> Follow these for production deployments:

1. **Strong Passwords:**
   - Use generated passwords (20+ characters)
   - Don't reuse passwords

2. **Don't Expose Database Port:**
   - PostgreSQL should only be accessible within Docker network
   - Never publish port 5432 to host

3. **Use Portainer Secrets:**
   - Store passwords as secrets instead of plain environment variables
   - Reference secrets in container configuration

4. **Restrict API Access:**
   - Use reverse proxy (nginx/Traefik)
   - Add authentication middleware
   - Update CORS settings in `main.py`

5. **Regular Backups:**
   - Automate database backups
   - Test restore procedures

6. **Monitor Logs:**
   - Regularly check for errors
   - Set up log aggregation

---

## Next Steps

1. **Configure Flutter App** to connect to `http://your-server-ip:8080`
2. **Set up reverse proxy** (nginx) for HTTPS
3. **Add authentication** to API endpoints
4. **Implement monitoring** (Prometheus/Grafana)
5. **Set up automated backups**

---

## Demo Mode (frontend) 🔧

If you are using demo mode (DEMO_MODE=true) the frontend includes a small helper script that attempts to fetch the demo DB from sensible hosts and provides a cache-clear helper.

Steps to ensure deployed web clients use the server demo DB:

1. Make sure the mock server is running and serving `/__demo_api/_db` (default dev host: `http://127.0.0.1:8000`).
2. The built web assets include `demo-mode.js` which will try same-origin first, then `127.0.0.1:8000` and `localhost:8000`.
3. If your deployed site serves static assets from a different host, either:
   - Add a small meta tag to your `index.html` or update `demo-mode.js` to include your deployed demo API host, or
   - Configure your webserver to proxy `/_demo_api/` to the demo API host so the client can use the relative path `/__demo_api/_db`.
4. When testing, clear client caches (localStorage and service worker caches) and reload the page. You can also use the helper exposed on the page by calling `window.demoMode.clearDemoCache()` in the browser console or visiting `/__demo_api/clear_demo_cache`.

Tips:
- To re-generate the demo DB locally run: `python3 v1/mock_server/generate_demo_db.py` (this writes `v1/mock_server/demo_db.json`).
- After changing `demo-mode.js`, rebuild and redeploy your static assets (e.g., `flutter build web`) so clients pick up the new script.


---

## Support

For issues:
1. Check container logs in Portainer
2. Verify network connectivity
3. Review environment variables
4. Check the troubleshooting section above
