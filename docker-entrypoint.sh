#!/bin/bash
set -e

echo "========================================="
echo "Tiannara MindCache - Starting..."
echo "========================================="

# Wait for database to be ready
echo "Waiting for database..."
until python -c "
import urllib.request
import os
from sqlalchemy import create_engine

db_url = os.getenv('DATABASE_URL', 'postgresql://tiannara:secret@db:5432/tiannara_db')
try:
    engine = create_engine(db_url)
    engine.connect()
    print('Database connection successful!')
except Exception as e:
    print(f'Database not ready: {e}')
    exit(1)
" 2>/dev/null; do
    echo "Database is unavailable - sleeping"
    sleep 2
done

echo "Database is up!"

# Run database migrations if they exist
if [ -f "migrations/run_migrations.py" ]; then
    echo "Running database migrations..."
    python migrations/run_migrations.py
fi

# Create logs directory if it doesn't exist
mkdir -p /app/logs

# Set proper permissions
chown -R appuser:appuser /app/logs 2>/dev/null || true

echo "========================================="
echo "Starting Tiannara API Server..."
echo "Environment: ${APP_ENV:-production}"
echo "Log Level: ${LOG_LEVEL:-info}"
echo "Workers: ${API_WORKERS:-4}"
echo "========================================="

# Execute the command passed to docker-compose
exec "$@"
