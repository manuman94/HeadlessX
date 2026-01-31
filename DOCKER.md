# 🐳 HeadlessX - Docker Deployment Guide

Complete Docker setup for HeadlessX V2.0 with PostgreSQL, Backend API, and Frontend Dashboard.

## 📋 Prerequisites

- [Docker](https://docs.docker.com/get-docker/) 20.10+
- [Docker Compose](https://docs.docker.com/compose/install/) 2.0+
- 4GB+ RAM available for containers
- 10GB+ free disk space

## 🚀 Quick Start

### 1️⃣ Configure Environment

```bash
# Copy example environment file
cp .env.docker .env

# Edit .env with your configuration
# At minimum, change POSTGRES_PASSWORD for security
nano .env  # or use your preferred editor
```

### 2️⃣ Build and Start Services

```bash
# Build and start all services (Frontend, Backend, PostgreSQL)
docker-compose up -d --build

# View logs
docker-compose logs -f

# Or view logs for specific service
docker-compose logs -f backend
docker-compose logs -f frontend
```

### 3️⃣ Initialize Database

The database schema is automatically created on first backend startup via Prisma.

```bash
# Check backend logs to verify database initialization
docker-compose logs backend | grep -i prisma
```

### 4️⃣ Access the Application

| Service            | URL                   | Description                |
| ------------------ | --------------------- | -------------------------- |
| 🖥️ **Frontend**    | http://localhost:3000 | Dashboard UI               |
| 🔗 **Backend API** | http://localhost:3001 | REST API                   |
| 🗄️ **PostgreSQL**  | localhost:5432        | Database (optional expose) |

## 📦 Docker Services

### Architecture

```
┌─────────────────────────────────────────┐
│          Frontend (Next.js 16)          │
│              Port: 3000                 │
└───────────────┬─────────────────────────┘
                │
                ↓ HTTP Proxy
┌─────────────────────────────────────────┐
│      Backend (Express + Camoufox)       │
│              Port: 3001                 │
└───────────────┬─────────────────────────┘
                │
                ↓ PostgreSQL Protocol
┌─────────────────────────────────────────┐
│         PostgreSQL Database             │
│              Port: 5432                 │
└─────────────────────────────────────────┘
```

### Service Details

#### **PostgreSQL** (`postgres`)

- **Image**: `postgres:17-alpine`
- **Purpose**: Store scraping jobs, API keys, configurations, browser profiles
- **Health Check**: `pg_isready` (10s interval)
- **Volumes**:
    - `postgres_data`: Persists database files
- **Ports**: 5432 (configurable via `POSTGRES_PORT`)

#### **Backend** (`backend`)

- **Build**: Multi-stage from `./backend/Dockerfile`
- **Purpose**: API server with Camoufox browser automation
- **Depends On**: PostgreSQL (waits for healthy)
- **Health Check**: HTTP `/health` endpoint (30s interval, 60s start period)
- **Volumes**:
    - `browser_profiles`: Fingerprint profiles for stealth
    - `backend_logs`: Application logs
- **Ports**: 3001 (configurable via `BACKEND_PORT`)
- **Special**: 2GB shared memory for browser processes

#### **Frontend** (`frontend`)

- **Build**: Multi-stage from `./frontend/Dockerfile`
- **Purpose**: Next.js dashboard and API proxy
- **Depends On**: Backend (waits for healthy)
- **Health Check**: HTTP root endpoint (30s interval, 40s start period)
- **Ports**: 3000 (configurable via `FRONTEND_PORT`)

## ⚙️ Configuration

### Environment Variables

See [`.env.docker`](.env.docker) for all available options:

| Variable                       | Default                 | Description                |
| ------------------------------ | ----------------------- | -------------------------- |
| `POSTGRES_USER`                | `headlessx`             | PostgreSQL username        |
| `POSTGRES_PASSWORD`            | ⚠️ **Change me**        | PostgreSQL password        |
| `POSTGRES_DB`                  | `headlessx`             | Database name              |
| `BACKEND_PORT`                 | `3001`                  | Backend API port           |
| `FRONTEND_PORT`                | `3000`                  | Frontend UI port           |
| `NEXT_PUBLIC_API_URL`          | `http://localhost:3001` | External API URL (browser) |
| `NEXT_PUBLIC_API_URL_INTERNAL` | `http://backend:3001`   | Internal API URL (Docker)  |
| `LOG_LEVEL`                    | `info`                  | Backend logging level      |

> ⚠️ **Security**: Always change `POSTGRES_PASSWORD` before deploying to production!

### Dashboard Settings

Most scraping configurations are managed via the **Settings** page in the dashboard:

- **Browser Configuration**
    - Headless mode
    - Browser timeout
    - Max concurrent jobs
- **Camoufox Engine**
    - OS fingerprinting
    - Human behavior simulation
    - GeoIP spoofing
    - WebRTC blocking
- **Proxies**
    - Proxy rotation
    - Authentication
    - Geographic targeting

## 🛠️ Common Commands

### Service Management

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart a specific service
docker-compose restart backend

# View service status
docker-compose ps

# View logs (all services)
docker-compose logs -f

# View logs (specific service)
docker-compose logs -f backend
```

### Database Management

```bash
# Access PostgreSQL CLI
docker-compose exec postgres psql -U headlessx -d headlessx

# Backup database
docker-compose exec postgres pg_dump -U headlessx headlessx > backup.sql

# Restore database
cat backup.sql | docker-compose exec -T postgres psql -U headlessx -d headlessx

# Reset database (⚠️ destructive)
docker-compose down -v  # Removes volumes
docker-compose up -d
```

### Prisma Management

```bash
# Run Prisma migrations
docker-compose exec backend npx prisma migrate deploy

# Open Prisma Studio
docker-compose exec backend npx prisma studio
# Then access http://localhost:5555

# Regenerate Prisma Client
docker-compose exec backend npx prisma generate
```

### Troubleshooting

```bash
# View container resource usage
docker stats

# Inspect container
docker-compose exec backend sh
docker-compose exec frontend sh

# Check health status
docker-compose ps

# View full container logs
docker-compose logs --tail=1000 backend

# Rebuild specific service
docker-compose up -d --build --force-recreate backend
```

## 🔄 Updates and Maintenance

### Update Application

```bash
# Pull latest code
git pull origin main

# Rebuild and restart services
docker-compose down
docker-compose up -d --build

# Or rebuild specific service
docker-compose up -d --build backend
```

### Clean Up

```bash
# Stop and remove containers (keeps volumes)
docker-compose down

# Remove containers AND volumes (⚠️ deletes data)
docker-compose down -v

# Remove unused images
docker image prune -a

# Remove all unused resources
docker system prune -a --volumes
```

## 🌐 Production Deployment

### Recommended Changes

1. **Use strong passwords**

    ```env
    POSTGRES_PASSWORD=<long random string>
    ```

2. **Set production URLs**

    ```env
    NEXT_PUBLIC_API_URL=https://api.yourdomain.com
    FRONTEND_URL=https://app.yourdomain.com
    ```

3. **Don't expose PostgreSQL port**

    ```yaml
    # Remove from docker-compose.yml
    # ports:
    #   - "5432:5432"
    ```

4. **Use Docker secrets** (Swarm/Kubernetes)

    ```yaml
    secrets:
        postgres_password:
            external: true
    ```

5. **Add reverse proxy** (Nginx/Traefik)
    - SSL/TLS termination
    - Rate limiting
    - Load balancing

### Example Nginx Configuration

```nginx
# Frontend
server {
    listen 443 ssl http2;
    server_name app.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# Backend API
server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;

        # SSE support
        proxy_buffering off;
        proxy_cache off;
        chunked_transfer_encoding on;
    }
}
```

## 🐛 Troubleshooting

### Common Issues

#### **"Backend can't connect to database"**

- ✅ Verify PostgreSQL is healthy: `docker-compose ps`
- ✅ Check `DATABASE_URL` in backend logs
- ✅ Ensure `POSTGRES_PASSWORD` matches in `.env`

#### **"Frontend shows 502 Bad Gateway"**

- ✅ Check backend health: `docker-compose ps`
- ✅ Verify `NEXT_PUBLIC_API_URL_INTERNAL=http://backend:3001`
- ✅ Review backend logs: `docker-compose logs backend`

#### **"Browser timeout errors"**

- ✅ Increase shared memory: `shm_size: 2gb` (already configured)
- ✅ Adjust browser timeout in Dashboard Settings
- ✅ Check container resources: `docker stats`

#### **"Out of memory"**

- ✅ Increase Docker memory limit (Docker Desktop → Settings → Resources)
- ✅ Reduce max concurrent jobs in Dashboard Settings
- ✅ Monitor with: `docker stats`

#### **"Port already in use"**

```bash
# Change ports in .env
FRONTEND_PORT=4000
BACKEND_PORT=4001
```

### Get Help

If you encounter issues:

1. **Check logs**: `docker-compose logs -f`
2. **Verify health**: `docker-compose ps`
3. **Test connectivity**:

    ```bash
    # From frontend to backend
    docker-compose exec frontend curl http://backend:3001/health

    # From backend to database
    docker-compose exec backend sh -c 'apt-get update && apt-get install -y postgresql-client && psql $DATABASE_URL -c "SELECT 1"'
    ```

## 📊 Monitoring

### Health Checks

All services include health checks:

```bash
# View health status
docker-compose ps

# Detailed health info
docker inspect headlessx-backend --format='{{json .State.Health}}' | jq

# Test endpoints manually
curl http://localhost:3001/health  # Backend
curl http://localhost:3000         # Frontend
```

### Logs

```bash
# Follow all logs
docker-compose logs -f

# Filter by service
docker-compose logs -f backend frontend

# Last 100 lines
docker-compose logs --tail=100

# Since timestamp
docker-compose logs --since 2026-01-31T10:00:00
```

## 📝 Additional Resources

- [HeadlessX Documentation](../README.md)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Camoufox GitHub](https://github.com/AurelicButter/camoufox)

---

**🦊 HeadlessX V2.0 — Undetectable by Design**

_Need help? Open an issue on GitHub_
