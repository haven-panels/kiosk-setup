#!/bin/bash

# Ubuntu Kiosk Mode Setup Script
# Run this on a fresh Ubuntu installation to set up browser kiosk mode

set -e

echo "=== Ubuntu Kiosk Mode Setup ==="
echo "This script will configure Ubuntu to run a browser in kiosk mode"
echo

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Get kiosk URL from command line argument or user input
KIOSK_URL="$1"
if [[ -z "$KIOSK_URL" ]]; then
    read -p "Enter the URL to display in kiosk mode: " KIOSK_URL </dev/tty
    if [[ -z "$KIOSK_URL" ]]; then
        echo "No URL provided. Exiting."
        exit 1
    fi
fi

# Get username
KIOSK_USER=$(whoami)
echo "Setting up kiosk for user: $KIOSK_USER"

echo
echo "=== Updating system packages ==="
sudo apt update && sudo apt upgrade -y

echo
echo "=== Installing minimal desktop environment ==="
# Install minimal desktop environment
sudo apt install -y ubuntu-desktop-minimal

echo
echo "=== Installing additional packages ==="
# Install required packages
sudo apt install -y \
    chromium-browser \
    unclutter \
    x11-xserver-utils \
    lightdm \
    openbox

echo
echo "=== Configuring auto-login ==="
# Configure LightDM for auto-login
sudo tee /etc/lightdm/lightdm.conf.d/10-kiosk.conf > /dev/null <<EOF
[Seat:*]
autologin-user=$KIOSK_USER
autologin-user-timeout=0
user-session=openbox
EOF

echo
echo "=== Creating openbox configuration ==="
# Create openbox config directory
mkdir -p /home/$KIOSK_USER/.config/openbox

# Create openbox autostart script
cat > /home/$KIOSK_USER/.config/openbox/autostart <<EOF
#!/bin/bash

# Disable screen saver and power management
xset s off
xset -dpms
xset s noblank

# Hide cursor after inactivity
unclutter -idle 0.1 &

# Remove window decorations and start browser in kiosk mode
chromium-browser \\
    --kiosk \\
    --no-first-run \\
    --disable-infobars \\
    --disable-session-crashed-bubble \\
    --disable-translate \\
    --disable-features=TranslateUI \\
    --disable-ipc-flooding-protection \\
    --disable-background-timer-throttling \\
    --disable-backgrounding-occluded-windows \\
    --disable-renderer-backgrounding \\
    --disable-field-trial-config \\
    --disable-back-forward-cache \\
    --disable-backgrounding-occluded-windows \\
    --disable-features=VizDisplayCompositor \\
    --start-fullscreen \\
    --window-position=0,0 \\
    --window-size=1920,1080 \\
    --no-sandbox \\
    --disable-web-security \\
    "$KIOSK_URL"
EOF

# Make autostart executable
chmod +x /home/$KIOSK_USER/.config/openbox/autostart

echo
echo "=== Creating browser refresh script ==="
# Create a script to refresh the browser (useful for remote management)
sudo tee /usr/local/bin/refresh-kiosk <<EOF
#!/bin/bash
# Kill chromium and restart it
pkill chromium-browser
sleep 2
DISPLAY=:0 chromium-browser \\
    --kiosk \\
    --no-first-run \\
    --disable-infobars \\
    --disable-session-crashed-bubble \\
    --disable-translate \\
    --disable-features=TranslateUI \\
    --disable-ipc-flooding-protection \\
    --disable-background-timer-throttling \\
    --disable-backgrounding-occluded-windows \\
    --disable-renderer-backgrounding \\
    --disable-field-trial-config \\
    --disable-back-forward-cache \\
    --disable-features=VizDisplayCompositor \\
    --start-fullscreen \\
    --window-position=0,0 \\
    --window-size=1920,1080 \\
    --no-sandbox \\
    --disable-web-security \\
    "$KIOSK_URL" &
EOF

sudo chmod +x /usr/local/bin/refresh-kiosk

echo
echo "=== Configuring system settings ==="
# Disable automatic updates (optional - uncomment if desired)
# sudo systemctl disable unattended-upgrades

# Create a simple way to exit kiosk mode (Ctrl+Alt+F1)
echo "To exit kiosk mode, press Ctrl+Alt+F1 to get to a terminal"

echo
echo "=== Setting up SSH for remote management (recommended) ==="
read -p "Do you want to install SSH server for remote management? (y/n): " INSTALL_SSH </dev/tty
if [[ $INSTALL_SSH =~ ^[Yy]$ ]]; then
    sudo apt install -y openssh-server
    sudo systemctl enable ssh
    sudo systemctl start ssh
    echo "SSH server installed and started"
fi

echo
echo "=== Creating systemd service for kiosk recovery ==="
# Create a systemd service to restart the kiosk if it crashes
sudo tee /etc/systemd/system/kiosk-recovery.service > /dev/null <<EOF
[Unit]
Description=Kiosk Recovery Service
After=graphical-session.target

[Service]
Type=simple
User=$KIOSK_USER
Environment=DISPLAY=:0
ExecStart=/bin/bash -c 'while true; do sleep 30; if ! pgrep chromium-browser > /dev/null; then /usr/local/bin/refresh-kiosk; fi; done'
Restart=always

[Install]
WantedBy=graphical-session.target
EOF

sudo systemctl enable kiosk-recovery.service

echo
echo "=== Setup Complete! ==="
echo
echo "Configuration Summary:"
echo "- Auto-login user: $KIOSK_USER"
echo "- Kiosk URL: $KIOSK_URL"
echo "- Desktop Environment: Openbox (minimal)"
echo "- Browser: Chromium in kiosk mode"
echo
echo "Next steps:"
echo "1. Reboot the system: sudo reboot"
echo "2. The system will automatically log in and start the browser in kiosk mode"
echo
echo "Useful commands:"
echo "- Refresh kiosk: sudo /usr/local/bin/refresh-kiosk"
echo "- Exit to terminal: Ctrl+Alt+F1"
echo "- Return to kiosk: Ctrl+Alt+F7"
echo "- Edit kiosk URL: Edit /home/$KIOSK_USER/.config/openbox/autostart"
echo
echo "Ready to reboot? (y/n)"
read -p "> " REBOOT_NOW </dev/tty
if [[ $REBOOT_NOW =~ ^[Yy]$ ]]; then
    sudo reboot
else
    echo "System configured. Reboot when ready with: sudo reboot"
fi
EOF
