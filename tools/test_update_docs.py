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

    def test_unknown_explicit_source_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Unknown source document"):
            select_documents(
                [self.document], self.root, False, (Path("documentation/other.docx"),)
            )


if __name__ == "__main__":
    unittest.main()
