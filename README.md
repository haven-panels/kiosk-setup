# Haven Panels Kiosk Setup

Quick setup script to create a desktop shortcut that launches the Haven Portal in kiosk mode on Ubuntu.

## Usage

### Default (Haven Portal)
Automatically configures kiosk for `https://portal.havenpanels.com`:
```bash
curl -fsSL https://raw.githubusercontent.com/haven-panels/kiosk-setup/main/setup-kiosk.sh | bash
```

### Custom URL
Specify a different URL:
```bash
curl -fsSL https://raw.githubusercontent.com/haven-panels/kiosk-setup/main/setup-kiosk.sh | bash -s -- "https://your-custom-url.com"
```

## What it does

- Installs Chromium browser
- Creates a desktop shortcut named "PortalKiosk"
- Configures the shortcut to launch the portal in fullscreen kiosk mode

## After Installation

1. **Launch Kiosk**: Double-click the "PortalKiosk" icon on your desktop
2. **Exit Kiosk**: Press `Alt+F4` or `Ctrl+W` to close the browser

## Requirements

- Ubuntu (any desktop version)
- Internet connection
- User with sudo privileges

## Kiosk Features

The kiosk launches with:
- Full screen mode (`--kiosk`)
- No error dialogs (`--noerrdialogs`)
- No information bars (`--disable-infobars`)

## Troubleshooting

If the desktop shortcut doesn't appear:
```bash
ls ~/Desktop/PortalKiosk.desktop
```

If the shortcut exists but won't launch, make it executable:
```bash
chmod +x ~/Desktop/PortalKiosk.desktop
```

To manually launch kiosk mode:
```bash
chromium-browser --kiosk --noerrdialogs --disable-infobars 'https://portal.havenpanels.com' &
```
