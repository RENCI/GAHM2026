import hashlib
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from update_docs import (
    SourceDocument,
    build_page,
    clean_markdown,
    publish_staged_documents,
    read_source_checksum,
    select_documents,
    sha256_file,
)


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

    def test_checksum_reader_ignores_checksum_in_page_body(self):
        checksum = "a" * 64
        self.output.write_text(
            f"---\ntitle: Example\n---\nsource_sha256: \"{checksum}\"\n",
            encoding="utf-8",
        )
        self.assertIsNone(read_source_checksum(self.output))

    def test_checksum_reader_rejects_malformed_front_matter(self):
        checksum = "a" * 64
        self.output.write_text(
            f"title: Example\nsource_sha256: \"{checksum}\"\n---\n",
            encoding="utf-8",
        )
        self.assertIsNone(read_source_checksum(self.output))

    def test_unknown_explicit_source_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Unknown source document"):
            select_documents(
                [self.document], self.root, False, (Path("documentation/other.docx"),)
            )

    def test_clean_markdown_promotes_source_title_and_section(self):
        source = "**Document Title**\n\n**1. Derivation** (source note)\n"
        expected = "# Document Title\n\n## 1. Derivation (source note)\n"
        self.assertEqual(clean_markdown(source), expected)

    def test_clean_markdown_preserves_equation_content_and_numbers(self):
        source = "$$x^{2} + y^{2} = z^{2}\\#(12)$$\n"
        expected = "$$x^{2} + y^{2} = z^{2}\\tag{12}$$\n"
        self.assertEqual(clean_markdown(source), expected)

    def test_clean_markdown_safely_displays_pandoc_multiline_inline_tex(self):
        source = (
            "Setting $V_{g}(r) = 1.5*V_{\\max}$ preserves TeX.\n\n"
            "$\\begin{array}{r}\n"
            "P(r) - P_{n} = e^{-A/r^{B_{g}}}\\#(17)\n"
            "\\end{array}$\n\n"
            "$\\begin{array}{r}\n"
            "\\frac{{dV}_{g}(r)}{dr} = 0\\#\n"
            "\\end{array}$\n"
        )
        expected = (
            'Setting <span class="math" markdown="0">\\(V_{g}(r) = 1.5*V_{\\max}\\)</span> preserves TeX.\n\n'
            "$$\\begin{array}{r}\n"
            "P(r) - P_{n} = e^{-A/r^{B_{g}}}\\tag{17}\n"
            "\\end{array}$$\n\n"
            "$$\\begin{array}{r}\n"
            "\\frac{{dV}_{g}(r)}{dr} = 0\n"
            "\\end{array}$$\n"
        )
        self.assertEqual(clean_markdown(source), expected)

    def test_clean_markdown_preserves_inline_tex_subscripts_and_multiplication(self):
        source = "Pressure $P_{c}$ and product $1.5*V_{\\max}$.\n"
        expected = (
            'Pressure <span class="math" markdown="0">\\(P_{c}\\)</span> and product '
            '<span class="math" markdown="0">\\(1.5*V_{\\max}\\)</span>.\n'
        )
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

    def test_build_page_records_source_identity_and_navigation(self):
        page = build_page(self.document, "a" * 64, "# Example\n")
        self.assertIn('source_sha256: "' + "a" * 64 + '"', page)
        self.assertIn("parent: Source Documents", page)
        self.assertIn("nav_order: 1", page)
        self.assertIn("permalink: /source-documents/example/", page)
        self.assertIn("documentation/example.docx", page)
        self.assertTrue(page.endswith("# Example\n"))

    def test_build_page_marks_draft_source(self):
        document = SourceDocument(
            source=self.document.source,
            output=self.document.output,
            slug=self.document.slug,
            title=self.document.title,
            nav_order=self.document.nav_order,
            is_draft=True,
        )
        page = build_page(document, "a" * 64, "# Example\n")
        self.assertIn(
            "> **Draft source:** This document contains incomplete or provisional material.",
            page,
        )

    def test_build_page_protects_tex_braces_without_disabling_media_liquid(self):
        body = (
            "$$\\frac{{dV}_{g}}{dr}$$\n\n"
            "![Figure]({{ '/assets/source-documents/example/media/image1.png' "
            "| relative_url }})\n"
        )
        page = build_page(self.document, "a" * 64, body)
        self.assertIn("{% raw %}\n$$\\frac{{dV}_{g}}{dr}$$", page)
        self.assertIn(
            "![Figure]({{ '/assets/source-documents/example/media/image1.png' "
            "| relative_url }})\n",
            page,
        )

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

    def test_publish_copies_pandoc_asset_layout_into_docs(self):
        staging = self.root / "staging"
        staged_page = staging / self.document.output
        staged_page.parent.mkdir(parents=True)
        staged_page.write_text("new page\n", encoding="utf-8")
        staged_asset = (
            staging
            / "assets/source-documents"
            / self.document.slug
            / "media/new.png"
        )
        staged_asset.parent.mkdir(parents=True)
        staged_asset.write_bytes(b"new image")

        publish_staged_documents([self.document], self.root, staging)

        destination = (
            self.root
            / "docs/assets/source-documents"
            / self.document.slug
            / "media/new.png"
        )
        self.assertEqual(destination.read_bytes(), b"new image")

    def test_publish_failure_restores_all_pages_and_media(self):
        second = SourceDocument(
            source=Path("documentation/second.docx"),
            output=Path("docs/source-documents/second.md"),
            slug="second",
            title="Second",
            nav_order=2,
            is_draft=False,
        )
        staging = self.root / "staging"
        for document in (self.document, second):
            staged_page = staging / document.output
            staged_page.parent.mkdir(parents=True, exist_ok=True)
            staged_page.write_bytes(f"new {document.slug}".encode())
            staged_asset = staging / "docs/assets/source-documents" / document.slug / "media/new.png"
            staged_asset.parent.mkdir(parents=True)
            staged_asset.write_bytes(f"new image {document.slug}".encode())

        self.output.write_bytes(b"old example page")
        old_asset = self.root / "docs/assets/source-documents/example/media/old.png"
        old_asset.parent.mkdir(parents=True)
        old_asset.write_bytes(b"old example image")

        from update_docs import replace_published_document
        calls = 0

        def fail_second(*args):
            nonlocal calls
            calls += 1
            if calls == 2:
                raise OSError("injected publication failure")
            return replace_published_document(*args)

        with patch("update_docs.replace_published_document", side_effect=fail_second):
            with self.assertRaisesRegex(OSError, "injected publication failure"):
                publish_staged_documents([self.document, second], self.root, staging)

        self.assertEqual(self.output.read_bytes(), b"old example page")
        self.assertEqual(old_asset.read_bytes(), b"old example image")
        self.assertFalse((self.root / second.output).exists())
        self.assertFalse((self.root / "docs/assets/source-documents/second").exists())


if __name__ == "__main__":
    unittest.main()
