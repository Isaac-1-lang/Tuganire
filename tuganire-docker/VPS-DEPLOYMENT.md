# VPS Deployment Guide for Tuganire

Complete step-by-step guide to deploy Tuganire on a VPS (Ubuntu/Debian).

## Prerequisites

- VPS with Ubuntu 20.04+ or Debian 11+
- Root or sudo access
- Domain name (optional but recommended)
- Neon database already set up

## Step 1: Prepare Your VPS

### 1.1 Connect to VPS

```bash
ssh root@your-vps-ip
# or
ssh your-username@your-vps-ip
```

### 1.2 Update System

```bash
sudo apt update
sudo apt upgrade -y
```

### 1.3 Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (optional, to run without sudo)
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose -y

# Verify installation
docker --version
docker-compose --version
```

### 1.4 Install Git

```bash
sudo apt install git -y
```

### 1.5 Configure Firewall

```bash
# Allow SSH (important - don't lock yourself out!)
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

## Step 2: Deploy Application

### 2.1 Clone Repository

```bash
# Create app directory
mkdir -p /opt/tuganire
cd /opt/tuganire

# Clone your repository
git clone https://github.com/your-username/tuganire.git .
# or upload files via SCP/SFTP

# Navigate to docker directory
cd tuganire-docker
```

### 2.2 Configure Environment

**Option A: Use existing production config**
```bash
# The docker-compose.prod.yml already has your Neon credentials
# Just verify they're correct
cat docker-compose.prod.yml
```

**Option B: Use environment file (more secure)**
```bash
# Create production env file
nano .env.production

# Add these values:
DB_URL=jdbc:postgresql://ep-lively-sea-aj87r78n-pooler.c-3.us-east-2.aws.neon.tech/neondb?sslmode=require
DB_USERNAME=neondb_owner
DB_PASSWORD=npg_oQ8cFRbwjaq6
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_EXPIRY_HOURS=24
HIBERNATE_HBM2DDL_AUTO=validate
```

### 2.3 Build and Start

```bash
# Build and start in detached mode
docker-compose -f docker-compose.prod.yml up -d --build

# Check status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

### 2.4 Verify Deployment

```bash
# Check if app is running
curl http://localhost:8080

# Check containers
docker ps

# Check logs for errors
docker-compose -f docker-compose.prod.yml logs app
```

## Step 3: Configure Domain (Optional)

### 3.1 Point Domain to VPS

In your domain registrar (Namecheap, GoDaddy, etc.):

```
Type: A Record
Name: @ (or your subdomain)
Value: your-vps-ip
TTL: 300 (or automatic)
```

Wait 5-60 minutes for DNS propagation.

### 3.2 Update Nginx Configuration

```bash
cd /opt/tuganire/tuganire-docker
nano nginx.conf
```

Update server_name:
```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    # ... rest of config
}
```

Restart nginx:
```bash
docker-compose -f docker-compose.prod.yml restart nginx
```

## Step 4: Set Up SSL/HTTPS (Recommended)

### 4.1 Install Certbot

```bash
sudo apt install certbot -y
```

### 4.2 Stop Nginx temporarily

```bash
docker-compose -f docker-compose.prod.yml stop nginx
```

### 4.3 Get SSL Certificate

```bash
sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com
```

Follow prompts and enter your email.

### 4.4 Copy Certificates

```bash
# Create SSL directory
mkdir -p /opt/tuganire/tuganire-docker/ssl

# Copy certificates
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /opt/tuganire/tuganire-docker/ssl/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem /opt/tuganire/tuganire-docker/ssl/

# Set permissions
sudo chmod 644 /opt/tuganire/tuganire-docker/ssl/*.pem
```

### 4.5 Update Nginx for HTTPS

```bash
nano /opt/tuganire/tuganire-docker/nginx-ssl.conf
```

Add this configuration:
```nginx
events {
    worker_connections 1024;
}

http {
    upstream tomcat {
        server app:8080;
    }

    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }

    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name your-domain.com www.your-domain.com;
        return 301 https://$server_name$request_uri;
    }

    # HTTPS Server
    server {
        listen 443 ssl http2;
        server_name your-domain.com www.your-domain.com;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        client_max_body_size 10M;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        location /ws/ {
            proxy_pass http://tomcat;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_read_timeout 86400;
        }

        # Main application
        location / {
            proxy_pass http://tomcat;
            proxy_redirect off;
        }
    }
}
```

Update docker-compose.prod.yml to use new config:
```bash
nano docker-compose.prod.yml
```

Change nginx volumes:
```yaml
volumes:
  - ./nginx-ssl.conf:/etc/nginx/nginx.conf:ro
  - ./ssl:/etc/nginx/ssl:ro
```

### 4.6 Restart Services

```bash
docker-compose -f docker-compose.prod.yml restart nginx
```

### 4.7 Set Up Auto-Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Add cron job for auto-renewal
sudo crontab -e

# Add this line (runs twice daily):
0 0,12 * * * certbot renew --quiet && docker-compose -f /opt/tuganire/tuganire-docker/docker-compose.prod.yml restart nginx
```

## Step 5: Monitoring & Maintenance

### 5.1 View Logs

```bash
# All logs
docker-compose -f docker-compose.prod.yml logs -f

# App logs only
docker-compose -f docker-compose.prod.yml logs -f app

# Last 100 lines
docker-compose -f docker-compose.prod.yml logs --tail=100 app
```

### 5.2 Restart Services

```bash
# Restart all
docker-compose -f docker-compose.prod.yml restart

# Restart app only
docker-compose -f docker-compose.prod.yml restart app
```

### 5.3 Update Application

```bash
cd /opt/tuganire

# Pull latest code
git pull origin main

# Rebuild and restart
cd tuganire-docker
docker-compose -f docker-compose.prod.yml up -d --build

# Check logs
docker-compose -f docker-compose.prod.yml logs -f app
```

### 5.4 Check Resource Usage

```bash
# Container stats
docker stats

# Disk usage
df -h

# Memory usage
free -h

# Docker disk usage
docker system df
```

### 5.5 Backup Strategy

```bash
# Create backup script
nano /opt/tuganire/backup.sh
```

Add:
```bash
#!/bin/bash
BACKUP_DIR="/opt/tuganire/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup application files
tar -czf $BACKUP_DIR/tuganire_$DATE.tar.gz /opt/tuganire

# Note: Database is on Neon - use their backup features
# Or export via pg_dump if needed

# Keep only last 7 backups
ls -t $BACKUP_DIR/tuganire_*.tar.gz | tail -n +8 | xargs rm -f

echo "Backup completed: $BACKUP_DIR/tuganire_$DATE.tar.gz"
```

Make executable and schedule:
```bash
chmod +x /opt/tuganire/backup.sh

# Add to crontab (daily at 2 AM)
crontab -e
0 2 * * * /opt/tuganire/backup.sh
```

## Step 6: Troubleshooting

### App won't start

```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs app

# Check if port is available
sudo netstat -tulpn | grep 8080

# Restart
docker-compose -f docker-compose.prod.yml restart app
```

### Database connection issues

```bash
# Test connection from VPS
curl -v https://ep-lively-sea-aj87r78n-pooler.c-3.us-east-2.aws.neon.tech

# Check environment variables
docker-compose -f docker-compose.prod.yml exec app env | grep DB_

# Check Neon dashboard for connection limits
```

### WebSocket not working

```bash
# Check nginx logs
docker-compose -f docker-compose.prod.yml logs nginx

# Verify WebSocket upgrade headers in nginx.conf
# Test WebSocket: wss://your-domain.com/ws/chat
```

### Out of disk space

```bash
# Clean up Docker
docker system prune -a

# Remove old images
docker image prune -a

# Check disk usage
df -h
```

### High memory usage

```bash
# Check container stats
docker stats

# Restart app to free memory
docker-compose -f docker-compose.prod.yml restart app

# Increase Java heap if needed (in docker-compose.prod.yml):
environment:
  - JAVA_OPTS=-Xms512m -Xmx1g
```

## Step 7: Security Checklist

- [ ] Firewall configured (UFW)
- [ ] SSH key authentication enabled
- [ ] Root login disabled
- [ ] SSL/HTTPS configured
- [ ] Strong JWT secret set
- [ ] Database uses SSL (Neon default)
- [ ] Regular backups scheduled
- [ ] Monitoring set up
- [ ] Fail2ban installed (optional)
- [ ] Auto-updates enabled

### Install Fail2ban (Optional)

```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## Quick Commands Reference

```bash
# Start
docker-compose -f docker-compose.prod.yml up -d

# Stop
docker-compose -f docker-compose.prod.yml down

# Restart
docker-compose -f docker-compose.prod.yml restart

# Logs
docker-compose -f docker-compose.prod.yml logs -f

# Update
git pull && docker-compose -f docker-compose.prod.yml up -d --build

# Status
docker-compose -f docker-compose.prod.yml ps

# Clean up
docker system prune -a
```

## Support

If you encounter issues:
1. Check logs: `docker-compose -f docker-compose.prod.yml logs -f`
2. Verify Neon database is accessible
3. Check firewall rules: `sudo ufw status`
4. Verify DNS propagation: `nslookup your-domain.com`
5. Test SSL: `curl -I https://your-domain.com`

## Next Steps

1. Set up monitoring (Uptime Robot, Pingdom)
2. Configure CDN (Cloudflare)
3. Set up log aggregation
4. Configure automated backups
5. Set up staging environment
