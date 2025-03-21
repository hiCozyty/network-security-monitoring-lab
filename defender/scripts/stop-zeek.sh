#!/bin/bash
echo "Forcing Zeek to stop completely..."

# Try the clean way first
echo "Attempting clean stop with zeekctl..."
zeekctl stop &>/dev/null

# Now use pkill to forcefully terminate all zeek processes
echo "Forcefully terminating all Zeek processes..."
pkill -9 -f "zeek" || echo "No processes found with pkill"

# Double-check with direct kill of any process with zeek in its command
echo "Directly targeting any remaining processes..."
ps -ef | grep zeek | grep -v grep | grep -v "stop-zeek" | awk '{print $2}' | xargs -r kill -9 &>/dev/null

# Clean up Zeek run directory
echo "Cleaning up Zeek run files..."
rm -f /var/run/zeek/* &>/dev/null
rm -f /var/log/zeek/*.lock &>/dev/null
rm -f /var/log/zeek/spool/*.lock &>/dev/null
rm -f /var/log/zeek/spool/zeek/*.lock &>/dev/null

# Verify no Zeek processes remain
echo "Checking for any remaining Zeek processes..."
REMAINING=$(ps -ef | grep -i zeek | grep -v grep | grep -v "stop-zeek")

if [ -z "$REMAINING" ]; then
    echo "SUCCESS: All Zeek processes have been terminated."
    echo "Zombie processes may still appear in process list but are harmless."
    echo "Zeek can now be restarted."
else
    echo "WARNING: Some processes may still be running:"
    echo "$REMAINING"
fi

echo "Force stop completed."
