#!/usr/bin/env python3
"""
Focus Pal - Core System Daemon
Runs continuously on macOS, monitors active and background tabs across all browsers,
and redirects non-educational YouTube videos, Shorts, and distraction websites.
"""

import os
import sys
import time
import json
import threading
import logging

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE_DIR)

from daemon.paths import (
    get_config_path,
    get_log_path,
    get_reload_trigger_path
)
from daemon.browser_monitor import BrowserMonitor
from daemon.classifier import ContentClassifier
from daemon.pass_manager import PassManager
from server.server import run_server, stop_server

# Setup Logging
logging.basicConfig(
    filename=get_log_path(),
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

def load_config():
    config_path = get_config_path()
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        logging.error(f"Failed to load config: {e}")
        return {}

def start_server_thread(host, port):
    server_thread = threading.Thread(target=run_server, args=(host, port), daemon=True)
    server_thread.start()
    logging.info(f"Local Reflection Server started in background on {host}:{port}")
    return server_thread

def main():
    config = load_config()
    monitor = BrowserMonitor(config)
    platform_name = monitor.platform.name

    print("=" * 60)
    print(f" 🤝  FOCUS PAL - {platform_name} System Protection Active")
    print(" Multi-Browser Watcher • Deep Work Companion • Distraction Blocker")
    print("=" * 60)
    server_cfg = config.get("server", {})
    host = server_cfg.get("host", "127.0.0.1")
    port = server_cfg.get("port", 8989)

    # 1. Start local reflection HTTP server
    start_server_thread(host, port)

    # 2. Initialize components
    classifier = ContentClassifier(config)
    pass_manager = PassManager()

    interval = config.get("daemon", {}).get("check_interval_seconds", 0.5)
    last_intercept_title = ""
    last_intercept_time = 0
    last_background_scan = 0
    last_active_pass_domain = None
    reload_trigger = get_reload_trigger_path()

    logging.info("Focus Pal daemon initialized and watching.")

    while True:
        try:
            # 0. Check active dopamine pass expiration
            pass_status = pass_manager.get_status()
            current_active = pass_status.get("active_pass")
            if last_active_pass_domain and not current_active:
                logging.info(f"Intentional pass for '{last_active_pass_domain}' has ended. Focus re-locked.")
                monitor.send_notification(
                    title="🤝 Focus Pal",
                    subtitle="Time Expired",
                    message=f"Temporary pass for {last_active_pass_domain} has ended. Focus Pal re-activated."
                )
                last_active_pass_domain = None
            elif current_active:
                last_active_pass_domain = current_active.get("target_domain")

            # Hot reload if trigger file exists
            if os.path.exists(reload_trigger):
                try:
                    os.remove(reload_trigger)
                except Exception:
                    pass
                logging.info("Hot reload trigger detected! Re-executing daemon in place...")
                print("[Focus Pal] Reloading daemon code and configuration...")
                stop_server()
                os.execv(sys.executable, [sys.executable] + sys.argv)

            now = time.time()
            running_browsers = monitor.get_running_browsers()

            # Pass 1: Immediate check on frontmost tabs of all running browsers (very fast)
            for browser in running_browsers:
                has_tab, title, url = monitor.get_front_tab_info(browser)
                if not has_tab or not (title or url):
                    continue

                lower_title = title.lower()
                lower_url = url.lower()

                # Skip if already on the Focus Pal blocked page
                if f"127.0.0.1:{port}" in lower_url or f"localhost:{port}" in lower_url or "focus pal" in lower_title or "focuspal" in lower_title or "lockin" in lower_title or "focus guardian" in lower_title:
                    continue

                # Classify the page dynamically using semantic metadata & educational rules
                is_distraction, reason, clean_title = classifier.classify_title(title, url)

                if is_distraction:
                    # Debounce intercepts of the same title within 2.5s
                    if clean_title != last_intercept_title or (now - last_intercept_time) > 2.5:
                        last_intercept_title = clean_title
                        last_intercept_time = now

                        print(f"\n[INTERCEPT] Blocked on {browser}:")
                        print(f"  • Title: {clean_title}")
                        print(f"  • Reason: {reason}")
                        logging.info(f"BLOCKED [{browser}] '{clean_title}' Reason: {reason}")

                        monitor.redirect_tab(browser, clean_title, reason, host=host, port=port, original_url=url)

            # Pass 2: Periodic background scan of all open tabs (every 3 seconds)
            if (now - last_background_scan) > 3.0:
                last_background_scan = now
                for browser in running_browsers:
                    all_tabs = monitor.get_all_tabs(browser)
                    for tab in all_tabs:
                        t_url = tab["url"].lower()
                        t_title = tab["title"].lower()

                        if f"127.0.0.1:{port}" in t_url or f"localhost:{port}" in t_url or "focus guardian" in t_title:
                            continue

                        # Check if any background tab is running a distraction / OTT stream
                        is_dist, reason, clean = classifier.classify_title(tab["title"], tab["url"])
                        if is_dist:
                            print(f"\n[BACKGROUND INTERCEPT] Blocked on {browser} Tab {tab['tab_idx']}: {clean}")
                            logging.info(f"BACKGROUND BLOCKED [{browser}] Tab {tab['tab_idx']}: '{clean}' Reason: {reason}")
                            monitor.redirect_tab(
                                browser, clean, reason,
                                window_idx=tab["window_idx"],
                                tab_idx=tab["tab_idx"],
                                host=host, port=port,
                                original_url=tab["url"]
                            )

            time.sleep(interval)

        except KeyboardInterrupt:
            print("\n[Focus Pal] Exiting gracefully.")
            stop_server()
            break
        except Exception as e:
            logging.error(f"Error in guardian loop: {e}")
            time.sleep(interval)

if __name__ == "__main__":
    main()
