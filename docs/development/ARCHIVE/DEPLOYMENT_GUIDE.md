# Tiannara MindCache - Production Deployment Guide

**Version**: 1.0.0  
**Last Updated**: April 30, 2026  
**Status**: Production Ready

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Prerequisites](#prerequisites)
3. [Local Development with Docker](#local-development-with-docker)
4. [Production Deployment](#production-deployment)
5. [Configuration](#configuration)
6. [Monitoring & Logging](#monitoring--logging)
7. [Security](#security)
8. [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start

```bash
# 1. Clone repository
git clone https://github.com/your-org/tiannara-mindcache.git
cd tiannara-mindcache

# 2. Copy environment template
cp .env.production .env

# 3. Update .env with your production values
nano .env  # or use your preferred editor

# 4. Start all services
docker-compose up -d

# 5. Verify deployment
curl http://localhost:8000/health

# 6. View logs
docker-compose logs -f api
```

---

## 📦 Prerequisites

### Required Software

- **Docker**: Version 20.10+ ([Install Guide](https://docs.docker.com/get-docker/))
- **Docker Compose**: Version 2.0+ (included with Docker Desktop)
- **Git**: For version control

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 4 GB | 8+ GB |
| Storage | 20 GB | 50+ GB SSD |
| Network | 10 Mbps | 100+ Mbps |

### Port Requirements

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| API | 8000 | TCP | FastAPI application |
| PostgreSQL | 5432 | TCP | Database (internal) |
| Redis | 6379 | TCP | Cache (internal) |
| Nginx | 80/443 | TCP | Reverse proxy (optional) |

---

## 🛠️ Local Development with Docker

### Start Development Environment

```bash
# Build and start all services
docker-compose up --build

# Run in detached mode (background)
docker-compose up -d

# View running containers
docker-compose ps
```

### Common Development Commands

```bash
# Rebuild after code changes
docker-compose up --build api

# Restart a specific service
docker-compose restart api

# View logs for a service
docker-compose logs -f api
docker-compose logs -f db
docker-compose logs -f redis

# Execute commands inside container
docker-compose exec api bash
docker-compose exec db psql -U tiannara -d tiannara_db

# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes data!)
docker-compose down -v
```

### Database Management

```bash
# Connect to PostgreSQL
docker-compose exec db psql -U tiannara -d tiannara_db

# Backup database
docker-compose exec db pg_dump -U tiannara tiannara_db > backup.sql

# Restore database
cat backup.sql | docker-compose exec -T db psql -U tiannara tiannara_db

# View table structure
docker-compose exec db psql -U tiannara -d tiannara_db -c "\dt"
```

---

## 🌐 Production Deployment

### Step 1: Server Preparation

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose (if not included)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Configure firewall
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Step 2: SSL Certificate Setup (Let's Encrypt)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain certificate
sudo certbot certonly --nginx -d yourdomain.com -d www.yourdomain.com

# Copy certificates to project
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ./ssl/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ./ssl/key.pem
sudo chown $USER:$USER ./ssl/*.pem
```

### Step 3: Environment Configuration

```bash
# Copy production template
cp .env.production .env

# Generate secure SECRET_KEY
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# Edit .env file
nano .env
```

**Critical Settings to Change:**

```env
SECRET_KEY=<generated-key-from-above>
POSTGRES_PASSWORD=<strong-password>
GRAFANA_PASSWORD=<strong-password>
CORS_ORIGINS=https://yourdomain.com
APP_ENV=production
DEBUG=false
```

### Step 4: Deploy with Nginx (HTTPS)

```bash
# Uncomment nginx service in docker-compose.yml
# Or use profile:
docker-compose --profile production up -d

# Verify all services are running
docker-compose ps

# Check health endpoints
curl https://yourdomain.com/health
```

### Step 5: Automated Backups

Create `backup.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/backup/tiannara/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup database
docker-compose exec -T db pg_dump -U tiannara tiannara_db | gzip > $BACKUP_DIR/db_backup.sql.gz

# Backup volumes
docker run --rm -v tiannara-mindcache_postgres_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/postgres_data.tar.gz -C /data .

# Keep only last 7 days of backups
find /backup/tiannara -type d -mtime +7 -exec rm -rf {} +

echo "Backup completed: $BACKUP_DIR"
```

Add to crontab:

```bash
# Daily backup at 2 AM
0 2 * * * /path/to/backup.sh >> /var/log/tiannara-backup.log 2>&1
```

---

## ⚙️ Configuration

### Environment Variables Reference

See `.env.production` for complete list. Key variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_ENV` | production | Application environment |
| `LOG_LEVEL` | info | Logging verbosity (debug/info/warn/error) |
| `SECRET_KEY` | - | **REQUIRED**: Secret key for JWT/signing |
| `POSTGRES_PASSWORD` | secret | Database password |
| `REDIS_MAX_MEMORY` | 512mb | Redis memory limit |
| `API_WORKERS` | 4 | Number of Uvicorn workers |
| `CORS_ORIGINS` | - | Allowed CORS origins |

### Resource Limits

Configured in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 2G
    reservations:
      cpus: '0.5'
      memory: 512M
```

Adjust based on your server capacity.

---

## 📊 Monitoring & Logging

### Health Checks

All services have built-in health checks:

```bash
# Check service health
docker inspect --format='{{.State.Health.Status}}' tiannara-api

# View health check logs
docker inspect --format='{{json .State.Health}}' tiannara-api | jq
```

### Log Management

Logs are stored in `/app/logs` volume:

```bash
# View application logs
docker-compose logs -f api

# Access log files
docker-compose exec api tail -f /app/logs/tiannara.log

# Export logs
docker-compose logs api > api_logs.txt
```

### Prometheus Metrics (Optional)

If monitoring is enabled:

```bash
# Access Prometheus
open http://localhost:9090

# Access Grafana
open http://localhost:3000
# Username: admin
# Password: <GRAFANA_PASSWORD from .env>
```

---

## 🔒 Security

### Best Practices

1. **Never commit `.env` file** - Already in `.gitignore`
2. **Use strong passwords** - Generate with: `openssl rand -base64 32`
3. **Enable HTTPS** - Use Let's Encrypt or commercial SSL
4. **Regular updates** - Keep Docker images updated
5. **Firewall rules** - Only expose necessary ports
6. **Non-root user** - Containers run as `appuser` (not root)

### Security Checklist

- [ ] Changed default passwords in `.env`
- [ ] Generated unique `SECRET_KEY`
- [ ] Enabled HTTPS with valid SSL certificate
- [ ] Configured firewall (UFW/iptables)
- [ ] Set up automated security updates
- [ ] Enabled rate limiting (configured in nginx.conf)
- [ ] Reviewed CORS settings
- [ ] Disabled debug mode (`DEBUG=false`)

### Updating Dependencies

```bash
# Check for outdated packages
pip list --outdated

# Update requirements-production.txt
# Then rebuild:
docker-compose build --no-cache api
docker-compose up -d
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Container Won't Start

```bash
# Check logs
docker-compose logs api

# Common fix: rebuild
docker-compose build api
docker-compose up -d
```

#### 2. Database Connection Failed

```bash
# Check if database is healthy
docker-compose ps db

# View database logs
docker-compose logs db

# Reset database (WARNING: deletes all data!)
docker-compose down -v
docker-compose up -d
```

#### 3. Port Already in Use

```bash
# Find process using port
sudo lsof -i :8000

# Kill process or change port in docker-compose.yml
```

#### 4. Out of Memory

```bash
# Check resource usage
docker stats

# Increase limits in docker-compose.yml
# Or reduce API_WORKERS in .env
```

#### 5. Permission Denied

```bash
# Fix volume permissions
sudo chown -R $USER:$USER ./runs ./logs

# Ensure entrypoint script is executable
chmod +x docker-entrypoint.sh
```

### Getting Help

1. Check logs: `docker-compose logs -f <service>`
2. Inspect container: `docker inspect <container_name>`
3. Execute shell: `docker-compose exec <service> bash`
4. Review documentation: `docs/README.md`

---

## 📝 Maintenance

### Regular Tasks

**Weekly:**
- Review logs for errors
- Check disk space: `df -h`
- Monitor resource usage: `docker stats`

**Monthly:**
- Update Docker images: `docker-compose pull && docker-compose up -d`
- Test backups by restoring to staging
- Review security updates

**Quarterly:**
- Rotate passwords and keys
- Audit access logs
- Performance tuning review

### Scaling

For high-traffic deployments:

```yaml
# Scale API workers
docker-compose up -d --scale api=3

# Or use Kubernetes for advanced orchestration
# See docs/kubernetes/ for K8s manifests
```

---

## 🎯 Next Steps

After successful deployment:

1. **Configure CI/CD** - See `.github/workflows/deploy.yml`
2. **Set up monitoring alerts** - Configure Grafana alerts
3. **Implement load testing** - Use tools like k6 or Apache Bench
4. **Document custom configurations** - Update this guide
5. **Train team** - Share deployment procedures

---

## 📞 Support

- **Documentation**: `docs/README.md`
- **Issues**: GitHub Issues
- **Email**: support@tiannara.ai
- **Community**: Discord/Slack channel

---

**Remember**: Always test changes in staging before production!
