#!/bin/sh
# ==============================================
# HeadlessX Backend - Docker Entrypoint
# ==============================================
# This script runs before the application starts
# to ensure the database is initialized
# ==============================================

set -e

echo "🔍 Checking database connection..."
echo "📍 DATABASE_URL is set: $(test -n \"$DATABASE_URL\" && echo 'yes' || echo 'no')"

# Wait for database to be ready and sync schema
# Prisma 7 requires --url flag for db push
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if npx prisma db push --url "$DATABASE_URL" --accept-data-loss; then
    echo "✅ Database schema synchronized"
    break
  else
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "⏳ Waiting for database to be ready... (attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
  fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "❌ Failed to connect to database after $MAX_RETRIES attempts"
  exit 1
fi

# Start the application
echo "🚀 Starting HeadlessX Backend..."
exec "$@"
