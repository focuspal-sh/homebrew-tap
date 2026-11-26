# 🪟 Focus Pal on Windows

Complete installation, background service setup, and management guide for Windows 10 & Windows 11.

---

## ⚡ Prerequisites

Focus Pal on Windows requires **Python 3.10+**.
If Python is not installed yet, open PowerShell and install it:
```powershell
winget install Python.Python.3.12
```
*(Or download from [python.org](https://www.python.org/downloads/) — be sure to check **"Add Python to PATH"** during setup).*

---

## 🚀 Installation Options

### Option 1: 1-Line PowerShell Web Installer (Recommended)

Open **PowerShell as Administrator** (right-click Start → *Terminal (Admin)* or *Windows PowerShell (Admin)*) and run (`irm` fetches the raw script and executes it):
```powershell
irm https://raw.githubusercontent.com/focuspal-sh/homebrew-tap/main/scripts/install.ps1 | iex
```
*(If run from a standard PowerShell window, the installer will automatically prompt for Administrator elevation via UAC.)*

**What this does automatically:**
1. Installs the Windows UI Automation library (`uiautomation`).
2. Deploys Focus Pal files to `%LOCALAPPDATA%\FocusPal`.
3. Adds the `focuspal` CLI command to your user PATH.
4. Creates a Windows Task Scheduler task (`FocusPalDaemon`) to run 24/7 in the background on startup.
5. Starts the background service immediately.

---

### Option 2: Run Directly from Cloned Repository

If you cloned or downloaded the Focus Pal repository, open **PowerShell as Administrator**:

```powershell
# 1. Navigate to the repository
cd focus-guardian

# 2. Run the Windows installer script
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

---

### Option 3: Manual Direct Run (Minimal)

If you just want to run Focus Pal directly with Python without any installer:

```powershell
# 1. Install UI Automation dependency
pip install uiautomation

# 2. Run in interactive foreground mode (view live terminal logs)
python daemon\guardian.py --foreground

# Or run silently in the background (no console window)
pythonw daemon\guardian.py
```

> [!TIP]
> **PowerShell Syntax Note ("The ampersand (&) character is not allowed"):**
> Unlike Linux/Bash, Windows PowerShell 5.1 does not allow `&&` to chain commands or `&` to background a process.
> * To chain commands in PowerShell, use a **semicolon (`;`)**:
>   ```powershell
>   pip install uiautomation ; python daemon\guardian.py
>   ```
> * To run in the background, use **`pythonw`** instead of appending `&`:
>   ```powershell
>   pythonw daemon\guardian.py
>   ```

---

## 🛠️ Management Commands

Once installed, use `focuspal` directly from any PowerShell or Command Prompt:

```powershell
# Check background service health & status
focuspal status

# Test in interactive console mode (view live interceptions)
focuspal test

# Hot-reload configuration and safe harbor rules
focuspal reload

# Start background service
focuspal start

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
* **Arc for Windows**

---

## ⚙️ How it Works on Windows (Zero Pop-ups)

Unlike macOS, Windows does **not** prompt the user with permission dialogs:
1. **Window Introspection (`0% CPU`):**
   Uses native Win32 APIs (`GetForegroundWindow` and `GetWindowTextW` from `user32.dll`) to detect active browser windows instantaneously with zero user prompts.
2. **Address Bar URL Verification (UI Automation):**
   Connects to the native Windows UI Automation accessibility tree (`UIAutomationCore.dll`) to verify exact URL paths without requiring any browser extensions.
3. **Tab Redirection:**
   Directs distraction tabs to the local calm reflection page at `http://127.0.0.1:8989/blocked`.

---

## 🗑️ Uninstallation

To remove Focus Pal from Windows at any time (works from any directory):
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/focuspal-sh/homebrew-tap/main/scripts/install.ps1))) -Uninstall
```
*(Or, if running from a cloned repository: `powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Uninstall`)*
