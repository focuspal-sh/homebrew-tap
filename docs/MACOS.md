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

# 3. Lock 24/7 background protection (Recommended)
focuspal install-root

# 4. Verify browser permissions
focuspal permissions
```

> **💡 Note:** Running `focuspal install-root` installs Focus Pal as a permanent background daemon in `/Library/LaunchDaemons/com.focuspal.rootdaemon.plist` (`root:wheel`). This ensures it runs 24/7 without being closed or killed in Activity Monitor. If you prefer running without root privileges, simply run `focuspal install`.

### Option 2: 1-Line Universal Curl Installer
```bash
curl -fsSL https://raw.githubusercontent.com/focuspal-sh/homebrew-tap/main/scripts/install.sh | bash
```

---

## 🛠️ Management CLI Commands

```bash
# Check service health and running processes
focuspal status

# Lock daemon with root privileges (tamper-proof 24/7 protection)
focuspal install-root

# Install as standard user LaunchAgent
focuspal install

# Test and proactively prompt all macOS browser & notification permissions
focuspal permissions

# Trigger in-place hot reload of rules and code (zero downtime)
focuspal reload

# Start 24/7 background service (detached, immune to Ctrl+C)
focuspal start

# Run in foreground test mode (view live tab intercepts in terminal)
focuspal test

# Attempt shutdown (triggers 3-stage anti-tamper confirmation shield)
focuspal stop

# Uninstall service
focuspal uninstall
```

---

## 🔒 macOS Permissions & Automation

Focus Pal operates natively using AppleScript application dictionaries and OS UI introspection (`Google Chrome`, `Safari`, `Brave Browser`, `Arc`, `Mozilla Firefox`, `Microsoft Edge`, `Opera`, `Vivaldi`).

### Granting Automation Permissions:
Run the built-in diagnostic and permission prompter:
```bash
focuspal permissions
```
When first prompted by macOS:
> *"Terminal / Focus Pal would like to control Google Chrome.app"*

Click **OK** to allow Focus Pal to inspect active distraction tabs and redirect them.

If permissions need manual verification:
1. Open **System Settings ➔ Privacy & Security ➔ Automation**.
2. Ensure your terminal (or Python) has checkmarks enabled next to **System Events** and your installed web browsers.
3. You can also run `focuspal permissions --open` to jump directly to this settings pane.

---

## 🛡️ Anti-Tamper Protection

Running `focuspal install-root` installs Focus Pal under `/Library/LaunchDaemons/com.focuspal.rootdaemon.plist` owned by `root:wheel`. It automatically restarts if killed via Activity Monitor and cannot be terminated without root authorization.

---

## 🏢 Enterprise & Fleet Deployment

Managing a fleet of MacBooks with **Jamf Pro, Kandji, or Microsoft Intune**?
See our dedicated guide: **[Enterprise & MDM Deployment Guide](ENTERPRISE_MDM.md)** for `.pkg` creation, silent PPPC automation profiles, and centralized policy enforcement.

