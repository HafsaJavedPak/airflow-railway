#!/bin/bash

# entrypoint.sh
# This script runs every time the Railway container starts

set -e
# set -e means: if any command fails, stop immediately
# Without this, a failed db migrate would be silently ignored
# and Airflow would try to start with a broken database

# ── SSH setup ──────────────────────────────────────────────────────────────
# Set up SSH authorized keys if the environment variable is set
# This allows GitHub Actions to SSH into this container for deployments
if [ -n "$AIRFLOW_SSH_PUBLIC_KEY" ]; then
    echo "Setting up SSH authorized keys..."
    mkdir -p /home/airflow/.ssh
    echo "$AIRFLOW_SSH_PUBLIC_KEY" > /home/airflow/.ssh/authorized_keys
    chmod 700 /home/airflow/.ssh
    chmod 600 /home/airflow/.ssh/authorized_keys
    echo "SSH authorized keys configured."
fi

# ── Airflow setup ──────────────────────────────────────────────────────────
echo "=== Starting Airflow setup ==="

# Initialize or migrate the database
# In Airflow 3.x, db init was removed — db migrate handles both
# first-time initialization and upgrades safely
echo "Running database migration..."
airflow db migrate

# Create the admin user
# || true means: if this fails because the user already exists,
# do not stop — just continue. Without || true, the second container
# start would fail here because the user already exists from the first start.
echo "Creating admin user..."
airflow users create \
    --username "${AIRFLOW_ADMIN_USERNAME:-admin}" \
    --password "${AIRFLOW_ADMIN_PASSWORD:-admin}" \
    --firstname "TransTrack" \
    --lastname "Admin" \
    --role "Admin" \
    --email "${AIRFLOW_ADMIN_EMAIL:-admin@transtrack.com}" \
    || true

# ── Start services ─────────────────────────────────────────────────────────

# Start SSH server so GitHub Actions can connect for deployments
echo "Starting SSH server..."
sudo service ssh start || true

# Start the scheduler in the background
# The & puts it in the background so we can also start the webserver
echo "Starting Airflow scheduler..."
airflow scheduler &

# Start the webserver in the foreground
# This is the last command and runs in the foreground
# Railway keeps the container alive as long as this process is running
# If the webserver crashes, Railway will restart the container
echo "Starting Airflow webserver on port 8080..."
exec airflow webserver --port 8080
