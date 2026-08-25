# Archived documentation

These files are retained for reference only. They are **not** published to the documentation site
and should not be treated as current.

| File | Superseded by | Why |
|---|---|---|
| `Documentation_GAHM2026_derivation.docx` | `../GAHM2026_derivation_implementation.docx` | Titled "GAHM2024 derivation"; contains the derivation only, through Eq (17). The current document adds Implementation, default conditions/flags, blending, WAF, references, and Appendix A. |
| `Documentation_GAHM2026_derivation.md` | site page generated from the docx | Hand-converted copy of the file above. Markdown is now generated at build time by `tools/docs/build_docs.py`; do not hand-edit markdown derived from a docx. |
| `Documentation_blending.docx` | `../GAHM2026_derivation_implementation.docx` §4 | GAHM2024-era (1/25/2026); describes `blend_GAHM2024a.m`, which no longer exists. |
| `Documentation_Zo_WAF.docx` | `../GAHM2026_derivation_implementation.docx` §5 | GAHM2024-era (1/25/2026). |
| `Documentation_GAHM2026_use_cases.docx` | `docs/examples.md` | Titled "GAHM2024 Use Cases"; describes `run_build_GAHM2024_param_file.m`, which no longer exists. |
| `Documentation_ASWIP_fort22.docx` | `../ASWIP_fort22_doc.docx` | Dated 5/29/2025; the current version (8/3/2026) rewrites the col-4 base-time description. |
| `Documentation_GAHM2026_fort22_v2.docx` | `../GAHM2026_fort22_v2.docx` | The current version (8/4/2026) adds the GAHM2026 diagnostic-flag note. |

To publish a document, put the `.docx` in `documentation/` and add an entry to
`docs/_data/docx_pages.yml`.
