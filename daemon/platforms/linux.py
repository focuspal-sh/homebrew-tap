"""
Focus Pal - Linux Platform Adapter
Implements zero-extension browser monitoring for X11 & Wayland desktops.
Monitors Google Chrome, Chromium, Mozilla Firefox, Brave Browser, Microsoft Edge, and Opera.
"""

import os
import shutil
import subprocess
from typing import List, Tuple, Dict, Any, Optional
from .base import BasePlatform

LINUX_BROWSERS = [
    "google-chrome", "chrome", "chromium", "firefox",
    "brave-browser", "brave", "microsoft-edge", "opera", "vivaldi",
    "zen", "zen-browser", "floorp", "waterfox", "librewolf", "thorium-browser", "tor-browser"
]

LINUX_BROWSER_DISPLAY_NAMES = {
    "google-chrome": "Google Chrome",
    "chrome": "Google Chrome",
    "chromium": "Chromium",
    "firefox": "Mozilla Firefox",
    "brave-browser": "Brave Browser",
    "brave": "Brave Browser",
    "microsoft-edge": "Microsoft Edge",
    "opera": "Opera",
    "vivaldi": "Vivaldi",
    "zen": "Zen Browser",
    "zen-browser": "Zen Browser",
    "floorp": "Floorp",
    "waterfox": "Waterfox",
    "librewolf": "LibreWolf",
    "thorium-browser": "Thorium",
    "tor-browser": "Tor Browser"
}

class LinuxPlatform(BasePlatform):
    def __init__(self):
        super().__init__(name="Linux", known_browsers=list(set(LINUX_BROWSER_DISPLAY_NAMES.values())))
        self.is_wayland = bool(os.environ.get("WAYLAND_DISPLAY"))
        self.has_xdotool = bool(shutil.which("xdotool"))
        self.has_xprop = bool(shutil.which("xprop"))
        self.has_notify_send = bool(shutil.which("notify-send"))

    def get_running_browsers(self) -> List[str]:
        """
        Returns list of friendly browser names currently running on Linux via pgrep / ps.
        """
        running = set()
        for proc, friendly in LINUX_BROWSER_DISPLAY_NAMES.items():
            try:
                res = subprocess.run(["pgrep", "-x", proc], capture_output=True, check=False)
                if res.returncode == 0:
                    running.add(friendly)
            except Exception:
                pass
        return list(running)

    def get_front_tab_info(self, browser_name: str) -> Tuple[bool, str, str]:
        """
        Returns (has_tab: bool, title: str, url: str) for the active window.
        On X11: uses xdotool getactivewindow getwindowname.
        """
        raw_title = ""

        # 1. Try xdotool on X11
        if self.has_xdotool:
            try:
                res = subprocess.run(
                    ["xdotool", "getactivewindow", "getwindowname"],
                    capture_output=True,
                    text=True,
                    check=False,
                    timeout=1.0
                )
                if res.returncode == 0:
                    raw_title = res.stdout.strip()
            except Exception:
                pass

        # 2. Fallback: xprop on X11
        if not raw_title and self.has_xprop:
            try:
                res = subprocess.run(
                    ["xprop", "-root", "_NET_ACTIVE_WINDOW"],
                    capture_output=True,
                    text=True,
                    check=False,
                    timeout=1.0
                )
                if "window id #" in res.stdout:
                    win_id = res.stdout.split("window id #")[-1].strip().split()[0]
                    name_res = subprocess.run(
                        ["xprop", "-id", win_id, "_NET_WM_NAME"],
                        capture_output=True,
                        text=True,
                        check=False,
                        timeout=1.0
                    )
                    if "=" in name_res.stdout:
                        raw_title = name_res.stdout.split("=", 1)[-1].strip().strip('"')
            except Exception:
                pass

        if not raw_title:
            return False, "", ""

        # Verify active window is one of the supported browsers
        is_browser = False
        for b_name in self.known_browsers:
            if b_name.lower() in raw_title.lower() or browser_name.lower() in raw_title.lower():
                is_browser = True
                break

        if not is_browser:
            return False, "", ""

        # Clean title suffix (e.g. "<Title> - Google Chrome", "<Title> — Mozilla Firefox")
        clean_title = raw_title
        for b_name in self.known_browsers:
            if f" - {b_name}" in clean_title:
                clean_title = clean_title.split(f" - {b_name}")[0].strip()
            elif f" — {b_name}" in clean_title:
                clean_title = clean_title.split(f" — {b_name}")[0].strip()

        # Deduce URL / Domain from window title
        url = ""
        lower_raw = raw_title.lower()
        if "youtube.com" in lower_raw or "youtube" in lower_raw:
            url = "https://www.youtube.com"
        elif "instagram" in lower_raw:
            url = "https://www.instagram.com"
        elif "netflix" in lower_raw:
            url = "https://www.netflix.com"
        else:
            url = "https://" + clean_title.split()[0].lower() if clean_title else ""

        return True, clean_title, url

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
        Redirects the active browser tab on Linux to the blocked reflection page.
        """
        target_url = self.build_blocked_url(host, port, title, browser_name, reason, original_url)

        # Strategy A: X11 xdotool keystroke injection (Focus address bar -> Type URL -> Enter)
        if self.has_xdotool:
            try:
                # Ctrl + L to focus address bar
                subprocess.run(["xdotool", "key", "ctrl+l"], check=False)
                # Type target URL
                subprocess.run(["xdotool", "type", "--delay", "0", target_url], check=False)
                # Press Enter
                subprocess.run(["xdotool", "key", "Return"], check=False)
                self.send_notification("🤝 Focus Pal", "Distraction Blocked", title)
                return True
            except Exception:
                pass

        # Strategy B: xdg-open fallback
        try:
            subprocess.run(["xdg-open", target_url], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self.send_notification("🤝 Focus Pal", "Distraction Blocked", title)
            return True
        except Exception:
            return False

    def close_active_tab(self, browser_name: str = "") -> bool:
        """
        Closes the active tab on Linux by simulating Ctrl + W via xdotool or ydotool.
        """
        if self.has_xdotool:
            try:
                subprocess.run(["xdotool", "key", "ctrl+w"], check=False)
                return True
            except Exception:
                pass

        if shutil.which("ydotool"):
            try:
                # 29 is KEY_LEFTCTRL, 17 is KEY_W
                subprocess.run(["ydotool", "key", "29:1", "17:1", "17:0", "29:0"], check=False)
                return True
            except Exception:
                pass

        return False

    def send_notification(self, title: str, subtitle: str, message: str) -> bool:
        """
        Sends a standard Linux desktop notification via libnotify (notify-send).
        """
        if not self.has_notify_send:
            return False

        clean_title = f"{title} - {subtitle}".strip(" -")
        clean_msg = message[:120]
        try:
            subprocess.run(
                ["notify-send", "-a", "Focus Pal", "-i", "security-high", clean_title, clean_msg],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            return True
        except Exception:
            return False

