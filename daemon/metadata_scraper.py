"""
Focus Pal - Metadata Scraper & Dynamic HTML Analyzer
Fetches and analyzes OpenGraph and HTML metadata for unknown websites.
Classifies any website dynamically into the 12-Category Focus Taxonomy.
Caches decisions in config/classification_cache.json.
"""

import os
import re
import json
import time
import urllib.request
import threading
import logging
from typing import Tuple
from daemon.paths import get_classification_cache_path
from daemon.categories import classify_html, get_category_display

class MetadataScraper:
    def __init__(self):
        self.cache = self._load_cache()
        self.pending_domains = set()
        self.lock = threading.Lock()

    def _load_cache(self):
        try:
            cache_file = get_classification_cache_path()
            if os.path.exists(cache_file):
                with open(cache_file, "r", encoding="utf-8") as f:
                    return json.load(f)
        except Exception:
            pass
        return {}

    def _save_cache(self):
        try:
            cache_file = get_classification_cache_path()
            with open(cache_file, "w", encoding="utf-8") as f:
                json.dump(self.cache, f, indent=2)
        except Exception:
            pass

    def check_domain_cache(self, domain: str) -> Tuple[bool, str, str]:
        """
        Returns (is_cached: bool, category_id: str, reason: str)
        """
        if not domain:
            return False, "", ""
        domain_clean = domain.lower().strip()
        if domain_clean.startswith("www."):
            domain_clean = domain_clean[4:]

        if domain_clean in self.cache:
            entry = self.cache[domain_clean]
            cat_id = entry.get("category")
            # Backward-compatibility fallback if old cache entry format
            if not cat_id:
                cat_id = "entertainment_and_video" if entry.get("is_distraction") else "other_general"
            return True, cat_id, entry.get("reason", "")
        return False, "", ""

    def cache_domain(self, domain: str, category_id: str, reason: str, title: str = ""):
        """
        Explicitly records a domain classification into the cache.
        """
        if not domain:
            return
        domain_clean = domain.lower().strip()
        if domain_clean.startswith("www."):
            domain_clean = domain_clean[4:]

        with self.lock:
            self.cache[domain_clean] = {
                "category": category_id,
                "reason": reason,
                "title": title,
                "timestamp": time.time()
            }
            self._save_cache()

    def analyze_domain_async(self, url: str, domain: str):
        """
        Fetches HTML metadata in the background without blocking the main daemon loop.
        """
        if not domain:
            return
        domain_clean = domain.lower().strip()
        if domain_clean.startswith("www."):
            domain_clean = domain_clean[4:]

        with self.lock:
            if domain_clean in self.cache or domain_clean in self.pending_domains:
                return
            self.pending_domains.add(domain_clean)

        thread = threading.Thread(target=self._fetch_and_analyze, args=(url, domain_clean), daemon=True)
        thread.start()

    def _fetch_and_analyze(self, url: str, domain: str):
        headers = {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        }
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=3.5) as resp:
                html = resp.read(60000).decode("utf-8", errors="ignore")

                title_m = re.search(r'<title>(.*?)</title>', html, re.I)
                page_title = title_m.group(1).strip() if title_m else ""

                # Classify HTML page dynamically via Schema.org, OpenGraph & Meta semantics
                cat_id, reason = classify_html(html, url, page_title)

                with self.lock:
                    self.cache[domain] = {
                        "category": cat_id,
                        "reason": reason,
                        "title": page_title,
                        "timestamp": time.time()
                    }
                    self.pending_domains.discard(domain)
                    self._save_cache()

                cat_display = get_category_display(cat_id)
                logging.info(f"[Metadata Scraper] Classified '{domain}' as {cat_display}: {reason}")

        except Exception as e:
            with self.lock:
                self.pending_domains.discard(domain)
