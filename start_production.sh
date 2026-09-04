#!/bin/bash

# Tiannara API Production Startup Script
# Supports both HTTP (development) and HTTPS (production) modes

set -e

echo "=========================================="
echo "  Tiannara API Server"
echo "=========================================="
echo ""

# Load environment variables
if [ -f .env.production ]; then
    echo "✅ Loading production environment..."
    set -a
    source .env.production
    set +a
elif [ -f .env ]; then
    echo "⚠️  Loading development environment..."
    set -a
    source .env
    set +a
else
    echo "❌ No environment file found (.env or .env.production)"
    exit 1
fi

# Set defaults if not configured
HOST=${HOST:-0.0.0.0}
PORT=${PORT:-8004}
USE_SSL=${USE_SSL:-false}
WORKERS=${WORKERS:-4}
LOG_LEVEL=${LOG_LEVEL:-info}

echo ""
echo "Configuration:"
echo "  Host: $HOST"
echo "  Port: $PORT"
echo "  Workers: $WORKERS"
echo "  SSL: $USE_SSL"
echo "  Log Level: $LOG_LEVEL"
echo ""

# Check if SSL is enabled
if [ "$USE_SSL" = "true" ]; then
    echo "🔒 Starting with HTTPS/WSS support..."
    
    # Verify SSL certificates exist
    if [ -z "$SSL_CERT_FILE" ] || [ -z "$SSL_KEY_FILE" ]; then
        echo "❌ SSL_CERT_FILE and SSL_KEY_FILE must be set when USE_SSL=true"
        exit 1
    fi
    
    if [ ! -f "$SSL_CERT_FILE" ]; then
        echo "❌ SSL certificate not found: $SSL_CERT_FILE"
        exit 1
    fi
    
    if [ ! -f "$SSL_KEY_FILE" ]; then
        echo "❌ SSL key not found: $SSL_KEY_FILE"
        exit 1
    fi
    
    echo "✅ SSL Certificate: $SSL_CERT_FILE"
    echo "✅ SSL Key: $SSL_KEY_FILE"
    echo ""
    echo "Starting uvicorn with SSL..."
    echo "  API: https://$HOST:$PORT"
    echo "  WebSocket: wss://$HOST:$PORT/ws/..."
    echo ""
    
    # Start with SSL
    exec uvicorn tiannara_api.main:app \
        --host "$HOST" \
        --port "$PORT" \
        --ssl-certfile "$SSL_CERT_FILE" \
        --ssl-keyfile "$SSL_KEY_FILE" \
        --workers "$WORKERS" \
        --log-level "$LOG_LEVEL" \
        --forwarded-allow-ips '*'
else
    echo "⚠️  Starting without SSL (HTTP/WS only)"
    echo "   ⚠️  NOT RECOMMENDED FOR PRODUCTION"
    echo ""
    echo "Starting uvicorn..."
    echo "  API: http://$HOST:$PORT"
    echo "  WebSocket: ws://$HOST:$PORT/ws/..."
    echo ""
    
    # Start without SSL
    exec uvicorn tiannara_api.main:app \
        --host "$HOST" \
        --port "$PORT" \
        --workers "$WORKERS" \
        --log-level "$LOG_LEVEL"
fi
