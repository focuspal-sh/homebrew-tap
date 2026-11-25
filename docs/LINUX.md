# 🐧 Focus Pal on Linux

Complete installation, background service setup, and desktop environment guide for Linux (Ubuntu, Debian, Fedora, Arch, Mint, Pop!_OS).

---

## 🚀 Installation Options

### Option 1: 1-Line Universal Installer (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/focuspal-sh/homebrew-tap/main/scripts/install.sh | bash
```
*Automatically detects systemd, installs the user service, and links `focuspal` into `/usr/local/bin`.*

### Option 2: Run Directly with Python
```bash
python3 daemon/guardian.py
```
*(Requires `xdotool` on X11: `sudo apt install xdotool` or `sudo dnf install xdotool`).*

---

## 🛠️ Management Commands

```bash
# Check service health and running processes
focuspal status
# or native systemd:
systemctl --user status focuspal

# Trigger hot reload of rules (zero downtime)
focuspal reload

# Start background service
focuspal start
# or native systemd:
systemctl --user start focuspal

# Run in foreground interactive mode
focuspal test

# Stop service
focuspal stop
# or
systemctl --user stop focuspal
```

---

## 🌐 Supported Linux Browsers

Focus Pal operates natively across both X11 and Wayland desktops for:
* **Google Chrome & Chromium**
* **Mozilla Firefox**
* **Brave Browser**
* **Microsoft Edge for Linux**
* **Opera**
* **Vivaldi**

---

## ⚙️ How it Works on Linux

1. **X11 Window Introspection:**
   Uses `xdotool` and `xprop` to query `_NET_ACTIVE_WINDOW` and `_NET_WM_NAME` to detect active browser tab titles with sub-millisecond response times.
2. **Wayland & AT-SPI2 Accessibility:**
   Connects to the desktop accessibility bus (`org.a11y.atspi`) over D-Bus to inspect accessible elements without browser extensions.
3. **Tab Redirection & Tab Close:**
   Navigates the browser to `http://127.0.0.1:8989/blocked` and closes tabs using native keystroke injection (`Ctrl + W`) via `xdotool` or `ydotool`.
4. **Desktop Notifications:**
   Uses standard `notify-send` via libnotify.

---

## 🛡️ Anti-Tamper Protection

Running `focuspal install-root` on Linux creates a system-wide root daemon in `/etc/systemd/system/focuspal.service`. Non-root users cannot kill or disable the service without `sudo` privileges.

