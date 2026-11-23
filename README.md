# 🛡️ Focus Guardian (Homebrew Tap)

Official Homebrew Tap for **Focus Guardian** — the system-wide, multi-browser distraction blocker, deep work engine, and spiritual reflection guardian.

Focus Guardian operates natively at the operating system layer, running **completely independently of browser extensions**. It protects your focus across **Google Chrome, Microsoft Edge, Brave, Mozilla Firefox, Safari, Arc, Opera, Vivaldi, and any future browser**.

> 🌐 **Cross-Platform Engine:**
> While this repository is the dedicated Homebrew distribution for macOS, Focus Guardian runs natively across all major platforms:
> - 🪟 **[Windows (Winget) Setup Guide](docs/WINDOWS.md)**
> - 🐧 **[Linux (systemd) Setup Guide](docs/LINUX.md)**
> - 🏛️ **[Technical Architecture & Internal Specs](ARCHITECTURE.md)**

---

## 🚀 Quick Install (macOS via Homebrew)

Open your Terminal and run:

```bash
# 1. Tap the repository
brew tap shireenazadsyed/focus-guardian

# 2. Trust the formula (Required by modern Homebrew)
brew trust --formula shireenazadsyed/focus-guardian/focus-guardian

# 3. Install Focus Guardian
brew install focus-guardian

# 4. Start the 24/7 background focus service
brew services start focus-guardian
```

*Focus Guardian is now actively guarding your focus in the background across all your browsers!*

---

## 🛠️ Management CLI Commands

The `focus-guardian` command-line interface is available globally from any terminal directory:

```bash
# Check service health, background processes, and active passes
focus-guardian status

# Trigger in-place hot reload of rules and safe harbor topics (zero downtime)
focus-guardian reload

# Run in foreground test mode (view live tab intercepts in terminal)
focus-guardian start

# Lock daemon with root privileges (anti-tamper protection)
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

*(All your personal preferences, whitelisted videos, custom settings, and dopamine passes in `~/.focus-guardian/` are permanently preserved across updates).*

---

## 🌟 Key Features

### 1. Zero Browser Extensions Required (Native OS Layer)
- Enforces deep focus directly at the operating system layer.
- Completely eliminates profile switching loopholes, Guest mode workarounds, and Incognito mode bypasses.
- Guards **Chrome, Safari, Edge, Brave, Firefox, Arc, Opera, Vivaldi**.

### 2. Balanced Distraction-First Content Filtering
- **Educational & Spiritual Allowed by Default:** Coding tutorials, university lectures, mathematics, science talks, Islamic lectures, Quranic classes, documentaries, and academic research pass freely without requiring manual keyword whitelisting.
- **Safe Harbor Priority Shield:** Core topics (`islam`, `quran`, `seerah`, `coding`, `tutorial`, `physics`, etc.) act as priority shields so educational series (e.g. *"Seerah Series Episode 4"*) are never confused with entertainment serials.
- **Distractions Intercepted:** Social media feeds (`instagram.com`, `tiktok.com`, `x.com`), OTT streaming platforms (Sony LIV, Netflix, Prime Video, Hotstar, Zee5, JioCinema), TV serials and dramas, gaming live streams, clickbait, and comedy skits.
- **Shorts Trap Killer:** Automatically intercepts 100% of YouTube Shorts (`/shorts/`).

### 3. Dual-Persona Reflection Engine (`http://127.0.0.1:8989/blocked`)
When a distraction is intercepted, your tab is redirected to a distraction-free, non-scrollable (`100dvh`) intervention page:

* **🌙 Spiritual (Islamic Mode):**
  * **Authentic Crystal-Clear Artwork:** Mosque silhouette at sunset in Light and Dark mode.
  * **Quranic Verses:** Arabic typography, translation, and Tafsir context (*Surah Al-Asr 103:1-3*).
  * **Prophetic Hadiths:** Reflections on the scarcity of free time and youth (*Sahih Al-Bukhari 6412*).
  * **100s Dual-Track Dhikr Engine:**
    * **Track 1: Sacred Tasbeeh (100s):** Cycles every 20s through *SubhanAllah*, *Alhamdulillah*, *Allahu Akbar*, *Astaghfirullah*, and *La ilaha illa Allah*.
    * **Track 2: Prophetic Duas (100s):** *SubhanAllahi wa bihamdihi* (33s), *HasbunAllahu wa ni'mal wakeel* (33s), and *Rabbi-shrah li sadri* (34s).
    * `+60s Extend` button for continuous remembrance.

* **🌱 Deep Focus (Universal / Stoic Mode):**
  * **Typography-Only Layout:** Clean reflection card without artwork.
  * **Time Scarcity Philosophy:** Reflections from Seneca (*On the Shortness of Life*) and Marcus Aurelius (*Meditations*).
  * **High-Performance Discipline:** Systems wisdom from Cal Newport (*Deep Work*) and James Clear (*Atomic Habits*).
  * **Focused 2-Card Toolset:** Automatically hides the Dhikr card in Deep Focus mode, focusing strictly on Pomodoro and Square Breathing.

* **💡 / 🌙 Theme Toggle:**
  * Displays a glowing **Light Bulb** icon 💡 in Light mode and a glowing **Half Moon** icon 🌙 in Dark mode.
  * Instant switching synchronized with system color schemes.

### 4. Interactive Dopamine Reset & Deep Work Tools
* **Perimeter Guided Box Breathing (4-4-4-4 Technique):**
  * Navy SEAL physiological reset: Inhale (4s) ➔ Hold (4s) ➔ Exhale (4s) ➔ Hold (4s).
  * Guide dot smoothly glides along the 4 outer edges of the box frame while keeping the center countdown number clean and prominent.
* **Pomodoro Deep Work Sprint (25 Minutes):**
  * Real-time SVG circular countdown ring for 25:00.
  * Goal task input prompt: *"What single task will you finish in this sprint?"*
  * Controls: Start, Pause, Reset (25m), and `+5m` Extend.
  * Audio Chime on completion synthesized natively via the HTML5 Web Audio API.
* **Smart "Return to Work":**
  * Navigating from an earlier work page (e.g. GitHub, Google Docs, Jira) uses `history.go(-2)` to jump back to work without re-triggering distraction blocks.
  * Fresh distraction tabs are cleanly closed to return focus to your desktop.

### 5. 1-Click "Allow this Video & Watch" (YouTube Educational Only)
* Instant safety valve on the reflection page for legitimate learning or spiritual videos with ambiguous titles.
* **YouTube Video ID Bound:** Extracts and whitelists only the unique 11-character YouTube `video_id` into `~/.focus-guardian/config/user_whitelist.json`.
* **Zero Social Media Poisoning:** The "Allow" button is strictly hidden for social media and streaming domains (Instagram, TikTok, X, Netflix). Non-video sites cannot be permanently whitelisted.
* **Auto-Expanding Pass Button:** When "Allow Video" is hidden on non-YouTube sites, "Use a Pass" smoothly expands to full width.

### 6. Intentional Dopamine Pass (Hybrid Model for Social Media)
* **Conscious, Time-Boxed Breaks:** Need to check an urgent message or 2FA code? Request a strictly timed pass: **5 Minutes (Quick Task)** or **10 Minutes (Standard Break)**.
* **Daily Quota Protection:** Hard cap of **2 passes per day** (configurable in `~/.focus-guardian/config/config.json`). When your daily quota hits zero, the unlock button is strictly locked.
* **10-Second Impulse Cooling-Off Gate:** Requires entering a specific purpose and enduring a mandatory 10-second reflection countdown before unlocking.
* **Zero-Friction Cancel:** Clicking *"Cancel & Stay Focused"* (or pressing `Esc`) instantly dismisses the dialog with zero required-field validation errors.
* **Wall-Clock Window & Automatic Eviction:** The timer runs continuously in real time. When `00:00` hits, Focus Guardian immediately re-locks the site across open browser tabs and delivers a native desktop notification.
* **Discipline Refund (Early Seal):** Finish your task in under 3 minutes? Click `[ 🔒 Re-Lock Now ]`! Focus Guardian records a **Discipline Win** and **refunds the pass 100% back to your daily balance**.

### 7. Anti-Tamper & Commitment Friction Shield
* **Root System Lock:** Running `focus-guardian install-root` anchors the daemon as a root service, making it impossible for standard user commands or task managers to kill.
* **Auto-Respawn:** Registered with native OS service managers (`launchd`, `systemd`, Windows Service). If terminated, it automatically restarts in < 1 second.
* **Friction-Protected Shutdown:** Stopping or uninstalling (`focus-guardian stop`) enforces:
  1. Native OS confirmation prompt.
  2. 30-Second Cooling-Off Period.
  3. Cognitive Typing Challenge: *"I choose distraction over my future"*.

---

## 🌐 Other Operating Systems (Windows & Linux)

While this repository is the official **Homebrew Tap for macOS**, Focus Guardian runs natively on Windows and Linux:

* 🪟 **Windows:** Install via Winget (`winget install shireenazadsyed.focus-guardian`) or PowerShell. Full setup in [docs/WINDOWS.md](docs/WINDOWS.md).
* 🐧 **Linux:** Run via native `systemd --user` units across X11 & Wayland. Full setup in [docs/LINUX.md](docs/LINUX.md).

---

## 🔒 Security & Privacy Guarantee

- **100% Local Execution:** Focus Guardian binds strictly to loopback (`127.0.0.1:8989`).
- **Zero Telemetry:** No analytics, tracking, or remote phone-home servers.
- **Zero Cloud Dependencies:** All classification, reflection pages, audio synthesis, and timing run completely on your local machine.

---

## 💬 Issues & Feature Requests

Encountered an issue or have an educational channel you'd like added to defaults?
Open an issue on the [Homebrew Tap Issue Tracker](https://github.com/ShireenAzadSyed/homebrew-focus-guardian/issues).
