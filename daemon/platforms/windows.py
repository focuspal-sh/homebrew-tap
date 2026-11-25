"""
Focus Pal - Windows Platform Adapter
Implements zero-extension browser monitoring, UI Automation address-bar introspection,
and native Windows window management.
Monitors Microsoft Edge, Google Chrome, Brave Browser, Opera, Vivaldi, and Mozilla Firefox.
"""

import sys
import subprocess
import time
from typing import List, Tuple, Dict, Any, Optional
from .base import BasePlatform

WINDOWS_BROWSERS = [
    "msedge.exe", "chrome.exe", "brave.exe", "opera.exe", "vivaldi.exe",
    "firefox.exe", "zen.exe", "floorp.exe", "waterfox.exe", "librewolf.exe",
    "thorium.exe", "arc.exe", "sidekick.exe", "tor.exe"
]

WINDOWS_BROWSER_NAMES = {
    "msedge.exe": "Microsoft Edge",
    "chrome.exe": "Google Chrome",
    "brave.exe": "Brave Browser",
    "opera.exe": "Opera",
    "vivaldi.exe": "Vivaldi",
    "firefox.exe": "Mozilla Firefox",
    "zen.exe": "Zen Browser",
    "floorp.exe": "Floorp",
    "waterfox.exe": "Waterfox",
    "librewolf.exe": "LibreWolf",
    "thorium.exe": "Thorium",
    "arc.exe": "Arc",
    "sidekick.exe": "Sidekick",
    "tor.exe": "Tor Browser"
}

class WindowsPlatform(BasePlatform):
    def __init__(self):
        super().__init__(name="Windows", known_browsers=list(WINDOWS_BROWSER_NAMES.values()))
        self._uia = None
        self._init_uia()

    def _init_uia(self):
        """Attempts to initialize Windows UI Automation helper if available."""
        if sys.platform != "win32":
            return
        try:
            import uiautomation as auto
            self._uia = auto
        except ImportError:
            # Graceful fallback: uiautomation will be optional; ctypes/Win32 used for titles & keys
            self._uia = None

    def get_running_browsers(self) -> List[str]:
        """
        Returns list of browser names currently running on Windows via tasklist.
        """
        running = []
        try:
            res = subprocess.run(
                ["tasklist", "/FO", "CSV", "/NH"],
                capture_output=True,
                text=True,
                check=False,
                timeout=1.5
            )
            out_lower = res.stdout.lower()
            for proc, friendly in WINDOWS_BROWSER_NAMES.items():
                if proc.lower() in out_lower:
                    running.append(friendly)
        except Exception:
            pass
        return running

    def get_front_tab_info(self, browser_name: str) -> Tuple[bool, str, str]:
        """
        Returns (has_tab: bool, title: str, url: str) for the active foreground window.
        Uses Win32 GetForegroundWindow and UIA for address bar inspection.
        """
        if sys.platform != "win32":
            return False, "", ""

        try:
            import ctypes
            from ctypes import wintypes

            user32 = ctypes.windll.user32
            hwnd = user32.GetForegroundWindow()
            if not hwnd:
                return False, "", ""

            # 1. Get Window Title (Instant, 0% CPU)
            length = user32.GetWindowTextLengthW(hwnd)
            buff = ctypes.create_unicode_buffer(length + 1)
            user32.GetWindowTextW(hwnd, buff, length + 1)
            window_title = buff.value.strip()

            if not window_title:
                return False, "", ""

            # Check if active window matches a supported browser
            is_browser = False
            for b_name in self.known_browsers:
                if b_name.lower() in window_title.lower() or browser_name.lower() in window_title.lower():
                    is_browser = True
                    break

            if not is_browser:
                return False, "", ""

            # 2. Extract Title & URL
            # In Chrome/Edge/Firefox, window title is formatted as: "<Tab Title> - <Browser Name>"
            clean_title = window_title
            for b_name in self.known_browsers:
                if f" - {b_name}" in clean_title:
                    clean_title = clean_title.split(f" - {b_name}")[0].strip()
                elif f" — {b_name}" in clean_title:
                    clean_title = clean_title.split(f" — {b_name}")[0].strip()

            url = ""
            # If UI Automation is available, inspect the Address Bar
            if self._uia:
                try:
                    control = self._uia.ControlFromHandle(hwnd)
                    # Common address bar IDs and names in Chromium & Edge
                    edit = control.EditControl(AutomationId="address-bar") or \
                           control.EditControl(Name="Address and search bar") or \
                           control.EditControl(Name="Search or enter web address")
                    if edit:
                        url = edit.GetValuePattern().Value
                except Exception:
                    pass

            # Fallback: Synthesize URL from title if navigation/domain is detected
            if not url:
                if "youtube.com" in window_title.lower() or "youtube" in window_title.lower():
                    url = "https://www.youtube.com"
                elif "instagram" in window_title.lower():
                    url = "https://www.instagram.com"
                elif "netflix" in window_title.lower():
                    url = "https://www.netflix.com"
                else:
                    url = "https://" + clean_title.split()[0].lower() if clean_title else ""

            return True, clean_title, url

        except Exception:
            return False, "", ""

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
        Redirects the active foreground tab on Windows to the blocked reflection page.
        """
        target_url = self.build_blocked_url(host, port, title, browser_name, reason, original_url)

        if sys.platform != "win32":
            return False

        try:
            import ctypes
            user32 = ctypes.windll.user32
            hwnd = user32.GetForegroundWindow()

            # Strategy A: Use UI Automation if present
            if self._uia and hwnd:
                try:
                    control = self._uia.ControlFromHandle(hwnd)
                    edit = control.EditControl(AutomationId="address-bar") or \
                           control.EditControl(Name="Address and search bar") or \
                           control.EditControl(Name="Search or enter web address")
                    if edit:
                        edit.GetValuePattern().SetValue(target_url)
                        # Press Enter (VK_RETURN = 0x0D)
                        user32.keybd_event(0x0D, 0, 0, 0)
                        time.sleep(0.05)
                        user32.keybd_event(0x0D, 0, 2, 0)
                        self.send_notification("🤝 Focus Pal", "Distraction Blocked", title)
                        return True
                except Exception:
                    pass

            # Strategy B: Generic Keystroke Injection (Ctrl + L -> Paste URL -> Enter)
            # VK_CONTROL = 0x11, 'L' = 0x4C, VK_RETURN = 0x0D
            # Open target URL via Windows default browser command
            subprocess.run(["cmd.exe", "/c", "start", "", target_url], check=False, shell=True)
            self.send_notification("🤝 Focus Pal", "Distraction Blocked", title)
            return True

        except Exception:
            return False

    def close_active_tab(self, browser_name: str = "") -> bool:
        """
        Closes the active tab on Windows by sending Ctrl + W (VK_CONTROL + 'W') to the active window.
        """
        if sys.platform != "win32":
            return False

        try:
            import ctypes
            user32 = ctypes.windll.user32
            VK_CONTROL = 0x11
            VK_W = 0x57

            # Press Ctrl + W
            user32.keybd_event(VK_CONTROL, 0, 0, 0)
            user32.keybd_event(VK_W, 0, 0, 0)
            time.sleep(0.05)
            # Release W + Ctrl
            user32.keybd_event(VK_W, 0, 2, 0)
            user32.keybd_event(VK_CONTROL, 0, 2, 0)
            return True
        except Exception:
            return False

    def send_notification(self, title: str, subtitle: str, message: str) -> bool:
        """
        Sends a native Windows Toast notification via PowerShell.
        """
        clean_msg = message.replace('"', '`"').replace("'", "’")[:80]
        clean_sub = subtitle.replace('"', '`"')[:50]

        ps_script = f'''
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
        $textNodes = $template.GetElementsByTagName("text")
        $textNodes.Item(0).AppendChild($template.CreateTextNode("{title} - {clean_sub}")) | Out-Null
        $textNodes.Item(1).AppendChild($template.CreateTextNode("{clean_msg}")) | Out-Null
        $toast = [Windows.UI.Notifications.ToastNotification]::new($template)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Focus Pal").Show($toast)
        '''
        try:
            subprocess.run(
                ["powershell", "-NoProfile", "-NonInteractive", "-Command", ps_script],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=1.5
            )
            return True
        except Exception:
            return False

