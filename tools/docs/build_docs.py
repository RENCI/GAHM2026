#!/usr/bin/env python3
"""Assemble the GAHM2026 documentation site staging directory.

The authoritative narrative documentation lives in ``documentation/*.docx``.  This
script copies the hand-written site in ``docs/`` into a staging directory, renders
each docx listed in ``docs/_data/docx_pages.yml`` to markdown with pandoc, and drops
the result alongside the hand-written pages.  Jekyll then builds from the staging
directory.  Nothing generated here is committed.

Usage::

    python tools/docs/build_docs.py              # assemble _docs_build/
    python tools/docs/build_docs.py --clean      # remove the staging dir first
    python tools/docs/build_docs.py --check      # verify pandoc and the manifest only

Requires pandoc on PATH and PyYAML.
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
DOCS_DIR = REPO_ROOT / "docs"
MANIFEST = DOCS_DIR / "_data" / "docx_pages.yml"
STAGING_DIR = REPO_ROOT / "_docs_build"

# Pandoc writer options.
#   tex_math_dollars      -> $...$ / $$...$$, which kramdown passes through to MathJax
#   -raw_tex              -> do not emit raw LaTeX blocks kramdown cannot handle
#   -superscript-subscript-> emit <sup>/<sub> instead of ^3^ / ~3~, which kramdown
#                            does not render
PANDOC_TO = "markdown+tex_math_dollars-raw_tex-superscript-subscript"

# $$\begin{array}{r}\n<expr>\#(7)\n\end{array}$$  ->  $$<expr>\tag{7}$$
#
# Word numbers its equations with a trailing \#(n) inside a right-aligned array.
# MathJax renders that literally, so lift the number out into a \tag.  The array
# wrapper only exists for right alignment and is dropped with it.
#
# Equation 17 is styled inline in the source, so it arrives wrapped in single
# dollars; it is promoted to a display equation here.  Both delimiters are matched
# by the same pattern.
#
# The body must not cross an \end{array}, otherwise an unnumbered block sitting
# between two numbered ones gets swallowed into a single match.
_ARRAY_BODY = r"((?:(?!\\end\{array\}).)*?)"

EQ_ARRAY_TAG = re.compile(
    r"(\$\$?)\\begin\{array\}\{r\}\s*\n"
    + _ARRAY_BODY
    + r"\\#\((\d+)\)\s*\n\\end\{array\}\1",
    re.DOTALL,
)

# Same wrapper, but with no equation number.
EQ_ARRAY_PLAIN = re.compile(
    r"(\$\$?)\\begin\{array\}\{r\}\s*\n" + _ARRAY_BODY + r"\s*\n\\end\{array\}\1",
    re.DOTALL,
)

# A paragraph that is entirely bold and starts with a section number, e.g.
# "**2. Implementation**" or "**1. Derivation** (adapted from J. Gao, 2018)".
#
# The source documents mark sections with manual bold rather than Word's Heading
# styles, so pandoc emits bold paragraphs.  If the docx is ever restyled with real
# Heading 1/2 levels, pandoc will emit "#"/"##" directly and this rule becomes inert.
BOLD_NUMBERED_HEADING = re.compile(r"^\*\*(\d+(?:\.\d+)*\.?)\s+([^*]+?)\*\*(.*)$")

# "**Appendix A - Alternative derivation of** $...$"
BOLD_APPENDIX_HEADING = re.compile(r"^\*\*(Appendix\s+[A-Z][^*]*?)\*\*(.*)$")

# Pandoc's --extract-media writes to <dir>/media/imageN.png and emits an absolute
# path plus Word's inch-based sizing as a pandoc attribute block, which kramdown does
# not understand:
#
#   ![alt](/abs/path/media/image3.png){width="5.48in" height="1.49in"}
#
# Rewrite to a site-relative <img> carrying the responsive .doc-figure class.
MD_IMAGE = re.compile(
    r"!\[(?P<alt>[^\]]*)\]\([^)]*?/media/(?P<file>[^)/]+)\)"
    r"(?:\{[^}]*\})?"
)

# Word fills the alt text of pasted figures with this boilerplate.  It is noise in a
# screen reader; the "Figure N." caption paragraph that follows carries the meaning.
ALT_NOISE = re.compile(r"AI-generated content may be incorrect", re.IGNORECASE)

# Underlined and highlighted runs become pandoc bracketed spans, which kramdown emits
# verbatim.  Map them to HTML the browser understands.
SPAN_CLASSES = {"underline": "u", "mark": "mark"}
BRACKETED_SPAN = re.compile(r"\[([^\]]*)\]\{\.(" + "|".join(SPAN_CLASSES) + r")\}")


def fail(message: str) -> None:
    print(f"build_docs: error: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_manifest() -> list[dict]:
    if not MANIFEST.is_file():
        fail(f"manifest not found: {MANIFEST.relative_to(REPO_ROOT)}")
    with MANIFEST.open("r", encoding="utf-8") as fh:
        entries = yaml.safe_load(fh)
    if not entries:
        return []
    for entry in entries:
        for key in ("docx", "output", "slug", "title", "nav_order"):
            if key not in entry:
                fail(f"manifest entry missing required key '{key}': {entry}")
        docx = REPO_ROOT / entry["docx"]
        if not docx.is_file():
            fail(f"docx listed in the manifest does not exist: {entry['docx']}")
    return entries


def require_pandoc() -> str:
    pandoc = shutil.which("pandoc")
    if pandoc is None:
        fail("pandoc not found on PATH")
    version = subprocess.run(
        [pandoc, "--version"], capture_output=True, text=True, check=True
    ).stdout.splitlines()[0]
    return version


def front_matter(entry: dict) -> str:
    lines = ["---", "layout: default", f"title: {entry['title']}"]
    if "parent" in entry:
        lines.append(f"parent: {entry['parent']}")
    lines.append(f"nav_order: {entry['nav_order']}")
    if "permalink" in entry:
        lines.append(f"permalink: {entry['permalink']}")
    lines.append("---")
    lines.append("")
    return "\n".join(lines)


def promote_headings(text: str) -> str:
    """Turn bold section paragraphs into real markdown headings."""
    out = []
    for line in text.split("\n"):
        match = BOLD_NUMBERED_HEADING.match(line)
        if match:
            number, heading, trailing = match.groups()
            number = number.rstrip(".")
            level = "##" if "." not in number else "###"
            out.append(f"{level} {number}. {heading.strip()}")
            if trailing.strip():
                out.append("")
                out.append(trailing.strip())
            continue

        match = BOLD_APPENDIX_HEADING.match(line)
        if match:
            heading, trailing = match.groups()
            # The appendix title ends in an inline equation, so keep the trailing
            # text on the heading line rather than splitting it into a paragraph.
            out.append(f"## {heading.strip()} {trailing.strip()}".rstrip())
            continue

        out.append(line)
    return "\n".join(out)


def rewrite_images(text: str, slug: str, site_prefix: str) -> str:
    def replace(match: re.Match) -> str:
        alt = match.group("alt").strip()
        if ALT_NOISE.search(alt):
            alt = ""
        src = f"{site_prefix}/assets/images/{slug}/{match.group('file')}"
        return f'<img class="doc-figure" src="{src}" alt="{alt}">'

    return MD_IMAGE.sub(replace, text)


def strip_doc_title(text: str) -> str:
    """Drop the leading bold document title; the theme renders one from front matter."""
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if not line.strip():
            continue
        if line.startswith("**") and line.rstrip().endswith("**"):
            return "\n".join(lines[i + 1 :]).lstrip("\n")
        break
    return text


def convert(entry: dict, pandoc: str) -> Path:
    docx = REPO_ROOT / entry["docx"]
    output = STAGING_DIR / entry["output"]
    output.parent.mkdir(parents=True, exist_ok=True)

    media_dir = STAGING_DIR / "assets" / "images" / entry["slug"]
    if media_dir.exists():
        shutil.rmtree(media_dir)

    subprocess.run(
        [
            pandoc,
            "-f",
            "docx",
            "-t",
            PANDOC_TO,
            "--wrap=none",
            f"--extract-media={media_dir}",
            str(docx),
            "-o",
            str(output),
        ],
        check=True,
    )

    text = output.read_text(encoding="utf-8")
    text = EQ_ARRAY_TAG.sub(
        lambda m: f"$${m.group(2).strip()}\\tag{{{m.group(3)}}}$$", text
    )
    text = EQ_ARRAY_PLAIN.sub(lambda m: f"$${m.group(2).strip()}$$", text)
    text = text.replace("\\#", "")
    text = BRACKETED_SPAN.sub(
        lambda m: f"<{SPAN_CLASSES[m.group(2)]}>{m.group(1)}</{SPAN_CLASSES[m.group(2)]}>",
        text,
    )
    text = strip_doc_title(text)
    text = promote_headings(text)
    text = rewrite_images(text, entry["slug"], "{{ site.baseurl }}")

    output.write_text(front_matter(entry) + text, encoding="utf-8")

    # --extract-media nests the files one level deeper than the directory it is given.
    nested = media_dir / "media"
    if nested.is_dir():
        for image in nested.iterdir():
            image.rename(media_dir / image.name)
        nested.rmdir()

    return output


def stage_docs() -> None:
    shutil.copytree(
        DOCS_DIR,
        STAGING_DIR,
        dirs_exist_ok=True,
        ignore=shutil.ignore_patterns(
            "_site", ".jekyll-cache", "Gemfile.lock", "vendor", "*~"
        ),
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--clean", action="store_true", help="remove the staging directory first"
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="validate pandoc and the manifest without building",
    )
    args = parser.parse_args()

    entries = load_manifest()
    version = require_pandoc()

    if args.check:
        print(f"build_docs: {version}")
        print(f"build_docs: {len(entries)} docx page(s) in the manifest, all present")
        return 0

    if args.clean and STAGING_DIR.exists():
        shutil.rmtree(STAGING_DIR)

    stage_docs()
    for entry in entries:
        output = convert(entry, shutil.which("pandoc"))
        print(f"build_docs: {entry['docx']} -> {output.relative_to(REPO_ROOT)}")

    print(f"build_docs: staged {STAGING_DIR.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
