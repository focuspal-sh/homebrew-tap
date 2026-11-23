# 🪟 Focus Pal on Windows

Complete installation, background service setup, and management guide for Windows 10 & Windows 11.

---

## 🚀 Installation Options

### Option 1: Windows Package Manager (Winget)
```powershell
winget install focuspal-sh.focuspal
```

### Option 2: 1-Line PowerShell Web Installer
Open PowerShell as Administrator and run:
```powershell
iwr -useb https://raw.githubusercontent.com/focuspal-sh/focuspal/main/install.ps1 | iex
```

### Option 3: Manual Git / Python Setup
```powershell
git clone https://github.com/focuspal-sh/focuspal.git
cd focuspal
python -m pip install -r requirements-windows.txt
python daemon/guardian.py
```

---

## 🛠️ Management Commands

```powershell
# Check background service status
focuspal status

# Hot-reload configuration and safe harbor rules
focuspal reload

# Start background service
focuspal start

# Run in foreground console mode to watch intercepts live
focuspal test

# Stop background service
focuspal stop
```

---

## 🌐 Supported Windows Browsers

Focus Pal operates natively at the Windows OS layer without browser extensions across:
* **Microsoft Edge** (Default Windows Browser)
* **Google Chrome**
* **Brave Browser**
* **Opera & Opera GX**
* **Vivaldi**
* **Mozilla Firefox**

---

## ⚙️ How it Works on Windows

1. **Active Window Title Introspection (`0% CPU`):**
   Uses `GetForegroundWindow` and `GetWindowTextW` from `user32.dll` to inspect foreground tab titles instantaneously.
2. **Address Bar Verification (UI Automation):**
   Connects to the Windows UI Automation accessibility tree (`UIAutomationCore.dll`) to verify exact URL paths without needing extensions.
3. **Tab Redirection & Tab Close:**
   Updates the address bar value pattern to `http://127.0.0.1:8989/blocked` and injects `VK_RETURN`, or sends `Ctrl + W` to close distraction tabs.

---

## 🛡️ Anti-Tamper Protection

On Windows, Focus Pal can register as a Windows Service running under the `NT AUTHORITY\SYSTEM` service account. Standard user accounts in Task Manager cannot terminate protected system processes without administrator credentials.

