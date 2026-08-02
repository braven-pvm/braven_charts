#!/usr/bin/env python3
"""Capture and validate Braven Charts' pre-release public surfaces.

The input is the same release artifact deployed to GitHub Pages: the Flutter
showcase at its root, generated guides under ``guides/``, and generated dartdoc
under ``api/``. The README preview is rendered from the checked-in README after
``tool/public_docs.dart --check`` has verified all generated blocks.

Requirements:
    python -m pip install -r tool/requirements-public-surface-visual.txt
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time
from dataclasses import dataclass
from functools import partial
from html import escape
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import unquote, urlsplit

from markdown_it import MarkdownIt
from PIL import Image, ImageChops, ImageEnhance, ImageStat
from selenium import webdriver
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
RAW_REPOSITORY_URL = (
    "https://raw.githubusercontent.com/braven-pvm/braven_charts/master/"
)
VIEWPORTS = {
    "phone": (390, 844),
    "tablet": (768, 1024),
    "desktop": (1440, 1000),
}
SHORT_DESKTOP_GUIDE_VIEWPORT = (1440, 800)
SURFACES = {
    "readme": "/preview/readme.html",
    "gallery": "/braven_charts/?page=gallery",
    "chart-types": "/braven_charts/?page=chart-types",
    "documentation": "/braven_charts/?page=docs",
    "guide-index": "/braven_charts/guides/",
    "guide-detail": "/braven_charts/guides/chart-grammar/",
    "api": "/braven_charts/api/",
}
FLUTTER_SURFACES = {"gallery", "chart-types", "documentation"}
DEFAULT_BASELINE_DIR = (
    REPOSITORY_ROOT / ".github" / "visual-baselines" / "public-surfaces"
)
DEFAULT_VISUAL_DIFF_THRESHOLD = 0.12


@dataclass(frozen=True)
class Roots:
    preview: Path
    repository: Path
    site: Path


class PublicSurfaceHandler(SimpleHTTPRequestHandler):
    """Serve the release artifact and preview without copying either tree."""

    def __init__(self, *args: Any, roots: Roots, **kwargs: Any) -> None:
        self._roots = roots
        super().__init__(*args, directory=str(roots.site), **kwargs)

    def translate_path(self, path: str) -> str:
        request_path = unquote(urlsplit(path).path)
        mappings = (
            ("/preview/", self._roots.preview),
            ("/repo/", self._roots.repository),
            ("/braven_charts/", self._roots.site),
        )
        for prefix, root in mappings:
            if request_path.startswith(prefix):
                relative = request_path[len(prefix) :]
                candidate = (root / relative).resolve()
                if candidate.is_dir():
                    candidate /= "index.html"
                if candidate == root or root in candidate.parents:
                    return str(candidate)
                return str(root / "__invalid_path__")
        return str(self._roots.site / "__missing_path__")

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, _format: str, *_args: Any) -> None:
        return


class PublicSurfaceServer(ThreadingHTTPServer):
    """Ignore browser disconnects while still surfacing real server errors."""

    def handle_error(self, request: Any, client_address: Any) -> None:
        if isinstance(
            sys.exc_info()[1],
            (ConnectionAbortedError, ConnectionResetError),
        ):
            return
        super().handle_error(request, client_address)


def _run_public_docs_check() -> None:
    dart = shutil.which("dart")
    if dart is None:
        raise FileNotFoundError("dart is not available on PATH")
    subprocess.run(
        [dart, "run", "tool/public_docs.dart", "--check"],
        cwd=REPOSITORY_ROOT,
        check=True,
    )


def _freeze_animated_media(markdown: str, preview_dir: Path) -> tuple[str, list[dict]]:
    first_frame_dir = preview_dir / "first-frame"
    first_frame_dir.mkdir(parents=True, exist_ok=True)
    media_report: list[dict] = []
    pattern = re.compile(
        re.escape(RAW_REPOSITORY_URL)
        + r"(?P<path>doc/screenshots/[^)\s]+?\.(?:png|gif|jpe?g|webp))",
        re.IGNORECASE,
    )

    def replace(match: re.Match[str]) -> str:
        relative = Path(match.group("path"))
        source = (REPOSITORY_ROOT / relative).resolve()
        if REPOSITORY_ROOT not in source.parents or not source.is_file():
            raise FileNotFoundError(f"README media does not exist: {relative}")

        with Image.open(source) as image:
            frames = int(getattr(image, "n_frames", 1))
            width, height = image.size
            first = image.convert("RGB")
            luminance_deviation = round(ImageStat.Stat(first.convert("L")).stddev[0], 2)
            if width < 2 or height < 2 or luminance_deviation < 1:
                raise ValueError(f"README media is blank or invalid: {relative}")
            media_report.append(
                {
                    "path": relative.as_posix(),
                    "width": width,
                    "height": height,
                    "frames": frames,
                    "firstFrameLuminanceDeviation": luminance_deviation,
                }
            )
            if frames > 1:
                target = first_frame_dir / f"{relative.stem}-first-frame.png"
                first.save(target, format="PNG", optimize=True)
                return f"/preview/first-frame/{target.name}"

        return f"/repo/{relative.as_posix()}"

    return pattern.sub(replace, markdown), media_report


def _localize_badges(markdown: str, preview_dir: Path) -> str:
    version_match = re.search(
        r"^version:\s*(?P<version>\S+)\s*$",
        (REPOSITORY_ROOT / "pubspec.yaml").read_text(encoding="utf-8"),
        re.MULTILINE,
    )
    if version_match is None:
        raise ValueError("pubspec.yaml does not declare a package version")
    badges = {
        "https://img.shields.io/pub/v/braven_charts.svg": (
            "pub",
            f"v{version_match.group('version')}",
            "#e56b2f",
        ),
        "https://img.shields.io/badge/Flutter-%E2%89%A53.35-02569B.svg": (
            "Flutter",
            "≥3.35",
            "#02569b",
        ),
        "https://img.shields.io/badge/license-MIT-0F766E.svg": (
            "license",
            "MIT",
            "#0f766e",
        ),
    }
    badge_dir = preview_dir / "badges"
    badge_dir.mkdir(parents=True, exist_ok=True)
    for index, (source, (label, value, color)) in enumerate(badges.items()):
        left_width = max(28, 8 * len(label) + 10)
        right_width = max(28, 8 * len(value) + 10)
        width = left_width + right_width
        target = badge_dir / f"badge-{index + 1}.svg"
        target.write_text(
            f"""<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="20" role="img" aria-label="{escape(label)}: {escape(value)}">
  <title>{escape(label)}: {escape(value)}</title>
  <mask id="round"><rect width="{width}" height="20" rx="3" fill="#fff"/></mask>
  <g mask="url(#round)">
    <rect width="{left_width}" height="20" fill="#555"/>
    <rect x="{left_width}" width="{right_width}" height="20" fill="{color}"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="Verdana,DejaVu Sans,sans-serif" font-size="11">
    <text x="{left_width / 2}" y="14">{escape(label)}</text>
    <text x="{left_width + right_width / 2}" y="14">{escape(value)}</text>
  </g>
</svg>
""",
            encoding="utf-8",
        )
        markdown = markdown.replace(
            source,
            f"/preview/badges/{target.name}",
        )
    return markdown


def _render_readme(preview_dir: Path) -> tuple[Path, list[dict]]:
    source_path = REPOSITORY_ROOT / "README.md"
    catalog = json.loads(
        (REPOSITORY_ROOT / "doc" / "public_catalog.json").read_text(
            encoding="utf-8"
        )
    )
    family_count = len(catalog["chartFamilies"])
    gallery_group_counts: dict[str, int] = {}
    for entry in catalog["gallery"]:
        group = entry["group"]
        gallery_group_counts[group] = gallery_group_counts.get(group, 0) + 1
    gallery_columns = ",".join(
        str(count) for count in gallery_group_counts.values()
    )
    source = source_path.read_text(encoding="utf-8")
    source, media_report = _freeze_animated_media(source, preview_dir)
    source = _localize_badges(source, preview_dir)
    external_media = re.findall(
        r"!\[[^\]]*\]\((https?://[^)\s]+)",
        source,
    )
    if external_media:
        raise ValueError(
            "README preview media must be localized for deterministic capture: "
            + ", ".join(external_media)
        )
    renderer = MarkdownIt("commonmark", {"html": True}).enable(
        ["table", "strikethrough"]
    )
    rendered = renderer.render(source)
    source_hash = hashlib.sha256(
        source_path.read_bytes()
    ).hexdigest()
    html = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light dark">
  <meta name="braven-readme-sha256" content="{source_hash}">
  <title>Braven Charts README preview</title>
  <style>
    :root {{
      color-scheme: light;
      --background: #ffffff;
      --foreground: #1f2328;
      --muted: #59636e;
      --border: #d0d7de;
      --code: #f6f8fa;
      --link: #0969da;
    }}
    @media (prefers-color-scheme: dark) {{
      :root {{
        color-scheme: dark;
        --background: #0d1117;
        --foreground: #f0f6fc;
        --muted: #9198a1;
        --border: #3d444d;
        --code: #151b23;
        --link: #4493f8;
      }}
    }}
    * {{ box-sizing: border-box; }}
    html, body {{ margin: 0; min-width: 0; background: var(--background); }}
    body {{
      color: var(--foreground);
      font: 16px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }}
    .markdown {{
      width: min(100% - 32px, 1280px);
      margin: 0 auto;
      padding: 32px 0 64px;
      overflow-wrap: anywhere;
    }}
    h1, h2 {{ border-bottom: 1px solid var(--border); padding-bottom: .3em; }}
    h1 {{ font-size: 2em; }}
    h2 {{ margin-top: 1.5em; font-size: 1.5em; }}
    h3 {{ margin-top: 1.25em; }}
    a {{ color: var(--link); }}
    code {{
      padding: .2em .4em;
      border-radius: 6px;
      background: var(--code);
      font-family: ui-monospace, SFMono-Regular, Consolas, monospace;
    }}
    pre {{
      padding: 16px;
      overflow: auto;
      border-radius: 6px;
      background: var(--code);
    }}
    pre code {{ padding: 0; background: transparent; }}
    blockquote {{
      margin-left: 0;
      padding-left: 1em;
      border-left: .25em solid var(--border);
      color: var(--muted);
    }}
    table {{
      display: table;
      table-layout: fixed;
      width: 100%;
      max-width: 100%;
      border-collapse: collapse;
    }}
    th, td {{
      min-width: 0;
      padding: 8px 12px;
      border: 1px solid var(--border);
      vertical-align: top;
    }}
    th {{ font-weight: 600; }}
    img {{
      display: inline-block;
      max-width: 100%;
      height: auto;
    }}
    p > a:only-child > img {{ display: block; margin: 0 auto; }}
    table img {{ display: block; width: 100%; }}
    @media (max-width: 600px) {{
      .markdown {{ width: min(100% - 20px, 1280px); padding-top: 20px; }}
      th, td {{ padding: 6px; font-size: 14px; }}
    }}
  </style>
</head>
<body>
  <main
    class="markdown"
    data-readme-source="README.md"
    data-family-count="{family_count}"
    data-gallery-columns="{gallery_columns}"
  >
{rendered}
  </main>
</body>
</html>
"""
    target = preview_dir / "readme.html"
    target.write_text(html, encoding="utf-8")
    return target, media_report


def _find_chrome() -> str | None:
    candidates = [
        shutil.which("google-chrome"),
        shutil.which("google-chrome-stable"),
        shutil.which("chrome"),
        shutil.which("chromium"),
        shutil.which("chromium-browser"),
        "C:/Program Files/Google/Chrome/Application/chrome.exe",
    ]
    return next(
        (str(candidate) for candidate in candidates if candidate and Path(candidate).exists()),
        None,
    )


def _driver() -> webdriver.Chrome:
    options = Options()
    chrome = _find_chrome()
    if chrome:
        options.binary_location = chrome
    for argument in (
        "--headless=new",
        "--hide-scrollbars",
        "--force-device-scale-factor=1",
        "--window-size=1440,1000",
        "--no-first-run",
        "--no-default-browser-check",
        "--run-all-compositor-stages-before-draw",
        "--disable-features=PaintHolding",
        "--disable-gpu",
        "--no-sandbox",
        "--disable-dev-shm-usage",
    ):
        options.add_argument(argument)
    return webdriver.Chrome(options=options)


def _set_viewport(
    driver: webdriver.Chrome, width: int, height: int, *, dark: bool = False
) -> None:
    driver.execute_cdp_cmd(
        "Emulation.setDeviceMetricsOverride",
        {
            "width": width,
            "height": height,
            "deviceScaleFactor": 1,
            "mobile": False,
        },
    )
    driver.execute_cdp_cmd(
        "Emulation.setEmulatedMedia",
        {
            "features": [
                {
                    "name": "prefers-color-scheme",
                    "value": "dark" if dark else "light",
                },
                {"name": "prefers-reduced-motion", "value": "reduce"},
            ]
        },
    )


def _wait_for_surface(
    driver: webdriver.Chrome, surface: str, timeout_seconds: float
) -> None:
    wait = WebDriverWait(driver, timeout_seconds)
    if surface == "readme":
        wait.until(
            lambda current: current.execute_script(
                "return document.readyState === 'complete' && "
                "[...document.images].every((image) => "
                "image.complete && image.naturalWidth > 0) && "
                "(!document.fonts || document.fonts.status === 'loaded')"
            )
        )
        # `HTMLImageElement.complete` becomes true before Chrome necessarily
        # finishes decoding and laying out the image. Await decoding and two
        # animation frames so table geometry is sampled from the settled
        # layout rather than an intermittent intrinsic-size transition.
        driver.set_script_timeout(timeout_seconds)
        driver.execute_async_script(
            """
            const done = arguments[arguments.length - 1];
            const images = [...document.images];
            Promise.all([
              document.fonts ? document.fonts.ready : Promise.resolve(),
              ...images.map((image) =>
                typeof image.decode === 'function'
                  ? image.decode().catch(() => undefined)
                  : Promise.resolve()
              ),
            ])
              .then(() => new Promise((resolve) =>
                requestAnimationFrame(() => requestAnimationFrame(resolve))
              ))
              .then(() => done(true), (error) => done(String(error)));
            """
        )
    elif surface in FLUTTER_SURFACES:
        wait.until(lambda current: current.title == "Braven Charts Showcase")
        wait.until(
            lambda current: current.execute_script(
                "return Boolean(document.querySelector('flutter-view, flt-glass-pane'))"
            )
        )
        time.sleep(4)
    elif surface.startswith("guide-"):
        wait.until(
            lambda current: current.execute_script(
                "return document.readyState === 'complete' && "
                "Boolean(document.querySelector('#main-content'))"
            )
        )
        wait.until(
            lambda current: current.execute_script(
                "return document.fonts ? document.fonts.status === 'loaded' : true"
            )
        )
    else:
        wait.until(
            lambda current: "Dart API docs" in current.title
            and current.execute_script(
                "return Boolean(document.querySelector('#dartdoc-main-content'))"
            )
        )
        wait.until(
            lambda current: current.execute_script(
                "return document.fonts ? document.fonts.status === 'loaded' : true"
            )
        )


GENERIC_GEOMETRY_SCRIPT = """
const viewportWidth = document.documentElement.clientWidth;
const bodyWidth = Math.max(
  document.documentElement.scrollWidth,
  document.body ? document.body.scrollWidth : 0
);
const originalScrollX = window.scrollX;
window.scrollTo(1000000, window.scrollY);
const scrollablePixels = window.scrollX;
window.scrollTo(originalScrollX, window.scrollY);
function isIntentionallyClipped(element) {
  if (element.closest('.sidebar-offcanvas-left, .sidebar-offcanvas-right')) {
    return true;
  }
  for (let node = element; node && node !== document.documentElement; node = node.parentElement) {
    const style = getComputedStyle(node);
    if (['auto', 'scroll', 'hidden', 'clip'].includes(style.overflowX)) {
      return true;
    }
  }
  return false;
}
const wideElements = [...document.querySelectorAll('*')]
  .map((element) => {
    const bounds = element.getBoundingClientRect();
    const style = getComputedStyle(element);
    return {
      tag: element.tagName.toLowerCase(),
      id: element.id,
      className: typeof element.className === 'string' ? element.className : '',
      left: Math.round(bounds.left),
      right: Math.round(bounds.right),
      width: Math.round(bounds.width),
      display: style.display,
      visibility: style.visibility,
      intentionallyClipped: isIntentionallyClipped(element),
    };
  })
  .filter((entry) =>
    entry.display !== 'none' &&
    entry.visibility !== 'hidden' &&
    !entry.intentionallyClipped &&
    entry.width > 0 &&
    (entry.left < -1 || entry.right > viewportWidth + 1)
  )
  .slice(0, 12);
return {
  viewportWidth,
  bodyWidth,
  overflowPixels: Math.max(0, bodyWidth - viewportWidth),
  scrollablePixels,
  wideElements,
};
"""


README_GEOMETRY_SCRIPT = """
function tablesBetween(startText, endText) {
  const headings = [...document.querySelectorAll('h2')];
  const start = headings.find((heading) => heading.textContent.trim() === startText);
  const end = headings.find((heading) => heading.textContent.trim() === endText);
  if (!start) return [];
  return [...document.querySelectorAll('table')].filter((table) => {
    const afterStart = Boolean(start.compareDocumentPosition(table) & Node.DOCUMENT_POSITION_FOLLOWING);
    const beforeEnd = !end || Boolean(table.compareDocumentPosition(end) & Node.DOCUMENT_POSITION_FOLLOWING);
    return afterStart && beforeEnd;
  });
}
function consistency(tables, expectedColumns, label) {
  const issues = [];
  tables.forEach((table, tableIndex) => {
    const tableColumns = expectedColumns[tableIndex];
    [...table.rows].forEach((row, rowIndex) => {
      const cells = [...row.cells];
      if (cells.length !== tableColumns) {
        issues.push(`${label} table ${tableIndex + 1} row ${rowIndex + 1} has ${cells.length} columns; expected ${tableColumns}`);
        return;
      }
      const widths = cells.map((cell) => cell.getBoundingClientRect().width);
      if (Math.max(...widths) - Math.min(...widths) > 2) {
        issues.push(`${label} table ${tableIndex + 1} row ${rowIndex + 1} cell widths differ`);
      }
      const images = cells.map((cell) => cell.querySelector('img')).filter(Boolean);
      if (images.length === tableColumns) {
        const heights = images.map((image) => image.getBoundingClientRect().height);
        if (Math.max(...heights) - Math.min(...heights) > 3) {
          issues.push(`${label} table ${tableIndex + 1} image heights differ`);
        }
      }
    });
  });
  return issues;
}
const familyTables = tablesBetween('Choose a chart family', 'Install');
const galleryTables = tablesBetween('More visual examples', 'License');
const root = document.querySelector('[data-readme-source="README.md"]');
const familyCount = Number(root?.dataset.familyCount ?? 0);
const expectedFamilyColumns = Array.from(
  {length: Math.ceil(familyCount / 2)},
  (_, index) => Math.min(2, familyCount - index * 2),
);
const expectedGalleryColumns = (root?.dataset.galleryColumns ?? '')
  .split(',')
  .filter(Boolean)
  .map(Number);
const renderedFamilyCount = familyTables.reduce(
  (count, table) => count + table.rows[0].cells.length,
  0,
);
const renderedGalleryCount = galleryTables.reduce(
  (count, table) => count + table.rows[0].cells.length,
  0,
);
const expectedGalleryCount = expectedGalleryColumns.reduce(
  (count, columns) => count + columns,
  0,
);
return {
  expectedFamilyCount: familyCount,
  renderedFamilyCount,
  familyTableCount: familyTables.length,
  expectedGalleryCount,
  renderedGalleryCount,
  galleryTableCount: galleryTables.length,
  issues: [
    ...(familyTables.length === expectedFamilyColumns.length ? [] : [`expected ${expectedFamilyColumns.length} family tables, found ${familyTables.length}`]),
    ...(renderedFamilyCount === familyCount ? [] : [`expected ${familyCount} family cells, found ${renderedFamilyCount}`]),
    ...(galleryTables.length === expectedGalleryColumns.length ? [] : [`expected ${expectedGalleryColumns.length} gallery tables, found ${galleryTables.length}`]),
    ...(renderedGalleryCount === expectedGalleryCount ? [] : [`expected ${expectedGalleryCount} gallery cells, found ${renderedGalleryCount}`]),
    ...consistency(familyTables, expectedFamilyColumns, 'family'),
    ...consistency(galleryTables, expectedGalleryColumns, 'gallery'),
  ],
};
"""


API_GEOMETRY_SCRIPT = """
function rect(selector) {
  const node = document.querySelector(selector);
  if (!node) return null;
  const value = node.getBoundingClientRect();
  if (value.width === 0 || value.height === 0) return null;
  return {left: value.left, right: value.right, top: value.top, bottom: value.bottom};
}
const docsNav = rect('.braven-docs-nav');
const title = rect('#title');
const content = rect('#dartdoc-main-content');
const sidebar = rect('#dartdoc-sidebar-left');
const issues = [];
if (!docsNav) issues.push('missing Braven documentation navigation');
if (!title) issues.push('missing dartdoc title bar');
if (!content) issues.push('missing dartdoc main content');
if (docsNav && title && docsNav.bottom > title.top + 1) {
  issues.push('documentation navigation overlaps dartdoc title bar');
}
if (title && content && title.bottom > content.top + 1) {
  issues.push('dartdoc title bar overlaps main content');
}
if (sidebar && content && sidebar.right > content.left + 1) {
  issues.push('dartdoc sidebar overlaps main content');
}
return {docsNav, title, content, sidebar, issues};
"""

GUIDE_GEOMETRY_SCRIPT = """
function rect(selector) {
  const node = document.querySelector(selector);
  if (!node) return null;
  const value = node.getBoundingClientRect();
  if (value.width === 0 || value.height === 0) return null;
  return {left: value.left, right: value.right, top: value.top, bottom: value.bottom};
}
const main = rect('#main-content');
const header = rect('.site-header');
const search = document.querySelector('#guide-search');
const searchLabel = document.querySelector('label[for="guide-search"]');
const liveRegion = document.querySelector('#search-status[aria-live="polite"]');
const article = rect('.guide-content');
const tocNode = document.querySelector('.table-of-contents');
const toc = rect('.table-of-contents');
const tocStyle = tocNode ? getComputedStyle(tocNode) : null;
const tocScrollable = tocNode
  ? tocNode.scrollHeight > tocNode.clientHeight + 1
  : false;
const sourceLink = document.querySelector('.source-link a[href]');
const issues = [];
if (!main) issues.push('missing guide main content');
if (!header) issues.push('missing guide site header');
if (header && main && window.scrollY < 2 && header.bottom > main.top + 1) {
  issues.push('guide header overlaps main content');
}
if (document.body.classList.contains('guide-index')) {
  if (!search) issues.push('missing labelled guide search input');
  if (!searchLabel) issues.push('missing guide search label');
  if (!liveRegion) issues.push('missing polite guide result status');
  if (!document.querySelector('[data-guide-card]')) {
    issues.push('missing guide index entries');
  }
  if (search) {
    const originalScrollX = window.scrollX;
    search.focus();
    if (document.activeElement !== search) issues.push('guide search is not focusable');
    window.scrollTo(originalScrollX, window.scrollY);
  }
}
if (document.body.classList.contains('guide-detail')) {
  if (!article) issues.push('missing guide article');
  if (!toc) issues.push('missing guide table of contents');
  if (!sourceLink) issues.push('missing guide source link');
  if (toc && article && toc.left < article.right && toc.right > article.left &&
      toc.top < article.bottom && toc.bottom > article.top &&
      window.innerWidth >= 980) {
    issues.push('guide table of contents overlaps article');
  }
  if (tocNode && window.innerWidth > 860) {
    if (tocNode.tabIndex < 0) {
      issues.push('desktop guide table of contents is not keyboard-focusable');
    }
    if (toc && toc.top <= 90 && toc.bottom > window.innerHeight - 16) {
      issues.push('sticky guide table of contents extends below the viewport');
    }
    if (tocScrollable) {
      if (!tocStyle || !['auto', 'scroll'].includes(tocStyle.overflowY)) {
        issues.push('long desktop guide table of contents is not scrollable');
      }
      const originalScrollTop = tocNode.scrollTop;
      tocNode.focus({preventScroll: true});
      if (document.activeElement !== tocNode) {
        issues.push('desktop guide table of contents cannot receive focus');
      }
      tocNode.scrollTop = tocNode.scrollHeight;
      if (tocNode.scrollTop <= originalScrollTop) {
        issues.push('desktop guide table of contents cannot be scrolled');
      }
      tocNode.scrollTop = originalScrollTop;
      tocNode.blur();
    }
  }
  if (tocNode && window.innerWidth <= 860) {
    if (tocStyle && tocStyle.overflowY !== 'visible') {
      issues.push('responsive guide table of contents creates a nested scroll');
    }
    if (tocNode.scrollHeight > tocNode.clientHeight + 1) {
      issues.push('responsive guide table of contents clips its links');
    }
  }
}
return {
  main,
  header,
  search: Boolean(search),
  article,
  toc,
  tocClientHeight: tocNode ? tocNode.clientHeight : null,
  tocScrollHeight: tocNode ? tocNode.scrollHeight : null,
  tocOverflowY: tocStyle ? tocStyle.overflowY : null,
  tocTabIndex: tocNode ? tocNode.tabIndex : null,
  issues
};
"""


def _geometry(driver: webdriver.Chrome, surface: str) -> dict[str, Any]:
    result = {"document": driver.execute_script(GENERIC_GEOMETRY_SCRIPT)}
    if surface == "readme":
        result["readme"] = driver.execute_script(README_GEOMETRY_SCRIPT)
    elif surface.startswith("guide-"):
        result["guide"] = driver.execute_script(GUIDE_GEOMETRY_SCRIPT)
    elif surface == "api":
        result["api"] = driver.execute_script(API_GEOMETRY_SCRIPT)
    return result


def _issues_for_geometry(surface: str, geometry: dict[str, Any]) -> list[str]:
    issues = []
    overflow = geometry["document"]["scrollablePixels"]
    if overflow > 1:
        issues.append(f"{surface} document overflows horizontally by {overflow}px")
    clipped = [
        element
        for element in geometry["document"]["wideElements"]
        if element["left"] > -1000
    ]
    if clipped:
        labels = ", ".join(
            (
                element["tag"]
                + (f"#{element['id']}" if element["id"] else "")
                + (
                    f".{element['className'].split()[0]}"
                    if element["className"]
                    else ""
                )
            )
            for element in clipped[:4]
        )
        issues.append(f"{surface} has horizontally clipped content: {labels}")
    if surface == "readme":
        issues.extend(geometry["readme"]["issues"])
    elif surface.startswith("guide-"):
        issues.extend(geometry["guide"]["issues"])
    elif surface == "api":
        issues.extend(geometry["api"]["issues"])
    return issues


def _validate_api_search(
    driver: webdriver.Chrome,
    base_url: str,
    timeout_seconds: float,
) -> dict[str, Any]:
    expected_path = "braven_charts/GaugeChartSeries-class.html"
    result: dict[str, Any] = {
        "query": "GaugeChartSeries",
        "expectedPath": expected_path,
        "resolvedPath": None,
        "indexLoaded": False,
        "issues": [],
    }
    try:
        search = WebDriverWait(driver, timeout_seconds).until(
            lambda current: next(
                (
                    element
                    for element in current.find_elements(
                        By.CSS_SELECTOR,
                        "#search-box, #search-sidebar",
                    )
                    if element.is_displayed() and element.is_enabled()
                ),
                False,
            )
        )
        search.clear()
        search.send_keys(result["query"])
        suggestion = WebDriverWait(driver, timeout_seconds).until(
            lambda current: next(
                (
                    element
                    for element in current.find_elements(
                        By.CSS_SELECTOR,
                        f'.tt-suggestion[data-href="{expected_path}"]',
                    )
                    if element.is_displayed()
                ),
                False,
            )
        )
        result["resolvedPath"] = suggestion.get_attribute("data-href")
        suggestion.click()
        WebDriverWait(driver, timeout_seconds).until(
            lambda current: expected_path in current.current_url
        )
        driver.get(f"{base_url}/braven_charts/api/index.json")
        body = WebDriverWait(driver, timeout_seconds).until(
            lambda current: current.find_element(By.TAG_NAME, "body")
        )
        result["indexLoaded"] = "GaugeChartSeries" in body.text
        if not result["indexLoaded"]:
            result["issues"].append(
                "dartdoc index.json does not contain GaugeChartSeries"
            )
    except TimeoutException:
        result["issues"].append(
            "dartdoc search did not resolve GaugeChartSeries to its class page"
        )
    return result


def _capture(
    base_url: str, output_dir: Path, timeout_seconds: float
) -> tuple[list[dict], list[str]]:
    captures: list[dict] = []
    failures: list[str] = []
    driver = _driver()
    try:
        for viewport_name, (width, height) in VIEWPORTS.items():
            for surface, path in SURFACES.items():
                _set_viewport(driver, width, height)
                url = f"{base_url}{path}"
                try:
                    driver.get(url)
                    _wait_for_surface(driver, surface, timeout_seconds)
                    geometry = _geometry(driver, surface)
                    issues = _issues_for_geometry(surface, geometry)
                    screenshot = output_dir / f"{surface}-{viewport_name}.png"
                    screenshot.write_bytes(driver.get_screenshot_as_png())
                    if surface == "api" and viewport_name == "desktop":
                        api_search = _validate_api_search(
                            driver,
                            base_url,
                            timeout_seconds,
                        )
                        geometry["apiSearch"] = api_search
                        issues.extend(api_search["issues"])
                    captures.append(
                        {
                            "surface": surface,
                            "viewport": viewport_name,
                            "width": width,
                            "height": height,
                            "url": url,
                            "screenshot": screenshot.name,
                            "geometry": geometry,
                            "issues": issues,
                        }
                    )
                    failures.extend(
                        f"{surface}/{viewport_name}: {issue}" for issue in issues
                    )
                except TimeoutException:
                    failures.append(f"{surface}/{viewport_name}: timed out loading {url}")

            _set_viewport(driver, width, height, dark=True)
            dark_url = f"{base_url}{SURFACES['readme']}"
            try:
                driver.get(dark_url)
                _wait_for_surface(driver, "readme", timeout_seconds)
                geometry = _geometry(driver, "readme")
                issues = _issues_for_geometry("readme", geometry)
                screenshot = output_dir / f"readme-{viewport_name}-dark.png"
                screenshot.write_bytes(driver.get_screenshot_as_png())
                captures.append(
                    {
                        "surface": "readme-dark",
                        "viewport": viewport_name,
                        "width": width,
                        "height": height,
                        "url": dark_url,
                        "screenshot": screenshot.name,
                        "geometry": geometry,
                        "issues": issues,
                    }
                )
                failures.extend(
                    f"readme-dark/{viewport_name}: {issue}" for issue in issues
                )
            except TimeoutException:
                failures.append(
                    f"readme-dark/{viewport_name}: timed out loading {dark_url}"
                )

        width, height = SHORT_DESKTOP_GUIDE_VIEWPORT
        surface = "guide-detail"
        viewport_name = "desktop-short"
        _set_viewport(driver, width, height)
        url = f"{base_url}{SURFACES[surface]}"
        try:
            driver.get(url)
            _wait_for_surface(driver, surface, timeout_seconds)
            geometry = _geometry(driver, surface)
            driver.execute_script(
                """
                document.documentElement.style.scrollBehavior = 'auto';
                const layout = document.querySelector('.guide-layout');
                if (layout) window.scrollTo(0, layout.offsetTop);
                """
            )
            geometry["guide"] = driver.execute_script(GUIDE_GEOMETRY_SCRIPT)
            issues = _issues_for_geometry(surface, geometry)
            driver.execute_script(
                """
                const toc = document.querySelector('.table-of-contents');
                if (toc) toc.scrollTop = toc.scrollHeight;
                """
            )
            screenshot = output_dir / f"{surface}-{viewport_name}.png"
            screenshot.write_bytes(driver.get_screenshot_as_png())
            captures.append(
                {
                    "surface": surface,
                    "viewport": viewport_name,
                    "width": width,
                    "height": height,
                    "url": url,
                    "screenshot": screenshot.name,
                    "geometry": geometry,
                    "issues": issues,
                }
            )
            failures.extend(
                f"{surface}/{viewport_name}: {issue}" for issue in issues
            )
        except TimeoutException:
            failures.append(
                f"{surface}/{viewport_name}: timed out loading {url}"
            )
    finally:
        driver.quit()
    return captures, failures


def _difference_hash(image: Image.Image, hash_size: int = 32) -> int:
    grayscale = image.convert("L").resize(
        (hash_size + 1, hash_size),
        Image.Resampling.LANCZOS,
    )
    pixels = list(grayscale.getdata())
    result = 0
    for row in range(hash_size):
        offset = row * (hash_size + 1)
        for column in range(hash_size):
            result <<= 1
            if pixels[offset + column] > pixels[offset + column + 1]:
                result |= 1
    return result


def _visual_difference(
    current_path: Path,
    baseline_path: Path,
    diff_path: Path,
) -> dict[str, Any]:
    with Image.open(current_path) as current_source, Image.open(
        baseline_path
    ) as baseline_source:
        current = current_source.convert("RGB")
        baseline = baseline_source.convert("RGB")
        if current.size != baseline.size:
            return {
                "score": 1.0,
                "currentSize": list(current.size),
                "baselineSize": list(baseline.size),
                "reason": "viewport dimensions changed",
            }

        bits = 32 * 32
        current_hash = _difference_hash(current)
        baseline_hash = _difference_hash(baseline)
        differing_bits = (current_hash ^ baseline_hash).bit_count()
        edge_score = differing_bits / bits
        current_colours = list(
            current.resize((32, 32), Image.Resampling.LANCZOS).getdata()
        )
        baseline_colours = list(
            baseline.resize((32, 32), Image.Resampling.LANCZOS).getdata()
        )
        colour_score = sum(
            abs(current_channel - baseline_channel)
            for current_pixel, baseline_pixel in zip(
                current_colours,
                baseline_colours,
            )
            for current_channel, baseline_channel in zip(
                current_pixel,
                baseline_pixel,
            )
        ) / (32 * 32 * 3 * 255)
        score = max(edge_score, colour_score)

        pixel_diff = ImageChops.difference(current, baseline)
        if pixel_diff.getbbox() is not None:
            diff_path.parent.mkdir(parents=True, exist_ok=True)
            ImageEnhance.Contrast(pixel_diff).enhance(4).save(
                diff_path,
                format="PNG",
                optimize=True,
            )
        return {
            "score": round(score, 6),
            "edgeScore": round(edge_score, 6),
            "colourScore": round(colour_score, 6),
            "differingHashBits": differing_bits,
            "hashBits": bits,
            "currentSize": list(current.size),
            "baselineSize": list(baseline.size),
        }


def _update_baselines(captures: list[dict], output_dir: Path, baseline_dir: Path) -> None:
    if os.environ.get("CI", "").lower() in {"1", "true", "yes"}:
        raise RuntimeError("visual baselines cannot be updated in CI")
    baseline_dir.mkdir(parents=True, exist_ok=True)
    for capture in captures:
        shutil.copy2(
            output_dir / capture["screenshot"],
            baseline_dir / capture["screenshot"],
        )


def _compare_baselines(
    captures: list[dict],
    output_dir: Path,
    baseline_dir: Path,
    threshold: float,
) -> tuple[list[dict], list[str]]:
    comparisons: list[dict] = []
    failures: list[str] = []
    diff_dir = output_dir / "diffs"
    diff_dir.mkdir(parents=True, exist_ok=True)
    for stale_diff in diff_dir.glob("*.png"):
        stale_diff.unlink()
    for capture in captures:
        name = capture["screenshot"]
        baseline = baseline_dir / name
        if not baseline.is_file():
            failures.append(
                f"missing visual baseline {baseline}; review and run with "
                "--update-baselines"
            )
            continue
        result = _visual_difference(
            output_dir / name,
            baseline,
            diff_dir / name,
        )
        result.update({"screenshot": name, "baseline": str(baseline)})
        comparisons.append(result)
        if result["score"] > threshold:
            failures.append(
                f"{name} differs from its reviewed baseline by "
                f"{result['score']:.2%} (allowed {threshold:.2%})"
            )
    return comparisons, failures


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--site-dir",
        type=Path,
        default=REPOSITORY_ROOT / "example" / "build" / "web",
        help="Flutter release artifact containing api/ (default: example/build/web)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=REPOSITORY_ROOT / "build" / "public-surface-visual",
    )
    parser.add_argument("--timeout", type=float, default=30)
    parser.add_argument(
        "--skip-public-docs-check",
        action="store_true",
        help="Skip the generated README/catalog consistency check",
    )
    parser.add_argument(
        "--baseline-dir",
        type=Path,
        default=DEFAULT_BASELINE_DIR,
        help="Reviewed screenshot baseline directory",
    )
    parser.add_argument(
        "--update-baselines",
        action="store_true",
        help="Replace reviewed baselines after visually approving every capture",
    )
    parser.add_argument(
        "--visual-diff-threshold",
        type=float,
        default=DEFAULT_VISUAL_DIFF_THRESHOLD,
        help="Maximum perceptual hash difference from 0 to 1",
    )
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    site_dir = args.site_dir.resolve()
    api_index = site_dir / "api" / "index.html"
    guides_index = site_dir / "guides" / "index.html"
    if (
        not (site_dir / "index.html").is_file()
        or not api_index.is_file()
        or not guides_index.is_file()
    ):
        raise SystemExit(
            f"{site_dir} must contain the built showcase, guides/index.html, "
            "and api/index.html"
        )
    if not args.skip_public_docs_check:
        _run_public_docs_check()

    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    preview_dir = output_dir / "preview"
    preview_dir.mkdir(parents=True, exist_ok=True)
    readme_preview, media_report = _render_readme(preview_dir)

    roots = Roots(
        preview=preview_dir,
        repository=REPOSITORY_ROOT,
        site=site_dir,
    )
    handler = partial(PublicSurfaceHandler, roots=roots)
    server = PublicSurfaceServer(("127.0.0.1", 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    base_url = f"http://127.0.0.1:{server.server_port}"
    try:
        captures, failures = _capture(base_url, output_dir, args.timeout)
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)

    baseline_dir = args.baseline_dir.resolve()
    if not 0 <= args.visual_diff_threshold <= 1:
        raise SystemExit("--visual-diff-threshold must be between 0 and 1")
    if args.update_baselines:
        _update_baselines(captures, output_dir, baseline_dir)
        comparisons, baseline_failures = _compare_baselines(
            captures,
            output_dir,
            baseline_dir,
            args.visual_diff_threshold,
        )
    else:
        comparisons, baseline_failures = _compare_baselines(
            captures,
            output_dir,
            baseline_dir,
            args.visual_diff_threshold,
        )
    failures.extend(baseline_failures)

    report = {
        "readmeSource": "README.md",
        "readmePreview": str(readme_preview.relative_to(output_dir)),
        "readmeSha256": hashlib.sha256(
            (REPOSITORY_ROOT / "README.md").read_bytes()
        ).hexdigest(),
        "siteDirectory": str(site_dir),
        "viewports": VIEWPORTS,
        "media": media_report,
        "captures": captures,
        "visualBaselines": {
            "directory": str(baseline_dir),
            "updated": args.update_baselines,
            "threshold": args.visual_diff_threshold,
            "comparisons": comparisons,
        },
        "failures": failures,
    }
    report_path = output_dir / "report.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    print(f"Public surface report: {report_path}")
    print(f"Captured {len(captures)} screenshots.")
    if failures:
        for failure in failures:
            print(f"ERROR: {failure}")
        return 1
    print("Public surface geometry and reviewed visual baselines passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
