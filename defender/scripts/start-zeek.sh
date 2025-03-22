#!/bin/bash
echo "Starting Zeek..."
# Get this script's PID to exclude it from checks
SCRIPT_PID=$$
# Check if Zeek is already running (excluding zombie processes and this script)
if ps aux | grep -E 'zeek' | grep -v 'defunct' | grep -v "grep" | grep -v "$SCRIPT_PID" > /dev/null; then
    echo "Zeek appears to be already running. Restarting it..."
    zeekctl stop
    sleep 2
fi
# Try to clean up any lock files that might be causing issues
echo "Cleaning up any lock files..."
find /var/log/zeek -name "*.lock" -delete 2>/dev/null
# Start Zeek
echo "Deploying Zeek..."
zeekctl deploy
# Check if Zeek started successfully (excluding zombie processes)
if ps aux | grep -E "zeek" | grep -v "defunct" | grep -v "grep" > /dev/null; then
    echo "Zeek started successfully."
else
    echo "WARNING: Zeek may not have started properly."
    echo "Checking Zeek processes:"
    ps aux | grep zeek | grep -v grep
    echo "Trying to restart Zeek..."
    zeekctl stop
    sleep 2
    zeekctl start
    # Check again (excluding zombie processes)
    if ps aux | grep -E "zeek" | grep -v "defunct" | grep -v "grep" > /dev/null; then
        echo "Zeek started successfully after retry."
    else
        echo "ERROR: Failed to start Zeek. Please check configuration."
        exit 1
    fi
fi
curl https://www.example.com
# Give Zeek a moment to process the traffic and create logs
echo "Waiting for logs to be created..."
sleep 1
# Find log directories
echo "Checking log locations..."

# Use the known location of conn.log
ZEEK_LOG_DIR="/var/log/zeek/spool/zeek"
echo "Using Zeek log directory: $ZEEK_LOG_DIR"

if [ -n "$ZEEK_LOG_DIR" ]; then
    echo ""
    echo "================ ZEEK SETUP COMPLETE ================"
    echo "Zeek log location: $ZEEK_LOG_DIR"
    echo "===================================================="
    # Check if the conn.log file exists before tailing
    if [ -f "$ZEEK_LOG_DIR/conn.log" ]; then
        echo "Found conn.log, displaying latest entries:"
        # tail -f "$ZEEK_LOG_DIR/conn.log"
    else
        echo "conn.log not found in $ZEEK_LOG_DIR"
        echo "Available logs in this directory:"
        ls -la "$ZEEK_LOG_DIR"
    fi
fi
