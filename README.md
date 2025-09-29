# Haven Panels Kiosk Setup

Quick setup script to configure Ubuntu as a web kiosk for Haven Panels displays.

## Usage

### Interactive Mode
Prompts for URL and configuration options:
```bash
curl -fsSL https://raw.githubusercontent.com/haven-panels/kiosk-setup/main/setup-kiosk.sh | bash
```

Direct Mode
Specify the kiosk URL directly:

```bash
curl -fsSL https://raw.githubusercontent.com/haven-panels/kiosk-setup/main/setup-kiosk.sh | bash -s -- "https://havenpanels.com"
```

What it does

Installs minimal Ubuntu desktop environment
Configures auto-login and kiosk mode
Sets up Chromium browser in fullscreen
Includes recovery mechanisms for reliability
Optional SSH server for remote management

Requirements

Fresh Ubuntu installation
Internet connection
Curl installed
User with sudo privileges


This makes it super easy to deploy kiosk systems for Haven Panels - just boot Ubuntu and run one command!
