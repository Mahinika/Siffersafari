#!/usr/bin/env python3
"""Create a fully registered SVG-first character from a short brief."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import unicodedata
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:
    yaml = None


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
BASE_FORM_SOURCE = (
    SCRIPT_ROOT / "assets" / "characters" / "_shared" / "config" / "humanoid_base_form_v1.json"
)

SVG_PART_ORDER = [
    "head",
    "eyes_open",
    "eyes_blink",
    "mouth_neutral",
    "mouth_happy",
    "mouth_sad",
    "torso",
    "arm_upper_left",
    "arm_lower_left",
    "arm_upper_right",
    "arm_lower_right",
    "leg_upper_left",
    "leg_lower_left",
    "leg_upper_right",
    "leg_lower_right",
    "shoe_left",
    "shoe_right",
    "hat",
    "backpack",
    "shadow",
    "composite",
]

THEME_DEFAULTS = {
    "jungle": {
        "style": "cartoon_jungle_child",
        "inspiration": "Bright jungle adventure child with cap, glasses-friendly face and clean sporty silhouette",
        "colors": {
            "skin": "#E7B187",
            "hair": "#B5794E",
            "hat": "#8ED081",
            "shirt": "#5B8DFF",
            "overallsPrimary": "#4A7CFF",
            "backpack": "#F2C94C",
            "shoe": "#FFF0B8",
            "accent": "#FF8A5B",
            "outline": "#7A4F3A",
        },
        "hat_variant": "cap",
        "backpack_variant": "round",
    },
    "adventure": {
        "style": "cartoon_adventure_child",
        "inspiration": "Cheerful adventure kid with simple readable silhouette, hat and backpack",
        "colors": {
            "skin": "#E7A279",
            "hair": "#5C3B2E",
            "hat": "#F4E4BB",
            "shirt": "#F7DC29",
            "overallsPrimary": "#73E9CA",
            "backpack": "#17A984",
            "shoe": "#F4C835",
            "accent": "#D65033",
            "outline": "#6A2E31",
        },
        "hat_variant": "safari",
        "backpack_variant": "round",
    },
    "forest": {
        "style": "cartoon_forest_hero_child",
        "inspiration": "Original child forest hero with green tunic silhouette, blond hair and friendly explorer gear",
        "colors": {
            "skin": "#E7A279",
            "hair": "#D6B25C",
            "hat": "#3D9448",
            "shirt": "#2E7D32",
            "overallsPrimary": "#4E9F5A",
            "backpack": "#2B6FD6",
            "shoe": "#8B5A2B",
            "accent": "#D7C27A",
            "outline": "#6A2E31",
        },
        "hat_variant": "cap",
        "backpack_variant": "cape_pack",
    },
    "space": {
        "style": "cartoon_space_child",
        "inspiration": "Bright child space explorer with helmet, bold jumpsuit colors and compact jet-pack style backpack",
        "colors": {
            "skin": "#E7A279",
            "hair": "#2A2D56",
            "hat": "#A8BEFF",
            "shirt": "#5B78FF",
            "overallsPrimary": "#6D8BFF",
            "backpack": "#FFB347",
            "shoe": "#E2EAFF",
            "accent": "#FF6F61",
            "outline": "#273056",
        },
        "hat_variant": "helmet",
        "backpack_variant": "jetpack",
    },
    "ocean": {
        "style": "cartoon_ocean_child",
        "inspiration": "Playful ocean explorer with soft teal palette, rounded gear and simple sailor cap",
        "colors": {
            "skin": "#E7A279",
            "hair": "#234A5A",
            "hat": "#71C7EC",
            "shirt": "#2A9D8F",
            "overallsPrimary": "#5DD0C8",
            "backpack": "#2F80ED",
            "shoe": "#FFF4D9",
            "accent": "#F2C94C",
            "outline": "#1F4050",
        },
        "hat_variant": "beanie",
        "backpack_variant": "round",
    },
    "robot": {
        "style": "cartoon_robot_child",
        "inspiration": "Friendly robot-like child mascot with rounded helmet shapes and bright readable panels",
        "colors": {
            "skin": "#C9D1D9",
            "hair": "#90A4AE",
            "hat": "#B0BEC5",
            "shirt": "#78909C",
            "overallsPrimary": "#90CAF9",
            "backpack": "#607D8B",
            "shoe": "#ECEFF1",
            "accent": "#FFB300",
            "outline": "#37474F",
        },
        "hat_variant": "antenna",
        "backpack_variant": "jetpack",
    },
}

THEME_KEYWORDS = {
    "jungle": ("jungle", "djungel", "tropic", "tropical", "monkey", "vine"),
    "forest": ("forest", "skog", "wood", "leaf", "ranger", "hero", "cape", "moss"),
    "space": ("space", "astronaut", "rocket", "galaxy", "star", "planet", "cosmic"),
    "ocean": ("ocean", "sea", "water", "underwater", "pirate", "sailor", "marine"),
    "robot": ("robot", "android", "mech", "cyborg", "bot"),
    "adventure": ("adventure", "explorer", "safari", "jungle", "camp", "trek"),
}

COLOR_WORDS = {
    "red": "#D94C4C",
    "rod": "#D94C4C",
    "blue": "#4A7CFF",
    "bla": "#4A7CFF",
    "blaa": "#4A7CFF",
    "green": "#4E9F5A",
    "gron": "#4E9F5A",
    "yellow": "#F2C94C",
    "gul": "#F2C94C",
    "orange": "#F2994A",
    "purple": "#9B51E0",
    "lila": "#9B51E0",
    "pink": "#F78FB3",
    "rosa": "#F78FB3",
    "brown": "#8B5A2B",
    "brun": "#8B5A2B",
    "black": "#2D2D2D",
    "svart": "#2D2D2D",
    "white": "#F8FAFC",
    "vit": "#F8FAFC",
    "gray": "#90A4AE",
    "grey": "#90A4AE",
    "gra": "#90A4AE",
    "silver": "#B0BEC5",
    "gold": "#D7B45A",
    "teal": "#2CB7B0",
    "turquoise": "#2CB7B0",
    "cyan": "#4DD0E1",
    "navy": "#304FFE",
    "cream": "#F4E4BB",
    "beige": "#E0C59A",
    "tan": "#C9A57C",
    "blond": "#D6B25C",
    "blonde": "#D6B25C",
}

NOUN_GROUPS = {
    "hair": ("hair", "har"),
    "hat": ("hat", "cap", "helmet", "hood", "hatt", "keps", "hjalm"),
    "shirt": ("shirt", "tunic", "jacket", "hoodie", "troja"),
    "overallsPrimary": ("overall", "overalls", "outfit", "suit", "jumpsuit", "pants", "byxor", "shorts"),
    "backpack": ("backpack", "bag", "ryggsack", "pack"),
    "shoe": ("shoe", "shoes", "boot", "boots", "sneaker", "sneakers", "sko", "skor"),
}

SNAKE_CASE_COLOR_KEYS = {
    "hatShadow": "hat_shadow",
    "hatBand": "hat_band",
    "overallsPrimary": "overalls_primary",
    "overallsSecondary": "overalls_secondary",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create a fully registered SVG-first character from a short brief.",
    )
    parser.add_argument("--name", required=True, help="Display name for the character.")
    parser.add_argument("--brief", required=True, help="Plain-language character brief.")
    parser.add_argument("--slug", help="Optional explicit slug/id. Defaults to a slugified name.")
    parser.add_argument(
        "--theme",
        choices=sorted(THEME_DEFAULTS.keys()),
        help="Optional theme override. Otherwise derived from the brief.",
    )
    parser.add_argument(
        "--output-root",
        help="Optional alternate root for generated files. Useful for dry verification.",
    )
    parser.add_argument(
        "--skip-pipeline",
        action="store_true",
        help="Skip running tools/pipeline.py validate/manifest after writing files.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the character plan without writing files.",
    )
    return parser.parse_args()


def ensure_yaml_available() -> None:
    if yaml is None:
        raise SystemExit("PyYAML is required. Install it with 'pip install pyyaml'.")


def normalize_text(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    ascii_text = normalized.encode("ascii", "ignore").decode("ascii")
    return ascii_text.lower()


def slugify(value: str) -> str:
    ascii_text = normalize_text(value)
    ascii_text = re.sub(r"[^a-z0-9]+", "_", ascii_text).strip("_")
    return ascii_text or "character"


def pascal_case(value: str) -> str:
    return "".join(part.capitalize() for part in slugify(value).split("_"))


def clamp_channel(channel: float) -> int:
    return max(0, min(255, int(round(channel))))


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    stripped = value.lstrip("#")
    if len(stripped) == 8:
        stripped = stripped[:6]
    return int(stripped[0:2], 16), int(stripped[2:4], 16), int(stripped[4:6], 16)


def rgb_to_hex(rgb: tuple[int, int, int]) -> str:
    return "#" + "".join(f"{clamp_channel(channel):02X}" for channel in rgb)


def mix(color_a: str, color_b: str, amount: float) -> str:
    amount = max(0.0, min(1.0, amount))
    rgb_a = hex_to_rgb(color_a)
    rgb_b = hex_to_rgb(color_b)
    return rgb_to_hex(
        tuple(
            rgb_a[index] + (rgb_b[index] - rgb_a[index]) * amount
            for index in range(3)
        )
    )


def darken(color: str, amount: float) -> str:
    return mix(color, "#000000", amount)


def lighten(color: str, amount: float) -> str:
    return mix(color, "#FFFFFF", amount)


def detect_theme(brief: str, explicit_theme: str | None) -> str:
    if explicit_theme is not None:
        return explicit_theme

    normalized = normalize_text(brief)
    for theme, keywords in THEME_KEYWORDS.items():
        if any(keyword in normalized for keyword in keywords):
            return theme
    return "adventure"


def brief_has_any(brief: str, *keywords: str) -> bool:
    normalized = normalize_text(brief)
    return any(keyword in normalized for keyword in keywords)


def prefers_light_palette(brief: str) -> bool:
    normalized = normalize_text(brief)
    return any(
        phrase in normalized
        for phrase in (
            "inga morka farger",
            "inga morka farger",
            "no dark colors",
            "no dark colour",
            "not dark",
            "bright colors",
            "bright colours",
            "ljusa farger",
        )
    )


def detect_hat_variant(theme: str, brief: str) -> str:
    normalized = normalize_text(brief)
    if any(keyword in normalized for keyword in ("cap", "keps")):
        return "cap"
    if any(keyword in normalized for keyword in ("helmet", "hjalm")):
        return "helmet"
    if any(keyword in normalized for keyword in ("beanie", "mossa")):
        return "beanie"
    if any(keyword in normalized for keyword in ("antenna", "antenner")):
        return "antenna"
    return THEME_DEFAULTS[theme]["hat_variant"]


def wears_glasses(brief: str) -> bool:
    return brief_has_any(brief, "glasses", "glasogon", "spectacles")


def wears_shorts(brief: str) -> bool:
    return brief_has_any(brief, "shorts", "kortbyxor")


def extract_color_overrides(brief: str) -> dict[str, str]:
    normalized = normalize_text(brief)
    color_pattern = "|".join(sorted(COLOR_WORDS.keys(), key=len, reverse=True))
    overrides: dict[str, str] = {}

    for field_name, noun_keywords in NOUN_GROUPS.items():
        noun_pattern = "|".join(sorted(noun_keywords, key=len, reverse=True))
        match = re.search(
            rf"\b(?P<color>{color_pattern})\b(?:(?!\b(?:{noun_pattern})s?\b)\s+[\w-]+){{0,2}}\s+(?:{noun_pattern})s?\b",
            normalized,
        )
        if match:
            overrides[field_name] = COLOR_WORDS[match.group("color")]
    return overrides


def build_palette(theme: str, overrides: dict[str, str], brief: str = "") -> dict[str, str]:
    defaults = THEME_DEFAULTS[theme]["colors"]
    hair = overrides.get("hair", defaults["hair"])
    hat = overrides.get("hat", defaults["hat"])
    shirt = overrides.get("shirt", defaults["shirt"])
    overalls_primary = overrides.get("overallsPrimary", defaults["overallsPrimary"])
    backpack = overrides.get("backpack", defaults["backpack"])
    shoe = overrides.get("shoe", defaults["shoe"])
    outline = defaults["outline"]
    accent = defaults["accent"]
    is_light = prefers_light_palette(brief)

    if is_light:
        hair = mix(hair, "#F3D7AC", 0.26)
        outline = mix(outline, "#FFFFFF", 0.18)

    return {
        "skin": defaults["skin"],
        "hair": hair,
        "hat": hat,
        "hatShadow": darken(hat, 0.12 if is_light else 0.18),
        "hatBand": accent,
        "shirt": shirt,
        "overallsPrimary": overalls_primary,
        "overallsSecondary": darken(overalls_primary, 0.12 if is_light else 0.22),
        "backpack": backpack,
        "strap": darken(backpack, 0.14 if is_light else 0.24),
        "shoe": shoe,
        "lace": accent,
        "sole": lighten(shoe, 0.78),
        "outline": outline,
        "blush": mix(defaults["skin"], "#FF9AA2", 0.35),
        "shadow": "#0000001A",
        "eyes": darken(outline, 0.18),
        "mouth": darken(outline, 0.18),
    }


SCHOOL_AGE_CHILD_PROPORTIONS = {
    "headToBodyRatio": 0.24,
    "eyeSizeRelativeToHead": 0.09,
    "mouthWidthRelativeToHead": 0.16,
    "armLengthRelativeToBody": 0.44,
    "legLengthRelativeToBody": 0.47,
    "hatWidthRelativeToHead": 1.00,
    "shoeWidthRelativeToLeg": 0.82,
}

SCHOOL_AGE_CHILD_TPOSE_ALIGNMENT = {
    "armUpperTranslateY": {"left": 10, "right": 10},
    "armLowerTranslateY": {"left": -1, "right": -1},
    "alignmentRule": "relaxed_shoulders_with_wrists_resting_near_mid_thigh",
}

SCHOOL_AGE_CHILD_BONE_POSITIONS = {
    "root": {"x": 200.0, "y": 532.0},
    "pelvis": {"x": 200.0, "y": 362.0},
    "spine": {"x": 200.0, "y": 302.0},
    "chest": {"x": 200.0, "y": 238.0},
    "neck": {"x": 200.0, "y": 172.0},
    "head": {"x": 200.0, "y": 126.0},
    "shoulder_left": {"x": 158.0, "y": 236.0},
    "upper_arm_left": {"x": 144.0, "y": 266.0},
    "lower_arm_left": {"x": 134.0, "y": 350.0},
    "wrist_left": {"x": 128.0, "y": 426.0},
    "hand_left": {"x": 126.0, "y": 448.0},
    "shoulder_right": {"x": 242.0, "y": 236.0},
    "upper_arm_right": {"x": 256.0, "y": 266.0},
    "lower_arm_right": {"x": 266.0, "y": 350.0},
    "wrist_right": {"x": 272.0, "y": 426.0},
    "hand_right": {"x": 274.0, "y": 448.0},
    "hip_left": {"x": 183.0, "y": 360.0},
    "upper_leg_left": {"x": 180.0, "y": 412.0},
    "lower_leg_left": {"x": 178.0, "y": 498.0},
    "ankle_left": {"x": 176.0, "y": 548.0},
    "foot_left": {"x": 156.0, "y": 568.0},
    "toe_left": {"x": 182.0, "y": 574.0},
    "hip_right": {"x": 217.0, "y": 360.0},
    "upper_leg_right": {"x": 220.0, "y": 412.0},
    "lower_leg_right": {"x": 222.0, "y": 498.0},
    "ankle_right": {"x": 224.0, "y": 548.0},
    "foot_right": {"x": 244.0, "y": 568.0},
    "toe_right": {"x": 218.0, "y": 574.0},
    "hat": {"x": 200.0, "y": 70.0},
    "backpack": {"x": 166.0, "y": 236.0},
}


def default_proportions(theme: str) -> dict[str, float]:
    base = dict(SCHOOL_AGE_CHILD_PROPORTIONS)
    if theme == "space":
        base["hatWidthRelativeToHead"] = 1.08
    if theme == "robot":
        base["eyeSizeRelativeToHead"] = 0.07
        base["mouthWidthRelativeToHead"] = 0.12
    return base


def style_settings() -> dict[str, Any]:
    return {
        "strokeWidth": 4,
        "cornerRadius": 14,
        "useGradients": False,
        "useTextures": False,
        "rigFriendly": True,
        "strokeLinecap": "round",
        "strokeLinejoin": "round",
    }


def tpose_alignment() -> dict[str, Any]:
    return dict(SCHOOL_AGE_CHILD_TPOSE_ALIGNMENT)


def build_visual_spec(
    slug: str,
    name: str,
    brief: str,
    theme: str,
    palette: dict[str, str],
    proportions: dict[str, float],
) -> dict[str, Any]:
    return {
        "name": name,
        "version": 1,
        "style": THEME_DEFAULTS[theme]["style"],
        "inspiration": brief.strip(),
        "baseFormRef": "../../_shared/config/humanoid_base_form_v1.json",
        "colors": palette,
        "proportions": proportions,
        "styleSettings": style_settings(),
        "tPosePreviewAlignment": tpose_alignment(),
        "parts": {
            "head": f"svg/{slug}_head.svg",
            "eyes_open": f"svg/{slug}_eyes_open.svg",
            "eyes_blink": f"svg/{slug}_eyes_blink.svg",
            "mouth_neutral": f"svg/{slug}_mouth_neutral.svg",
            "mouth_happy": f"svg/{slug}_mouth_happy.svg",
            "mouth_sad": f"svg/{slug}_mouth_sad.svg",
            "torso": f"svg/{slug}_torso.svg",
            "arm_upper_left": f"svg/{slug}_arm_upper_left.svg",
            "arm_lower_left": f"svg/{slug}_arm_lower_left.svg",
            "arm_upper_right": f"svg/{slug}_arm_upper_right.svg",
            "arm_lower_right": f"svg/{slug}_arm_lower_right.svg",
            "leg_upper_left": f"svg/{slug}_leg_upper_left.svg",
            "leg_lower_left": f"svg/{slug}_leg_lower_left.svg",
            "leg_upper_right": f"svg/{slug}_leg_upper_right.svg",
            "leg_lower_right": f"svg/{slug}_leg_lower_right.svg",
            "shoe_left": f"svg/{slug}_shoe_left.svg",
            "shoe_right": f"svg/{slug}_shoe_right.svg",
            "hat": f"svg/{slug}_hat.svg",
            "backpack": f"svg/{slug}_backpack.svg",
            "shadow": f"svg/{slug}_shadow.svg",
            "composite": f"svg/{slug}_composite.svg",
        },
    }


def build_animation_spec(name: str) -> dict[str, Any]:
    state_machine = f"{pascal_case(name)}StateMachine"
    return {
        "character": name,
        "artboard": pascal_case(name),
        "state_machine": state_machine,
        "rig": {
            "profile": "segmented_humanoid_multi_joint_v2",
            "bones": [
                "root",
                "pelvis",
                "spine",
                "chest",
                "neck",
                "head",
                "shoulder_left",
                "upper_arm_left",
                "lower_arm_left",
                "wrist_left",
                "hand_left",
                "shoulder_right",
                "upper_arm_right",
                "lower_arm_right",
                "wrist_right",
                "hand_right",
                "hip_left",
                "upper_leg_left",
                "lower_leg_left",
                "ankle_left",
                "foot_left",
                "toe_left",
                "hip_right",
                "upper_leg_right",
                "lower_leg_right",
                "ankle_right",
                "foot_right",
                "toe_right",
                "hat",
                "backpack",
            ],
            "constraints": [
                "head_follow_chest",
                "shoulder_follow_chest_soft",
                "hat_follow_head_80",
                "backpack_follow_torso_100",
                "elbow_soft_limit",
                "wrist_soft_limit",
                "pelvis_counterbalance",
                "knee_soft_limit",
                "ankle_soft_limit",
                "feet_ground_lock",
                "toe_roll_optional",
            ],
            "bindingOverrides": {
                "hand_left": "arm_lower_left",
                "hand_right": "arm_lower_right",
                "foot_left": "shoe_left",
                "foot_right": "shoe_right",
                "toe_left": "shoe_left",
                "toe_right": "shoe_right",
            },
        },
        "animations": {
            "base": ["idle", "idle_blink", "idle_head_bob"],
            "positive": ["happy", "celebrate_small"],
            "negative": ["sad", "head_drop"],
            "interactive": ["tap_react", "enter_screen", "exit_screen"],
        },
        "states": {
            "initial": "idle",
            "list": ["idle", "happy", "sad", "tap_react", "enter", "exit"],
            "transitions": [
                {"from": "idle", "to": "happy", "trigger": "answer_correct"},
                {"from": "idle", "to": "sad", "trigger": "answer_wrong"},
                {"from": "idle", "to": "tap_react", "trigger": "user_tap"},
                {"from": "any", "to": "exit", "trigger": "screen_change"},
                {"from": "enter", "to": "idle", "trigger": "animation_done"},
                {"from": "happy", "to": "idle", "trigger": "animation_done"},
                {"from": "sad", "to": "idle", "trigger": "animation_done"},
                {"from": "tap_react", "to": "idle", "trigger": "animation_done"},
            ],
        },
    }


def wrap_svg(content: str, width: int, height: int, view_box: str | None = None) -> str:
    actual_view_box = view_box or f"0 0 {width} {height}"
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<svg width="{width}" height="{height}" viewBox="{actual_view_box}" xmlns="http://www.w3.org/2000/svg">\n'
        f"{content}\n"
        "</svg>\n"
    )


def hat_shape(theme: str, palette: dict[str, str], brief: str) -> str:
    outline = palette["outline"]
    variant = detect_hat_variant(theme, brief)
    if variant == "helmet":
        return f"""
  <ellipse cx="160" cy="102" rx="110" ry="74" fill="{palette['hat']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <path d="M 88 110 Q 160 58 232 110 Q 220 138 160 142 Q 100 138 88 110 Z" fill="{lighten(palette['hat'], 0.30)}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="112" y="50" width="96" height="16" rx="8" fill="{palette['hatBand']}" opacity="0.9"/>
"""
    if variant == "cap":
        return f"""
  <path d="M 88 118 Q 112 48 176 44 Q 232 44 252 118 L 88 118 Z" fill="{palette['hat']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <path d="M 124 118 Q 174 138 246 118 Q 210 148 124 134 Z" fill="{palette['hatShadow']}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="118" y="84" width="88" height="14" rx="7" fill="{palette['hatBand']}"/>
"""
    if variant == "antenna":
        return f"""
  <rect x="84" y="56" width="152" height="88" rx="36" fill="{palette['hat']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="126" y="82" width="68" height="22" rx="11" fill="{lighten(palette['hat'], 0.18)}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
  <line x1="160" y1="56" x2="160" y2="18" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <circle cx="160" cy="18" r="10" fill="{palette['hatBand']}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
"""
    if variant == "beanie":
        return f"""
  <path d="M 94 116 Q 100 52 160 44 Q 220 52 226 116 L 94 116 Z" fill="{palette['hat']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="104" y="102" width="112" height="24" rx="12" fill="{palette['hatShadow']}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
  <circle cx="160" cy="36" r="12" fill="{palette['hatBand']}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
"""
    return f"""
  <ellipse cx="160" cy="128" rx="118" ry="22" fill="{palette['hatShadow']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="108" y="52" width="104" height="76" rx="32" fill="{palette['hat']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="116" y="88" width="88" height="18" rx="9" fill="{palette['hatBand']}"/>
"""


def backpack_shape(theme: str, palette: dict[str, str]) -> str:
    outline = palette["outline"]
    variant = THEME_DEFAULTS[theme]["backpack_variant"]
    if variant == "jetpack":
        return f"""
  <rect x="62" y="58" width="58" height="126" rx="20" fill="{palette['backpack']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="140" y="58" width="58" height="126" rx="20" fill="{palette['backpack']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="110" y="42" width="40" height="146" rx="18" fill="{lighten(palette['backpack'], 0.12)}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <circle cx="91" cy="196" r="14" fill="{palette['hatBand']}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
  <circle cx="169" cy="196" r="14" fill="{palette['hatBand']}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
"""
    if variant == "cape_pack":
        return f"""
  <path d="M 68 72 Q 130 24 192 72 L 192 190 Q 130 224 68 190 Z" fill="{palette['backpack']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <path d="M 192 72 Q 230 116 216 190 Q 184 214 150 208 Q 182 152 192 72 Z" fill="{lighten(palette['backpack'], 0.08)}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="88" y="88" width="84" height="18" rx="9" fill="{palette['strap']}"/>
"""
    return f"""
  <rect x="74" y="48" width="112" height="148" rx="32" fill="{palette['backpack']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="96" y="74" width="68" height="20" rx="10" fill="{palette['strap']}"/>
  <rect x="88" y="108" width="84" height="60" rx="22" fill="{lighten(palette['backpack'], 0.10)}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
"""


def glasses_layer(palette: dict[str, str]) -> str:
    frame = darken(palette["outline"], 0.08)
    return f"""
  <rect x="70" y="44" width="36" height="24" rx="9" fill="none" stroke="{frame}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="130" y="44" width="36" height="24" rx="9" fill="none" stroke="{frame}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <line x1="106" y1="56" x2="130" y2="56" stroke="{frame}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <line x1="60" y1="56" x2="70" y2="54" stroke="{frame}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <line x1="166" y1="54" x2="176" y2="56" stroke="{frame}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
"""


def svg_fragment(svg_text: str) -> str:
    match = re.search(r"<svg[^>]*>(?P<content>.*)</svg>", svg_text, re.DOTALL)
    if match is None:
        raise ValueError("Unexpected SVG wrapper.")
    return match.group("content").strip()


def part_svg_map(palette: dict[str, str], theme: str, brief: str) -> dict[str, str]:
    outline = palette["outline"]
    has_glasses = wears_glasses(brief)
    has_shorts = wears_shorts(brief)
    glasses = glasses_layer(palette) if has_glasses else ""

    torso_svg = f"""
  <path d="M 60 30 Q 80 8 118 8 Q 156 8 176 30 L 184 142 Q 154 174 118 174 Q 82 174 52 142 Z" fill="{palette['shirt']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <path d="M 88 28 Q 102 16 118 16 Q 134 16 148 28 L 142 46 Q 130 38 118 38 Q 106 38 94 46 Z" fill="{lighten(palette['shirt'], 0.18)}" opacity="0.85"/>
  <rect x="84" y="132" width="68" height="18" rx="9" fill="{lighten(palette['shirt'], 0.08)}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
"""
    if not has_shorts:
        torso_svg = f"""
  <path d="M 60 30 Q 80 8 118 8 Q 156 8 176 30 L 190 210 Q 158 238 118 238 Q 78 238 46 210 Z" fill="{palette['shirt']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <path d="M 82 82 Q 98 54 118 54 Q 138 54 154 82 L 164 206 Q 142 226 118 226 Q 94 226 72 206 Z" fill="{palette['overallsPrimary']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="96" y="94" width="44" height="62" rx="16" fill="{lighten(palette['overallsPrimary'], 0.14)}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="76" y="82" width="18" height="82" rx="9" fill="{palette['overallsSecondary']}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="142" y="82" width="18" height="82" rx="9" fill="{palette['overallsSecondary']}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
"""

    parts = {
        "head": wrap_svg(
            f"""
  <path d="M 58 74 Q 68 28 118 22 Q 168 28 178 76 Q 158 58 118 56 Q 80 58 58 74 Z" fill="{palette['hair']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <ellipse cx="118" cy="106" rx="60" ry="62" fill="{palette['skin']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <ellipse cx="88" cy="132" rx="12" ry="8" fill="{palette['blush']}" opacity="0.55"/>
  <ellipse cx="148" cy="132" rx="12" ry="8" fill="{palette['blush']}" opacity="0.55"/>
""",
            236,
            188,
        ),
        "eyes_open": wrap_svg(
            f"""
  <ellipse cx="88" cy="54" rx="12" ry="16" fill="white" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
  <ellipse cx="148" cy="54" rx="12" ry="16" fill="white" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
  <circle cx="88" cy="57" r="6" fill="{palette['eyes']}"/>
  <circle cx="148" cy="57" r="6" fill="{palette['eyes']}"/>
  <circle cx="91" cy="53" r="2" fill="white"/>
  <circle cx="151" cy="53" r="2" fill="white"/>
  {glasses}
""",
            236,
            112,
        ),
        "eyes_blink": wrap_svg(
            f"""
  <path d="M 76 58 Q 88 66 100 58" fill="none" stroke="{palette['eyes']}" stroke-width="4" stroke-linecap="round"/>
  <path d="M 136 58 Q 148 66 160 58" fill="none" stroke="{palette['eyes']}" stroke-width="4" stroke-linecap="round"/>
  {glasses}
""",
            236,
            112,
        ),
        "mouth_neutral": wrap_svg(
            f"""  <line x1="88" y1="54" x2="148" y2="54" stroke="{palette['mouth']}" stroke-width="5" stroke-linecap="round"/>""",
            236,
            96,
        ),
        "mouth_happy": wrap_svg(
            f"""  <path d="M 88 46 Q 118 74 148 46" fill="none" stroke="{palette['mouth']}" stroke-width="5" stroke-linecap="round"/>""",
            236,
            96,
        ),
        "mouth_sad": wrap_svg(
            f"""  <path d="M 88 64 Q 118 38 148 64" fill="none" stroke="{palette['mouth']}" stroke-width="5" stroke-linecap="round"/>""",
            236,
            96,
        ),
        "torso": wrap_svg(
            torso_svg,
            236,
            248,
        ),
    }

    for side in ("left", "right"):
        parts[f"arm_upper_{side}"] = wrap_svg(
            f"""  <rect x="24" y="8" width="28" height="118" rx="14" fill="{palette['shirt']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>""",
            76,
            134,
        )
        parts[f"arm_lower_{side}"] = wrap_svg(
            f"""
  <rect x="24" y="8" width="28" height="98" rx="14" fill="{palette['skin']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <circle cx="38" cy="122" r="16" fill="{palette['skin']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="18" y="4" width="40" height="14" rx="7" fill="{palette['overallsSecondary']}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
""",
            80,
            144,
        )
        parts[f"leg_upper_{side}"] = wrap_svg(
            (
                f"""
  <rect x="16" y="8" width="48" height="30" rx="12" fill="{palette['overallsPrimary']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <rect x="20" y="32" width="40" height="96" rx="18" fill="{palette['skin']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
"""
                if has_shorts
                else f"""  <rect x="18" y="8" width="44" height="128" rx="18" fill="{palette['overallsPrimary']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>"""
            ),
            80,
            144,
        )
        parts[f"leg_lower_{side}"] = wrap_svg(
            (
                f"""  <rect x="18" y="6" width="36" height="132" rx="18" fill="{palette['skin']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>"""
                if has_shorts
                else f"""  <rect x="18" y="6" width="36" height="132" rx="18" fill="{palette['overallsSecondary']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>"""
            ),
            72,
            150,
        )
        parts[f"shoe_{side}"] = wrap_svg(
            f"""
  <path d="M 22 68 Q 40 42 90 42 Q 122 44 138 60 L 136 82 Q 118 98 62 100 Q 18 98 14 80 Z" fill="{palette['shoe']}" stroke="{outline}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>
  <path d="M 24 76 Q 70 88 130 82" fill="none" stroke="{palette['lace']}" stroke-width="4" stroke-linecap="round"/>
  <path d="M 18 84 Q 74 104 140 92 L 140 100 Q 78 112 16 96 Z" fill="{palette['sole']}" stroke="{outline}" stroke-width="3" stroke-linejoin="round" stroke-linecap="round"/>
""",
            156,
            110,
        )

    parts["hat"] = wrap_svg(hat_shape(theme, palette, brief), 320, 180)
    parts["backpack"] = wrap_svg(backpack_shape(theme, palette), 260, 260)
    parts["shadow"] = wrap_svg(
        f"""  <ellipse cx="110" cy="34" rx="84" ry="18" fill="{palette['shadow']}"/>""",
        220,
        64,
    )

    parts["composite"] = wrap_svg(
        f"""
  <g id="shadow" transform="translate(90 522)">{svg_fragment(parts['shadow'])}</g>
  <g id="backpack" transform="translate(86 196) scale(0.62)">{svg_fragment(parts['backpack'])}</g>
  <g id="leg_upper_left" transform="translate(140 300)">{svg_fragment(parts['leg_upper_left'])}</g>
  <g id="leg_lower_left" transform="translate(144 416)">{svg_fragment(parts['leg_lower_left'])}</g>
  <g id="shoe_left" transform="translate(108 526) scale(0.52)">{svg_fragment(parts['shoe_left'])}</g>
  <g id="leg_upper_right" transform="translate(200 300)">{svg_fragment(parts['leg_upper_right'])}</g>
  <g id="leg_lower_right" transform="translate(204 416)">{svg_fragment(parts['leg_lower_right'])}</g>
  <g id="shoe_right" transform="translate(180 526) scale(0.52)">{svg_fragment(parts['shoe_right'])}</g>
  <g id="arm_upper_left" transform="translate(100 214) rotate(6 38 14)">{svg_fragment(parts['arm_upper_left'])}</g>
  <g id="arm_lower_left" transform="translate(92 324) rotate(6 40 14)">{svg_fragment(parts['arm_lower_left'])}</g>
  <g id="arm_upper_right" transform="translate(224 214) rotate(-6 38 14)">{svg_fragment(parts['arm_upper_right'])}</g>
  <g id="arm_lower_right" transform="translate(228 324) rotate(-6 40 14)">{svg_fragment(parts['arm_lower_right'])}</g>
  <g id="torso" transform="translate(82 166)">{svg_fragment(parts['torso'])}</g>
  <g id="head" transform="translate(94 36)">{svg_fragment(parts['head'])}</g>
  <g id="eyes" transform="translate(94 60)">{svg_fragment(parts['eyes_open'])}</g>
  <g id="mouth" transform="translate(94 120)">{svg_fragment(parts['mouth_happy'])}</g>
  <g id="hat" transform="translate(64 -12) scale(0.84)">{svg_fragment(parts['hat'])}</g>
""",
        400,
        600,
    )
    return parts


def generic_bone_parent(bone_name: str) -> str | None:
    parent_map = {
        "root": None,
        "pelvis": "root",
        "spine": "pelvis",
        "chest": "spine",
        "neck": "chest",
        "head": "neck",
        "shoulder_left": "chest",
        "upper_arm_left": "shoulder_left",
        "lower_arm_left": "upper_arm_left",
        "wrist_left": "lower_arm_left",
        "hand_left": "wrist_left",
        "shoulder_right": "chest",
        "upper_arm_right": "shoulder_right",
        "lower_arm_right": "upper_arm_right",
        "wrist_right": "lower_arm_right",
        "hand_right": "wrist_right",
        "hip_left": "pelvis",
        "upper_leg_left": "hip_left",
        "lower_leg_left": "upper_leg_left",
        "ankle_left": "lower_leg_left",
        "foot_left": "ankle_left",
        "toe_left": "foot_left",
        "hip_right": "pelvis",
        "upper_leg_right": "hip_right",
        "lower_leg_right": "upper_leg_right",
        "ankle_right": "lower_leg_right",
        "foot_right": "ankle_right",
        "toe_right": "foot_right",
        "hat": "head",
        "backpack": "chest",
    }
    return parent_map.get(bone_name)


def generic_bone_position(bone_name: str) -> dict[str, float]:
    return SCHOOL_AGE_CHILD_BONE_POSITIONS.get(bone_name, {"x": 200.0, "y": 300.0})


def generic_bind_mesh(bone_name: str) -> str:
    mesh_map = {
        "root": "torso",
        "pelvis": "torso",
        "spine": "torso",
        "chest": "torso",
        "neck": "head",
        "head": "head",
        "shoulder_left": "arm_upper_left",
        "upper_arm_left": "arm_upper_left",
        "lower_arm_left": "arm_lower_left",
        "wrist_left": "arm_lower_left",
        "hand_left": "arm_lower_left",
        "shoulder_right": "arm_upper_right",
        "upper_arm_right": "arm_upper_right",
        "lower_arm_right": "arm_lower_right",
        "wrist_right": "arm_lower_right",
        "hand_right": "arm_lower_right",
        "hip_left": "leg_upper_left",
        "upper_leg_left": "leg_upper_left",
        "lower_leg_left": "leg_lower_left",
        "ankle_left": "shoe_left",
        "foot_left": "shoe_left",
        "toe_left": "shoe_left",
        "hip_right": "leg_upper_right",
        "upper_leg_right": "leg_upper_right",
        "lower_leg_right": "leg_lower_right",
        "ankle_right": "shoe_right",
        "foot_right": "shoe_right",
        "toe_right": "shoe_right",
        "hat": "hat",
        "backpack": "backpack",
    }
    return mesh_map.get(bone_name, "torso")


def build_blueprint(slug: str, name: str, brief: str, animation_spec: dict[str, Any]) -> dict[str, Any]:
    artboard_name = animation_spec.get("artboard") or pascal_case(name)
    state_machine_name = animation_spec.get("state_machine") or "MascotStateMachine"
    import_parts = [
        "shadow",
        "backpack",
        "leg_upper_left",
        "leg_lower_left",
        "shoe_left",
        "arm_upper_left",
        "arm_lower_left",
        "torso",
        "head",
        "eyes_open",
        "eyes_blink",
        "mouth_neutral",
        "mouth_happy",
        "mouth_sad",
        "hat",
        "arm_upper_right",
        "arm_lower_right",
        "leg_upper_right",
        "leg_lower_right",
        "shoe_right",
    ]
    return {
        "meta": {
            "version": "1.0",
            "character": name,
            "description": f"Optional Rive rigging blueprint for {name}. Generated from brief: {brief.strip()}",
            "target_artboard_name": artboard_name,
            "target_state_machine": state_machine_name,
        },
        "import_assets": {
            "svg_parts": [
                {
                    "file": f"assets/characters/{slug}/svg/{slug}_{part}.svg",
                    "layer_name": part,
                }
                for part in import_parts
            ],
            "import_order": import_parts,
        },
        "artboard": {
            "name": artboard_name,
            "width": 400,
            "height": 600,
            "origin": {"x": 200, "y": int(SCHOOL_AGE_CHILD_BONE_POSITIONS["root"]["y"])},
        },
        "bones": {
            "bones": [
                {
                    "name": bone_name,
                    "parent": generic_bone_parent(bone_name),
                    "position": generic_bone_position(bone_name),
                    "bind_mesh": generic_bind_mesh(bone_name),
                }
                for bone_name in animation_spec["rig"]["bones"]
            ],
            "constraints": animation_spec["rig"]["constraints"],
        },
        "animations": [
            {"name": "idle", "duration_seconds": 1.2, "notes": ["breathing", "small head bob", "occasional blink"]},
            {"name": "happy", "duration_seconds": 0.8, "notes": ["bounce up", "arms lift", "happy mouth"]},
            {"name": "sad", "duration_seconds": 0.7, "notes": ["head drop", "arms down", "sad mouth"]},
            {"name": "tap_react", "duration_seconds": 0.45, "notes": ["quick pop", "blink", "return to idle"]},
            {"name": "enter", "duration_seconds": 0.55, "notes": ["ease in from side", "settle into idle"]},
            {"name": "exit", "duration_seconds": 0.4, "notes": ["fade or slide out cleanly"]},
        ],
        "state_machine": {
            "name": state_machine_name,
            "inputs": [
                {"name": "answer_correct", "type": "Trigger"},
                {"name": "answer_wrong", "type": "Trigger"},
                {"name": "user_tap", "type": "Trigger"},
                {"name": "screen_change", "type": "Trigger"},
            ],
            "states": animation_spec["states"]["list"],
            "transitions": animation_spec["states"]["transitions"],
        },
    }


def build_guide_markdown(slug: str, name: str, brief: str, animation_spec: dict[str, Any]) -> str:
    state_machine_name = animation_spec.get("state_machine") or "MascotStateMachine"
    import_lines = "\n".join(
        f"{index}. `assets/characters/{slug}/svg/{slug}_{part}.svg`"
        for index, part in enumerate(
            [
                "shadow",
                "backpack",
                "leg_upper_left",
                "leg_lower_left",
                "shoe_left",
                "arm_upper_left",
                "arm_lower_left",
                "torso",
                "head",
                "eyes_open",
                "eyes_blink",
                "mouth_neutral",
                "mouth_happy",
                "mouth_sad",
                "hat",
                "arm_upper_right",
                "arm_lower_right",
                "leg_upper_right",
                "leg_lower_right",
                "shoe_right",
            ],
            start=1,
        )
    )
    return f"""# {pascal_case(name)} Rive Guide

Generated from brief: {brief.strip()}

## Default Runtime
The default runtime asset for this character is the generated SVG composite:

`assets/characters/{slug}/svg/{slug}_composite.svg`

A `.riv` export is optional and not required for app integration.

## Source Files
- `assets/characters/{slug}/config/{slug}_visual_spec.json`
- `assets/characters/{slug}/config/{slug}_animation_spec.json`
- `assets/characters/{slug}/svg/{slug}_*.svg`
- `artifacts/{slug}_rive_blueprint.json`

## Optional Rive Import Order
{import_lines}

## Suggested State Machine
Name: `{state_machine_name}`

Inputs:
- `answer_correct`
- `answer_wrong`
- `user_tap`
- `screen_change`
"""


def svg_readme(slug: str, name: str) -> str:
    return f"""# {pascal_case(name)} SVG Assets

These files are generated by `python tools/create_character.py` and are safe to use as the default runtime character assets.

## Runtime Asset
- `assets/characters/{slug}/svg/{slug}_composite.svg`

## Segmented Parts
Generated parts are stored in the same folder and match the rig-friendly segmented humanoid layout used by the repo pipeline.

## Notes
- The app can use the composite SVG directly without any manual editor step.
- The segmented SVG files also act as source input for the optional Rive blueprint under `artifacts/`.
"""


def rive_readme(slug: str, name: str, animation_spec: dict[str, Any]) -> str:
    artboard_name = animation_spec.get("artboard") or pascal_case(name)
    state_machine_name = animation_spec.get("state_machine") or "MascotStateMachine"
    return f"""# {pascal_case(name)} Optional Rive Runtime

This folder is intentionally kept lightweight. The default runtime character path is SVG-first and does not require a `.riv` file.

If a future optional Rive export is added, keep it here as:

`assets/characters/{slug}/rive/{slug}_character.riv`

Expected artboard:
- `{artboard_name}`

Expected state machine:
- `{state_machine_name}`

Current rule:
- blueprint and guide are generated automatically
- final `.riv` is optional and not required for app integration
"""


def ensure_base_form(output_root: Path) -> None:
    if not BASE_FORM_SOURCE.exists():
        raise SystemExit(f"Missing shared base form: {BASE_FORM_SOURCE}")

    target = output_root / "assets" / "characters" / "_shared" / "config" / BASE_FORM_SOURCE.name
    if target.exists():
        return

    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(BASE_FORM_SOURCE.read_text(encoding="utf-8"), encoding="utf-8")


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def load_yaml_file(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if data is None:
        return {}
    if not isinstance(data, dict):
        raise SystemExit(f"Expected a top-level object in {path}")
    return data


def upsert_yaml_entry(document: dict[str, Any], top_level: str, entry: dict[str, Any]) -> None:
    items = document.setdefault(top_level, [])
    if not isinstance(items, list):
        raise SystemExit(f"Expected '{top_level}' to be a list")

    for index, existing in enumerate(items):
        if isinstance(existing, dict) and existing.get("id") == entry["id"]:
            items[index] = entry
            return

    items.append(entry)


def palette_key_for_yaml(key: str) -> str:
    if key in SNAKE_CASE_COLOR_KEYS:
        return SNAKE_CASE_COLOR_KEYS[key]
    return re.sub(r"(?<!^)([A-Z])", r"_\1", key).lower()


def palette_entry(slug: str, palette: dict[str, str]) -> dict[str, Any]:
    return {
        "id": f"{slug}_default",
        "colors": {
            palette_key_for_yaml(key): value
            for key, value in palette.items()
        },
    }


def rig_entry(slug: str) -> dict[str, Any]:
    return {
        "id": f"{slug}_humanoid",
        "character": slug,
        "source_animation_spec": f"assets/characters/{slug}/config/{slug}_animation_spec.json",
        "runtime": "rive",
        "template_family": "segmented_humanoid_multi_joint_v2",
        "slots": [
            "head",
            "torso",
            "arm_upper_left",
            "arm_lower_left",
            "arm_upper_right",
            "arm_lower_right",
            "leg_upper_left",
            "leg_lower_left",
            "leg_upper_right",
            "leg_lower_right",
            "shoe_left",
            "shoe_right",
            "hat",
            "backpack",
        ],
    }


def character_entry(slug: str, name: str) -> dict[str, Any]:
    return {
        "id": slug,
        "display_name": name,
        "visual_spec": f"assets/characters/{slug}/config/{slug}_visual_spec.json",
        "animation_spec": f"assets/characters/{slug}/config/{slug}_animation_spec.json",
        "rig": f"{slug}_humanoid",
        "palette": f"{slug}_default",
        "outputs": {
            "svg_parts_dir": f"assets/characters/{slug}/svg",
            "composite_svg": f"assets/characters/{slug}/svg/{slug}_composite.svg",
            "rive_runtime": f"assets/characters/{slug}/rive/{slug}_character.riv",
            "rive_blueprint": f"artifacts/{slug}_rive_blueprint.json",
            "rive_guide": f"artifacts/{slug.upper()}_RIVE_GUIDE.md",
        },
    }


def write_yaml(path: Path, document: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        yaml.safe_dump(document, sort_keys=False, allow_unicode=True),
        encoding="utf-8",
    )


def run_pipeline(output_root: Path) -> None:
    commands = [
        [sys.executable, "tools/pipeline.py", "validate", "--strict"],
        [sys.executable, "tools/pipeline.py", "manifest"],
    ]
    for command in commands:
        result = subprocess.run(command, cwd=output_root, check=False)
        if result.returncode != 0:
            raise SystemExit(f"Pipeline command failed: {' '.join(command)}")


def main() -> None:
    args = parse_args()
    ensure_yaml_available()

    output_root = Path(args.output_root).resolve() if args.output_root else SCRIPT_ROOT
    slug = slugify(args.slug or args.name)
    theme = detect_theme(args.brief, args.theme)
    color_overrides = extract_color_overrides(args.brief)
    palette = build_palette(theme, color_overrides, args.brief)
    visual_spec = build_visual_spec(
        slug=slug,
        name=args.name,
        brief=args.brief,
        theme=theme,
        palette=palette,
        proportions=default_proportions(theme),
    )
    animation_spec = build_animation_spec(args.name)
    svg_parts = part_svg_map(palette, theme, args.brief)
    blueprint = build_blueprint(slug, args.name, args.brief, animation_spec)
    guide = build_guide_markdown(slug, args.name, args.brief, animation_spec)

    plan = {
        "name": args.name,
        "slug": slug,
        "theme": theme,
        "brief": args.brief.strip(),
        "output_root": str(output_root),
        "generated_files": {
            "visual_spec": f"assets/characters/{slug}/config/{slug}_visual_spec.json",
            "animation_spec": f"assets/characters/{slug}/config/{slug}_animation_spec.json",
            "svg_parts": [f"assets/characters/{slug}/svg/{slug}_{part}.svg" for part in SVG_PART_ORDER],
            "rive_blueprint": f"artifacts/{slug}_rive_blueprint.json",
            "rive_guide": f"artifacts/{slug.upper()}_RIVE_GUIDE.md",
        },
    }

    if args.dry_run:
        print(json.dumps(plan, indent=2))
        return

    ensure_base_form(output_root)

    character_root = output_root / "assets" / "characters" / slug
    config_dir = character_root / "config"
    svg_dir = character_root / "svg"
    rive_dir = character_root / "rive"
    artifacts_dir = output_root / "artifacts"
    specs_dir = output_root / "specs"

    write_json(config_dir / f"{slug}_visual_spec.json", visual_spec)
    write_json(config_dir / f"{slug}_animation_spec.json", animation_spec)

    for part_name in SVG_PART_ORDER:
        write_text(svg_dir / f"{slug}_{part_name}.svg", svg_parts[part_name])

    write_text(svg_dir / "README.md", svg_readme(slug, args.name))
    write_text(rive_dir / "README.md", rive_readme(slug, args.name, animation_spec))
    write_json(artifacts_dir / f"{slug}_rive_blueprint.json", blueprint)
    write_text(artifacts_dir / f"{slug.upper()}_RIVE_GUIDE.md", guide)

    characters_doc = load_yaml_file(specs_dir / "characters.yaml")
    rigs_doc = load_yaml_file(specs_dir / "rigs.yaml")
    palettes_doc = load_yaml_file(specs_dir / "palettes.yaml")

    upsert_yaml_entry(characters_doc, "characters", character_entry(slug, args.name))
    upsert_yaml_entry(rigs_doc, "rigs", rig_entry(slug))
    upsert_yaml_entry(palettes_doc, "palettes", palette_entry(slug, palette))

    write_yaml(specs_dir / "characters.yaml", characters_doc)
    write_yaml(specs_dir / "rigs.yaml", rigs_doc)
    write_yaml(specs_dir / "palettes.yaml", palettes_doc)

    print(f"Created character '{args.name}' as '{slug}' in {output_root}")

    should_run_pipeline = (
        output_root == SCRIPT_ROOT
        and not args.skip_pipeline
        and (output_root / "tools" / "pipeline.py").exists()
    )
    if should_run_pipeline:
        run_pipeline(output_root)
        print("Pipeline validate + manifest completed.")
    else:
        print("Skipped pipeline validate/manifest.")


if __name__ == "__main__":
    main()
