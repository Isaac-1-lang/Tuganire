# Tuganire Deployment Guide

## Three Deployment Options

### 1. Local Development (No Docker)
**Use when:** Developing in your IDE with local PostgreSQL

**Setup:**
- PostgreSQL running on localhost:5432
- Database: `tuganire_data_storage`
- Run from IDE (IntelliJ/Eclipse) or local Tomcat

**Configuration:** Uses `.env` file in project root
```env
DB_URL=jdbc:postgresql://localhost:5432/tuganire_data_storage
DB_USERNAME=postgres
DB_PASSWORD=121402pr0732021
```

---

### 2. Docker Development (Containerized DB)
**Use when:** Testing full Docker setup locally

**Setup:**
```bash
cd tuganire-docker
docker-compose up -d
```

**What it does:**
- Creates PostgreSQL container (port 5433)
- Creates Tomcat app container (port 8080)
- Creates Nginx container (port 80)
- All containers networked together

**Access:**
- App: http://localhost or http://localhost:8080
- Database: localhost:5433

**Stop:**
```bash
docker-compose down
# Or to delete database:
docker-compose down -v
```

---

### 3. Docker with Local PostgreSQL
**Use when:** Want containerized app but use existing local database

**Setup:**
```bash
cd tuganire-docker
docker-compose -f docker-compose.local-db.yml up -d
```

**Requirements:**
- Local PostgreSQL must be running
- Database `tuganire_data_storage` must exist

**Access:**
- App: http://localhost or http://localhost:8080

---

### 4. Production (VPS with Neon Cloud DB)
**Use when:** Deploying to production server

**Setup:**
```bash
cd tuganire-docker

# First time: Run database migrations
docker-compose -f docker-compose.prod.yml up -d

# Check logs
docker-compose -f docker-compose.prod.yml logs -f
```

**What it does:**
- Connects to Neon cloud database
- Uses `validate` for Hibernate (no auto schema changes)
- Production-ready configuration

**Access:**
- App: http://your-vps-ip or http://your-domain.com

**Important:**
- Set up SSL certificates for HTTPS
- Configure firewall
- Set up monitoring

---

## Quick Reference

| Scenario | Command | Database | Port |
|----------|---------|----------|------|
| Local Dev | Run in IDE | localhost:5432 | 8080 |
| Docker Dev | `docker-compose up -d` | Container (5433) | 8080 |
| Docker + Local DB | `docker-compose -f docker-compose.local-db.yml up -d` | localhost:5432 | 8080 |
| Production | `docker-compose -f docker-compose.prod.yml up -d` | Neon Cloud | 8080 |

---

## Common Commands

```bash
# View logs
docker-compose logs -f app

# Restart app only
docker-compose restart app

# Rebuild after code changes
docker-compose up -d --build

# Stop everything
docker-compose down

# Check status
docker-compose ps

# Access database (Docker Dev only)
docker-compose exec db psql -U postgres -d tuganire_data_storage
```

---

## Troubleshooting

### Port 8080 already in use
```bash
# Stop local Tomcat or change Docker port in docker-compose.yml
ports:
  - "8081:8080"  # Use 8081 instead
```

### Database connection failed
```bash
# Check database is running
docker-compose ps

# Check logs
docker-compose logs db

# Verify credentials in docker-compose.yml match your database
```

### App won't start
```bash
# Check logs
docker-compose logs app

# Rebuild
docker-compose down
docker-compose up -d --build
```

---

## Migration Path

**Development → Production:**

1. Develop locally (no Docker)
2. Test with Docker locally: `docker-compose up -d`
3. Deploy to VPS: `docker-compose -f docker-compose.prod.yml up -d`

**Important:** Before production:
- Change `HIBERNATE_HBM2DDL_AUTO` to `validate`
- Set up database backups
- Configure SSL/HTTPS
- Set strong JWT secret
