#!/bin/sh -e

# Download and run InfluxDB 3.0
echo "Downloading and running InfluxDB 3.0..."
docker pull quay.io/influxdb/influxdb3-core:latest
docker tag quay.io/influxdb/influxdb3-core:latest influxdb3-core
docker run -d --name influxdb3 -p 8181:8181 influxdb3-core serve --object-store memory --writer-id writer0 > /dev/null

# Wait for container to be healthy
for i in $(seq 1 30); do
    if docker inspect influxdb3 --format='{{.State.Running}}' | grep -q 'true'; then
        sleep 2
        echo "InfluxDB 3.0 is up and running"
        break
    fi
    sleep 1
done

# Create the database
echo "Creating database: $INFLUXDB3_DATABASE..."
docker exec influxdb3 influxdb3 create database $INFLUXDB3_DATABASE
echo "Database $INFLUXDB3_DATABASE created."

if [ "$INFLUXDB3_CREATE_TOKEN" = "true" ]
then
    echo "Creating token..."
    INFLUXDB3_TOKEN=$(docker exec influxdb3 influxdb3 create token | grep "Token:" | awk '{print $2}' | head -n 1)
    echo "Token created successfully. This will grant you access to every HTTP endpoint or deny it otherwise."

    # Export the token to GITHUB_OUTPUT
    echo "influxdb3-auth-token=$(echo $INFLUXDB3_TOKEN)" >> $GITHUB_OUTPUT
fi
