"""
Focus Pal - Cross-Platform OS Adapter Base
Defines the abstract interface for platform-specific browser monitoring,
tab redirection, and desktop notifications.
"""

from abc import ABC, abstractmethod
from typing import List, Tuple, Dict, Any, Optional
import urllib.parse

class BasePlatform(ABC):
    """
    Abstract interface for OS-level browser detection, window introspection,
    and tab manipulation.
    """
    def __init__(self, name: str, known_browsers: Optional[List[str]] = None):
        self.name = name
        self.known_browsers = known_browsers or [
            "Google Chrome", "Brave Browser", "Microsoft Edge", "Opera", "Vivaldi"
        ]

    @abstractmethod
    def get_running_browsers(self) -> List[str]:
        """
        Returns a list of currently running supported browser names.
        """
        raise NotImplementedError

    @abstractmethod
    def get_front_tab_info(self, browser_name: str) -> Tuple[bool, str, str]:
        """
        Returns (has_active_tab: bool, title: str, url: str) for the active window's front tab.
        """
        raise NotImplementedError

    def get_all_tabs(self, browser_name: str) -> List[Dict[str, Any]]:
        """
        Returns a list of dicts: [{'window_idx': int, 'tab_idx': int, 'title': str, 'url': str}]
        Default implementation returns empty list if deep tab enumeration is unsupported.
        """
        return []

    @abstractmethod
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
        raise NotImplementedError

    @abstractmethod
    def close_active_tab(self, browser_name: str = "") -> bool:
        """
        Closes the active/foreground tab in the specified browser (or active window).
        """
        raise NotImplementedError

    @abstractmethod
    def send_notification(self, title: str, subtitle: str, message: str) -> bool:
        """
        Displays a native desktop notification.
        """
        raise NotImplementedError

    def build_blocked_url(self, host: str, port: int, title: str, browser: str, reason: str, original_url: str = "") -> str:
        """
        Helper to construct the localized blocked reflection URL with encoded query parameters.
        """
        query_data = {
            "title": title,
            "browser": browser,
            "reason": reason
        }
        if original_url:
            query_data["url"] = original_url
        params = urllib.parse.urlencode(query_data)
        return f"http://{host}:{port}/blocked?{params}"

