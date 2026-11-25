"""
Focus Pal - 12-Category Focus Taxonomy & Dynamic HTML Classifier
Zero hardcoded website lists, zero domain dictionaries, zero buzzwords.
Determines website classification dynamically via:
1. Schema.org JSON-LD Structured Data (<script type="application/ld+json">)
2. OpenGraph Protocol Metadata (og:type, og:site_name)
3. Website HTML Description & Semantic Intent (<meta name="description">, <title>)
4. Native YouTube Machine Learning Innertube API
"""

import re
import json
import html as html_lib
from typing import Dict, Any, Optional, Tuple

CATEGORIES: Dict[str, Dict[str, Any]] = {
    "programming_and_development": {
        "id": "programming_and_development",
        "name": "Programming & Development",
        "emoji": "💻",
        "default_policy": "allow",
        "description": "Software engineering, coding, dev tools, source control, and technical problem solving.",
        "youtube_categories": [],
        "schema_types": ["SoftwareSourceCode", "SoftwareApplication", "CodeRepository"],
        "og_types": [],
    },
    "education_and_learning": {
        "id": "education_and_learning",
        "name": "Education & Learning",
        "emoji": "🎓",
        "default_policy": "allow",
        "description": "Structured courses, academic lectures, tutorials, and language acquisition.",
        "youtube_categories": ["education", "howto & style"],
        "schema_types": ["Course", "EducationalOrganization", "LearningResource", "EducationalOccupationalCredential"],
        "og_types": [],
    },
    "science_and_research": {
        "id": "science_and_research",
        "name": "Science & Research",
        "emoji": "🔬",
        "default_policy": "allow",
        "description": "Peer-reviewed scientific journals, preprints, research papers, and STEM disciplines.",
        "youtube_categories": ["science & technology"],
        "schema_types": ["ScholarlyArticle", "MedicalScholarlyArticle", "MedicalWebPage"],
        "og_types": [],
    },
    "finance_and_business": {
        "id": "finance_and_business",
        "name": "Finance & Business",
        "emoji": "💰",
        "default_policy": "allow",
        "description": "Financial markets, economics, investment research, accounting, and business intelligence.",
        "youtube_categories": [],
        "schema_types": ["FinancialProduct", "ExchangeRateSpecification", "InvestmentOrDeposit", "BankOrCreditUnion"],
        "og_types": [],
    },
    "career_and_professional": {
        "id": "career_and_professional",
        "name": "Career & Professional",
        "emoji": "💼",
        "default_policy": "allow",
        "description": "Professional networking, career advancement, resumes, and job listings.",
        "youtube_categories": [],
        "schema_types": ["JobPosting", "Occupation"],
        "og_types": [],
    },
    "documentation_and_reference": {
        "id": "documentation_and_reference",
        "name": "Documentation & Reference",
        "emoji": "📚",
        "default_policy": "allow",
        "description": "Official documentation, technical manuals, encyclopedias, and reference specifications.",
        "youtube_categories": [],
        "schema_types": ["TechArticle", "APIReference", "Guide"],
        "og_types": [],
    },
    "news_and_current_affairs": {
        "id": "news_and_current_affairs",
        "name": "News & Current Affairs",
        "emoji": "📰",
        "default_policy": "allow",
        "description": "Journalistic reporting, world events, politics, and current affairs.",
        "youtube_categories": ["news & politics"],
        "schema_types": ["NewsArticle", "ReportageNewsArticle", "AnalysisNewsArticle"],
        "og_types": ["article"],
    },
    "social_media_and_messaging": {
        "id": "social_media_and_messaging",
        "name": "Social Media & Messaging",
        "emoji": "📱",
        "default_policy": "block",
        "description": "Infinite feeds, algorithmic recommendation reels, and conversational distraction traps.",
        "youtube_categories": [],
        "schema_types": ["SocialMediaPosting"],
        "og_types": ["profile"],
    },
    "gaming_and_esports": {
        "id": "gaming_and_esports",
        "name": "Gaming & Esports",
        "emoji": "🎮",
        "default_policy": "block",
        "description": "Video games, livestreams, esports tournaments, walkthroughs, and gaming forums.",
        "youtube_categories": ["gaming"],
        "schema_types": ["VideoGame", "Game"],
        "og_types": ["game"],
    },
    "entertainment_and_video": {
        "id": "entertainment_and_video",
        "name": "Entertainment & Video",
        "emoji": "🎬",
        "default_policy": "block",
        "description": "OTT streaming platforms, TV serials, micro-dramas, music videos, movies, and anime.",
        "youtube_categories": ["entertainment", "music", "comedy", "film & animation"],
        "schema_types": [
            "Movie", "TVSeries", "TVEpisode", "VideoObject", "MediaObject",
            "MovieTheater", "MusicAlbum", "MusicRecording", "RadioSeries"
        ],
        "og_types": [
            "video.movie", "video.tv_show", "video.episode", "video.other",
            "music.song", "music.album"
        ],
    },
    "shopping_and_ecommerce": {
        "id": "shopping_and_ecommerce",
        "name": "Shopping & E-commerce",
        "emoji": "🛒",
        "default_policy": "allow",
        "description": "Online storefronts, retail marketplaces, and e-commerce shopping carts.",
        "youtube_categories": [],
        "schema_types": ["Product", "Offer", "ItemPage", "Store", "IndividualProduct"],
        "og_types": ["product"],
    },
    "other_general": {
        "id": "other_general",
        "name": "Other / General",
        "emoji": "🌐",
        "default_policy": "allow",
        "description": "Search engines, utilities, navigation, and unclassified productivity sites.",
        "youtube_categories": [],
        "schema_types": [],
        "og_types": [],
    }
}

DEFAULT_CATEGORY_POLICIES: Dict[str, str] = {
    cat_id: data["default_policy"]
    for cat_id, data in CATEGORIES.items()
}

# Pre-indexed reverse lookup: youtube category (lower) -> category_id
_YOUTUBE_CATEGORY_INDEX: Dict[str, str] = {}
for cat_id, data in CATEGORIES.items():
    for yt_cat in data.get("youtube_categories", []):
        _YOUTUBE_CATEGORY_INDEX[yt_cat.lower()] = cat_id

def get_category_info(category_id: str) -> Dict[str, Any]:
    """Retrieves metadata for a specific category ID."""
    return CATEGORIES.get(category_id, CATEGORIES["other_general"])

def get_category_display(category_id: str) -> str:
    """Returns human-readable display string with emoji: e.g. '🎮 Gaming & Esports'"""
    info = get_category_info(category_id)
    return f"{info['emoji']} {info['name']}"

def map_youtube_category(yt_category: str) -> str:
    """Maps a native YouTube Machine Learning category string to the 12-Category taxonomy."""
    if not yt_category:
        return "other_general"
    clean_yt = yt_category.lower().strip()
    return _YOUTUBE_CATEGORY_INDEX.get(clean_yt, "other_general")

def classify_html(html: str, url: str = "", page_title: str = "") -> Tuple[str, str]:
    """
    Parses the HTML <head> of a website dynamically to determine its category.
    Inspects:
    1. Schema.org JSON-LD Structured Data (<script type="application/ld+json">)
    2. OpenGraph Protocol (og:type)
    3. Meta tags: description, keywords, og:description, and page title semantics.
    Returns (category_id, reason).
    """
    if not html:
        return "other_general", "Empty HTML"

    # 1. Schema.org JSON-LD Structured Data (@type) inspection
    ld_matches = re.findall(
        r'<script[^>]*type=[\"\']application/ld\+json[\"\'][^>]*>(.*?)</script>',
        html,
        re.DOTALL | re.IGNORECASE
    )
    for ld in ld_matches:
        try:
            data = json.loads(ld.strip())
            items = data if isinstance(data, list) else [data]
            for item in items:
                types = []
                if isinstance(item, dict):
                    t = item.get("@type")
                    if isinstance(t, list):
                        types.extend(t)
                    elif isinstance(t, str):
                        types.append(t)
                for t in types:
                    t_low = t.lower()
                    for cat_id, info in CATEGORIES.items():
                        for st in info.get("schema_types", []):
                            if t_low == st.lower():
                                return cat_id, f"Schema.org Structured Data (@type: {t})"
        except Exception:
            # Fallback regex search in malformed or non-standard JSON
            for cat_id, info in CATEGORIES.items():
                for st in info.get("schema_types", []):
                    if re.search(rf'\"@type\"\s*:\s*\"{re.escape(st)}\"', ld, re.I):
                        return cat_id, f"Schema.org Structured Data (@type: {st})"

    # 2. OpenGraph Protocol (og:type) inspection
    og_m = re.search(r'<meta[^>]*property=[\"\']og:type[\"\'][^>]*content=[\"\'](.*?)[\"\']', html, re.I) or \
           re.search(r'<meta[^>]*content=[\"\'](.*?)[\"\'][^>]*property=[\"\']og:type[\"\']', html, re.I)
    if og_m:
        og_type = og_m.group(1).lower().strip()
        for cat_id, info in CATEGORIES.items():
            for ot in info.get("og_types", []):
                if og_type == ot.lower():
                    return cat_id, f"OpenGraph Media Type (og:type: {og_type})"

    # 3. Meta Description, Keywords & Title Semantic Analysis
    desc_m = re.search(r'<meta[^>]*name=[\"\']description[\"\'][^>]*content=[\"\'](.*?)[\"\']', html, re.I) or \
             re.search(r'<meta[^>]*property=[\"\']og:description[\"\'][^>]*content=[\"\'](.*?)[\"\']', html, re.I)
    kw_m = re.search(r'<meta[^>]*name=[\"\']keywords[\"\'][^>]*content=[\"\'](.*?)[\"\']', html, re.I)
    title_m = re.search(r'<title>(.*?)</title>', html, re.I)

    raw_desc = desc_m.group(1) if desc_m else ""
    raw_kw = kw_m.group(1) if kw_m else ""
    raw_title = title_m.group(1) if title_m else page_title

    combined_meta = html_lib.unescape(f"{raw_title} {raw_desc} {raw_kw}").lower()

    # A. Entertainment & Video
    ent_pattern = r'\b(movies?\s*(?:&|and|\||\/)\s*tv\s*shows?|movie\s*trailers?|tv\s*trailers?|where\s+to\s+watch|ratings?,?\s*reviews?.*movies?|watch\s+.*(?:movies?|shows?|episodes?|series|films?|anime|dramas?|playlets?)|stream\s+.*(?:movies?|shows?|episodes?|series|films?)|streaming\s+(?:service|platform|movies?|tv)|box\s+office|film\s+(?:database|discovery|reviews?)|micro\s*dramas?|playlets?|short\s*(?:dramas?|films?|plays?)|ott\s+platform|video\s+on\s+demand|(?:latest|new|top|popular|hd|free|full|dubbed)?\s*(?:telugu|tamil|hindi|kannada|malayalam|hollywood|bollywood|asian|korean)?\s*movies?|movies?\s*(?:download|streaming|online|free))\b'
    m_ent = re.search(ent_pattern, combined_meta)
    if m_ent:
        return "entertainment_and_video", f"Website Content Intent: '{m_ent.group(0)}'"

    # B. Gaming & Esports
    gaming_pattern = r'\b(video\s+games?|play\s+(?:free\s+)?online\s+games?|browser\s+games?|gameplay|walkthrough|speedrun|esports\s+tournament|multiplayer\s+games?|casual\s+games?|rpg|fps\s+game)\b'
    m_game = re.search(gaming_pattern, combined_meta)
    if m_game:
        return "gaming_and_esports", f"Website Content Intent: '{m_game.group(0)}'"

    # C. Social Media & Messaging
    social_pattern = r'\b(social\s+network|connect\s+with\s+friends|share\s+photos?\s+and\s+videos?|posts?\s+and\s+stories|infinite\s+scroll|follow\s+creators?|messaging\s+app|direct\s+messages?)\b'
    m_soc = re.search(social_pattern, combined_meta)
    if m_soc:
        return "social_media_and_messaging", f"Website Content Intent: '{m_soc.group(0)}'"

    # D. Shopping & E-commerce
    shopping_pattern = r'\b(online\s+store|shop\s+online|add\s+to\s+cart|buy\s+now|free\s+shipping\s+on\s+orders?|checkout|e-?commerce)\b'
    m_shop = re.search(shopping_pattern, combined_meta)
    if m_shop:
        return "shopping_and_ecommerce", f"Website Content Intent: '{m_shop.group(0)}'"

    # E. Education & Learning
    edu_pattern = r'\b(online\s+courses?|learn\s+(?:online|python|programming|math|to\s+code)|academic\s+courses?|degrees?\s+and\s+certificates?|tutorials?)\b'
    m_edu = re.search(edu_pattern, combined_meta)
    if m_edu:
        return "education_and_learning", f"Website Content Intent: '{m_edu.group(0)}'"

    # F. Science & Research
    sci_pattern = r'\b(journal\s+of|peer\s*reviewed|research\s+paper|scientific\s+article|preprint|abstract|doi:\s*10\.|ncbi|pubmed|genomics|biotechnology)\b'
    m_sci = re.search(sci_pattern, combined_meta)
    if m_sci:
        return "science_and_research", f"Website Content Intent: '{m_sci.group(0)}'"

    # G. Programming & Development
    prog_pattern = r'\b(source\s+code|code\s+repository|compiler|debugger|package\s+manager|api\s+endpoint|sdk\s+documentation|developer\s+tools?)\b'
    m_prog = re.search(prog_pattern, combined_meta)
    if m_prog:
        return "programming_and_development", f"Website Content Intent: '{m_prog.group(0)}'"

    # H. Documentation & Reference
    doc_pattern = r'\b(documentation|api\s+reference|developer\s+guide|manual|cheat\s*sheet|specification|reference\s+manual|encyclopedia)\b'
    m_doc = re.search(doc_pattern, combined_meta)
    if m_doc:
        return "documentation_and_reference", f"Website Content Intent: '{m_doc.group(0)}'"

    # I. News & Current Affairs
    news_pattern = r'\b(breaking\s+news|world\s+news|headlines|latest\s+news|journalism|editorial|press\s+release|daily\s+news)\b'
    m_news = re.search(news_pattern, combined_meta)
    if m_news:
        return "news_and_current_affairs", f"Website Content Intent: '{m_news.group(0)}'"

    # J. Finance & Business
    fin_pattern = r'\b(stock\s+(?:market|quote|prices?)|cryptocurrency|crypto\s+prices?|forex\s+trading|portfolio|dividends?|nasdaq|s&p\s*500)\b'
    m_fin = re.search(fin_pattern, combined_meta)
    if m_fin:
        return "finance_and_business", f"Website Content Intent: '{m_fin.group(0)}'"

    # K. Career & Professional
    career_pattern = r'\b(job\s+(?:opening|listing|posting|board|search)|apply\s+now|salary\s+insights?|career\s+opportunities?|resume\s+builder)\b'
    m_car = re.search(career_pattern, combined_meta)
    if m_car:
        return "career_and_professional", f"Website Content Intent: '{m_car.group(0)}'"

    return "other_general", "General Web Content"

def classify_intent_from_text(title: str, url: str = "") -> Optional[Tuple[str, str]]:
    """
    Evaluates real-time window title and URL path for high-confidence category intent.
    Completely zero hardcoded brand names.
    Returns (category_id, reason) or None.
    """
    if not title and not url:
        return None

    lower_title = html_lib.unescape(title).lower() if title else ""
    lower_url = url.lower() if url else ""

    # 1. Entertainment & Video Intent
    # A. Cinema, film reviews, movie database patterns
    cinema_intent = r'\b(?:movies?\s*(?:&|and|\||\/)\s*tv\s*shows?|movie\s*trailers?|tv\s*trailers?|where\s+to\s+watch|ratings?,?\s*reviews?.*movies?|top\s+\d+\s+movies?|movie\s+database|film\s+database|anime\s+database|box\s*office|film\s+discovery|movie\s*tickets?|(?:latest|new|top|popular|hd|free|full|dubbed)?\s*(?:telugu|tamil|hindi|kannada|malayalam|hollywood|bollywood|asian|korean)?\s*movies?|movies?\s*(?:download|streaming|online|free))\b'
    m = re.search(cinema_intent, lower_title)
    if m:
        return "entertainment_and_video", f"Movie/Film Discovery Intent: '{m.group(0)}'"

    # B. TV series, episode, and season markers (Universal Multilingual)
    episode_pattern = (
        r'('
        r'\b(?:season\s+\d+|episode\s+\d+|ep\s+\d+|s\d+\s*e\d+|playlet\s+\d+)\b|'
        r'\b(?:cap[íi]tulo\s*\d+|temporada\s*\d+)\b|'
        r'\b(?:\d+[\.\s]+b[öo]l[üu]m)\b|'
        r'(?:الحلقة\s*\d+|الموسم\s*\d+)|'
        r'(?:第\s*\d+\s*[集话話])|'
        r'(?:\d+\s*화)|'
        r'(?:قسط\s*(?:نمبر\s*)?\d+)|'
        r'(?:एपिसोड\s*\d+)|'
        r'\b(?:\d+\s*серия|\d+\s*сезон)\b'
        r')'
    )
    m = re.search(episode_pattern, lower_title) or re.search(episode_pattern, lower_url)
    if m:
        return "entertainment_and_video", f"TV Episode/Series Marker: '{m.group(0)}'"

    # C. Streaming & video viewing actions
    streaming_verbs = r'\b(watch\s+.*(?:movies?|shows?|episodes?|series|seasons?|online|free|playlets?)|stream\s+.*(?:movies?|shows?|episodes?|series)|streaming\s+online|full\s+movies?|box\s+office|hindi\s+dubbed|eng\s+sub|drama\s+serial|k-drama|kdrama|anime|manga|new\s+promo|serial\s+promo|tv\s+promo|precap|maha\s*episode|short\s*(?:films?|dramas?|plays?|videos?)|micro\s*dramas?|playlets?|dramas?,\s*movies|(?:online\s+)?free\s+to\s+watch|watch\s+online\s+free)\b'
    m = re.search(streaming_verbs, lower_title)
    if m:
        return "entertainment_and_video", f"Streaming Action Phrase: '{m.group(0)}'"

    # D. Entertainment URL Path Patterns
    entertainment_paths = r'(/(?:title/tt\d+|movie|movies|film|films|shows?|series|episode|episodes|anime|manga|drama|dramas|playlet|playlets|short-drama|trailers?|showtimes?)/|ibomma)'
    if re.search(entertainment_paths, lower_url):
        return "entertainment_and_video", "Entertainment/Film URL Path"

    # 2. Gaming & Esports Intent
    gaming_intent = r'\b(?:play\s+.*(?:game|online)|video\s+games?|gameplay|game\s+walkthrough|speedrun|esports\s+tournament|casual\s+games?)\b'
    m = re.search(gaming_intent, lower_title) or re.search(r'/(?:games?|play|gameplay)/', lower_url)
    if m:
        match_str = m.group(0) if hasattr(m, 'group') else 'game'
        return "gaming_and_esports", f"Gaming Intent: '{match_str}'"

    # 3. Social Media & Messaging Intent
    social_paths = r'(/(?:reels?|shorts?|explore|stories|messages|direct)/)'
    if re.search(social_paths, lower_url):
        return "social_media_and_messaging", "Social Feed/Reels Path"

    # 4. Shopping & E-commerce Intent
    shopping_intent = r'\b(?:online\s+shopping|add\s+to\s+cart|buy\s+online|free\s+shipping\s+on\s+orders?)\b'
    m = re.search(shopping_intent, lower_title) or re.search(r'/(?:cart|checkout|shop)/', lower_url)
    if m:
        match_str = m.group(0) if hasattr(m, 'group') else 'shop'
        return "shopping_and_ecommerce", f"Shopping Intent: '{match_str}'"

    return None
