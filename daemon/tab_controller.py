"""
Focus Pal - Tab Controller
Controls and redirects the active browser tab when a distraction is detected.
Supports Safari, Google Chrome, Brave Browser, Arc, Microsoft Edge, and generic browsers.
"""

import subprocess
import urllib.parse

class TabController:
    def __init__(self, host="127.0.0.1", port=8989):
        self.base_url = f"http://{host}:{port}/blocked"

    def redirect_tab(self, browser_name, blocked_title, reason):
        """
        Redirects the front tab of the given browser to the reflection page.
        """
        params = urllib.parse.urlencode({
            "title": blocked_title,
            "browser": browser_name,
            "reason": reason
        })
        target_url = f"{self.base_url}?{params}"
        browser_clean = browser_name.lower()

        # Immediate action: Pause any running video/audio and set URL
        if "safari" in browser_clean:
            script = f'''
            tell application "Safari"
                if (count of windows) > 0 then
                    try
                        do JavaScript "document.querySelectorAll('video, audio').forEach(e => e.pause());" in current tab of front window
                    end try
                    set URL of current tab of front window to "{target_url}"
                end if
            end tell
            '''
        elif "chrome" in browser_clean:
            script = f'''
            tell application "Google Chrome"
                if (count of windows) > 0 then
                    try
                        execute active tab of front window javascript "document.querySelectorAll('video, audio').forEach(e => e.pause());"
                    end try
                    set URL of active tab of front window to "{target_url}"
                end if
            end tell
            '''
        elif "brave" in browser_clean:
            script = f'''
            tell application "Brave Browser"
                if (count of windows) > 0 then
                    try
                        execute active tab of front window javascript "document.querySelectorAll('video, audio').forEach(e => e.pause());"
                    end try
                    set URL of active tab of front window to "{target_url}"
                end if
            end tell
            '''
        elif "edge" in browser_clean:
            script = f'''
            tell application "Microsoft Edge"
                if (count of windows) > 0 then
                    try
                        execute active tab of front window javascript "document.querySelectorAll('video, audio').forEach(e => e.pause());"
                    end try
                    set URL of active tab of front window to "{target_url}"
                end if
            end tell
            '''
        elif "arc" in browser_clean:
            script = f'''
            tell application "Arc"
                if (count of windows) > 0 then
                    try
                        execute active tab of front window javascript "document.querySelectorAll('video, audio').forEach(e => e.pause());"
                    end try
                    set URL of active tab of front window to "{target_url}"
                end if
            end tell
            '''
        else:
            # Fallback for Firefox / unscriptable browsers:
            # Send Cmd+L (focus address bar), set clipboard, and Cmd+V, Enter
            script = f'''
            set the clipboard to "{target_url}"
            tell application "System Events"
                keystroke "l" using {{command down}}
                delay 0.1
                keystroke "v" using {{command down}}
                key code 36 -- Enter key
            end tell
            '''

        try:
            res = subprocess.run(
                ["osascript", "-e", script],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            # Send native macOS notification banner (universal & secular)
            notif_script = f'''
            display notification "Distraction blocked. Return to your deep work and goals." with title "🤝 Focus Pal" subtitle "Focus Protected"
            '''
            subprocess.run(["osascript", "-e", notif_script], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            # If AppleScript failed, open target_url with system open command
            if res.returncode != 0:
                subprocess.run(["open", target_url], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True
        except Exception:
            subprocess.run(["open", target_url], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return False

    def close_tab(self, browser_name):
        """
        Closes the active tab in the browser.
        """
        browser_clean = browser_name.lower()
        if "safari" in browser_clean:
            script = 'tell application "Safari" to close current tab of front window'
        elif "chrome" in browser_clean:
            script = 'tell application "Google Chrome" to close active tab of front window'
        elif "brave" in browser_clean:
            script = 'tell application "Brave Browser" to close active tab of front window'
        elif "edge" in browser_clean:
            script = 'tell application "Microsoft Edge" to close active tab of front window'
        elif "arc" in browser_clean:
            script = 'tell application "Arc" to close active tab of front window'
        else:
            script = '''
            tell application "System Events"
                keystroke "w" using {command down}
            end tell
            '''
        try:
            subprocess.run(["osascript", "-e", script], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True
        except Exception:
            return False

