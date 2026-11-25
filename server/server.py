#!/usr/bin/env python3
"""
Lockin - Local HTTP Server
Hosts the custom Islamic reflection and study intervention page.
Zero external dependencies (uses standard library http.server).
"""

import os
import sys
import re
import json
import random
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler
import subprocess

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from daemon.paths import (
    get_config_path,
    get_quotes_path,
    get_user_whitelist_path,
    get_asset_path
)
from daemon.pass_manager import PassManager
from daemon.platforms import get_platform

TEMPLATES_DIR = get_asset_path("server", "templates")
STATIC_DIR = get_asset_path("server", "static")
_pass_manager = PassManager()

def load_json(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"[Error] Failed to load {path}: {e}", file=sys.stderr)
        return {}

def close_active_browser_tab(browser_name=""):
    """
    Closes the active browser tab via the native OS platform adapter (macOS, Windows, Linux).
    """
    try:
        platform = get_platform()
        return platform.close_active_tab(browser_name)
    except Exception as e:
        print(f"[Error] Could not close tab via platform adapter: {e}", file=sys.stderr)
        return False

class GuardianRequestHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Clean logging
        pass

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path == "/" or path == "/blocked":
            self.serve_blocked_page()
        elif path.startswith("/static/"):
            self.serve_static(path[len("/static/"):])
        elif path == "/api/random-quote":
            self.serve_random_quote()
        elif path == "/api/status":
            self.send_json_response({"status": "running", "service": "Focus Pal"})
        elif path == "/api/pass-status":
            self.send_json_response(_pass_manager.get_status())
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"404 Not Found")

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path == "/api/close-tab":
            query = urllib.parse.parse_qs(parsed.query)
            browser = query.get("browser", [""])[0]
            success = close_active_browser_tab(browser)
            self.send_json_response({"success": success})
        elif path == "/api/allow-target":
            query = urllib.parse.parse_qs(parsed.query)
            raw_title = query.get("title", [""])[0].strip()
            raw_url = query.get("url", [""])[0].strip()

            # Clean title: strip "- YouTube" and generic fallback words
            clean_title = re.sub(r'\s*-\s*youtube$', '', raw_title, flags=re.IGNORECASE).strip()
            if clean_title.lower() in ["youtube", "home", "new tab", "non-educational video or streaming platform"]:
                clean_title = ""

            # Extract YouTube Video ID (allows reliable matching across URL variations)
            vid_m = re.search(r'(?:v=|\/shorts\/|\/embed\/|youtu\.be\/)([a-zA-Z0-9_-]{11})', raw_url)
            video_id = vid_m.group(1) if vid_m else ""

            if not video_id:
                self.send_json_response({
                    "success": False,
                    "error": "Only specific YouTube videos with valid Video IDs can be whitelisted. For social media, please use an Intentional Pass."
                })
                return

            whitelist_path = get_user_whitelist_path()
            try:
                data = {"channels": [], "titles": [], "urls": [], "video_ids": []}
                if os.path.exists(whitelist_path):
                    with open(whitelist_path, "r", encoding="utf-8") as f:
                        data = json.load(f)

                if video_id and video_id not in data.setdefault("video_ids", []):
                    data["video_ids"].append(video_id)

                if clean_title and len(clean_title) >= 5 and clean_title not in data.setdefault("titles", []):
                    data["titles"].append(clean_title)

                if raw_url and raw_url not in data.setdefault("urls", []):
                    data["urls"].append(raw_url)

                with open(whitelist_path, "w", encoding="utf-8") as f:
                    json.dump(data, f, indent=2)

                self.send_json_response({"success": True, "message": "Added to user whitelist", "video_id": video_id})
            except Exception as e:
                self.send_json_response({"success": False, "error": str(e)})
        elif path == "/api/request-pass":
            query = urllib.parse.parse_qs(parsed.query)
            target_url = query.get("url", [""])[0].strip()
            duration_str = query.get("duration", ["5"])[0].strip()
            reason = query.get("reason", [""])[0].strip()
            try:
                duration_mins = int(duration_str)
            except ValueError:
                duration_mins = 5

            success, res = _pass_manager.request_pass(target_url, duration_mins, reason)
            if success:
                self.send_json_response({"success": True, "pass": res, "redirect_url": target_url})
            else:
                self.send_json_response({"success": False, "error": str(res)})
        elif path == "/api/seal-pass":
            success, msg, refunded = _pass_manager.seal_pass_early()
            self.send_json_response({"success": success, "message": msg, "refunded": refunded})
        else:
            self.send_response(404)
            self.end_headers()

    def serve_blocked_page(self):
        html_path = os.path.join(TEMPLATES_DIR, "blocked.html")
        if os.path.exists(html_path):
            with open(html_path, "rb") as f:
                content = f.read()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(content)))
            self.end_headers()
            self.wfile.write(content)
        else:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(b"Template blocked.html not found.")

    def serve_static(self, filename):
        # Normalize and guard against directory traversal (../)
        file_path = os.path.realpath(os.path.join(STATIC_DIR, filename))
        real_static = os.path.realpath(STATIC_DIR)
        if not file_path.startswith(real_static) or not os.path.exists(file_path):
            self.send_response(404)
            self.end_headers()
            return

        content_types = {
            ".css": "text/css; charset=utf-8",
            ".js": "application/javascript; charset=utf-8",
            ".png": "image/png",
            ".jpg": "image/jpeg",
            ".jpeg": "image/jpeg",
            ".webp": "image/webp",
            ".svg": "image/svg+xml"
        }
        _, ext = os.path.splitext(filename)
        content_type = content_types.get(ext.lower(), "text/plain")

        with open(file_path, "rb") as f:
            data = f.read()

        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def serve_random_quote(self):
        quotes = load_json(get_quotes_path())
        quran_list = quotes.get("quranic_reminders", [])
        hadith_list = quotes.get("hadith_reminders", [])
        study_list = quotes.get("study_interventions", [])
        universal_list = quotes.get("universal_time_reminders", [])
        stoic_list = quotes.get("stoic_discipline_reminders", [])

        payload = {
            "quran": random.choice(quran_list) if quran_list else None,
            "hadith": random.choice(hadith_list) if hadith_list else None,
            "study": random.choice(study_list) if study_list else None,
            "universal": random.choice(universal_list) if universal_list else None,
            "stoic": random.choice(stoic_list) if stoic_list else None
        }
        self.send_json_response(payload)

    def send_json_response(self, data):
        body = json.dumps(data).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

class ReusableHTTPServer(HTTPServer):
    allow_reuse_address = True

_global_server = None

def run_server(host="127.0.0.1", port=8989):
    global _global_server
    try:
        _global_server = ReusableHTTPServer((host, port), GuardianRequestHandler)
        print(f"[Focus Pal Server] Listening at http://{host}:{port}/blocked")
        _global_server.serve_forever()
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"[Focus Pal Server] Port {port} already bound, continuing...")
            return
        raise e
    except KeyboardInterrupt:
        print("\n[Focus Pal Server] Stopping...")
        stop_server()

def stop_server():
    global _global_server
    if _global_server:
        try:
            _global_server.shutdown()
            _global_server.server_close()
        except Exception:
            pass
        _global_server = None

if __name__ == "__main__":
    config = load_json(get_config_path())
    srv_conf = config.get("server", {})
    host = srv_conf.get("host", "127.0.0.1")
    port = srv_conf.get("port", 8989)
    run_server(host, port)

