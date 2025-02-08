#!/bin/bash
# IRLP Node script to detect COS INACTIVE and key the transmitter

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

