#!/usr/bin/env python3
import argparse
import hashlib
import re
import shutil
import subprocess
import sys
import tempfile
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


DOCUMENTS = (
    SourceDocument(
        Path("documentation/Getting_Started.docx"),
        Path("docs/source-documents/getting-started-source.md"),
        "getting-started-source", "Getting Started (Source Document)", 1, False,
    ),
    SourceDocument(
        Path("documentation/Derivation_and_Implementation.docx"),
        Path("docs/source-documents/derivation-and-implementation.md"),
        "derivation-and-implementation", "Derivation and Implementation", 2, False,
    ),
    SourceDocument(
        Path("documentation/Blending.docx"),
        Path("docs/source-documents/blending.md"),
        "blending", "Gridded Meteorology Blending", 3, True,
    ),
    SourceDocument(
        Path("documentation/Use_cases.docx"),
        Path("docs/source-documents/use-cases.md"),
        "use-cases", "GAHM2024 Use Cases", 4, True,
    ),
    SourceDocument(
        Path("documentation/ASWIP_fort22.docx"),
        Path("docs/source-documents/aswip-fort22.md"),
        "aswip-fort22", "ASWIP fort.22 Format", 5, True,
    ),
    SourceDocument(
        Path("documentation/fort22_v2.docx"),
        Path("docs/source-documents/fort22-v2.md"),
        "fort22-v2", "Extended fort.22 Format", 6, False,
    ),
    SourceDocument(
        Path("documentation/Zo_WAF.docx"),
        Path("docs/source-documents/wind-adjustment-factor.md"),
        "wind-adjustment-factor", "Wind Adjustment Factor", 7, True,
    ),
)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source_file:
        for block in iter(lambda: source_file.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def read_source_checksum(path: Path) -> Optional[str]:
    if not path.exists():
        return None
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        return None
    try:
        closing_index = lines.index("---", 1)
    except ValueError:
        return None
    front_matter = "\n".join(lines[1:closing_index])
    match = re.search(
        r'^source_sha256:\s*["\']?([0-9a-f]{64})["\']?\s*$',
        front_matter,
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


def clean_markdown(markdown: str) -> str:
    markdown = re.sub(r"\A\*\*([^*\n]+)\*\*", r"# \1", markdown)
    markdown = re.sub(
        r"^\*\*((?:\d+\.\s+|Appendix\s+)[^*\n]+)\*\*(.*)$",
        lambda match: f"## {match.group(1).strip()}{match.group(2)}",
        markdown,
        flags=re.MULTILINE,
    )
    markdown = re.sub(
        r"^\*\*([^*\n]+)\*\*$", r"## \1", markdown, flags=re.MULTILINE
    )
    markdown = re.sub(
        r"^\$(\\begin\{array\}.*?\\end\{array\})\$$",
        r"$$\1$$",
        markdown,
        flags=re.MULTILINE | re.DOTALL,
    )

    def protect_inline_tex(match):
        return f'<span class="math" markdown="0">\\({match.group(1)}\\)</span>'

    markdown = re.sub(r"(?<!\$)\$(?!\$)([^\n$]+)\$(?!\$)", protect_inline_tex, markdown)
    markdown = re.sub(r"\\#\((\d+)\)", r"\\tag{\1}", markdown)
    markdown = re.sub(r"\\#(?=\n\\end\{array\}\$\$)", "", markdown)

    def replace_media(match):
        path = "/" + match.group("path")
        return f"![{match.group('alt')}]({{{{ '{path}' | relative_url }}}})"

    return re.sub(
        r"!\[(?P<alt>[^]]*)\]\((?P<path>assets/source-documents/[^)]+)\)",
        replace_media,
        markdown,
    )


def build_page(document: SourceDocument, checksum: str, body: str) -> str:
    front_matter = (
        "---\n"
        "layout: default\n"
        f"title: {document.title}\n"
        "parent: Source Documents\n"
        f"nav_order: {document.nav_order}\n"
        f"permalink: /source-documents/{document.slug}/\n"
        f"source_document: {document.source}\n"
        f'source_sha256: "{checksum}"\n'
        "---\n\n"
    )
    source_url = f"https://github.com/RENCI/GAHM2026/blob/main/{document.source}"
    note = f"> Converted from the [source DOCX]({source_url}).\n"
    if document.is_draft:
        note += "> **Draft source:** This document contains incomplete or provisional material.\n"
    protected_lines = []
    for line in body.splitlines(keepends=True):
        if "{{" in line and "| relative_url }}" not in line:
            protected_lines.extend(("{% raw %}\n", line, "{% endraw %}\n"))
        else:
            protected_lines.append(line)
    return front_matter + note + "\n" + "".join(protected_lines)


def stage_document(
    document: SourceDocument, repository_root: Path, staging_root: Path
) -> None:
    staged_markdown = staging_root / document.output
    staged_markdown.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "pandoc",
            str(repository_root / document.source),
            "--from=docx",
            "--to=markdown+tex_math_dollars",
            "--wrap=none",
            f"--extract-media=assets/source-documents/{document.slug}",
            "--output",
            str(staged_markdown),
        ],
        cwd=staging_root,
        check=True,
    )
    body = clean_markdown(staged_markdown.read_text(encoding="utf-8"))
    checksum = sha256_file(repository_root / document.source)
    staged_markdown.write_text(
        build_page(document, checksum, body), encoding="utf-8"
    )


def replace_published_document(
    document: SourceDocument, repository_root: Path, staging_root: Path
) -> None:
    destination_page = repository_root / document.output
    destination_page.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(staging_root / document.output, destination_page)

    asset_path = Path("docs/assets/source-documents") / document.slug
    staged_assets = staging_root / asset_path
    if not staged_assets.exists():
        staged_assets = staging_root / "assets/source-documents" / document.slug
    destination_assets = repository_root / asset_path
    if destination_assets.exists():
        shutil.rmtree(destination_assets)
    if staged_assets.exists():
        shutil.copytree(staged_assets, destination_assets)


def publish_staged_documents(
    documents: Sequence[SourceDocument], repository_root: Path, staging_root: Path
) -> None:
    with tempfile.TemporaryDirectory() as backup_directory:
        backup_root = Path(backup_directory)
        for document in documents:
            page = repository_root / document.output
            if page.exists():
                backup_page = backup_root / document.output
                backup_page.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(page, backup_page)
            asset_path = Path("docs/assets/source-documents") / document.slug
            assets = repository_root / asset_path
            if assets.exists():
                shutil.copytree(assets, backup_root / asset_path)

        try:
            for document in documents:
                replace_published_document(document, repository_root, staging_root)
        except OSError:
            for document in documents:
                page = repository_root / document.output
                backup_page = backup_root / document.output
                if page.exists():
                    page.unlink()
                if backup_page.exists():
                    page.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(backup_page, page)

                asset_path = Path("docs/assets/source-documents") / document.slug
                assets = repository_root / asset_path
                backup_assets = backup_root / asset_path
                if assets.exists():
                    shutil.rmtree(assets)
                if backup_assets.exists():
                    shutil.copytree(backup_assets, assets)
            raise


def validate_sources(repository_root: Path) -> None:
    missing = [str(document.source) for document in DOCUMENTS if not (repository_root / document.source).is_file()]
    if missing:
        raise ValueError("Missing source document: " + ", ".join(missing))


def parse_arguments(argv=None):
    parser = argparse.ArgumentParser(description="Convert source DOCX files to documentation pages.")
    parser.add_argument("sources", nargs="*", type=Path, metavar="DOCX")
    parser.add_argument("--all", action="store_true", dest="force_all")
    parser.add_argument("--check", action="store_true")
    arguments = parser.parse_args(argv)
    if arguments.force_all and arguments.sources:
        parser.error("--all cannot be combined with explicit DOCX paths")
    return arguments


def run(argv=None) -> int:
    arguments = parse_arguments(argv)
    repository_root = Path(__file__).resolve().parent.parent
    validate_sources(repository_root)
    selected = select_documents(
        DOCUMENTS, repository_root, arguments.force_all, arguments.sources
    )
    if selected:
        if shutil.which("pandoc") is None:
            raise ValueError("pandoc is required to convert source documents")
        with tempfile.TemporaryDirectory() as temporary_directory:
            staging_root = Path(temporary_directory)
            for document in selected:
                stage_document(document, repository_root, staging_root)
            publish_staged_documents(selected, repository_root, staging_root)
        for document in selected:
            print(f"Updated {document.output}")
    else:
        print("Documentation is already current.")

    if arguments.check:
        docs_root = repository_root / "docs"
        subprocess.run(
            ["bundle", "exec", "jekyll", "build", "--strict_front_matter"],
            cwd=docs_root,
            check=True,
        )
        subprocess.run(
            ["bundle", "exec", "htmlproofer", "./_site", "--disable-external"],
            cwd=docs_root,
            check=True,
        )
    return 0


def main(argv=None) -> int:
    try:
        return run(argv)
    except (ValueError, FileNotFoundError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
