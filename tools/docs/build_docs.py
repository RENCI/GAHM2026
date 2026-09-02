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

# Trailing whitespace at the end of a math body, including the LaTeX escaped space
# ("\ ") pandoc writes for a trailing space run in the Word equation.  Plain .strip()
# takes the space but leaves its backslash behind, and that orphan then binds to
# whatever is appended next: "...\right)}\" + "\tag{13}" becomes "\\tag{13}", which
# MathJax reads as a line break followed by the literal text "tag13".
#
# Only a backslash that stands immediately before whitespace or the end of the body
# is dropped, so real macros ("\,", "\}") are left alone.
TRAILING_MATH_SPACE = re.compile(r"(?:\s+|\\(?=\s|$))+$")

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

# Where an inline equation is followed directly by a digit, pandoc separates the two
# with an empty raw-HTML comment so the markdown cannot be reparsed as one token:
#
#   $...\right| = $`<!-- -->`{=html}64, 50, 34 kts
#
# kramdown has no raw_html attribute syntax, so it prints the backticks, the comment
# and the "{=html}" verbatim.  restore_math_delimiters() already reinstates the space
# that made the separator necessary, so drop it.
RAW_HTML_SEPARATOR = re.compile(r"`<!--\s*-->`\{=html\}")

# Pandoc writes inline math in single dollars.  kramdown has no notion of that
# delimiter, so it runs ordinary markdown span rules straight through the expression.
# Three collisions matter:
#
#   \_   A LaTeX literal underscore looks like a backslash escape, so kramdown eats
#        the backslash: "V_{\max\_ vor\_ tbl}" becomes "V_{\max_ vor_ tbl}", and
#        MathJax then reports "Double subscripts: use braces to clarify".
#   _ *  Two of either in one expression become <em>...</em>, which cuts the
#        expression in half and drops the "\ " spacing runs in between.
#   |    kramdown reads a line containing pipes as a table row, so a paragraph built
#        around "\left| ... \right|" is shattered into <td> cells.
#
# kramdown does understand "$$...$$", at span level as well as block level, and passes
# the contents through untouched -- so promote inline math to the doubled delimiter.
# Table detection is block level and still runs first, so the pipes have to go as well;
# "\vert" typesets identically and means nothing to the table parser.
#
# kramdown also strips the whitespace off a math body before wrapping it in \(..\) or
# \[..\], which turns a body ending in "\ " into one ending in a bare backslash that
# then binds to the delimiter: "...\right\vert \]" becomes "...\right\vert\\]".  So
# every expression is passed through trim_math_body() on the way out, not just the
# numbered ones rebuilt from a \begin{array} wrapper.
#
# Every display equation occupies a line of its own by the time this runs, so inline
# math can be matched a line at a time.
INLINE_MATH = re.compile(r"(?<!\$)\$(?!\$)(.+?)(?<!\$)\$(?!\$)")
MATH_PIPE = re.compile(r"\|")
MATH_VERT_RUN = re.compile(r"\\vert +")

# Word numbers the two steps of section 2 as a real list, but they are far apart and
# each ends up its own single-item <ol>.  kramdown discards the number it was written
# with and restarts at 1, so both steps render as "1.".  An inline attribute list puts
# it back.  Only a list that is a single item on its own -- blank line either side --
# is annotated, so a genuine multi-item list is never cut in half.
ORDERED_ITEM = re.compile(r"^\s{0,3}(\d+)\.\s")


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


def trim_math_body(body: str) -> str:
    """Strip trailing whitespace and its leftover LaTeX spacing backslash."""
    return TRAILING_MATH_SPACE.sub("", body.strip())


def restore_math_delimiters(text: str) -> str:
    r"""Un-escape the closing "$" of an inline equation that ends in a space.

    Word equations frequently end with a space run.  Pandoc writes that as the LaTeX
    escaped space ``\ ``, then drops the space itself because it sits against the
    closing delimiter -- leaving the delimiter escaped::

        $B_{g} \rightarrow B\ \ as\ R_{o} \rightarrow \infty\ \$

    MathJax is configured with ``processEscapes``, so it reads the ``\$`` as a literal
    dollar sign, never closes the expression, and swallows every following paragraph
    up to the next ``$`` on the page.

    Rewrite those to a plain ``$`` and put the space back outside the math, where Word
    meant it ("for different $B$ values", not "for different $B$values").  A ``\$``
    encountered outside math is a real escaped dollar in the prose and is left alone,
    so the state of the scan has to be tracked rather than pattern-matched.
    """
    out: list[str] = []
    index = 0
    in_math = False
    while index < len(text):
        if text.startswith("\\$", index):
            if not in_math:
                out.append("\\$")
                index += 2
                continue
            out.append("$")
            in_math = False
            index += 2
            if index < len(text) and not text[index].isspace():
                out.append(" ")
            continue
        if text.startswith("$$", index):
            out.append("$$")
            in_math = not in_math
            index += 2
            continue
        if text[index] == "$":
            out.append("$")
            in_math = not in_math
            index += 1
            continue
        out.append(text[index])
        index += 1
    return "".join(out)


def isolate_math_from_kramdown(text: str) -> str:
    r"""Hand every expression to kramdown as ``$$...$$`` with no pipes in it."""

    def clean(expr: str) -> str:
        expr = MATH_VERT_RUN.sub(r"\\vert ", MATH_PIPE.sub(r"\\vert ", expr))
        return "$$" + trim_math_body(expr) + "$$"

    out = []
    for line in text.split("\n"):
        if line.startswith("$$") and line.endswith("$$") and line.count("$$") == 2:
            out.append(clean(line[2:-2]))
            continue
        out.append(INLINE_MATH.sub(lambda m: clean(m.group(1)), line))
    return "\n".join(out)


def restore_list_numbering(text: str) -> str:
    """Re-attach the written number to an ordered list item kramdown would renumber."""
    lines = text.split("\n")
    out = []
    for index, line in enumerate(lines):
        out.append(line)
        match = ORDERED_ITEM.match(line)
        if not match or match.group(1) == "1":
            continue
        alone = (index == 0 or not lines[index - 1].strip()) and (
            index + 1 >= len(lines) or not lines[index + 1].strip()
        )
        if alone:
            out.append(f'{{: start="{match.group(1)}"}}')
    return "\n".join(out)


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


def asset_prefix(entry: dict) -> str:
    """Relative path from a generated page back to the site root.

    Generated pages must contain no Liquid at all (see ``protect_from_liquid``),
    so ``{{ site.baseurl }}`` cannot be used for image sources.  A path relative
    to the page resolves correctly under any baseurl instead.
    """
    permalink = entry.get("permalink") or "/" + entry["output"].rsplit(".", 1)[0] + "/"
    depth = len([part for part in permalink.split("/") if part])
    return "/".join([".."] * depth) if depth else "."


def rewrite_images(text: str, slug: str, site_prefix: str) -> str:
    def replace(match: re.Match) -> str:
        alt = match.group("alt").strip()
        if ALT_NOISE.search(alt):
            alt = ""
        src = f"{site_prefix}/assets/images/{slug}/{match.group('file')}"
        return f'<img class="doc-figure" src="{src}" alt="{alt}">'

    return MD_IMAGE.sub(replace, text)


def protect_from_liquid(text: str) -> str:
    """Wrap the page body so Jekyll does not try to parse LaTeX as Liquid.

    Expressions such as ``\\frac{{dV}_{g}(r)}{dr}`` contain ``{{``, which Liquid
    reads as the start of a variable and then fails on.  Nothing in a generated
    page is meant to be templated, so the whole body is marked raw.
    """
    return "{% raw %}\n" + text.strip("\n") + "\n{% endraw %}\n"


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
        lambda m: f"$${trim_math_body(m.group(2))}\\tag{{{m.group(3)}}}$$", text
    )
    text = EQ_ARRAY_PLAIN.sub(lambda m: f"$${trim_math_body(m.group(2))}$$", text)
    text = restore_math_delimiters(text)
    text = RAW_HTML_SEPARATOR.sub("", text)
    text = text.replace("\\#", "")
    text = isolate_math_from_kramdown(text)
    text = restore_list_numbering(text)
    text = BRACKETED_SPAN.sub(
        lambda m: f"<{SPAN_CLASSES[m.group(2)]}>{m.group(1)}</{SPAN_CLASSES[m.group(2)]}>",
        text,
    )
    text = strip_doc_title(text)
    text = promote_headings(text)
    text = rewrite_images(text, entry["slug"], asset_prefix(entry))
    text = protect_from_liquid(text)

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
