#!/usr/bin/env bash
set -euo pipefail

# Auto-export all variables
set -a
source .env
set +a

exec_psql() {
  docker exec -i "$POSTGRES_CONTAINER" \
    psql -U "$POSTGRES_ADMIN_USER" -tAc "$1"
}

echo "▶ Preparing DB: $GITEA_DATABASE_NAME"

USER_EXISTS=$(exec_psql \
  "SELECT 1 FROM pg_roles WHERE rolname='${GITEA_DATABASE_USER}'")
if [[ "$USER_EXISTS" != "1" ]]; then
  exec_psql \
    "CREATE USER ${GITEA_DATABASE_USER} WITH LOGIN CREATEDB PASSWORD '${GITEA_DATABASE_PASSWORD}';"
else
  exec_psql \
    "ALTER USER ${GITEA_DATABASE_USER} WITH PASSWORD '${GITEA_DATABASE_PASSWORD}';"
fi

DB_EXISTS=$(exec_psql \
    "SELECT 1 FROM pg_database WHERE datname='${GITEA_DATABASE_NAME}'")
if [[ "$DB_EXISTS" != "1" ]]; then
  exec_psql "CREATE DATABASE ${GITEA_DATABASE_NAME} OWNER ${GITEA_DATABASE_USER};"
fi

exec_psql \
  "GRANT ALL PRIVILEGES ON DATABASE ${GITEA_DATABASE_NAME} TO ${GITEA_DATABASE_USER};"

exec_psql \
    "GRANT ALL PRIVILEGES ON SCHEMA public TO ${GITEA_DATABASE_USER};"

echo "Done"
