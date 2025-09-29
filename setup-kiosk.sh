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
KIOSK_USER="kiosk"
echo "Setting up kiosk for user: $KIOSK_USER"

echo
echo "=== Creating kiosk user ==="
# Create kiosk user if it doesn't exist
if ! id "kiosk" &>/dev/null; then
    sudo useradd -m -s /bin/bash kiosk
    echo "kiosk:kiosk" | sudo chpasswd
    sudo usermod -aG sudo kiosk
    echo "Created kiosk user with password 'kiosk'"
else
    echo "Kiosk user already exists"
fi
echo
echo "=== Updating system packages ==="
sudo apt update && sudo apt upgrade -y

echo
echo "=== Installing minimal desktop environment ==="
# Install minimal desktop environment with non-interactive frontend
sudo DEBIAN_FRONTEND=noninteractive apt install -y ubuntu-desktop-minimal

echo
echo "=== Installing additional packages ==="
# Pre-configure lightdm selection to avoid TUI prompt
echo "lightdm lightdm/default-x-display-manager select lightdm" | sudo debconf-set-selections

# Install required packages
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    chromium-browser \
    unclutter \
    x11-xserver-utils \
    lightdm \
    openbox

echo
echo "=== Configuring auto-login ==="
# Configure LightDM for auto-login
sudo mkdir -p /etc/lightdm/lightdm.conf.d
sudo tee /etc/lightdm/lightdm.conf.d/10-kiosk.conf > /dev/null <<EOF
[Seat:*]
autologin-user=$KIOSK_USER
autologin-user-timeout=0
user-session=openbox
greeter-session=unity-greeter
EOF

# Also configure in main lightdm.conf as backup (create if doesn't exist)
if [[ ! -f /etc/lightdm/lightdm.conf ]]; then
    sudo tee /etc/lightdm/lightdm.conf > /dev/null <<EOF
[Seat:*]
autologin-user=$KIOSK_USER
autologin-user-timeout=0
user-session=openbox
EOF
else
    sudo sed -i "s/#autologin-user=/autologin-user=$KIOSK_USER/" /etc/lightdm/lightdm.conf
    sudo sed -i "s/#autologin-user-timeout=0/autologin-user-timeout=0/" /etc/lightdm/lightdm.conf
    sudo sed -i "s/#user-session=default/user-session=openbox/" /etc/lightdm/lightdm.conf
fi

echo
echo "=== Creating openbox configuration ==="
# Create openbox config directory
mkdir -p /home/$KIOSK_USER/.config/openbox

# Create openbox menu (minimal)
cat > /home/$KIOSK_USER/.config/openbox/menu.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="Openbox 3">
    <item label="Exit">
      <action name="Exit">
        <prompt>yes</prompt>
      </action>
    </item>
  </menu>
</openbox_menu>
EOF

# Create openbox rc.xml config
cat > /home/$KIOSK_USER/.config/openbox/rc.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc" xmlns:xi="http://www.w3.org/2001/XInclude">
  <resistance>
    <strength>10</strength>
    <screen_edge_strength>20</screen_edge_strength>
  </resistance>
  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
    <focusLast>yes</focusLast>
    <underMouse>no</underMouse>
    <focusDelay>200</focusDelay>
    <raiseOnFocus>no</raiseOnFocus>
  </focus>
  <placement>
    <policy>Smart</policy>
    <center>yes</center>
    <monitor>Primary</monitor>
    <primaryMonitor>1</primaryMonitor>
  </placement>
  <theme>
    <name>Clearlooks</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
    <animateIconify>yes</animateIconify>
    <font place="ActiveWindow">
      <name>sans</name>
      <size>8</size>
      <weight>bold</weight>
      <slant>normal</slant>
    </font>
    <font place="InactiveWindow">
      <name>sans</name>
      <size>8</size>
      <weight>bold</weight>
      <slant>normal</slant>
    </font>
    <font place="MenuHeader">
      <name>sans</name>
      <size>9</size>
      <weight>normal</weight>
      <slant>normal</slant>
    </font>
    <font place="MenuItem">
      <name>sans</name>
      <size>9</size>
      <weight>normal</weight>
      <slant>normal</slant>
    </font>
    <font place="ActiveOnScreenDisplay">
      <name>sans</name>
      <size>9</size>
      <weight>bold</weight>
      <slant>normal</slant>
    </font>
    <font place="InactiveOnScreenDisplay">
      <name>sans</name>
      <size>9</size>
      <weight>bold</weight>
      <slant>normal</slant>
    </font>
  </theme>
  <desktops>
    <number>1</number>
    <firstdesk>1</firstdesk>
    <names>
      <name>Kiosk</name>
    </names>
    <popupTime>875</popupTime>
  </desktops>
  <resize>
    <drawContents>yes</drawContents>
    <popupShow>Nonpixel</popupShow>
    <popupPosition>Center</popupPosition>
    <popupFixedPosition>
      <x>10</x>
      <y>10</y>
    </popupFixedPosition>
  </resize>
  <margins>
    <top>0</top>
    <bottom>0</bottom>
    <left>0</left>
    <right>0</right>
  </margins>
  <dock>
    <position>TopLeft</position>
    <floatingX>0</floatingX>
    <floatingY>0</floatingY>
    <noStrut>no</noStrut>
    <stacking>Above</stacking>
    <direction>Vertical</direction>
    <autoHide>no</autoHide>
    <hideDelay>300</hideDelay>
    <showDelay>300</showDelay>
    <moveButton>Middle</moveButton>
  </dock>
  <keyboard>
    <chainQuitKey>C-g</chainQuitKey>
  </keyboard>
  <mouse>
    <dragThreshold>1</dragThreshold>
    <doubleClickTime>500</doubleClickTime>
    <screenEdgeWarpTime>400</screenEdgeWarpTime>
    <screenEdgeWarpMouse>false</screenEdgeWarpMouse>
  </mouse>
  <menu>
    <file>menu.xml</file>
    <hideDelay>200</hideDelay>
    <middle>no</middle>
    <submenuShowDelay>100</submenuShowDelay>
    <submenuHideDelay>400</submenuHideDelay>
    <applicationIcons>yes</applicationIcons>
    <manageDesktops>yes</manageDesktops>
  </menu>
  <applications>
    <application class="*">
      <decor>no</decor>
      <maximized>true</maximized>
    </application>
  </applications>
</openbox_config>
EOF

# Create openbox autostart script
cat > /home/$KIOSK_USER/.config/openbox/autostart <<EOF
#!/bin/bash

# Wait for X to be ready
sleep 2

# Disable screen saver and power management
xset s off
xset -dpms
xset s noblank

# Hide cursor after inactivity
unclutter -idle 0.1 &

# Wait a bit more
sleep 3

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
    "$KIOSK_URL" &
EOF

# Make autostart executable and set proper ownership
chmod +x /home/$KIOSK_USER/.config/openbox/autostart
chown -R $KIOSK_USER:$KIOSK_USER /home/$KIOSK_USER/.config/

# Create .desktop file for openbox session
sudo mkdir -p /usr/share/xsessions
sudo tee /usr/share/xsessions/openbox.desktop > /dev/null <<EOF
[Desktop Entry]
Type=Application
Exec=openbox-session
TryExec=openbox-session
Name=Openbox
Comment=Log in using the Openbox window manager (without a panel)
EOF

# Create .xsession as fallback
echo "exec openbox-session" > /home/$KIOSK_USER/.xsession
chmod +x /home/$KIOSK_USER/.xsession
chown $KIOSK_USER:$KIOSK_USER /home/$KIOSK_USER/.xsession

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
