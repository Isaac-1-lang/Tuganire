# Quick VPS Deployment Checklist

## Prerequisites
- [ ] VPS with Ubuntu 20.04+ (DigitalOcean, Linode, Vultr, etc.)
- [ ] Root or sudo access
- [ ] VPS IP address

## Step-by-Step Deployment

### 1. Connect to VPS
```bash
ssh root@YOUR_VPS_IP
```

### 2. Install Docker (if not installed)
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt install docker-compose -y
docker --version
```

### 3. Upload Your Code

**Option A: Via Git**
```bash
cd /opt
git clone https://github.com/YOUR_USERNAME/tuganire.git
cd tuganire/tuganire-docker
```

**Option B: Via SCP (from your Windows machine)**
```powershell
scp -r "C:\Users\user\Documents\YEAR 2\Group projects\TERM I\Ecommerce\tuganire" root@YOUR_VPS_IP:/opt/
```

### 4. Configure Firewall
```bash
# Allow SSH (IMPORTANT - don't lock yourself out!)
sudo ufw allow 22/tcp

# Allow HTTP, HTTPS, and your app port
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8083/tcp

# Enable firewall
sudo ufw enable
sudo ufw status
```

### 5. Deploy Application
```bash
cd /opt/tuganire/tuganire-docker

# Make script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

**OR manually:**
```bash
docker-compose -f docker-compose.prod.yml up -d --build
```

### 6. Verify Deployment
```bash
# Check containers
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs -f app

# Test locally on VPS
curl http://localhost:8083
```

### 7. Access Your App

**From browser:**
- Direct: `http://YOUR_VPS_IP:8083`
- Via Nginx: `http://YOUR_VPS_IP`

## Post-Deployment

### View Logs
```bash
cd /opt/tuganire/tuganire-docker
docker-compose -f docker-compose.prod.yml logs -f
```

### Restart Services
```bash
docker-compose -f docker-compose.prod.yml restart
```

### Update Application
```bash
cd /opt/tuganire
git pull origin main
cd tuganire-docker
docker-compose -f docker-compose.prod.yml up -d --build
```

### Stop Services
```bash
docker-compose -f docker-compose.prod.yml down
```

## Troubleshooting

### App won't start
```bash
docker-compose -f docker-compose.prod.yml logs app
```

### Port already in use
```bash
sudo netstat -tulpn | grep 8083
# Kill the process or change port in docker-compose.prod.yml
```

### Database connection failed
```bash
# Check if Neon database is accessible
curl -v https://ep-lively-sea-aj87r78n-pooler.c-3.us-east-2.aws.neon.tech

# Check environment variables
docker-compose -f docker-compose.prod.yml exec app env | grep DB_
```

### Can't access from browser
```bash
# Check firewall
sudo ufw status

# Check if app is listening
sudo netstat -tulpn | grep 8083

# Check Docker logs
docker-compose -f docker-compose.prod.yml logs nginx
```

## Access Points

After successful deployment:

| Service | URL | Port |
|---------|-----|------|
| App (Direct) | http://YOUR_VPS_IP:8083 | 8083 |
| Nginx | http://YOUR_VPS_IP | 80 |
| HTTPS (if configured) | https://YOUR_DOMAIN | 443 |

## Next Steps

1. **Get a domain name** (optional)
   - Point A record to your VPS IP
   - Update nginx.conf with your domain

2. **Set up SSL/HTTPS**
   - Follow VPS-DEPLOYMENT.md Step 4
   - Use Let's Encrypt (free)

3. **Set up monitoring**
   - Uptime Robot
   - Pingdom
   - Or custom monitoring

4. **Configure backups**
   - Neon has automatic backups
   - Backup your application files

## Important Notes

- ✅ Port 8083 is used to avoid conflicts
- ✅ Neon database is already configured
- ✅ Hibernate uses `validate` in production (no auto schema changes)
- ✅ JWT secret is set (change in production!)
- ⚠️ Remember to configure SSL for production use
- ⚠️ Change JWT_SECRET before going live

## Quick Commands

```bash
# Start
docker-compose -f docker-compose.prod.yml up -d

# Stop
docker-compose -f docker-compose.prod.yml down

# Restart
docker-compose -f docker-compose.prod.yml restart

# Logs
docker-compose -f docker-compose.prod.yml logs -f

# Status
docker-compose -f docker-compose.prod.yml ps

# Update
git pull && docker-compose -f docker-compose.prod.yml up -d --build
```

## Support

For detailed instructions, see:
- VPS-DEPLOYMENT.md - Complete deployment guide
- DEPLOYMENT.md - All deployment scenarios
- README.md - Docker basics

## Your Configuration

- **Database**: Neon Cloud (PostgreSQL)
- **App Port**: 8083
- **Nginx Port**: 80, 443
- **Database Port**: Not exposed (internal only)
