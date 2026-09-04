#!/bin/bash
set -e

echo "🚀 Starting Tiannara API..."

# Wait for database to be ready
echo "⏳ Waiting for database..."
while ! python -c "
import psycopg2
try:
    conn = psycopg2.connect('${DATABASE_URL}')
    conn.close()
    print('✅ Database is ready')
except Exception:
    print('⏳ Database not ready, waiting...')
    exit(1)
"; do
    sleep 2
done

# Run database migrations
echo "📊 Running database migrations..."
python migrate_white_label.py || echo "⚠️  White-label migration skipped (tables may already exist)"
python migrate_mapek_security.py || echo "⚠️  MAPE-K security migration skipped (tables may already exist)"

# Start the application
echo "✅ Starting Uvicorn server..."
exec uvicorn tiannara_api.main:app --host 0.0.0.0 --port 8000 --workers 4
