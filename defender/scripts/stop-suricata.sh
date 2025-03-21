#!/bin/bash
echo "Stopping Suricata..."

# Check if Suricata is running
if [ -f "/var/run/suricata.pid" ]; then
    echo "Found Suricata PID file. Stopping Suricata..."
    SURICATA_PID=$(cat /var/run/suricata.pid)

    if ps -p $SURICATA_PID > /dev/null; then
        echo "Sending SIGTERM to Suricata process (PID: $SURICATA_PID)..."
        kill $SURICATA_PID

        # Wait for it to stop gracefully
        echo "Waiting for Suricata to stop..."
        for i in {1..5}; do
            if ! ps -p $SURICATA_PID > /dev/null; then
                echo "Suricata stopped successfully."
                break
            fi
            sleep 1
        done

        # Force kill if still running
        if ps -p $SURICATA_PID > /dev/null; then
            echo "Suricata is still running. Sending SIGKILL..."
            kill -9 $SURICATA_PID
            sleep 1
        fi
    else
        echo "Suricata process not found, but PID file exists."
    fi

    # Remove the PID file
    rm -f /var/run/suricata.pid
    echo "Removed Suricata PID file."
else
    # Try to find Suricata by process name if PID file doesn't exist
    SURICATA_PID=$(pgrep -f "suricata -c" | head -1)

    if [ -n "$SURICATA_PID" ]; then
        echo "Found Suricata process (PID: $SURICATA_PID) without PID file. Stopping it..."
        kill $SURICATA_PID

        # Wait for it to stop
        sleep 2

        # Force kill if still running
        if ps -p $SURICATA_PID > /dev/null; then
            echo "Suricata is still running. Sending SIGKILL..."
            kill -9 $SURICATA_PID
        fi

        echo "Suricata stopped."
    else
        echo "Suricata does not appear to be running."
    fi
fi

echo "Suricata has been stopped."
