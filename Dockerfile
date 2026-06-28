# Dockerfile

# Official Airflow 3.0.0 image — version pinned so Railway always builds the same thing
FROM apache/airflow:3.0.0

# Switch to root to install system dependencies
USER root

RUN apt-get update && apt-get install -y \
    vim \
    curl \
    openssh-server \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Allow airflow user to start SSH service without a password prompt
RUN echo "airflow ALL=(ALL) NOPASSWD: /usr/sbin/service ssh start" >> /etc/sudoers

# Switch back to airflow user — never run Airflow as root
USER airflow

# Copy our requirements file and install Python dependencies
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt

# Create the dags folder — this is where CI/CD will copy DAG files to
RUN mkdir -p /opt/airflow/dags

# Copy any DAGs that already exist in our repo
COPY dags/ /opt/airflow/dags/

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh

# Switch to root just to set permissions on the entrypoint
USER root
RUN chmod +x /entrypoint.sh

# Switch back to airflow for running
USER airflow

# Expose the Airflow webserver port and SSH port
EXPOSE 8080
EXPOSE 22

# Run our entrypoint script when the container starts
ENTRYPOINT ["/entrypoint.sh"]
