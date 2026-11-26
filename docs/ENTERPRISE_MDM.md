# 🏢 Focus Pal: Enterprise & MDM Deployment Guide

A complete guide for IT Administrators and Security Teams deploying Focus Pal across managed macOS fleets using **Jamf Pro, Kandji, Microsoft Intune, VMware Workspace ONE, or SimpleMDM**.

---

## 🎯 Executive Summary for IT & Security Teams

Traditional browser extensions fail in enterprise environments because employees can easily bypass them using Incognito windows, Guest profiles, or downloading unmanaged alternate browsers. Furthermore, cloud-based monitoring extensions pose significant compliance risks by transmitting employee browsing history to third-party SaaS servers.

**Focus Pal solves this natively:**
* **Zero Browser Extensions:** Operates at the OS layer across Safari, Google Chrome, Arc, Brave, Microsoft Edge, and Firefox simultaneously.
* **Login-session protection:** Installs a root-owned LaunchAgent that runs as the logged-in user and restarts after an unexpected exit.
* **100% Offline & Private:** Binds strictly to `127.0.0.1:8989`. Zero telemetry, zero analytics, and zero data leaving the employee's machine (compliant with GDPR, HIPAA, and SOC 2 requirements).
* **Single Native Binary:** Self-contained Mach-O binary (`focuspal-engine`) with zero external runtime or Python dependencies.

---

## 📦 Enterprise Deployment Assets

Focus Pal is distributed as pre-compiled, self-contained binaries. IT administrators and enterprise teams **do not need to compile code or install build tools**. Everything needed for MDM deployment is available directly in the public release assets:

| Asset | Location / Download | Purpose |
|---|---|---|
| **Enterprise Installer (`.pkg`)** | **[FocusPal-v1.0.6.pkg](https://github.com/focuspal-sh/homebrew-tap/releases)** | Pre-compiled native macOS installer. Places the binary in `/usr/local/bin` and installs the login-session LaunchAgent. |
| **Silent TCC Profile (`.mobileconfig`)** | **[`com.focuspal.tcc.mobileconfig`](com.focuspal.tcc.mobileconfig)** | Upload directly to Jamf / Kandji / Intune to silently pre-approve browser automation (zero user dialogs). |

---

## 🚀 2-Step MDM Fleet Rollout

```
┌──────────────────────────────────────────────┐       ┌──────────────────────────────────────────────┐
│       1. Upload Pre-built .pkg to MDM        │       │       2. Upload .mobileconfig to MDM         │
│  Jamf/Intune distributes FocusPal.pkg        │ ────► │  Jamf/Intune pushes silent TCC policy        │
│  (Installs binary and starts login agent)   │       │  (Employees see ZERO permission pop-ups)     │
└──────────────────────────────────────────────┘       └──────────────────────────────────────────────┘
```

---

### Step 1: Deploy the Enterprise `.pkg` Package

1. Download **`FocusPal-v1.0.6.pkg`** from the [Focus Pal Releases Page](https://github.com/focuspal-sh/homebrew-tap/releases).
2. In your MDM console:
   - **Jamf Pro:** Navigate to *Settings ➔ Computer Management ➔ Packages* ➔ Upload `FocusPal-v1.0.6.pkg`. Create a Policy targeting your fleet with execution frequency set to *Once per computer*.
   - **Kandji:** Navigate to *Custom Apps* ➔ Add *Custom App* ➔ Upload `FocusPal-v1.0.6.pkg` ➔ Set execution to *Install once*.
   - **Microsoft Intune:** Navigate to *Apps ➔ macOS ➔ Add ➔ macOS app (PKG)* ➔ Upload `FocusPal-v1.0.6.pkg`.

**What the PKG does automatically upon deployment:**
- Installs the standalone compiled engine to `/usr/local/bin/focuspal-engine` and CLI to `/usr/local/bin/focuspal`.
- Installs the root-owned plist at `/Library/LaunchAgents/com.focuspal.daemon.plist`. It loads at the next login. An interactive `focuspal install-root` run activates it in the current session after installation.
- Disables the legacy Focus Pal root service on upgrade.
- Supplies package defaults from `/Library/Application Support/FocusPal/config`. Files in the current user's `~/.focuspal/config` take precedence.
- Users enable each browser with `focuspal permissions`, even when an MDM profile has already authorized Automation.

---

### Step 2: Deploy the Silent Automation Profile (`.mobileconfig`)

To ensure employees **never see AppleScript authorization dialogs**, deploy the pre-configured **Privacy Preferences Policy Control (PPPC)** profile:

1. Download **[`com.focuspal.tcc.mobileconfig`](com.focuspal.tcc.mobileconfig)** (also attached to [Releases](https://github.com/focuspal-sh/homebrew-tap/releases)).
2. In your MDM console:
   - **Jamf Pro:** Go to *Computers ➔ Configuration Profiles ➔ Upload* ➔ Select `com.focuspal.tcc.mobileconfig` ➔ Scope to your target devices.
   - **Kandji:** Go to *Library ➔ Add Custom Profile* ➔ Upload `com.focuspal.tcc.mobileconfig`.
   - **Microsoft Intune:** Go to *Devices ➔ macOS ➔ Configuration profiles ➔ Create ➔ Profile type: Templates ➔ Custom* ➔ Upload `com.focuspal.tcc.mobileconfig`.

This profile silently grants permission to `focuspal-engine` to inspect tab URLs across Google Chrome, Safari, Arc, Brave, and Microsoft Edge without displaying any macOS authorization prompts to the employee.

#### Example `.mobileconfig` Payload for Jamf / Kandji / Intune:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <array>
        <dict>
            <key>PayloadType</key>
            <string>com.apple.TCC.configuration-profile-policy</string>
            <key>PayloadIdentifier</key>
            <string>com.focuspal.tcc.automation</string>
            <key>PayloadUUID</key>
            <string>B4C2A3D1-E8F9-4C5A-9D2E-1F3A4B5C6D7E</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
            <key>Services</key>
            <dict>
                <key>AppleEvents</key>
                <array>
                    <!-- Allow Focus Pal to send Apple Events to Google Chrome -->
                    <dict>
                        <key>Identifier</key>
                        <string>/usr/local/bin/focuspal-engine</string>
                        <key>IdentifierType</key>
                        <string>path</string>
                        <key>CodeRequirement</key>
                        <string>identifier "com.focuspal.engine" or identifier "focuspal-engine"</string>
                        <key>AEReceiverIdentifier</key>
                        <string>com.google.Chrome</string>
                        <key>AEReceiverIdentifierType</key>
                        <string>bundleID</string>
                        <key>AEReceiverCodeRequirement</key>
                        <string>identifier "com.google.Chrome" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = EQHXZ8M8AV</string>
                        <key>Allowed</key>
                        <true/>
                    </dict>
                    <!-- Allow Focus Pal to send Apple Events to Safari -->
                    <dict>
                        <key>Identifier</key>
                        <string>/usr/local/bin/focuspal-engine</string>
                        <key>IdentifierType</key>
                        <string>path</string>
                        <key>CodeRequirement</key>
                        <string>identifier "com.focuspal.engine" or identifier "focuspal-engine"</string>
                        <key>AEReceiverIdentifier</key>
                        <string>com.apple.Safari</string>
                        <key>AEReceiverIdentifierType</key>
                        <string>bundleID</string>
                        <key>AEReceiverCodeRequirement</key>
                        <string>identifier "com.apple.Safari" and anchor apple</string>
                        <key>Allowed</key>
                        <true/>
                    </dict>
                    <!-- Allow Focus Pal to send Apple Events to Arc -->
                    <dict>
                        <key>Identifier</key>
                        <string>/usr/local/bin/focuspal-engine</string>
                        <key>IdentifierType</key>
                        <string>path</string>
                        <key>CodeRequirement</key>
                        <string>identifier "com.focuspal.engine" or identifier "focuspal-engine"</string>
                        <key>AEReceiverIdentifier</key>
                        <string>company.thebrowser.Browser</string>
                        <key>AEReceiverIdentifierType</key>
                        <string>bundleID</string>
                        <key>AEReceiverCodeRequirement</key>
                        <string>anchor apple generic and identifier "company.thebrowser.Browser" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = S6N382Y83G)</string>
                        <key>Allowed</key>
                        <true/>
                    </dict>
                    <!-- Allow Focus Pal to send Apple Events to System Events -->
                    <dict>
                        <key>Identifier</key>
                        <string>/usr/local/bin/focuspal-engine</string>
                        <key>IdentifierType</key>
                        <string>path</string>
                        <key>CodeRequirement</key>
                        <string>identifier "com.focuspal.engine" or identifier "focuspal-engine"</string>
                        <key>AEReceiverIdentifier</key>
                        <string>com.apple.systemevents</string>
                        <key>AEReceiverIdentifierType</key>
                        <string>bundleID</string>
                        <key>AEReceiverCodeRequirement</key>
                        <string>identifier "com.apple.systemevents" and anchor apple</string>
                        <key>Allowed</key>
                        <true/>
                    </dict>
                </array>
            </dict>
        </dict>
    </array>
    <key>PayloadDisplayName</key>
    <string>Focus Pal - Automation Permissions</string>
    <key>PayloadIdentifier</key>
    <string>com.focuspal.mdm.tcc</string>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadUUID</key>
    <string>A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
</dict>
</plist>
```

---

### Step 3: Centralized Fleet Policy Configuration

Administrators can lock down configuration templates deployed to `/Library/Application Support/FocusPal/config/config.json`. When owned by `root:wheel` (`chmod 644`), standard users cannot alter policy.

#### A. Strict Work Mode (Disable Distraction Passes Entirely)
For corporate machines or testing environments where social media breaks are disallowed:
```json
{
  "mode": "monk",
  "intentional_pass": {
    "enabled": false,
    "daily_quota": 0
  }
}
```

#### B. Company Safe Harbor Rules
Ensure company tools, intranet portals, Jira, Confluence, and GitHub are never intercepted by adding them to `rules/safe_harbor.json`:
```json
{
  "enterprise_tools": [
    "github.com",
    "atlassian.net",
    "slack.com",
    "google.com",
    "corp.yourcompany.internal"
  ]
}
```

---

## 🔒 Security & Compliance Architecture

| Requirement | Focus Pal Enterprise Compliance |
|---|---|
| **Data Residency** | 100% on-device. No data is transmitted across networks. |
| **Tamper Resistance** | Root system daemon restarts in `< 1s` if killed. Standard users cannot stop it without root/sudo. |
| **Network Security** | Reflection server binds exclusively to `127.0.0.1:8989` (loopback). Inaccessible from outside network interfaces. |
| **GDPR / Privacy** | Focus Pal performs transient inspection of tab titles in RAM; it does not log employee keystrokes, passwords, or personal data. |
| **Audit Logs** | Daemon events are streamed to `/var/log/focuspal.log` for ingestion into enterprise SIEM (Splunk, Datadog) if desired. |

---

## 💬 Enterprise Support & Questions
For assistance creating custom PPPC profiles, enterprise packaging, or Windows Intune scripts, open an issue on the [Focus Pal Tap Repository](https://github.com/focuspal-sh/homebrew-tap/issues).

