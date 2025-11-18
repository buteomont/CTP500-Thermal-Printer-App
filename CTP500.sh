#!/bin/bash

# --- Configuration ---
# 1. Define the OUI Prefix (first three octets of the MAC address, e.g., for 'C0:35:32...')
# You should determine your printer's OUI and place it here.

# If you run "sudo setcap 'cap_net_raw,cap_net_admin+eip' /usr/bin/rfcomm" once in a terminal
# window, you can remove all of the sudo pre-commands from the script and won't have to enter
# your password each time you run the program.  You might have to change "/usr/bin/rfcomm" in
# the above command to match your system (find it with "which rfcomm").

PRINTER_OUI="79:BD:E7" 
RFCOMM_CHANNEL="1"
RFCOMM_DEVICE="rfcomm0" 

# --- Make APP_PATH Generic ---
# Finds the directory of the current script, and appends the Python file name.
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
#APP_FILE="CTP500_GUI_app_Github_Export.py"
APP_FILE="myCTP.py"
APP_PATH="$SCRIPT_DIR/$APP_FILE"
# ------------------------------

echo `pwd`

# --- Discovery Logic: Search by OUI ---

# Use 'bluetoothctl devices' to list paired devices and filter by the OUI prefix.
echo "Searching for paired printer by OUI: $PRINTER_OUI..."

# 1. List paired devices.
# 2. Filter the output using grep to find the MAC address starting with the OUI.
# 3. Use awk to extract only the MAC address (field $2).
PRINTER_MAC=$(bluetoothctl devices Paired | grep -i "$PRINTER_OUI" | head -n 1 | awk '{print $2}')

if [ -z "$PRINTER_MAC" ]; then
    echo "Error: No printer found with OUI prefix '$PRINTER_OUI' in paired list."
    echo "Please ensure the printer is ON, paired, and trusted."
    exit 1
fi

echo "Discovered Printer MAC: $PRINTER_MAC on Channel $RFCOMM_CHANNEL"

# --- Script Logic ---

# 1. BIND: Reserve the RFCOMM channel (requires sudo).
echo "Binding $PRINTER_MAC to /dev/$RFCOMM_DEVICE..."
rfcomm bind 0 "$PRINTER_MAC" "$RFCOMM_CHANNEL" || true 
sleep 1

# 2. ACTIVATE: Force an active connection via bluetoothctl.
echo "Attempting to activate and connect..."
bluetoothctl connect "$PRINTER_MAC" 
sleep 2

# 3. START APP: Execute the Python GUI application.
echo "Starting the Python GUI application..."
python3 "$APP_PATH"

# 4. CLEANUP: Unbind and disconnect when the application closes.
echo "Application closed. Cleaning up..."

# Unbind /dev/rfcomm0 (requires sudo)
rfcomm unbind 0 || true
bluetoothctl disconnect "$PRINTER_MAC" || true
