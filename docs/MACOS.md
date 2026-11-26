# 🍎 Focus Pal on macOS

Complete installation, permission configuration, and management guide for macOS.

---

## 🚀 Installation Options

### Option 1: Official Homebrew Tap (Recommended)
```bash
# 1. Tap the repository
brew tap focuspal-sh/tap

# 2. Install Focus Pal
brew install focuspal

# 3. Open a browser window, then enable protection
focuspal permissions
```

### Option 2: 1-Line Universal Curl Installer
```bash
curl -fsSL https://raw.githubusercontent.com/focuspal-sh/homebrew-tap/main/scripts/install.sh | bash
```

---

## 🛠️ Management CLI Commands

```bash
# Check service health and running processes
focuspal status

# Install as standard user LaunchAgent
focuspal install

# Choose one browser and verify a test redirect
focuspal permissions

# Trigger in-place hot reload of rules and code (zero downtime)
focuspal reload

# Start 24/7 background service (detached, immune to Ctrl+C)
focuspal start

# Run in foreground test mode (view live tab intercepts in terminal)
focuspal test

# Uninstall service
focuspal uninstall
```

---

## 🔒 macOS Permissions & Automation

Open a window in Chrome, Safari, or another browser with a compatible AppleScript tab interface. Then choose a browser interactively or provide its name.

```bash
focuspal permissions
focuspal permissions "Google Chrome"
```

The running daemon requests Automation access for the selected browser and verifies it can read and redirect a dedicated test tab. Focus Pal saves the selection after the test succeeds. Each browser can be enabled separately. Firefox-family browsers use a different automation path and are outside this setup flow.

If the agent is offline, start it before running `focuspal permissions`. Run `focuspal permissions --status` to check status without starting the agent or prompting. If macOS denies access, use `focuspal permissions --open` to open Automation settings, then retry setup. Browser selections must be configured once when upgrading from a release that monitored every detected browser. If the daemon uses a custom HTTP port, set `FOCUSPAL_PORT` when running the permissions command.

---

## Background service

Focus Pal runs as a login-session LaunchAgent. The agent restarts if its process exits while the service is registered. Removing the service with `focuspal uninstall` requires a cooling-off period and confirmation.

For an administrator-owned installation, open Chrome or Safari and run `focuspal install-root` from your regular macOS account. The macOS installer asks for administrator access to install the package. Then run `focuspal permissions` to approve browser Automation from your login session. You can also use `focuspal permissions "Google Chrome"`.

The package disables legacy Focus Pal root services before starting the login agent.

---

## 🏢 Enterprise & Fleet Deployment

Managing a fleet of MacBooks with **Jamf Pro, Kandji, or Microsoft Intune**?
See our dedicated guide: **[Enterprise & MDM Deployment Guide](ENTERPRISE_MDM.md)** for `.pkg` creation, silent PPPC automation profiles, and centralized policy enforcement.

