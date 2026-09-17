# Production Deployment Configuration

## SSL/TLS Certificate Setup

### Option 1: Let's Encrypt (Recommended for Production)

```bash
# Install certbot
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# Obtain certificate for your domain
sudo certbot certonly --standalone -d yourdomain.com -d api.yourdomain.com

# Certificates will be stored at:
# /etc/letsencrypt/live/yourdomain.com/fullchain.pem
# /etc/letsencrypt/live/yourdomain.com/privkey.pem
```

### Option 2: Self-Signed Certificate (Testing Only)

```bash
# Generate self-signed certificate
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# This creates:
# - key.pem (private key)
# - cert.pem (certificate)
```

### Option 3: Commercial SSL Certificate

Purchase from providers like:
- DigiCert
- Comodo
- GlobalSign
- GoDaddy

---

## Environment Variables for Production

Create `.env.production` file:

```bash
# Server Configuration
ENVIRONMENT=production
HOST=0.0.0.0
PORT=8004

# SSL/TLS Configuration
USE_SSL=true
SSL_CERT_FILE=/etc/letsencrypt/live/yourdomain.com/fullchain.pem
SSL_KEY_FILE=/etc/letsencrypt/live/yourdomain.com/privkey.pem

# CORS Configuration
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/tiannara_prod

# WebSocket Configuration
WS_URL=wss://api.yourdomain.com
NEXT_PUBLIC_WS_URL=wss://api.yourdomain.com

# Security
SECRET_KEY=your-super-secret-key-here
ADMIN_PASSWORD=secure-admin-password

# Logging
LOG_LEVEL=WARNING
LOG_FILE=/var/log/tiannara/api.log
```

---

## Backend Server with SSL

### Using Uvicorn with SSL

Create `start_production.sh`:

```bash
#!/bin/bash

# Load environment variables
set -a
source .env.production
set +a

# Check if SSL certificates exist
if [ "$USE_SSL" = "true" ]; then
    if [ ! -f "$SSL_CERT_FILE" ] || [ ! -f "$SSL_KEY_FILE" ]; then
        echo "❌ SSL certificates not found!"
        echo "   Cert: $SSL_CERT_FILE"
        echo "   Key:  $SSL_KEY_FILE"
        exit 1
    fi
    
    echo "✅ Starting Tiannara API with HTTPS..."
    echo "   URL: https://0.0.0.0:$PORT"
    echo "   WebSocket: wss://0.0.0.0:$PORT/ws/..."
    
    # Start with SSL
    uvicorn tiannara_api.main:app \
        --host $HOST \
        --port $PORT \
        --ssl-certfile $SSL_CERT_FILE \
        --ssl-keyfile $SSL_KEY_FILE \
        --workers 4 \
        --log-level warning \
        --forwarded-allow-ips '*'
else
    echo "⚠️  Starting Tiannara API without SSL (NOT RECOMMENDED FOR PRODUCTION)"
    echo "   URL: http://0.0.0.0:$PORT"
    
    # Start without SSL
    uvicorn tiannara_api.main:app \
        --host $HOST \
        --port $PORT \
        --workers 4 \
        --log-level warning
fi
```

Make it executable:
```bash
chmod +x start_production.sh
```

---

## Frontend Configuration for HTTPS/WSS

Update `tiannara_saas/.env.production`:

```bash
# API Configuration
NEXT_PUBLIC_API_URL=https://api.yourdomain.com/api/v1
NEXT_PUBLIC_WS_URL=wss://api.yourdomain.com

# Application Configuration
NEXT_PUBLIC_APP_NAME=Tiannara SaaS
NEXT_PUBLIC_APP_URL=https://yourdomain.com
```

Update frontend WebSocket client to use WSS:

The code already handles this automatically in `executor/page.tsx`:
```typescript
const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
const wsUrl = `${protocol}//${host}/ws/workflow/${execId}`
```

This means:
- If site is loaded via HTTPS → uses WSS
- If site is loaded via HTTP → uses WS

---

## Nginx Reverse Proxy Configuration (Recommended)

For production, use Nginx as reverse proxy with SSL termination:

Create `/etc/nginx/sites-available/tiannara`:

```nginx
# HTTP → HTTPS redirect
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com api.yourdomain.com;
    
    # Redirect all HTTP to HTTPS
    return 301 https://$host$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com api.yourdomain.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # Logging
    access_log /var/log/nginx/tiannara_access.log;
    error_log /var/log/nginx/tiannara_error.log;
    
    # Frontend (Next.js)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:8004;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout settings for long-running workflows
        proxy_connect_timeout 60s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
    
    # WebSocket endpoints
    location /ws/ {
        proxy_pass http://localhost:8004;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket timeout (important for long executions)
        proxy_read_timeout 86400s;  # 24 hours
        proxy_send_timeout 86400s;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8004/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
}
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/tiannara /etc/nginx/sites-enabled/
sudo nginx -t  # Test configuration
sudo systemctl restart nginx
```

---

## Docker Deployment with SSL

Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: tiannara_prod
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - tiannara-network
    restart: unless-stopped

  # Backend API
  api:
    build:
      context: .
      dockerfile: Dockerfile.api
    environment:
      - ENVIRONMENT=production
      - DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/tiannara_prod
      - USE_SSL=false  # SSL handled by Nginx
      - ALLOWED_ORIGINS=https://yourdomain.com
    depends_on:
      - postgres
    networks:
      - tiannara-network
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G

  # Frontend (Next.js)
  frontend:
    build:
      context: ./tiannara_saas
      dockerfile: Dockerfile.frontend
    environment:
      - NEXT_PUBLIC_API_URL=https://api.yourdomain.com/api/v1
      - NEXT_PUBLIC_WS_URL=wss://api.yourdomain.com
    depends_on:
      - api
    networks:
      - tiannara-network
    restart: unless-stopped

  # Nginx Reverse Proxy with SSL
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro  # Mount SSL certificates
      - nginx_logs:/var/log/nginx
    depends_on:
      - api
      - frontend
    networks:
      - tiannara-network
    restart: unless-stopped

volumes:
  postgres_data:
  nginx_logs:

networks:
  tiannara-network:
    driver: bridge
```

---

## Testing HTTPS/WSS Connection

### Test 1: Verify HTTPS Endpoint

```bash
# Test API health endpoint
curl -I https://api.yourdomain.com/health

# Expected response:
# HTTP/2 200
# strict-transport-security: max-age=31536000; includeSubDomains
# content-type: application/json
```

### Test 2: Verify WebSocket over WSS

Create `test_wss.py`:

```python
import asyncio
import websockets
import ssl
import json

async def test_wss_connection():
    """Test WebSocket Secure connection."""
    
    # Create SSL context (use default system certificates)
    ssl_context = ssl.create_default_context()
    
    # WebSocket URL
    url = "wss://api.yourdomain.com/ws/metrics?token=YOUR_TOKEN"
    
    try:
        print(f"🔌 Connecting to {url}...")
        
        async with websockets.connect(url, ssl=ssl_context) as websocket:
            print("✅ WSS connection established!")
            
            # Send test message
            await websocket.send(json.dumps({"type": "ping"}))
            
            # Receive response
            response = await websocket.recv()
            print(f"📨 Received: {response}")
            
            print("✅ WSS test successful!")
            
    except websockets.exceptions.InvalidStatusCode as e:
        print(f"❌ Connection failed: {e}")
    except ssl.SSLCertVerificationError as e:
        print(f"❌ SSL certificate error: {e}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_wss_connection())
```

Run the test:
```bash
pip install websockets
python test_wss.py
```

### Test 3: Browser Console Test

Open browser console on your production site and run:

```javascript
// Test WebSocket connection
const ws = new WebSocket('wss://api.yourdomain.com/ws/metrics?token=YOUR_TOKEN');

ws.onopen = () => {
  console.log('✅ WSS connected');
};

ws.onmessage = (event) => {
  console.log('📨 Message received:', event.data);
};

ws.onerror = (error) => {
  console.error('❌ WSS error:', error);
};

ws.onclose = (event) => {
  console.log('🔌 WSS closed:', event.code, event.reason);
};
```

---

## Monitoring & Logging

### SSL Certificate Expiry Monitoring

Add to crontab:
```bash
# Check certificate expiry weekly
0 9 * * 1 /usr/bin/certbot certificates | grep "Expiry Date" | mail -s "SSL Certificate Status" admin@yourdomain.com
```

### Log Rotation

Create `/etc/logrotate.d/tiannara`:

```
/var/log/tiannara/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        systemctl reload nginx > /dev/null 2>&1 || true
    endscript
}
```

---

## Security Checklist

- ✅ SSL/TLS enabled (HTTPS + WSS)
- ✅ HTTP → HTTPS redirect configured
- ✅ HSTS header enabled
- ✅ Strong SSL ciphers only (TLS 1.2+)
- ✅ Security headers configured
- ✅ CORS restricted to production domains
- ✅ Rate limiting enabled
- ✅ Input validation middleware active
- ✅ Database credentials secured
- ✅ Admin password set via environment variable
- ✅ Logs rotated and archived
- ✅ Firewall configured (ports 80, 443 only)
- ✅ Regular security updates scheduled

---

## Deployment Steps Summary

1. **Obtain SSL Certificate**
   ```bash
   sudo certbot certonly --standalone -d yourdomain.com
   ```

2. **Configure Environment**
   ```bash
   cp .env.example .env.production
   # Edit .env.production with production values
   ```

3. **Setup Nginx**
   ```bash
   sudo cp nginx.conf /etc/nginx/sites-available/tiannara
   sudo ln -s /etc/nginx/sites-available/tiannara /etc/nginx/sites-enabled/
   sudo nginx -t && sudo systemctl restart nginx
   ```

4. **Start Backend**
   ```bash
   ./start_production.sh
   ```

5. **Start Frontend**
   ```bash
   cd tiannara_saas
   npm run build
   npm start
   ```

6. **Test HTTPS/WSS**
   ```bash
   curl -I https://api.yourdomain.com/health
   python test_wss.py
   ```

7. **Monitor Logs**
   ```bash
   tail -f /var/log/tiannara/api.log
   tail -f /var/log/nginx/tiannara_error.log
   ```

---

## Troubleshooting

### Issue: SSL Certificate Errors

```bash
# Verify certificate
openssl x509 -in /etc/letsencrypt/live/yourdomain.com/fullchain.pem -text -noout

# Check expiry
openssl x509 -enddate -noout -in /etc/letsencrypt/live/yourdomain.com/fullchain.pem

# Renew certificate
sudo certbot renew
```

### Issue: WebSocket Connection Fails

```bash
# Check Nginx error logs
tail -f /var/log/nginx/tiannara_error.log

# Verify WebSocket upgrade headers
curl -I -H "Upgrade: websocket" -H "Connection: Upgrade" https://api.yourdomain.com/ws/metrics

# Check backend is running
systemctl status tiannara-api
```

### Issue: Mixed Content Errors

Ensure all resources use HTTPS:
- Update hardcoded `http://` URLs to `https://`
- Use protocol-relative URLs (`//api.yourdomain.com`) where appropriate
- Configure `NEXT_PUBLIC_API_URL` and `NEXT_PUBLIC_WS_URL` with `https://` and `wss://`

---

## Performance Optimization

### Enable HTTP/2

Already enabled in Nginx config with `listen 443 ssl http2;`

### Enable Gzip Compression

Add to Nginx:
```nginx
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
```

### Enable Caching

Add to Nginx:
```nginx
# Cache static assets
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

---

## Next Steps After Deployment

1. **Setup Monitoring**
   - Prometheus + Grafana for metrics
   - Sentry for error tracking
   - Uptime monitoring (UptimeRobot, Pingdom)

2. **Backup Strategy**
   - Daily database backups
   - Weekly full system backups
   - Off-site backup storage

3. **Scaling**
   - Horizontal scaling with load balancer
   - Database read replicas
   - CDN for static assets

4. **CI/CD Pipeline**
   - Automated testing
   - Staging environment
   - Blue-green deployments

---

**Status:** Ready for production deployment  
**Protocol:** HTTPS + WSS (WebSocket Secure)  
**Security:** Enterprise-grade with SSL/TLS
