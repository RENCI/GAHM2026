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
