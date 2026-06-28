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

# CHANGE 1: airflow users create → airflow fab create-admin
# The users command was removed in Airflow 3.x
# User management now goes through the FAB (Flask App Builder) interface
echo "Creating admin user..."
airflow fab create-admin \
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

# CHANGE 2: airflow webserver → airflow api-server
# The webserver command was removed in Airflow 3.x
# api-server is the new equivalent
echo "Starting Airflow api-server on port 8080..."
exec airflow api-server --port 8080
