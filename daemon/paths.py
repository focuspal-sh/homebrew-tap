"""
Focus Pal - Unified Path & Asset Resolver
Supports both:
1. Source Development Mode (Running from local git repository)
2. Frozen Binary Mode (Compiled PyInstaller standalone executable)
"""

import os
import sys
import shutil

# 1. Base / Asset Directory (Templates, Static UI, Default Quotes & Config)
if getattr(sys, "frozen", False) and hasattr(sys, "_MEIPASS"):
    # Running inside a PyInstaller single-file bundle
    ASSET_DIR = sys._MEIPASS
    IS_FROZEN = True
else:
    # Running directly from source repository
    ASSET_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    IS_FROZEN = False

# 2. Writable User Data Directory (Logs, User Whitelist, Config Overrides, Triggers)
# In dev mode: uses repo directory so local development is self-contained.
# In frozen mode: uses ~/.focuspal with seamless backward migration from ~/.lockin / ~/.focus-guardian.
if IS_FROZEN:
    DATA_DIR = os.path.expanduser("~/.focuspal")
    for legacy_dir in [os.path.expanduser("~/.lockin"), os.path.expanduser("~/.focus-guardian")]:
        if not os.path.exists(DATA_DIR) and os.path.exists(legacy_dir):
            try:
                shutil.copytree(legacy_dir, DATA_DIR)
                break
            except Exception:
                pass
else:
    DATA_DIR = ASSET_DIR

# Ensure necessary writable subdirectories exist
os.makedirs(os.path.join(DATA_DIR, "logs"), exist_ok=True)
os.makedirs(os.path.join(DATA_DIR, "config"), exist_ok=True)

def get_asset_path(*rel_parts):
    """Returns path to a read-only bundled asset (template, css, js, default json)."""
    return os.path.join(ASSET_DIR, *rel_parts)

def get_data_path(*rel_parts):
    """Returns path to a writable runtime file (log, whitelist, trigger)."""
    return os.path.join(DATA_DIR, *rel_parts)

def get_config_path():
    """
    Returns path to config.json. Checks user overrides first, then falls back to bundled default.
    """
    user_cfg = os.path.join(DATA_DIR, "config", "config.json")
    if os.path.exists(user_cfg):
        return user_cfg
    return get_asset_path("config", "config.json")

def get_quotes_path():
    """
    Returns path to quotes.json. Checks user overrides first, then falls back to bundled default.
    """
    user_quotes = os.path.join(DATA_DIR, "config", "quotes.json")
    if os.path.exists(user_quotes):
        return user_quotes
    return get_asset_path("config", "quotes.json")

def get_user_whitelist_path():
    """Returns path to persistent user_whitelist.json."""
    return os.path.join(DATA_DIR, "config", "user_whitelist.json")

def get_classification_cache_path():
    """Returns path to classification_cache.json."""
    return os.path.join(DATA_DIR, "config", "classification_cache.json")

def get_log_path():
    """Returns path to guardian.log."""
    return os.path.join(DATA_DIR, "logs", "guardian.log")

def get_reload_trigger_path():
    """Returns path to reload.trigger."""
    return os.path.join(DATA_DIR, "config", "reload.trigger")

def get_temp_unlocks_path():
    """Returns path to persistent temp_unlocks.json (stores active and past dopamine passes)."""
    return os.path.join(DATA_DIR, "config", "temp_unlocks.json")

