# Source Documentation Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish every authoritative DOCX as a faithful Jekyll page and provide a standalone command that
automatically regenerates pages whose source content changed.

**Architecture:** Add a Python 3.9 standard-library converter behind the executable `tools/update-docs` command. The
converter owns a fixed source-document manifest, records each DOCX SHA-256 in generated front matter, uses Pandoc for
DOCX/OMML conversion and media extraction, and stages every selected conversion before publishing generated Markdown
and assets. Keep the current task-oriented pages while grouping converted DOCX pages and native Markdown references
under Just the Docs' parent navigation.

**Tech Stack:** Python 3.9 standard library, Pandoc 3, Jekyll 4.4.1, Kramdown 2.5.2, MathJax 3.2.2, Just the Docs
0.12.0, Ruby 3.4, html-proofer 5.2.2, Markdown, Liquid, Git.

## Global Constraints

- Treat all seven DOCX files in `documentation/` as authoritative, including older GAHM2024 terminology and incomplete
  text; do not modernize or complete their prose.
- Preserve source wording, ordering, equations, figures, tables, and lists. Restrict cleanup to web presentation.
- Keep the existing primary Jekyll layout and concise guides; add source documents rather than replacing those guides.
- Publish sparse documents and identify their draft status without changing their body content.
- Generated Markdown must be checked in under `docs/`; GitHub Pages must not need Pandoc.
- Use content SHA-256 values, not Git state, for automatic change detection.
- Use Jekyll `relative_url` paths for published media so local and `/GAHM2026/` builds both work.
- Do not add a deployment workflow or change GitHub Pages settings.
- Preserve unrelated tracked and untracked workspace content and do not run MATLAB regression tests for documentation
  changes.

---

### Task 1: Build and test content-based source selection

**Files:**
- Create: `tools/update_docs.py`
- Create: `tools/test_update_docs.py`

**Interfaces:**
- Produces: `SourceDocument`, `sha256_file(path)`, `read_source_checksum(path)`,
  `select_documents(documents, repository_root, force_all, requested_sources)`.
- Consumes: Python 3.9 standard library only.

- [ ] **Step 1: Write failing checksum and selection tests**

Create `tools/test_update_docs.py` using `unittest`, temporary directories, and these exact behavioral cases:

```python
import hashlib
import tempfile
import unittest
from pathlib import Path

from update_docs import SourceDocument, read_source_checksum, select_documents, sha256_file


class UpdateDocsSelectionTests(unittest.TestCase):
    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary_directory.name)
        (self.root / "documentation").mkdir()
        (self.root / "docs/source-documents").mkdir(parents=True)
        self.document = SourceDocument(
            source=Path("documentation/example.docx"),
            output=Path("docs/source-documents/example.md"),
            slug="example",
            title="Example Source",
            nav_order=1,
            is_draft=False,
        )
        self.source = self.root / self.document.source
        self.output = self.root / self.document.output
        self.source.write_bytes(b"first source version")

    def tearDown(self):
        self.temporary_directory.cleanup()

    def write_output_checksum(self, checksum):
        self.output.write_text(
            f"---\nsource_sha256: \"{checksum}\"\n---\n# Example\n",
            encoding="utf-8",
        )

    def test_sha256_file_hashes_binary_source(self):
        expected = hashlib.sha256(b"first source version").hexdigest()
        self.assertEqual(sha256_file(self.source), expected)

    def test_missing_output_is_selected(self):
        selected = select_documents([self.document], self.root, False, ())
        self.assertEqual(selected, [self.document])

    def test_matching_checksum_is_not_selected(self):
        self.write_output_checksum(sha256_file(self.source))
        selected = select_documents([self.document], self.root, False, ())
        self.assertEqual(selected, [])

    def test_changed_source_is_selected(self):
        self.write_output_checksum(sha256_file(self.source))
        self.source.write_bytes(b"second source version")
        selected = select_documents([self.document], self.root, False, ())
        self.assertEqual(selected, [self.document])

    def test_force_all_selects_current_document(self):
        self.write_output_checksum(sha256_file(self.source))
        selected = select_documents([self.document], self.root, True, ())
        self.assertEqual(selected, [self.document])

    def test_explicit_source_selects_only_requested_document(self):
        self.write_output_checksum(sha256_file(self.source))
        selected = select_documents(
            [self.document], self.root, False, (self.document.source,)
        )
        self.assertEqual(selected, [self.document])

    def test_checksum_reader_rejects_missing_front_matter_value(self):
        self.output.write_text("---\ntitle: Example\n---\n", encoding="utf-8")
        self.assertIsNone(read_source_checksum(self.output))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the tests and verify the module is missing**

Run:

```bash
python3 -m unittest tools/test_update_docs.py -v
```

Expected: FAIL with `ModuleNotFoundError: No module named 'update_docs'`.

- [ ] **Step 3: Implement the manifest type, hashing, and selection**

In `tools/update_docs.py`, define:

```python
#!/usr/bin/env python3
import hashlib
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Optional, Sequence


@dataclass(frozen=True)
class SourceDocument:
    source: Path
    output: Path
    slug: str
    title: str
    nav_order: int
    is_draft: bool


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source_file:
        for block in iter(lambda: source_file.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def read_source_checksum(path: Path) -> Optional[str]:
    if not path.exists():
        return None
    match = re.search(
        r'^source_sha256:\s*["\']?([0-9a-f]{64})["\']?\s*$',
        path.read_text(encoding="utf-8"),
        flags=re.MULTILINE,
    )
    return match.group(1) if match else None


def select_documents(
    documents: Iterable[SourceDocument],
    repository_root: Path,
    force_all: bool,
    requested_sources: Sequence[Path],
) -> list:
    document_list = list(documents)
    requested = {Path(source) for source in requested_sources}
    if requested:
        known = {document.source for document in document_list}
        unknown = requested - known
        if unknown:
            names = ", ".join(str(path) for path in sorted(unknown))
            raise ValueError(f"Unknown source document: {names}")
        return [document for document in document_list if document.source in requested]
    if force_all:
        return document_list
    return [
        document
        for document in document_list
        if read_source_checksum(repository_root / document.output)
        != sha256_file(repository_root / document.source)
    ]
```

Keep all source paths repository-relative so the command works from any current directory. Validate source existence in
the CLI task before calling `select_documents`; do not make missing files look like checksum changes.

- [ ] **Step 4: Run the focused tests**

Run:

```bash
PYTHONPATH=tools python3 -m unittest tools/test_update_docs.py -v
```

Expected: all seven tests PASS.

- [ ] **Step 5: Add unknown-source coverage and verify it passes**

Add:

```python
    def test_unknown_explicit_source_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Unknown source document"):
            select_documents(
                [self.document], self.root, False, (Path("documentation/other.docx"),)
            )
```

Run the same unittest command. Expected: all eight tests PASS.

- [ ] **Step 6: Commit the tested selection core**

```bash
git add tools/update_docs.py tools/test_update_docs.py
git diff --cached --check
git commit -m "Add documentation source change detection"
```

---

### Task 2: Convert DOCX content and expose the terminal command

**Files:**
- Modify: `tools/update_docs.py`
- Modify: `tools/test_update_docs.py`
- Create: `tools/update-docs`
- Create (generated): `docs/source-documents/getting-started-source.md`
- Create (generated): `docs/source-documents/derivation-and-implementation.md`
- Create (generated): `docs/source-documents/blending.md`
- Create (generated): `docs/source-documents/use-cases.md`
- Create (generated): `docs/source-documents/aswip-fort22.md`
- Create (generated): `docs/source-documents/fort22-v2.md`
- Create (generated): `docs/source-documents/wind-adjustment-factor.md`
- Create (generated): `docs/assets/source-documents/derivation-and-implementation/media/image1.png`
- Create (generated): `docs/assets/source-documents/derivation-and-implementation/media/image2.png`

**Interfaces:**
- Consumes: `SourceDocument`, source-selection functions from Task 1, seven DOCX files, `pandoc`, and optionally the
  locked Bundler environment.
- Produces: executable commands `tools/update-docs [--all] [--check] [DOCX [DOCX]]`, deterministic generated pages, and
  base-URL-safe extracted assets.

- [ ] **Step 1: Add failing presentation-cleanup tests**

Import `clean_markdown` and add tests proving only structural conversion occurs:

```python
    def test_clean_markdown_promotes_source_title_and_section(self):
        source = "**Document Title**\n\n**1. Derivation** (source note)\n"
        expected = "# Document Title\n\n## 1. Derivation (source note)\n"
        self.assertEqual(clean_markdown(source), expected)

    def test_clean_markdown_preserves_equation_content_and_numbers(self):
        source = "$$x^{2} + y^{2} = z^{2}\\#(12)$$\n"
        expected = "$$x^{2} + y^{2} = z^{2}\\tag{12}$$\n"
        self.assertEqual(clean_markdown(source), expected)

    def test_clean_markdown_makes_extracted_media_base_url_safe(self):
        source = (
            "![Figure](assets/source-documents/example/media/image1.png)"
            '{width="3in"}\n'
        )
        expected = (
            "![Figure]({{ '/assets/source-documents/example/media/image1.png' "
            "| relative_url }}){width=\"3in\"}\n"
        )
        self.assertEqual(clean_markdown(source), expected)
```

Run:

```bash
PYTHONPATH=tools python3 -m unittest tools/test_update_docs.py -v
```

Expected: FAIL because `clean_markdown` is not defined.

- [ ] **Step 2: Implement deterministic structural cleanup**

Add `clean_markdown(markdown)` with narrowly scoped multiline substitutions:

```python
def clean_markdown(markdown: str) -> str:
    markdown = re.sub(r"\A\*\*([^*\n]+)\*\*", r"# \1", markdown)
    markdown = re.sub(
        r"^\*\*((?:\d+\.\s+|Appendix\s+)[^*\n]+)\*\*(.*)$",
        lambda match: f"## {match.group(1).strip()}{match.group(2)}",
        markdown,
        flags=re.MULTILINE,
    )
    markdown = re.sub(
        r"^\*\*([^*\n]+)\*\*$",
        r"## \1",
        markdown,
        flags=re.MULTILINE,
    )
    markdown = re.sub(r"\\#\((\d+)\)", r"\\tag{\1}", markdown)

    def replace_media(match):
        path = "/" + match.group("path")
        return f"![{match.group('alt')}]({{{{ '{path}' | relative_url }}}})"

    return re.sub(
        r"!\[(?P<alt>[^]]*)\]\((?P<path>assets/source-documents/[^)]+)\)",
        replace_media,
        markdown,
    )
```

Do not alter spelling, GAHM version names, incomplete markers, ordinary emphasis, formulas, or prose.

- [ ] **Step 3: Define the complete source manifest**

Add a `DOCUMENTS` tuple containing these exact source/output/slug/title/order/draft records:

| Source | Output | Title | Order | Draft |
|--------|--------|-------|-------|-------|
| `Getting_Started.docx` | `getting-started-source.md` | Getting Started (Source Document) | 1 | false |
| `Derivation_and_Implementation.docx` | `derivation-and-implementation.md` | Derivation and Implementation | 2 | false |
| `Blending.docx` | `blending.md` | Gridded Meteorology Blending | 3 | true |
| `Use_cases.docx` | `use-cases.md` | GAHM2024 Use Cases | 4 | true |
| `ASWIP_fort22.docx` | `aswip-fort22.md` | ASWIP fort.22 Format | 5 | true |
| `fort22_v2.docx` | `fort22-v2.md` | Extended fort.22 Format | 6 | false |
| `Zo_WAF.docx` | `wind-adjustment-factor.md` | Wind Adjustment Factor | 7 | true |

Every record uses `documentation/<Source>` and `docs/source-documents/<Output>`. Draft flags reflect visibly sparse,
uncertain, or incomplete passages; they do not change source content.

- [ ] **Step 4: Add failing front-matter and atomic-publish tests**

Test `build_page(document, checksum, body)` for all required metadata and test `publish_staged_documents` with a
temporary tree:

```python
    def test_build_page_records_source_identity_and_navigation(self):
        page = build_page(self.document, "a" * 64, "# Example\n")
        self.assertIn('source_sha256: "' + "a" * 64 + '"', page)
        self.assertIn("parent: Source Documents", page)
        self.assertIn("nav_order: 1", page)
        self.assertIn("permalink: /source-documents/example/", page)
        self.assertIn("documentation/example.docx", page)
        self.assertTrue(page.endswith("# Example\n"))
```

For publication, stage a page in a temporary directory, call the publisher, and assert its destination page and media
directory replace the old content.

```python
    def test_publish_replaces_page_and_removes_stale_media(self):
        staging = self.root / "staging"
        staged_page = staging / self.document.output
        staged_page.parent.mkdir(parents=True)
        staged_page.write_text("new page\n", encoding="utf-8")
        staged_asset = (
            staging
            / "docs/assets/source-documents"
            / self.document.slug
            / "media/new.png"
        )
        staged_asset.parent.mkdir(parents=True)
        staged_asset.write_bytes(b"new image")

        self.output.write_text("old page\n", encoding="utf-8")
        old_asset = (
            self.root
            / "docs/assets/source-documents"
            / self.document.slug
            / "media/old.png"
        )
        old_asset.parent.mkdir(parents=True)
        old_asset.write_bytes(b"old image")

        publish_staged_documents([self.document], self.root, staging)

        self.assertEqual(self.output.read_text(encoding="utf-8"), "new page\n")
        self.assertFalse(old_asset.exists())
        self.assertEqual(
            (
                self.root
                / "docs/assets/source-documents"
                / self.document.slug
                / "media/new.png"
            ).read_bytes(),
            b"new image",
        )
```

- [ ] **Step 5: Implement Pandoc staging and atomic publication**

Implement these contracts:

```python
def build_page(document: SourceDocument, checksum: str, body: str) -> str
def stage_document(document: SourceDocument, repository_root: Path, staging_root: Path) -> None
def publish_staged_documents(
    documents: Sequence[SourceDocument], repository_root: Path, staging_root: Path
) -> None
```

`stage_document` must run Pandoc with:

```python
[
    "pandoc",
    str(repository_root / document.source),
    "--from=docx",
    "--to=markdown+tex_math_dollars",
    "--wrap=none",
    f"--extract-media=assets/source-documents/{document.slug}",
    "--output",
    str(staged_markdown),
]
```

Run Pandoc with `cwd=staging_root`, clean its Markdown, prepend front matter with `layout`, `title`, `parent`,
`nav_order`, `permalink`, `source_document`, and quoted `source_sha256`, then prepend a short note linking to the DOCX
on GitHub. For `is_draft=True`, add: `> **Draft source:** This document contains incomplete or provisional material.`
Copy staged outputs only after every selected document converts successfully. Before replacing an asset directory,
remove that document's old destination asset directory so deleted DOCX images cannot survive as stale files.

- [ ] **Step 6: Implement argument parsing and check mode**

Implement `main(argv=None)` with `argparse` options `--all`, `--check`, and zero or more repository-relative DOCX
paths. It must:

1. locate the repository from `Path(__file__).resolve().parent.parent`;
2. reject `--all` combined with explicit paths;
3. validate every manifest source before selection;
4. require `pandoc` only when at least one page needs conversion;
5. stage all selected pages in `tempfile.TemporaryDirectory()` and publish only after successful conversion;
6. print either `Documentation is already current.` or one `Updated <output>` line per page; and
7. for `--check`, run these commands from `docs/` after updates:

```bash
bundle exec jekyll build --strict_front_matter
bundle exec htmlproofer ./_site --disable-external
```

Catch expected validation and subprocess errors once at the CLI boundary, print a concise `error:` message to stderr,
and return nonzero. Do not catch programming errors.

- [ ] **Step 7: Add the executable wrapper**

Create `tools/update-docs`:

```bash
#!/bin/sh
set -eu
SCRIPT_DIRECTORY=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec python3 "$SCRIPT_DIRECTORY/update_docs.py" "$@"
```

Run `chmod +x tools/update-docs`.

- [ ] **Step 8: Run unit tests and generate every DOCX page**

```bash
PYTHONPATH=tools python3 -m unittest tools/test_update_docs.py -v
./tools/update-docs --all
./tools/update-docs
```

Expected: tests PASS; `--all` reports seven updated pages; the second command prints
`Documentation is already current.` and changes no files.

- [ ] **Step 9: Verify faithful math, media, and checksums**

```bash
test "$(find docs/source-documents -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')" -eq 7
test -f docs/assets/source-documents/derivation-and-implementation/media/image1.png
test -f docs/assets/source-documents/derivation-and-implementation/media/image2.png
rg -n 'source_sha256: "[0-9a-f]{64}"' docs/source-documents
rg -n '\\tag\{1\}|V_\{g\}|R_\{mw\}' docs/source-documents/derivation-and-implementation.md
rg -n "relative_url.*image[12]\.png" docs/source-documents/derivation-and-implementation.md
git diff --check
```

Expected: seven pages, both figures, seven checksums, representative TeX, base-URL-safe image links, and no whitespace
errors.

- [ ] **Step 10: Commit the converter and generated DOCX pages**

```bash
git add tools/update-docs tools/update_docs.py tools/test_update_docs.py \
    docs/source-documents docs/assets/source-documents
git diff --cached --check
git commit -m "Publish converted source documents"
```

---

### Task 3: Add source navigation and native Markdown references

**Files:**
- Create: `docs/source-documents.md`
- Create: `docs/source-documents/configuration-reference.md`
- Create: `docs/source-documents/data-structures.md`
- Create: `docs/source-documents/workflow.md`
- Modify: `docs/index.md`
- Modify: `docs/configuration.md`
- Modify: `docs/gahm-derivation.md`
- Modify: `docs/outputs.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: generated child pages from Task 2 and authoritative native Markdown in `documentation/Config_Files.md`,
  `documentation/Data_Structures.md`, and `documentation/Workflow.md`.
- Produces: complete Just the Docs parent/child navigation and no links to filenames removed by commit `634b22e`.

- [ ] **Step 1: Create the Source Documents parent page**

Create `docs/source-documents.md` with:

```yaml
---
layout: default
title: Source Documents
nav_order: 8
has_children: true
permalink: /source-documents/
---
```

Explain that these pages faithfully render the files in `documentation/`, may contain provisional or older material,
and are published for search and review without asserting that their workflows match current code. Link back to the
primary Getting Started, Configuration, and Outputs guides for current task-oriented instructions.

- [ ] **Step 2: Publish the configuration reference**

Copy the body of `documentation/Config_Files.md` into `docs/source-documents/configuration-reference.md` and prepend:

```yaml
---
layout: default
title: Configuration Reference
parent: Source Documents
nav_order: 8
permalink: /source-documents/configuration-reference/
---
```

Replace only its opening relative README link with
`https://github.com/RENCI/GAHM2026/blob/main/README.md`; preserve tables and technical content.

- [ ] **Step 3: Publish the data-structure and workflow references**

Copy `documentation/Data_Structures.md` and `documentation/Workflow.md` into corresponding child pages with titles
`Data Structures` and `Project Workflow`, navigation orders 9 and 10, and permalinks
`/source-documents/data-structures/` and `/source-documents/workflow/`. Preserve their bodies verbatim after front
matter.

- [ ] **Step 4: Replace stale links throughout the site and README**

Make these exact link ownership changes:

- `README_config.md` references → `documentation/Config_Files.md` in `README.md`, and the local Configuration
  Reference page in Jekyll pages;
- `GAHM_struct.md` references → `documentation/Data_Structures.md` in `README.md`, and the local Data Structures page
  in Jekyll pages;
- removed `CALL_TREE.md` references → `documentation/Workflow.md` / local Project Workflow page, without claiming the
  workflow diagram is a call tree;
- the concise derivation's “complete derivation” link → the generated Derivation and Implementation child page;
  retain the PDF as an optional download;
- add Source Documents to the home page's guide list.

Use concrete `{{ '/source-documents/configuration-reference/' | relative_url }}`-style paths for Jekyll links.

- [ ] **Step 5: Prove no stale filenames remain**

```bash
if rg -n 'README_config\.md|GAHM_struct\.md|documentation/CALL_TREE\.md' README.md docs/*.md; then
    echo "stale documentation links remain" >&2
    exit 1
fi
```

Expected: no matches and exit status 0.

- [ ] **Step 6: Build and inspect navigation output**

Run from `docs/`:

```bash
bundle exec jekyll build --strict_front_matter
test -f _site/source-documents/index.html
test -f _site/source-documents/derivation-and-implementation/index.html
test -f _site/source-documents/configuration-reference/index.html
rg -n 'Source Documents|Derivation and Implementation|Configuration Reference' \
    _site/source-documents/index.html _site/index.html
```

Expected: the build succeeds and parent/child labels appear in generated navigation.

- [ ] **Step 7: Commit navigation and native references**

```bash
git add README.md docs/source-documents.md docs/source-documents/configuration-reference.md \
    docs/source-documents/data-structures.md docs/source-documents/workflow.md \
    docs/index.md docs/configuration.md docs/gahm-derivation.md docs/outputs.md
git diff --cached --check
git commit -m "Add source documentation navigation"
```

---

### Task 4: Document the updater and complete end-to-end verification

**Files:**
- Modify: `docs/LOCAL_DEVELOPMENT.md`
- Modify: `README.md`
- Modify if verification exposes delimiter issues: `docs/_includes/head_custom.html`

**Interfaces:**
- Consumes: `tools/update-docs` and the completed Jekyll source tree.
- Produces: human-operable update instructions and evidence that local and project-base-URL builds render links,
  equations, figures, and draft notices correctly.

- [ ] **Step 1: Document prerequisites and normal terminal workflows**

In `docs/LOCAL_DEVELOPMENT.md`, add a “Updating source documents” section that documents:

```bash
brew install pandoc

./tools/update-docs
./tools/update-docs --all
./tools/update-docs documentation/Derivation_and_Implementation.docx
./tools/update-docs --check
```

Explain checksum-based automatic detection, checked-in generated pages, the meaning of `--all`, explicit paths, and
the additional Ruby/Bundler requirement for `--check`. State that users should review and commit both DOCX and
generated Markdown/media changes together.

Add a concise Documentation section to `README.md` linking to `docs/LOCAL_DEVELOPMENT.md` and showing
`./tools/update-docs` as the normal refresh command.

- [ ] **Step 2: Test actual checksum detection without changing tracked DOCX content**

```bash
./tools/update-docs
cp docs/source-documents/wind-adjustment-factor.md /tmp/wind-adjustment-factor.md
python3 - <<'PY'
from pathlib import Path
page = Path("docs/source-documents/wind-adjustment-factor.md")
text = page.read_text(encoding="utf-8")
text = text.replace("source_sha256: \"", "source_sha256: \"0", 1)
page.write_text(text, encoding="utf-8")
PY
./tools/update-docs
cmp docs/source-documents/wind-adjustment-factor.md /tmp/wind-adjustment-factor.md
rm /tmp/wind-adjustment-factor.md
```

Expected: the first run reports current; corrupting one stored checksum causes only the WAF page to regenerate; the
regenerated page exactly matches its prior content.

- [ ] **Step 3: Run all unit and updater checks**

```bash
PYTHONPATH=tools python3 -m unittest tools/test_update_docs.py -v
./tools/update-docs --check
git diff --check
```

Expected: unit tests PASS, no pages require regeneration, Jekyll and html-proofer PASS, and no whitespace errors occur.

- [ ] **Step 4: Build with the future GitHub Pages base URL**

Run from `docs/`:

```bash
bundle exec jekyll build --strict_front_matter \
    --url https://renci.github.io --baseurl /GAHM2026
rg -n '/GAHM2026/assets/source-documents/.*/image[12]\.png' \
    _site/source-documents/derivation-and-implementation/index.html
```

Expected: build succeeds and both figure URLs include `/GAHM2026/`.

- [ ] **Step 5: Verify MathJax input and source fidelity in generated HTML**

```bash
rg -n '\\\[|\\tag\{1\}|V_\{g\}|R_\{mw\}' \
    docs/_site/source-documents/derivation-and-implementation/index.html
rg -n 'Draft source.*incomplete or provisional' \
    docs/_site/source-documents/wind-adjustment-factor/index.html
```

Expected: representative display math, equation numbering, GAHM symbols, and the draft notice appear. If Kramdown
emits delimiters not listed in `head_custom.html`, update only `inlineMath`/`displayMath` to include those emitted
delimiter pairs, rebuild, and repeat this check.

- [ ] **Step 6: Serve and visually inspect representative pages**

From `docs/`, run:

```bash
bundle exec jekyll serve --host 127.0.0.1
```

Inspect `/source-documents/`, `/source-documents/derivation-and-implementation/`,
`/source-documents/configuration-reference/`, and `/source-documents/wind-adjustment-factor/`. Confirm parent/child
navigation, searchable headings, rendered equations and equation numbers, two derivation figures, readable tables,
source links, and the WAF draft notice. Stop the server after inspection.

- [ ] **Step 7: Review final scope and commit operating documentation**

```bash
git status --short
git diff -- docs/LOCAL_DEVELOPMENT.md README.md docs/_includes/head_custom.html
git diff --check
git add docs/LOCAL_DEVELOPMENT.md README.md
if ! git diff --quiet -- docs/_includes/head_custom.html; then
    git add docs/_includes/head_custom.html
fi
git diff --cached --check
git commit -m "Document source page update workflow"
```

Confirm unrelated pre-existing files remain unstaged and generated `_site`/cache files remain ignored.

- [ ] **Step 8: Run final clean-state verification**

```bash
PYTHONPATH=tools python3 -m unittest tools/test_update_docs.py -v
./tools/update-docs --check
git diff --check
git status --short
```

Expected: tests and documentation checks PASS; tracked task files are clean; only pre-existing unrelated untracked
files remain.
