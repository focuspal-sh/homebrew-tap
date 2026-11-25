"""
Focus Pal - Multi-Platform Architecture
Auto-detects the host operating system (macOS, Windows, or Linux)
and initializes the native browser and window platform adapter.
"""

import sys
from typing import Optional
from .base import BasePlatform
from .macos import MacOSPlatform
from .windows import WindowsPlatform
from .linux import LinuxPlatform

_PLATFORM_INSTANCE: Optional[BasePlatform] = None

def get_platform() -> BasePlatform:
    """
    Returns the singleton OS platform adapter for the current host environment.
    """
    global _PLATFORM_INSTANCE
    if _PLATFORM_INSTANCE is not None:
        return _PLATFORM_INSTANCE

    if sys.platform == "darwin":
        _PLATFORM_INSTANCE = MacOSPlatform()
    elif sys.platform == "win32":
        _PLATFORM_INSTANCE = WindowsPlatform()
    elif sys.platform.startswith("linux"):
        _PLATFORM_INSTANCE = LinuxPlatform()
    else:
        # Fallback to base Linux-like generic adapter
        _PLATFORM_INSTANCE = LinuxPlatform()

    return _PLATFORM_INSTANCE

__all__ = [
    "BasePlatform",
    "MacOSPlatform",
    "WindowsPlatform",
    "LinuxPlatform",
    "get_platform"
]

