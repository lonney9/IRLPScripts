#!/bin/bash
# IRLP Node script to detect COS INACTIVE and key the transmitter

# Setup
# Save script to /home/irlp/custom/simplex_tail.sh
# Test from console: ./custom/simplex_tail.sh
# Start on boot:
#   1) Newer systems edit /home/irlp/custom/rc.irlp.repeater and add two lines to the end:
#      echo -n "Starting simplex tail script"
#      "${CUSTOM}/simplex_tail.sh" >&/dev/null 2>&1 &
#   2) Older systems (with out rc.irlp.repeater) edit /home/irlp/custom/rc.irlp and add two lines above the last line with "[ DONE ]":
#      echo -n "Starting simplex tail script"
#      /bin/su - -c "${CUSTOM}/simplex_tail.sh" repeater >&/dev/null 2>&1 &

# Paths to IRLP commands
READINPUT_CMD="/home/irlp/bin/readinput"
FORCEKEY_CMD="/home/irlp/bin/aux1on"
FORCEUNKEY_CMD="/home/irlp/bin/aux1off"

# Function to key and unkey the transmitter
function key_transmitter() {
    echo "TAIL ON"
    $FORCEKEY_CMD
    sleep 2  # Keep the transmitter keyed for n seconds
    $FORCEUNKEY_CMD
    echo "TAIL OFF"
}

# Run readinput in the background and monitor output
# $READINPUT_CMD | while read -r line; do
$READINPUT_CMD | tee /dev/tty | while read -r line; do
    # Check if the output contains "COS INACTIVE"
    if [[ "$line" == *"COS INACTIVE"* ]]; then
        # echo "COS INACTIVE detected."
        key_transmitter
    fi
done

