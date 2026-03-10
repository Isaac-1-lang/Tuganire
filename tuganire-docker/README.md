# Tuganire Docker Setup

Complete Docker configuration for running Tuganire with PostgreSQL and Nginx.

## Prerequisites

- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- Docker Compose
- At least 2GB free RAM

## Quick Start

### Windows

```cmd
cd tuganire-docker
copy .env.example tuganire.env
REM Edit tuganire.env and change passwords/secrets
start.bat
```

### Linux/Mac

```bash
cd tuganire-docker
cp .env.example tuganire.env
# Edit tuganire.env and change passwords/secrets
chmod +x start.sh
./start.sh
```

### Manual Start

```bash
cd tuganire-docker
docker-compose up -d --build
```

## Access Points

- **Application (via Nginx)**: http://localhost
- **Application (direct)**: http://localhost:8080
- **PostgreSQL**: localhost:5432

## Services

### db (PostgreSQL 15)
- Database server with persistent storage
- Health checks enabled
- Automatic restart on failure

### app (Tomcat 10 + Tuganire)
- Multi-stage build (Maven + Tomcat)
- Waits for database to be healthy
- Auto-restart enabled

### nginx (Reverse Proxy)
- WebSocket support for real-time chat
- Load balancing ready
- SSL/TLS ready (configure in production)

## Configuration

### Environment Variables

Edit `tuganire.env`:

```env
# Database
DB_URL=jdbc:postgresql://db:5432/tuganire
DB_USERNAME=tuganire_user
DB_PASSWORD=your_secure_password

# JWT
JWT_SECRET=your_long_random_secret_key
JWT_EXPIRY_HOURS=24

# Hibernate
HIBERNATE_HBM2DDL_AUTO=update  # or 'validate' for production
```

### Important Security Notes

⚠️ **Before deploying to production:**

1. Change all default passwords in `tuganire.env`
2. Generate a strong JWT secret (at least 32 characters)
3. Set `HIBERNATE_HBM2DDL_AUTO=validate`
4. Use `docker-compose.prod.yml` for production
5. Configure SSL certificates for HTTPS

## Common Commands

```bash
# Start services
docker-compose up -d

# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f app
docker-compose logs -f db

# Stop services
docker-compose down

# Stop and remove all data (WARNING: deletes database)
docker-compose down -v

# Rebuild after code changes
docker-compose up -d --build

# Restart a specific service
docker-compose restart app

# Access database shell
docker-compose exec db psql -U tuganire_user -d tuganire

# Check service status
docker-compose ps

# View resource usage
docker stats
```

## Development Workflow

1. **Make code changes** in your IDE
2. **Rebuild and restart**:
   ```bash
   docker-compose up -d --build app
   ```
3. **View logs**:
   ```bash
   docker-compose logs -f app
   ```

## Production Deployment

### Using Production Compose File

```bash
# Use production configuration
docker-compose -f docker-compose.prod.yml up -d --build

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

### Production Checklist

- [ ] Change all passwords in `tuganire.env`
- [ ] Generate strong JWT secret
- [ ] Set `HIBERNATE_HBM2DDL_AUTO=validate`
- [ ] Configure SSL certificates
- [ ] Set up database backups
- [ ] Configure firewall rules
- [ ] Set up monitoring and logging
- [ ] Use production compose file
- [ ] Test WebSocket connections
- [ ] Configure domain name and DNS

### SSL/HTTPS Setup

1. Obtain SSL certificates (Let's Encrypt recommended)
2. Place certificates in `tuganire-docker/ssl/`
3. Update `nginx.conf` to use SSL
4. Restart nginx: `docker-compose restart nginx`

## Troubleshooting

### Application won't start

```bash
# Check logs
docker-compose logs app

# Common issues:
# - Database not ready: wait 30 seconds and check again
# - Port conflict: stop other services using port 8080
# - Build errors: check Maven dependencies
```

### Database connection errors

```bash
# Check database status
docker-compose exec db pg_isready -U tuganire_user

# Check database logs
docker-compose logs db

# Verify connection settings in tuganire.env
```

### WebSocket connection issues

```bash
# Check nginx logs
docker-compose logs nginx

# Verify WebSocket upgrade headers in nginx.conf
# Test direct connection: ws://localhost:8080/ws/chat
```

### Port already in use

```bash
# Find process using port 8080
# Windows:
netstat -ano | findstr :8080

# Linux/Mac:
lsof -i :8080

# Change port in docker-compose.yml:
ports:
  - "8081:8080"  # Use 8081 instead
```

### Clean slate rebuild

```bash
# Stop everything and remove volumes
docker-compose down -v

# Remove images
docker-compose down --rmi all

# Rebuild from scratch
docker-compose build --no-cache
docker-compose up -d
```

## Database Backup

### Manual Backup

```bash
# Create backup
docker-compose exec db pg_dump -U tuganire_user tuganire > backup_$(date +%Y%m%d).sql

# Restore backup
docker-compose exec -T db psql -U tuganire_user tuganire < backup_20240309.sql
```

### Automated Backups

Add to crontab (Linux/Mac):

```bash
# Daily backup at 2 AM
0 2 * * * cd /path/to/tuganire-docker && docker-compose exec -T db pg_dump -U tuganire_user tuganire > backups/backup_$(date +\%Y\%m\%d).sql
```

## Performance Tuning

### Increase Java Heap Size

Edit `docker-compose.yml`:

```yaml
app:
  environment:
    - JAVA_OPTS=-Xms512m -Xmx2g
```

### PostgreSQL Tuning

Create `tuganire-docker/postgresql.conf` and mount it:

```yaml
db:
  volumes:
    - ./postgresql.conf:/etc/postgresql/postgresql.conf
```

## Monitoring

### Health Checks

```bash
# Check all services
docker-compose ps

# Manual health check
curl http://localhost/health
```

### Resource Usage

```bash
# Real-time stats
docker stats

# Disk usage
docker system df
```

## Support

For issues and questions:
- Check logs: `docker-compose logs -f`
- Review this README
- Check Docker and Docker Compose versions
- Ensure ports 80, 8080, 5432 are available
