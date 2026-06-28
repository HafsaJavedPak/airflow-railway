#!/bin/bash

set -e

# Set up SSH authorized keys for GitHub Actions deployments
if [ -n "$AIRFLOW_SSH_PUBLIC_KEY" ]; then
    echo "Setting up SSH authorized keys..."
    mkdir -p /home/airflow/.ssh
    echo "$AIRFLOW_SSH_PUBLIC_KEY" > /home/airflow/.ssh/authorized_keys
    chmod 700 /home/airflow/.ssh
    chmod 600 /home/airflow/.ssh/authorized_keys
    echo "SSH authorized keys configured."
fi

echo "=== Starting Airflow setup ==="

echo "Running database migration..."
airflow db migrate

echo "Creating admin user..."
airflow users create \
    --username "${AIRFLOW_ADMIN_USERNAME:-admin}" \
    --password "${AIRFLOW_ADMIN_PASSWORD:-admin}" \
    --firstname "TransTrack" \
    --lastname "Admin" \
    --role "Admin" \
    --email "${AIRFLOW_ADMIN_EMAIL:-admin@transtrack.com}" \
    || true

echo "Starting SSH server..."
sudo service ssh start || true

echo "Starting Airflow scheduler..."
airflow scheduler &

echo "Starting Airflow webserver on port 8080..."
exec airflow webserver --port 8080

