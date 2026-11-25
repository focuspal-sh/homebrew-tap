"""
Focus Pal - Pure Zero-Keyword Content Classifier
Driven 100% by the 12-Category Focus Taxonomy, Dynamic HTML Page Analysis,
and YouTube's Native Machine Learning Innertube API.
Zero arbitrary buzzwords, zero keyword dictionaries, zero manual domain maintenance.
"""

import os
import re
import json
import urllib.parse
import urllib.request
from daemon.paths import get_user_whitelist_path
from daemon.pass_manager import PassManager
from daemon.metadata_scraper import MetadataScraper
from daemon.categories import (
    CATEGORIES,
    DEFAULT_CATEGORY_POLICIES,
    classify_html,
    classify_intent_from_text,
    map_youtube_category,
    get_category_info,
    get_category_display,
)

class ContentClassifier:
    def __init__(self, config):
        daemon_cfg = config.get("daemon", {})

        # Policy Mode: "balanced" (Distraction-First, Recommended) or "monk" (Strict Default-Deny)
        self.mode = daemon_cfg.get("mode", "balanced").lower()
        self.block_all_shorts = daemon_cfg.get("block_all_shorts", True)

        # 12-Category Focus Taxonomy Policies (Config overrides defaults)
        user_policies = config.get("category_policies", {})
        self.category_policies = {**DEFAULT_CATEGORY_POLICIES, **user_policies}

        # Load optional personal overrides
        self._load_custom_rules(config)

        self.scraper = MetadataScraper()
        self.pass_manager = PassManager()
        self.yt_metadata_cache = {}
        self.user_whitelist = self._load_user_whitelist()

    def _load_custom_rules(self, config):
        """Loads optional personal domain or channel overrides from config.json."""
        custom = config.get("custom_rules", {}) or config.get("rules", {})
        self.custom_blocked_domains = sorted(list(set(d.lower() for d in custom.get("custom_blocked_domains", []) if d)))
        self.channel_whitelist = sorted(list(set(c.lower() for c in custom.get("channel_whitelist", []) if c)))
        self.channel_blacklist = sorted(list(set(c.lower() for c in custom.get("channel_blacklist", []) if c)))

    def _load_user_whitelist(self):
        """Loads persistent user allowances from user_whitelist.json (1-click safety valve)."""
        try:
            path = get_user_whitelist_path()
            if os.path.exists(path):
                with open(path, "r", encoding="utf-8") as f:
                    return json.load(f)
        except Exception:
            pass
        return {"channels": [], "titles": [], "urls": [], "video_ids": []}

    def reload_user_whitelist(self):
        self.user_whitelist = self._load_user_whitelist()

    def _get_youtube_metadata(self, video_id):
        """
        Lookup of YouTube video metadata (category, author, title, keywords)
        via YouTube's native Innertube Player API (https://www.youtube.com/youtubei/v1/player).

        Zero HTML scraping, zero fragile regexes. Returns a unified dict:
        {
            "category": "Gaming",
            "author": "Channel Name",
            "title": "Video Title",
            "keywords": ["tag1", "tag2"]
        }
        Cached in memory to guarantee sub-millisecond local loop performance.
        """
        if not video_id:
            return {}
        if video_id in self.yt_metadata_cache:
            return self.yt_metadata_cache[video_id]

        meta = {"category": "", "author": "", "title": "", "keywords": []}
        try:
            url = "https://www.youtube.com/youtubei/v1/player"
            payload = {
                "videoId": video_id,
                "context": {
                    "client": {
                        "clientName": "WEB",
                        "clientVersion": "2.20231201.00.00"
                    }
                }
            }
            req = urllib.request.Request(
                url,
                data=json.dumps(payload).encode("utf-8"),
                headers={
                    "Content-Type": "application/json",
                    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 FocusGuardian/1.0"
                }
            )
            with urllib.request.urlopen(req, timeout=2.0) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                mf = data.get("microformat", {}).get("playerMicroformatRenderer", {})
                vd = data.get("videoDetails", {})

                meta["category"] = mf.get("category", "") or ""
                meta["author"] = vd.get("author", "") or ""
                meta["title"] = vd.get("title", "") or ""
                meta["keywords"] = vd.get("keywords", []) or []

                self.yt_metadata_cache[video_id] = meta
        except Exception:
            pass
        return meta

    def classify_title(self, title, url=""):
        """
        Pure zero-keyword classifier. Returns (is_distraction: bool, reason: str, clean_title: str).
        """
        clean_title = title.strip()
        lower_title = clean_title.lower()
        lower_url = url.lower() if url else ""
        domain = self._extract_domain(url)

        # -------------------------------------------------------------
        # 1. Active Intentional Dopamine Pass Check (Top Priority)
        # -------------------------------------------------------------
        if self.pass_manager.is_target_unlocked(url):
            return False, "Active Dopamine Pass", clean_title

        # -------------------------------------------------------------
        # 2. Safety Valve & Whitelist Checks
        # -------------------------------------------------------------
        # A. Local Reflection Server & Internal URLs
        if any(h in lower_url for h in ["127.0.0.1", "localhost", "::1"]):
            return False, "Local Service", clean_title

        # B. User 1-Click Allowances (user_whitelist.json)
        if url and any(w_url in lower_url for w_url in self.user_whitelist.get("urls", [])):
            return False, "User Allowed URL", clean_title

        if any(w_title in lower_title for w_title in self.user_whitelist.get("titles", [])):
            return False, "User Allowed Title", clean_title

        # -------------------------------------------------------------
        # 3. Custom User Overrides from config.json
        # -------------------------------------------------------------
        if domain and domain in self.custom_blocked_domains:
            return True, f"Custom Blocked Domain ({domain})", clean_title

        # -------------------------------------------------------------
        # 4. YouTube Native Innertube Classification
        # -------------------------------------------------------------
        is_youtube = "youtube.com" in lower_url or "youtu.be" in lower_url
        if is_youtube:
            # A. Instant Short-form Intercept (Social Media / Brainrot feed)
            if ("/shorts/" in lower_url or "#shorts" in lower_title) and self.block_all_shorts:
                cat_display = get_category_display("social_media_and_messaging")
                return True, f"{cat_display} Blocked (Shorts / Reels Feed)", clean_title

            # B. Extract YouTube videoId
            video_id = ""
            if "v=" in lower_url:
                try:
                    video_id = urllib.parse.parse_qs(urllib.parse.urlparse(url).query).get("v", [""])[0]
                except Exception:
                    pass
            elif "youtu.be/" in lower_url:
                video_id = lower_url.split("youtu.be/")[1].split("?")[0].split("/")[0]

            if video_id:
                # Whitelisted video ID or channel
                if video_id in self.user_whitelist.get("video_ids", []):
                    return False, "User Allowed Video ID", clean_title

                yt_meta = self._get_youtube_metadata(video_id)
                author = yt_meta.get("author", "").lower()
                yt_category = yt_meta.get("category", "")

                # User channel whitelist / blacklist overrides
                if author:
                    if any(w_chan in author for w_chan in self.user_whitelist.get("channels", [])):
                        return False, f"User Allowed Channel ({author})", clean_title
                    if any(w_chan in author for w_chan in self.channel_whitelist):
                        return False, f"Whitelisted Channel ({author})", clean_title
                    if any(b_chan in author for b_chan in self.channel_blacklist):
                        return True, f"Blacklisted Channel ({author})", clean_title

                # Map YouTube's native ML category into our 12-Category taxonomy
                if yt_category:
                    cat_id = map_youtube_category(yt_category)
                    policy = self.category_policies.get(cat_id, "allow")
                    cat_display = get_category_display(cat_id)

                    if policy == "block":
                        return True, f"{cat_display} Blocked (YouTube: {yt_category})", clean_title
                    else:
                        return False, f"{cat_display} Allowed (YouTube: {yt_category})", clean_title

        # -------------------------------------------------------------
        # 5. Dynamic HTML Classification Cache Check (Non-YouTube)
        # -------------------------------------------------------------
        if domain and not is_youtube:
            is_cached, cat_id, reason = self.scraper.check_domain_cache(domain)
            if is_cached:
                policy = self.category_policies.get(cat_id, "allow")
                if policy == "block":
                    cat_display = get_category_display(cat_id)
                    return True, f"{cat_display} Blocked ({reason})", clean_title
                else:
                    # Explicitly allowed by cached HTML classification policy
                    return False, f"{get_category_display(cat_id)} Allowed ({reason})", clean_title

        # -------------------------------------------------------------
        # 6. Real-Time Semantic Intent Analysis (Window Title & URL)
        # -------------------------------------------------------------
        # Sub-millisecond zero-latency check for browser window titles
        # (Zero hardcoded brand names, handles new/unlisted websites instantly)
        intent_res = classify_intent_from_text(clean_title, url)
        if intent_res:
            cat_id, reason = intent_res
            # Automatically cache this domain classification for instant subsequent hits
            if domain and not is_youtube:
                self.scraper.cache_domain(domain, cat_id, reason, clean_title)

            policy = self.category_policies.get(cat_id, "allow")
            if policy == "block":
                cat_display = get_category_display(cat_id)
                return True, f"{cat_display} Blocked ({reason})", clean_title
            else:
                return False, f"{get_category_display(cat_id)} Allowed ({reason})", clean_title

        # -------------------------------------------------------------
        # 7. Background Metadata Scraper for Unknown Websites
        # -------------------------------------------------------------
        if domain and not is_youtube and "." in domain:
            is_cached, _, _ = self.scraper.check_domain_cache(domain)
            if not is_cached:
                self.scraper.analyze_domain_async(url, domain)

        # -------------------------------------------------------------
        # 8. Policy Mode Evaluation
        # -------------------------------------------------------------
        if self.mode == "monk":
            return True, "Strict Monk Mode: Unverified Content Blocked", clean_title

        return False, "General Navigation", clean_title

    def _extract_domain(self, url):
        if not url:
            return ""
        try:
            parsed = urllib.parse.urlparse(url)
            domain = parsed.netloc.lower()
            if domain.startswith("www."):
                domain = domain[4:]
            return domain
        except Exception:
            return ""
