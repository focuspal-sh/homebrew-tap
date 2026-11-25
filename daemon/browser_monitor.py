"""
Focus Pal - Cross-Platform Browser Monitor
Delegates to native OS platform adapters (macOS, Windows, Linux)
to monitor, detect, and redirect web browsers without extensions.
"""

from typing import List, Tuple, Dict, Any, Optional
from .platforms import get_platform

class BrowserMonitor:
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        self.platform = get_platform()
        if config:
            custom = config.get("daemon", {}).get("custom_browsers", []) or config.get("rules", {}).get("custom_browsers", [])
            for c in custom:
                if c and c not in self.platform.known_browsers:
                    self.platform.known_browsers.append(c)
        self.known_browsers = self.platform.known_browsers

    def get_running_browsers(self) -> List[str]:
        """
        Returns list of browser names currently running on the host OS.
        """
        return self.platform.get_running_browsers()

    def get_front_tab_info(self, browser_name: str) -> Tuple[bool, str, str]:
        """
        Returns (has_tab: bool, title: str, url: str) for the active window's front tab.
        """
        return self.platform.get_front_tab_info(browser_name)

    def get_all_tabs(self, browser_name: str) -> List[Dict[str, Any]]:
        """
        Returns list of dicts: [{'window_idx': int, 'tab_idx': int, 'title': str, 'url': str}]
        """
        return self.platform.get_all_tabs(browser_name)

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
        return self.platform.redirect_tab(
            browser_name=browser_name,
            title=title,
            reason=reason,
            window_idx=window_idx,
            tab_idx=tab_idx,
            host=host,
            port=port,
            original_url=original_url
        )

    def close_active_tab(self, browser_name: str = "") -> bool:
        """
        Closes the front/active tab in the specified browser.
        """
        return self.platform.close_active_tab(browser_name)

    def send_notification(self, title: str, subtitle: str, message: str) -> bool:
        """
        Displays a native desktop notification across platforms.
        """
        return self.platform.send_notification(title, subtitle, message)
