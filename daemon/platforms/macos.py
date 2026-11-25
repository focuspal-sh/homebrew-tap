"""
Focus Pal - macOS Platform Adapter
Implements universal, zero-extension browser monitoring for macOS.
Automatically discovers any installed web browser (Chromium, Gecko, WebKit) dynamically
via Launch Services / Info.plist inspection and engine-family protocol routing,
completely eliminating the need to manually hardcode new browsers.
"""

import os
import plistlib
import re
import subprocess
import sys
from typing import List, Tuple, Dict, Any, Optional
from .base import BasePlatform

# Built-in comprehensive catalog across all 3 major browser engine families
POPULAR_BROWSERS = [
    # Chromium Family (Universal tab dictionary protocol)
    "Google Chrome", "Brave Browser", "Microsoft Edge", "Arc",
    "Opera", "Opera GX", "Vivaldi", "Chromium", "Sidekick",
    "Thorium", "Orion", "Wavebox", "SigmaOS", "Yandex", "Whale", "Colibri",
    # Gecko Family (Window title + Open Location protocol)
    "Firefox", "Mozilla Firefox", "Zen", "Zen Browser",
    "Floorp", "Waterfox", "LibreWolf", "Tor Browser", "Mullvad Browser",
    # WebKit Family
    "Safari", "Safari Technology Preview"
]

EXCLUDE_APPS = {
    "iterm", "iterm2", "terminal", "warp", "visual studio code", "code",
    "xcode", "chatgpt", "slack", "discord", "postman", "dbeaver", "finder", "dock"
}

GECKO_BROWSERS = {
    "firefox", "mozilla firefox", "zen", "zen browser", "floorp",
    "waterfox", "librewolf", "tor browser", "mullvad browser"
}

SAFARI_BROWSERS = {
    "safari", "safari technology preview"
}

class MacOSPlatform(BasePlatform):
    def __init__(self):
        super().__init__(name="macOS", known_browsers=self._discover_all_browsers())

    def _discover_all_browsers(self) -> List[str]:
        """
        Dynamically discovers all web browsers installed on the Mac
        by scanning /Applications and ~/Applications for HTTP/HTML handlers.
        Combines with built-in catalog so no manual browser updates are ever required.
        """
        browsers = set(POPULAR_BROWSERS)
        search_dirs = [
            "/Applications",
            os.path.expanduser("~/Applications"),
            "/System/Applications"
        ]
        for d in search_dirs:
            if not os.path.exists(d):
                continue
            try:
                for item in os.listdir(d):
                    if not item.endswith(".app"):
                        continue
                    name = item[:-4]
                    if name.lower() in EXCLUDE_APPS:
                        continue
                    plist_path = os.path.join(d, item, "Contents", "Info.plist")
                    if not os.path.exists(plist_path):
                        continue
                    try:
                        with open(plist_path, "rb") as f:
                            pl = plistlib.load(f)
                        has_http = False
                        for ut in pl.get("CFBundleURLTypes", []):
                            schemes = [s.lower() for s in ut.get("CFBundleURLSchemes", [])]
                            if "http" in schemes or "https" in schemes:
                                has_http = True
                                break
                        if has_http:
                            doc_types = pl.get("CFBundleDocumentTypes", [])
                            for dt in doc_types:
                                content_types = [str(c).lower() for c in dt.get("LSItemContentTypes", [])]
                                extensions = [str(e).lower() for e in dt.get("CFBundleTypeExtensions", [])]
                                if any("html" in ct for ct in content_types) or any(ext in ["html", "htm"] for ext in extensions):
                                    browsers.add(name)
                                    break
                    except Exception:
                        pass
            except Exception:
                pass
        return sorted(list(browsers))

    def _is_safari(self, browser_name: str) -> bool:
        return browser_name.lower() in SAFARI_BROWSERS

    def _is_gecko(self, browser_name: str) -> bool:
        b_low = browser_name.lower()
        return b_low in GECKO_BROWSERS or "firefox" in b_low or "zen" in b_low or "waterfox" in b_low or "floorp" in b_low or "librewolf" in b_low

    def get_running_browsers(self) -> List[str]:
        """
        Returns list of browser names currently running on macOS.
        Uses native POSIX 'ps' to inspect running processes instantly
        without triggering AppleScript / System Events permission dialogs.
        """
        try:
            res = subprocess.run(["ps", "-A", "-c", "-o", "comm"], capture_output=True, text=True, check=False, timeout=1.0)
            if res.returncode == 0 and res.stdout:
                all_procs = {line.strip() for line in res.stdout.splitlines() if line.strip()}
                procs_lower = {p.lower(): p for p in all_procs}
                running = []
                for b in self.known_browsers:
                    b_low = b.lower()
                    if b in all_procs:
                        running.append(b)
                    elif b_low in procs_lower:
                        running.append(procs_lower[b_low])
                return list(dict.fromkeys(running))
        except Exception:
            pass
        return []

    def get_front_tab_info(self, browser_name: str) -> Tuple[bool, str, str]:
        """
        Returns (has_tab: bool, title: str, url: str) for the front window's active tab.
        Automatically routes through Safari WebKit, Gecko/Firefox, or Chromium universal protocols.
        """
        if self._is_safari(browser_name):
            script = f'tell application "{browser_name}" to if (count of windows) > 0 then return (name of current tab of front window) & "|||" & (URL of current tab of front window)'
        elif self._is_gecko(browser_name):
            # Gecko Family (Firefox, Zen, Floorp, Waterfox, LibreWolf):
            # Query window title via System Events and attempt address bar extraction.
            script = f'''
            tell application "System Events"
                if exists (application process "{browser_name}") then
                    tell application process "{browser_name}"
                        if (count of windows) > 0 then
                            set wTitle to name of front window
                            try
                                set uVal to value of (first text field of front window)
                                return wTitle & "|||" & uVal
                            on error
                                return wTitle & "|||"
                            end try
                        end if
                    end tell
                end if
                return ""
            end tell
            '''
        else:
            # Universal Chromium Family (Chrome, Brave, Arc, Edge, Opera, Vivaldi, Thorium, Orion, etc.)
            script = f'tell application "{browser_name}" to if (count of windows) > 0 then return (title of active tab of front window) & "|||" & (URL of active tab of front window)'

        try:
            res = subprocess.run(["osascript", "-e", script], capture_output=True, text=True, check=False, timeout=1.0)
            raw = res.stdout.strip()
            if "|||" in raw:
                parts = raw.split("|||", 1)
                title = parts[0].strip()
                url = parts[1].strip() if len(parts) > 1 else ""
                if self._is_gecko(browser_name):
                    # Strip engine branding suffixes from window title
                    title = re.sub(r'\s*[\u2014\-]\s*(Mozilla\s+)?(Firefox|Zen|Floorp|Waterfox|LibreWolf).*$', '', title, flags=re.IGNORECASE).strip()
                return True, title, url
        except Exception:
            pass

        # Fallback for unknown browsers: try System Events window title if Chromium AppleScript failed
        if not self._is_safari(browser_name) and not self._is_gecko(browser_name):
            fallback_script = f'''
            tell application "System Events"
                if exists (application process "{browser_name}") then
                    tell application process "{browser_name}"
                        if (count of windows) > 0 then
                            return name of front window
                        end if
                    end tell
                end if
                return ""
            end tell
            '''
            try:
                fb_res = subprocess.run(["osascript", "-e", fallback_script], capture_output=True, text=True, check=False, timeout=1.0)
                if fb_res.returncode == 0 and fb_res.stdout.strip():
                    return True, fb_res.stdout.strip(), ""
            except Exception:
                pass

        return False, "", ""

    def get_all_tabs(self, browser_name: str) -> List[Dict[str, Any]]:
        """
        Returns list of dicts: [{'window_idx': int, 'tab_idx': int, 'title': str, 'url': str}]
        Supported natively across Safari and all Chromium browsers.
        """
        if self._is_gecko(browser_name):
            return []

        results = []
        if self._is_safari(browser_name):
            script = f'''
            set tabData to {{}}
            tell application "{browser_name}"
                set wIndex to 1
                repeat with w in windows
                    set tIndex to 1
                    repeat with t in tabs of w
                        set end of tabData to ((wIndex as string) & "|||" & (tIndex as string) & "|||" & (name of t) & "|||" & (URL of t))
                        set tIndex to tIndex + 1
                    end repeat
                    set wIndex to wIndex + 1
                end repeat
            end tell
            return tabData
            '''
        else:
            # Universal Chromium Family tab iteration
            script = f'''
            set tabData to {{}}
            tell application "{browser_name}"
                set wIndex to 1
                repeat with w in windows
                    set tIndex to 1
                    repeat with t in tabs of w
                        set end of tabData to ((wIndex as string) & "|||" & (tIndex as string) & "|||" & (title of t) & "|||" & (URL of t))
                        set tIndex to tIndex + 1
                    end repeat
                    set wIndex to wIndex + 1
                end repeat
            end tell
            return tabData
            '''
        try:
            res = subprocess.run(["osascript", "-e", script], capture_output=True, text=True, check=False, timeout=2.0)
            if res.returncode == 0 and res.stdout:
                entries = res.stdout.strip().split(", ")
                for entry in entries:
                    parts = entry.split("|||")
                    if len(parts) >= 4:
                        results.append({
                            "window_idx": int(parts[0]),
                            "tab_idx": int(parts[1]),
                            "title": parts[2].strip(),
                            "url": parts[3].strip()
                        })
        except Exception:
            pass
        return results

    def redirect_tab(
        self,
        browser_name: str,
        title: str,
        reason: str,
        window_idx: Optional[int] = None,
        tab_idx: Optional[int] = None,
        host: str = "127.0.0.1",
        port: int = 8989,
        original_url: str = ""
    ) -> bool:
        """
        Redirects the active tab (or specific tab by index) to the local blocked reflection page.
        """
        target_url = self.build_blocked_url(host, port, title, browser_name, reason, original_url)

        if self._is_gecko(browser_name):
            # Gecko family: close distraction tab & open blocked page
            script = f'''
            tell application "System Events"
                if exists (application process "{browser_name}") then
                    tell application process "{browser_name}"
                        keystroke "w" using {{command down}}
                    end tell
                end if
            end tell
            tell application "{browser_name}" to open location "{target_url}"
            '''
        elif window_idx is not None and tab_idx is not None:
            if self._is_safari(browser_name):
                script = f'tell application "{browser_name}" to set URL of tab {tab_idx} of window {window_idx} to "{target_url}"'
            else:
                script = f'tell application "{browser_name}" to set URL of tab {tab_idx} of window {window_idx} to "{target_url}"'
        else:
            if self._is_safari(browser_name):
                script = f'tell application "{browser_name}" to if (count of windows) > 0 then set URL of current tab of front window to "{target_url}"'
            else:
                # Universal Chromium family redirect
                script = f'tell application "{browser_name}" to if (count of windows) > 0 then set URL of active tab of front window to "{target_url}"'

        try:
            res = subprocess.run(["osascript", "-e", script], capture_output=True, text=True, check=False, timeout=1.5)
            self.send_notification("🤝 Focus Pal", "Distraction Blocked", title)
            return res.returncode == 0
        except Exception:
            return False

    def close_active_tab(self, browser_name: str = "") -> bool:
        """
        Sends AppleScript command to close the front tab of the specified browser.
        """
        if self._is_safari(browser_name):
            script = f'tell application "{browser_name}" to close current tab of front window'
        elif not self._is_gecko(browser_name):
            # Try native Chromium close command first
            script = f'tell application "{browser_name}" to close active tab of front window'
        else:
            # Gecko & generic fallback: Cmd + W keystroke
            script = f'''
            tell application "System Events"
                if exists (application process "{browser_name}") then
                    tell application process "{browser_name}"
                        keystroke "w" using {{command down}}
                    end tell
                else
                    keystroke "w" using {{command down}}
                end if
            end tell
            '''

        try:
            res = subprocess.run(["osascript", "-e", script], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return res.returncode == 0
        except Exception:
            # Final fallback
            try:
                fallback = 'tell application "System Events" to keystroke "w" using {command down}'
                subprocess.run(["osascript", "-e", fallback], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                return True
            except Exception as e:
                print(f"[Error] Could not close tab via AppleScript: {e}", file=sys.stderr)
                return False

    def send_notification(self, title: str, subtitle: str, message: str) -> bool:
        """
        Displays a native macOS notification banner via AppleScript.
        """
        clean_msg = message.replace('"', '').replace('\\', '').replace('\n', ' ')[:80]
        clean_sub = subtitle.replace('"', '').replace('\\', '')[:50]
        script = f'display notification "{clean_msg}" with title "{title}" subtitle "{clean_sub}"'
        try:
            subprocess.run(["osascript", "-e", script], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True
        except Exception:
            return False
