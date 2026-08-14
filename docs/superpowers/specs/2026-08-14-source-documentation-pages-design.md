# Source Documentation Pages Design

## Goal

Expand the existing Jekyll site with faithful, searchable web versions of every source DOCX in `documentation/` while
retaining the site's current concise guides and Just the Docs layout. The checked-in Markdown must build locally and
remain suitable for later GitHub Pages deployment.

## Source policy

- Treat the DOCX files as authoritative source material even when they contain older GAHM2024 terminology, incomplete
  sections, or workflows that differ from the current code.
- Preserve source wording, ordering, equations, and figures. Do not reconcile the source text with the current MATLAB
  implementation during conversion.
- Normalize only web presentation: headings, lists, image paths, equation delimiters, and Jekyll front matter.
- Publish sparse and incomplete documents so their unfinished state remains visible. Add a brief presentation-level
  draft notice without rewriting their content.
- Keep generated Markdown under `docs/` so GitHub Pages does not need Pandoc or access to the DOCX files at build time.

## Site structure

Retain the existing primary pages:

- Home
- Getting Started
- GAHM Derivation
- Configuration
- Outputs
- SeparateEnvHur
- Plotting and Diagnostics

Add a grouped **Source Documents** section containing faithful conversions of all seven current DOCX files:

| Source | Published subject |
|--------|-------------------|
| `documentation/Getting_Started.docx` | Original getting-started document |
| `documentation/Derivation_and_Implementation.docx` | Full derivation and implementation document |
| `documentation/Blending.docx` | Gridded meteorology blending notes |
| `documentation/Use_cases.docx` | GAHM2024 use cases |
| `documentation/ASWIP_fort22.docx` | ASWIP fort.22 format |
| `documentation/fort22_v2.docx` | Extended fort.22 format |
| `documentation/Zo_WAF.docx` | Wind Adjustment Factor notes |

Also publish the native Markdown references for configuration, data structures, and project workflow within the same
reference-oriented navigation area. Existing site links that still use pre-cleanup filenames must point to the new
site pages or current repository paths.

## Command-line update workflow

The repository will provide a standalone `tools/update-docs` command that does not require an agent. Its normal mode
will detect changed source documents by content:

```bash
# Regenerate only pages whose source DOCX content changed
./tools/update-docs

# Force regeneration of every DOCX-derived page
./tools/update-docs --all

# Update changed pages, build Jekyll, and check links
./tools/update-docs --check

# Force regeneration of selected pages
./tools/update-docs documentation/Derivation_and_Implementation.docx
```

Each generated page will record the SHA-256 checksum of its source DOCX in Jekyll front matter. With no source
arguments, the command will compare the current checksums with those records and regenerate only changed or missing
pages. This remains reliable when a source is replaced outside Git, after the DOCX update has been committed, and
after switching branches. `--all` and explicit DOCX arguments will bypass checksum-based selection.

The command will report which pages were updated and return success without rewriting files when all pages are
current. It will document Pandoc as a conversion prerequisite; `--check` additionally requires the locked Ruby and
Bundler environment described in `docs/LOCAL_DEVELOPMENT.md`.

## Conversion design

For every selected source, `tools/update-docs` will run Pandoc independently and will:

1. verify that Pandoc and every expected source file are available;
2. convert Word paragraphs, tables, lists, links, and OMML equations to Markdown and TeX;
3. extract embedded media to a stable path under `docs/assets/`;
4. add deterministic Jekyll front matter, source checksum, permalinks, and navigation metadata;
5. perform narrowly scoped cleanup needed for Kramdown and MathJax rendering; and
6. write reviewable Markdown pages under `docs/`.

The script will use explicit source-to-page metadata rather than deriving user-facing titles and navigation order from
filenames. A conversion failure must stop the script with a clear error rather than leave a partially refreshed set of
pages. Re-running the script with unchanged DOCX inputs should produce no content changes.

## Equation and media handling

`Derivation_and_Implementation.docx` contains Word OMML equations. Pandoc will convert these to TeX math rather than
raster images. Display and inline delimiters will be compatible with the site's Kramdown and MathJax configuration,
and equation numbering present in the source will be retained. The existing pinned MathJax include remains the
browser renderer.

Embedded figures will be extracted from the DOCX rather than linked to `documentation/`. Published image references
will use Jekyll-aware paths so they work both at the local root and under the `/GAHM2026/` GitHub Pages base URL.

## Navigation and content presentation

- Use Just the Docs parent/child navigation for the source-document group.
- Keep primary task-oriented guides ahead of source documents in navigation.
- Identify each converted page as a faithful source-document rendering and link to its DOCX in the repository.
- Mark known sparse or incomplete documents as drafts without adding editorial corrections inside the converted body.
- Preserve the current visual layout and theme; no redesign or deployment workflow is part of this work.

## Verification

1. Re-run conversion and confirm a clean diff on the second run.
2. Modify one source copy during testing and confirm default change detection selects only its generated page; confirm
   explicit selection and `--all` override the checksum selection.
3. Confirm all seven DOCX files and all three native Markdown references have navigable pages.
4. Build with `bundle exec jekyll build --strict_front_matter`.
5. Run the existing HTML link checker against the generated site.
6. Check that no links retain removed documentation filenames such as `README_config.md`, `CALL_TREE.md`, or
   `GAHM_struct.md`.
7. Inspect the generated derivation HTML for MathJax input containing representative inline and display equations.
8. Visually inspect the local site navigation, the equation-heavy derivation, embedded figures, tables, and one sparse
   draft page.
9. Confirm generated Jekyll output, caches, and temporary conversion files are not committed.

## Out of scope

- Correcting or modernizing statements in the authoritative DOCX content.
- Completing sparse source documents.
- Replacing the existing concise guides with source conversions.
- Adding or enabling GitHub Pages deployment.
