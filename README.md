# 🛡️ Homebrew Focus Guardian

Official Homebrew Tap for **Focus Guardian** — the system-wide, multi-browser distraction blocker, deep work engine, and reflection guardian for macOS.

Focus Guardian operates natively at the macOS operating system layer, running **completely independently of browser extensions**. It protects your focus across **Safari, Google Chrome, Brave, Arc, Firefox, Microsoft Edge, Opera, and any new browser** you download in the future.

---

## 🚀 Quick Install

Open your Terminal and run:

```bash
# 1. Tap the repository
brew tap shireenazadsyed/focus-guardian

# 2. Install Focus Guardian
brew install focus-guardian

# 3. Start the 24/7 background focus service
brew services start focus-guardian
```

*Focus Guardian is now actively guarding your focus in the background across all browsers!*

---

## 🛠️ Management CLI Commands

The `focus-guardian` command-line interface is available globally from any terminal directory:

```bash
# Check service health and running processes
focus-guardian status

# Trigger in-place hot reload of rules and code (zero downtime)
focus-guardian reload

# Run in foreground test mode (view live tab intercepts in terminal)
focus-guardian start

# Lock daemon with root privileges (tamper-proof)
focus-guardian install-root

# Attempt shutdown (triggers 3-stage anti-tamper confirmation shield)
focus-guardian stop

# Uninstall service (triggers 3-stage anti-tamper confirmation shield)
focus-guardian uninstall
```

---

## 🔄 Updating to the Latest Version

To update Focus Guardian whenever a new release is published:

```bash
brew update
brew upgrade focus-guardian
brew services restart focus-guardian
```

*(All your personal preferences, whitelisted videos, and custom settings in `~/.focus-guardian/` are permanently preserved across updates).*

---

## 🌟 Key Features

### 1. Zero Browser Extensions Required
- Operates at the macOS system level via native Inter-Process Communication (IPC).
- Completely eliminates profile switching loopholes, Guest mode workarounds, and Incognito mode bypasses.
- Guards **Safari, Chrome, Brave, Arc, Edge, Opera, Vivaldi, and future browsers**.

### 2. Balanced Distraction-First Content Filtering
- **Educational & Spiritual Allowed by Default:** Coding tutorials, university lectures, mathematics, science talks, Islamic lectures, Quranic classes, documentaries, and academic research pass freely without requiring manual keyword whitelisting.
- **Safe Harbor Priority Shield:** Core topics (`islam`, `quran`, `seerah`, `coding`, `tutorial`, `physics`, etc.) act as priority shields so educational series are never confused with entertainment serials.
- **Distractions Intercepted:** Social media feeds (`instagram.com`, `tiktok.com`, `x.com`), OTT streaming platforms (Sony LIV, Netflix, Prime Video, Hotstar, Zee5, JioCinema), TV serials and dramas, gaming live streams, clickbait, and comedy skits.
- **Shorts Trap Killer:** Automatically intercepts 100% of YouTube Shorts (`/shorts/`).

### 3. Dual-Persona Reflection Engine (`http://127.0.0.1:8989/blocked`)
When a distraction is intercepted, your tab is redirected to a distraction-free, non-scrollable (`100dvh`) intervention page:

* **🌙 Spiritual (Islamic Mode):**
  * **Quranic Verses:** Arabic typography, translation, and Tafsir context.
  * **Prophetic Hadiths:** Reflections on the scarcity of free time and youth.
  * **100s Dual-Track Dhikr Engine:** Sacred Tasbeeh (100s) and Prophetic Duas (100s) with `+60s Extend`.

* **🌱 Deep Focus (Universal / Stoic Mode):**
  * **Time Scarcity Philosophy:** Reflections from Seneca (*On the Shortness of Life*), Marcus Aurelius (*Meditations*), Leonardo da Vinci, and Viktor Frankl (*Man's Search for Meaning*).
  * **High-Performance Discipline:** Systems wisdom from Cal Newport (*Deep Work*), James Clear (*Atomic Habits*), and Epictetus.

### 4. Interactive Dopamine Reset & Deep Work Tools
* **Square / Box Breathing (4-4-4-4 Technique):**
  * Inhale (4s) ➔ Hold (4s) ➔ Exhale (4s) ➔ Hold (4s) with smooth color-pulsing orb to lower heart rate and eliminate impulsive clicking urges.
* **Pomodoro Deep Work Sprint (25 Minutes):**
  * Real-time SVG circular countdown ring for 25:00.
  * Goal task input prompt: *"What single task will you finish in this sprint?"*
  * Controls: Start, Pause, Reset (25m), and `+5m` Extend.
  * Audio Chime on completion synthesized natively via the HTML5 Web Audio API.

### 5. 1-Click "Allow this Video & Watch" (YouTube Only)
* Instant safety valve on the reflection page for legitimate learning or spiritual videos with ambiguous titles.
* **YouTube Video ID Bound:** Extracts and whitelists only the unique 11-character YouTube `video_id` into `~/.focus-guardian/config/user_whitelist.json`.
* **Zero Social Media Poisoning:** The "Allow" button is strictly hidden for social media and streaming domains (Instagram, TikTok, X, Netflix). Non-video sites cannot be permanently whitelisted.
* **Zero False Re-Blocks:** Unaffected by URL variations, timestamps (`&t=`), or tracking tags (`&feature=shared`).
* **Subsequent Scanning Protected:** Next videos clicked on YouTube continue to be scanned and blocked normally.

### 6. Intentional Dopamine Pass (Hybrid Model for Social Media)
* **Conscious, Time-Boxed Breaks:** Need to check an urgent Instagram message, reply to an X/Twitter DM, or verify a 2FA code? Request a strictly timed pass: **5 Minutes (Quick Task)** or **10 Minutes (Standard Break)**.
* **Daily Quota Protection:** Hard cap of **2 passes per day** (configurable). When your daily quota hits zero, the unlock button is strictly locked.
* **10-Second Impulse Cooling-Off Gate:** Requires entering a specific purpose and enduring a mandatory 10-second reflection countdown before unlocking, interrupting impulsive dopamine craving loops.
* **Wall-Clock Window & Automatic Eviction:** The timer runs continuously in real time. When `00:00` hits, macOS launchd and AppleScript immediately re-lock the site, redirect open tabs back to the reflection page, and display a native macOS notification: *"🛡️ Time's Up! Focus Guardian has re-locked your session."*
* **Discipline Refund (Early Seal):** Finish your task in under 3 minutes? Click `[ 🔒 I'm Done — Re-Lock Now ]`! Focus Guardian records a **Discipline Win** and **refunds the pass 100% back to your daily balance**.

### 7. Anti-Tamper & Commitment Friction Shield
* **Root System Lock:** Running `focus-guardian install-root` anchors the daemon under `/Library/LaunchDaemons/`, making it impossible for standard user commands or Activity Monitor to kill.
* **Auto-Respawn:** Registered with macOS `launchd` (`KeepAlive: true`). If terminated, macOS automatically restarts it in < 1 second.
* **Friction-Protected Shutdown:** Stopping or uninstalling (`focus-guardian stop`) enforces:
  1. Native macOS System Alert Popup dialog.
  2. 30-Second Cooling-Off Period.
  3. Cognitive Typing Challenge: *"I choose distraction over my future"*.

---

## 🔒 Security & Privacy Guarantee

- **100% Local Execution:** Focus Guardian binds strictly to loopback (`127.0.0.1:8989`).
- **Zero Telemetry:** No analytics, tracking, or remote phone-home servers.
- **Zero Cloud Dependencies:** All classification, reflection pages, audio synthesis, and timing run completely on your local Mac.

---

## 📋 System Requirements

- **Operating System:** macOS 12 (Monterey) or later (macOS 13 Ventura, macOS 14 Sonoma, macOS 15 Sequoia supported).
- **Architecture:** Apple Silicon (`arm64`: M1, M2, M3, M4, Pro, Max, Ultra) and Intel (`x86_64`).
- **Package Manager:** [Homebrew](https://brew.sh).

---

## 💬 Issues & Feature Requests

Encountered an issue or have an educational channel you'd like added to defaults?
Open an issue on the [Issue Tracker](https://github.com/ShireenAzadSyed/homebrew-focus-guardian/issues).

