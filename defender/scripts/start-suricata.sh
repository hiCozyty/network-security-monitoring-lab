#!/bin/bash
echo "Setting up and starting Suricata..."

# 1. Stop Suricata if it's already running
echo "Checking if Suricata is already running..."
if [ -f "/var/run/suricata.pid" ]; then
    echo "Suricata is already running. Stopping it first..."
    SURICATA_PID=$(cat /var/run/suricata.pid)
    if ps -p $SURICATA_PID > /dev/null; then
        kill $SURICATA_PID
        # Wait for it to stop
        sleep 2
    fi
    # Remove the PID file in case the process is gone but file remains
    rm -f /var/run/suricata.pid
fi

# Download necessary configuration files
echo "Downloading Suricata configuration files..."
# Download classification.config
curl -o /etc/suricata/classification.config https://raw.githubusercontent.com/OISF/suricata/master/etc/classification.config
# Download reference.config
curl -o /etc/suricata/reference.config https://raw.githubusercontent.com/OISF/suricata/master/etc/reference.config
# Create empty threshold.config if it doesn't exist
touch /etc/suricata/threshold.config

# 2. Configure Suricata with proper defaults using suricata-update
echo "Configuring Suricata using suricata-update..."
suricata-update update-sources
suricata-update enable-source et/open
suricata-update

# 3. Define HTTP_SERVERS and other important variables in suricata.yaml
echo "Updating network variables in suricata.yaml..."
cp /scripts/suricata.yaml /etc/suricata/
cp /scripts/suricata-local.rules /etc/suricata/rules/local.rules

# Make sure rule files directory exists and copy rules if needed
echo "Ensuring rule files are in the correct location..."
mkdir -p /etc/suricata/rules
if [ ! -f "/etc/suricata/rules/dns-events.rules" ]; then
    cp -r /usr/share/suricata/rules/* /etc/suricata/rules/ 2>/dev/null || echo "No rules in /usr/share/suricata/rules/"
fi

# 4. Start Suricata
echo "Starting Suricata on interface eth0..."
suricata -c /etc/suricata/suricata.yaml -i eth0 -D

# 5. Give Suricata a moment to start
sleep 5  # Give Suricata time to start fully

# Check if Suricata started successfully
if pgrep -f suricata > /dev/null || [ -f "/var/run/suricata.pid" ]; then
    echo "Suricata started successfully."
else
    echo "ERROR: Suricata failed to start."
    echo "Checking Suricata logs for errors..."
    tail /var/log/suricata/suricata.log
fi

echo ""
echo "================ SURICATA SETUP COMPLETE ================"
echo "Log location: /var/log/suricata/"
echo "========================================================"
tail -f /var/log/suricata/fast.log
