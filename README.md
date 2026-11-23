# 🤝 Focus Pal (Homebrew Tap)

### Your system-wide focus companion. Stay in flow without willpower.

Official Homebrew Tap for **Focus Pal** — the lightweight, tamper-resistant distraction blocker and deep work engine for macOS.

Focus Pal runs natively at the operating system level, operating **completely independently of browser extensions**. It protects your focus across **Safari, Google Chrome, Arc, Brave, Firefox, Microsoft Edge, Opera, and any future browser**.

---

## 🚀 Quick Install (macOS)

Open your Terminal and run:

```bash
# 1. Add the tap & install
brew tap focuspal-sh/tap
brew install focuspal

# 2. Lock 24/7 background protection (Recommended)
focuspal install-root
```

> **💡 Why `install-root` is recommended:**
> On modern macOS, standard background apps can be quit easily when cravings strike. Running `focuspal install-root` sets up Focus Pal as a protected system service that runs quietly in the background 24/7, restarts automatically if closed, and keeps you committed to your deep work.
>
> *(If you prefer running without root privileges, run `focuspal install` instead).*

### 3. Verify Permissions
```bash
focuspal permissions
```
*(macOS will prompt you once to allow Automation for your browsers — click **Allow**).*

---

## 💎 Why Focus Pal?

### 🛡️ 1. Zero Browser Extensions
- Works across **all browsers** (Chrome, Safari, Arc, Brave, Edge, Firefox).
- **No loopholes**: Opening an Incognito window, Guest profile, or separate browser won't bypass your focus shield.

### 🎓 2. Blocks Distractions, Never Your Studies
- **Learning allowed by default**: Watch Python tutorials, calculus lectures, research talks, and documentaries freely.
- **Distractions stopped instantly**: Social media feeds (Instagram, TikTok, X), streaming movies/shows (Netflix, Prime, Sony LIV), clickbait, and gaming streams are intercepted immediately.
- **Shorts Trap Killer**: 100% of mindless YouTube Shorts (`/shorts/`) are blocked automatically.
- **1-Click Video Allowance**: Found an educational video with an ambiguous title? Click *"Allow this Video & Watch"* to whitelist just that specific video.

### 🧘 3. Calm, Distraction-Free Reflection Page
When you open a blocked site, you aren't greeted with a jarring error. Instead, Focus Pal opens a peaceful, non-scrollable workspace to help you reset:
- **4-4-4-4 Box Breathing**: Navy SEAL physiological reset to calm dopamine spikes (Inhale 4s ➔ Hold 4s ➔ Exhale 4s ➔ Hold 4s).
- **25-Minute Pomodoro Sprint**: Instant deep work timer with goal setting and chime audio.
- **Deep Focus Philosophy**: Thoughtful stoic reflections from Seneca, Marcus Aurelius, and James Clear.
- **Optional Spiritual Reminder**: A secondary opt-in tab with Quranic reflections, Hadiths, and a 100-second mindful Dhikr counter.

### ⏱️ 4. Intentional 5-Minute Passes
Need to check an urgent message or grab a 2FA code?
- Request a **5-minute** or **10-minute** pass with a strict daily quota (2 passes/day).
- Includes a 10-second impulse cooling-off period before unlocking.
- **Discipline Refund**: Finish what you needed in under 3 minutes? Click `[ Re-Lock Now ]` and Focus Pal **refunds the pass 100% back to your daily balance**!

---

## 🛠️ Essential Commands

| Command | What it does |
|---|---|
| `focuspal status` | Check if Focus Pal is actively guarding in the background |
| `focuspal install-root` | Lock as a tamper-resistant root daemon (Recommended) |
| `focuspal install` | Install as standard user LaunchAgent |
| `focuspal permissions` | Test and prompt all required macOS permissions |
| `focuspal reload` | Instantly reload rules after changing config |
| `focuspal test` | Run in foreground mode (see live blocks in terminal) |
| `focuspal stop` | Pause protection (with a 30-second commitment pledge) |

---

## 🔄 Updating to the Latest Version

```bash
brew update
brew upgrade focuspal
```

---

## 🌐 Enterprise MDM & Other Operating Systems

- 🏢 **[Enterprise & MDM Deployment Guide (Jamf, Kandji, Intune)](docs/ENTERPRISE_MDM.md)** — Package into `.pkg` and deploy silent PPPC profiles.
- 🪟 **[Windows Guide](docs/WINDOWS.md)** — Install via Winget or PowerShell.
- 🐧 **[Linux Guide](docs/LINUX.md)** — Run via native systemd user services.
- 🏛️ **[Technical Architecture & Internal Specs](ARCHITECTURE.md)** — Detailed IPC diagrams, OS accessibility drivers, and taxonomy engine.

---

## 🔒 100% Local & Private
Focus Pal runs completely on your local machine (`127.0.0.1:8989`). Zero telemetry, zero analytics, zero data sent to external servers.
