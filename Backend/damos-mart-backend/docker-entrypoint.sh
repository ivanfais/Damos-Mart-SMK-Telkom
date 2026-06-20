#!/bin/sh
set -e

echo "=== Damos Mart Backend startup ==="
echo "NODE_ENV=${NODE_ENV:-unknown}"
echo "PORT=${PORT:-3000}"

if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL is not set."
  echo "Add PostgreSQL in Railway, then link DATABASE_URL to this service."
  exit 1
fi

echo "Running database migrations..."
if ! npx prisma migrate deploy; then
  echo "ERROR: prisma migrate deploy failed."
  echo "Check DATABASE_URL and that PostgreSQL is running in the same Railway project."
  exit 1
fi

echo "Migrations OK. Starting application..."
exec "$@"
