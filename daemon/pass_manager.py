"""
Focus Pal - Intentional Dopamine Pass Manager (Hybrid Model)
Manages temporary unlocks, daily quotas, cooling-off countdowns,
and early-seal discipline refunds.
"""

import os
import json
import time
import datetime
from urllib.parse import urlparse
from daemon.paths import get_temp_unlocks_path, get_config_path

class PassManager:
    def __init__(self):
        self.file_path = get_temp_unlocks_path()

    def _get_today_str(self):
        return datetime.date.today().isoformat()

    def _load_data(self):
        today = self._get_today_str()
        default_data = {
            "active_pass": None,
            "daily_usage": {
                "date": today,
                "count": 0,
                "early_seals": 0
            },
            "history": []
        }
        if not os.path.exists(self.file_path):
            return default_data

        try:
            with open(self.file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            # Reset daily count if date has changed
            usage = data.setdefault("daily_usage", {})
            if usage.get("date") != today:
                usage["date"] = today
                usage["count"] = 0
                usage["early_seals"] = 0
            return data
        except Exception:
            return default_data

    def _save_data(self, data):
        try:
            with open(self.file_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
        except Exception as e:
            print(f"[PassManager Error] Could not save data: {e}")

    def get_pass_limits(self):
        """Reads pass configuration limits from config.json."""
        try:
            with open(get_config_path(), "r", encoding="utf-8") as f:
                cfg = json.load(f)
            pass_cfg = cfg.get("pass_system", {})
            return {
                "enabled": pass_cfg.get("enabled", True),
                "daily_pass_limit": pass_cfg.get("daily_pass_limit", 2),
                "durations_minutes": pass_cfg.get("available_durations_minutes", [5, 10]),
                "early_seal_threshold_minutes": pass_cfg.get("early_seal_refund_threshold_minutes", 3),
                "cooldown_between_passes_minutes": pass_cfg.get("cooldown_between_passes_minutes", 15)
            }
        except Exception:
            return {
                "enabled": True,
                "daily_pass_limit": 2,
                "durations_minutes": [5, 10],
                "early_seal_threshold_minutes": 3,
                "cooldown_between_passes_minutes": 15
            }

    def get_status(self):
        """Returns current pass status, active pass info, and remaining daily quota."""
        data = self._load_data()
        limits = self.get_pass_limits()
        active = data.get("active_pass")
        now = time.time()

        # Check if active pass has expired
        if active:
            if now >= active.get("expires_at", 0):
                # Auto-expire
                active["status"] = "expired"
                data["history"].append(active)
                data["active_pass"] = None
                self._save_data(data)
                active = None

        daily_count = data["daily_usage"]["count"]
        limit = limits["daily_pass_limit"]
        remaining = max(0, limit - daily_count)

        last_expired = 0
        if not active and data.get("history"):
            last_entry = data["history"][-1]
            last_expired = last_entry.get("expires_at", 0)

        cooldown_seconds = limits["cooldown_between_passes_minutes"] * 60
        cooldown_remaining = max(0, int((last_expired + cooldown_seconds) - now))

        return {
            "enabled": limits["enabled"],
            "daily_limit": limit,
            "daily_used": daily_count,
            "daily_remaining": remaining,
            "early_seals_today": data["daily_usage"].get("early_seals", 0),
            "available_durations": limits["durations_minutes"],
            "early_seal_threshold_minutes": limits["early_seal_threshold_minutes"],
            "active_pass": active,
            "cooldown_remaining_seconds": cooldown_remaining if (remaining > 0 and not active) else 0
        }

    def is_target_unlocked(self, url):
        """Checks if a URL matches a currently active, unexpired pass."""
        data = self._load_data()
        active = data.get("active_pass")
        if not active or active.get("status") != "active":
            return False

        now = time.time()
        if now >= active.get("expires_at", 0):
            return False

        target_domain = active.get("target_domain", "").lower()
        if not target_domain:
            return False

        parsed = urlparse(url)
        url_domain = parsed.netloc.lower()
        if target_domain in url_domain or url_domain in target_domain:
            return True

        return False

    def request_pass(self, target_url, duration_minutes, reason):
        """Creates a new active pass if quota permits and reason is provided."""
        status = self.get_status()
        if not status["enabled"]:
            return False, "Pass system is disabled in config."

        if status["active_pass"]:
            return False, "A pass is already currently active."

        if status["daily_remaining"] <= 0:
            return False, f"Daily limit of {status['daily_limit']} passes reached for today."

        if status["cooldown_remaining_seconds"] > 0:
            mins = int(status["cooldown_remaining_seconds"] // 60) + 1
            return False, f"Cooldown in effect. Please wait {mins} more minutes before requesting another pass."

        clean_reason = (reason or "").strip()
        if len(clean_reason) < 3:
            return False, "Please enter a specific reason for this pass (minimum 3 characters)."

        # Parse target domain
        parsed = urlparse(target_url)
        target_domain = parsed.netloc.lower() or target_url.lower()
        target_domain = target_domain.split(":")[0]
        if target_domain.startswith("www."):
            target_domain = target_domain[4:]

        limits = self.get_pass_limits()
        allowed_durations = limits["durations_minutes"]
        if duration_minutes not in allowed_durations:
            duration_minutes = allowed_durations[0]

        now = time.time()
        duration_seconds = duration_minutes * 60
        expires_at = now + duration_seconds
        refund_threshold = limits["early_seal_threshold_minutes"] * 60

        new_pass = {
            "target_domain": target_domain,
            "target_url": target_url,
            "reason": clean_reason,
            "unlocked_at": now,
            "expires_at": expires_at,
            "duration_minutes": duration_minutes,
            "duration_seconds": duration_seconds,
            "refund_threshold_seconds": refund_threshold,
            "status": "active"
        }

        data = self._load_data()
        data["active_pass"] = new_pass
        data["daily_usage"]["count"] += 1
        self._save_data(data)

        return True, new_pass

    def seal_pass_early(self):
        """Early seal requested by the user: locks the site and refunds pass if under threshold."""
        data = self._load_data()
        active = data.get("active_pass")
        if not active or active.get("status") != "active":
            return False, "No active pass found to seal.", False

        now = time.time()
        elapsed = now - active.get("unlocked_at", now)
        refund_threshold = active.get("refund_threshold_seconds", 180)
        refunded = False

        if elapsed <= refund_threshold:
            # Under threshold: Discipline Win! Refund the pass
            refunded = True
            if data["daily_usage"]["count"] > 0:
                data["daily_usage"]["count"] -= 1
            data["daily_usage"]["early_seals"] = data["daily_usage"].get("early_seals", 0) + 1
            active["status"] = "sealed_early_refunded"
        else:
            active["status"] = "sealed_early"

        active["sealed_at"] = now
        active["elapsed_seconds"] = int(elapsed)
        data["history"].append(active)
        data["active_pass"] = None
        self._save_data(data)

        if refunded:
            msg = f"Locked in {int(elapsed)}s! Discipline Win: Pass refunded back to your daily balance. 🏆"
        else:
            msg = f"Locked in {int(elapsed // 60)}m {int(elapsed % 60)}s. Great job returning to focus!"

        return True, msg, refunded
