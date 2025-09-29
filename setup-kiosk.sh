#!/bin/bash

# Haven Portal Kiosk Desktop Shortcut Setup Script
# Creates a desktop shortcut that launches the Haven Portal in kiosk mode

set -e

echo "=== Haven Portal Kiosk Setup ==="
echo

# Get kiosk URL from command line argument or user input
KIOSK_URL="$1"
if [[ -z "$KIOSK_URL" ]]; then
    KIOSK_URL="https://portal.havenpanels.com"
fi

CURRENT_USER=$(whoami)
echo "Setting up kiosk shortcut for user: $CURRENT_USER"
echo "Kiosk URL: $KIOSK_URL"

echo
echo "=== Installing required packages ==="
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y chromium-browser

echo
echo "=== Creating desktop shortcut ==="
# Create Desktop directory if it doesn't exist
mkdir -p ~/Desktop

# Create desktop shortcut
cat > ~/Desktop/PortalKiosk.desktop <<EOF
[Desktop Entry]
Name=PortalKiosk
Exec=chromium-browser --kiosk --noerrdialogs --disable-infobars '$KIOSK_URL' &
Terminal=true
Type=Application
Icon=chromium-browser
Categories=Application;
EOF

chmod +x ~/Desktop/PortalKiosk.desktop

# Mark as trusted (for Ubuntu 20.04+)
if command -v gio &> /dev/null; then
    gio set ~/Desktop/PortalKiosk.desktop metadata::trusted true
fi

echo
echo "=== Setup Complete! ==="
echo
echo "Desktop shortcut created: PortalKiosk"
echo "Double-click 'PortalKiosk' on desktop to launch"
echo
echo "To exit kiosk mode: Press Alt+F4 or Ctrl+W"
echo
