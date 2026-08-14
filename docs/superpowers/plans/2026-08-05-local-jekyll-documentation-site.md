# Local Jekyll Documentation Site Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the stale single-page documentation with a polished seven-page Just the Docs Jekyll site that runs
locally, renders the August 4, 2026 GAHM derivation equations, and is ready for a later GitHub Pages deployment at
`https://renci.github.io/GAHM2026/` without adding deployment infrastructure now.

**Architecture:** Keep all publishable site source and local Ruby tooling under `docs/`. Use one shared Jekyll
configuration whose local `url` and `baseurl` are empty, and make every internal URL pass through Jekyll's
`relative_url` filter so a later build can override the site location with `/GAHM2026`. Treat current MATLAB source,
the active repository READMEs, and the untracked August 4 derivation DOCX/PDF as source material; summarize those
sources rather than moving the full reference documentation into the website.

**Tech Stack:** Homebrew Ruby 3.4, Bundler, Jekyll 4.4.1, Kramdown 2.5.2, Just the Docs 0.12.0, MathJax 3.2.2,
html-proofer 5.2.2, Markdown, Liquid, HTML, Git.

## Global Constraints

- Work on `jekyllDocsSite`; preserve all unrelated tracked and untracked workspace content.
- Do not modify, stage, or commit `documentation/GAHM2026_derivation_implementation.docx` or
  `documentation/GAHM2026_derivation_implementation.pdf`. Copy the PDF to `docs/assets/` and verify the copy.
- Do not use the older `documentation/Documentation_GAHM2026_derivation.md` as the authoritative derivation.
- Do not add a GitHub Actions workflow, change GitHub Pages settings, or deploy the site.
- Do not modify MATLAB behavior. A MATLAB regression run is unnecessary for documentation-only changes.
- Use current camelCase APIs and the current default artifacts: `output/FLORENCE_AL06_2018.mat` containing
  `env_vals`, and `output/FLORENCE_2018.nc`.
- Use current `config/config_GAHM2026_default.m` values when a concise site example conflicts with stale prose in an
  existing README.
- Use `{{ '/path/' | relative_url }}` for site pages/assets and full GitHub URLs for source files outside `docs/`.
- Keep generated HTML, caches, local Bundler configuration, and project-local gems out of Git.

---

### Task 1: Establish reproducible local Ruby and Jekyll tooling

**Files:**
- Modify: `.gitignore`
- Create: `docs/.ruby-version`
- Create: `docs/Gemfile`
- Create (generated): `docs/Gemfile.lock`

**Interfaces:**
- Consumes: Homebrew `ruby@3.4` and RubyGems.
- Produces: a project-local, locked Jekyll toolchain that works on Apple Silicon and includes a Linux lock platform for
  a later GitHub Actions build.

- [ ] **Step 1: Record the branch and workspace baseline**

Run:

```bash
git branch --show-current
git status --short
git diff --check
test -f documentation/GAHM2026_derivation_implementation.docx
test -f documentation/GAHM2026_derivation_implementation.pdf
```

Expected: the branch is `jekyllDocsSite`; only the already-known unrelated files are untracked; the derivation source
files exist; and `git diff --check` prints nothing.

- [ ] **Step 2: Confirm the existing system Ruby cannot supply the site toolchain**

Run:

```bash
/usr/bin/ruby --version
/usr/bin/gem --version
command -v jekyll || true
```

Expected: macOS Ruby is 2.6.x and no usable Jekyll executable is present. Do not install gems into this Ruby.

- [ ] **Step 3: Install and select the versioned Homebrew Ruby**

Run:

```bash
brew install ruby@3.4
export PATH="$(brew --prefix ruby@3.4)/bin:$PATH"
ruby --version
gem --version
bundle --version
```

Expected: `ruby` reports 3.4.x from Homebrew and Bundler is available. Do not edit the user's shell startup files;
repeat the `PATH` export in later shells and document it for local developers.

- [ ] **Step 4: Add precise ignore rules for generated site artifacts**

Append repository-root rules scoped to this site:

```gitignore
/docs/_site/
/docs/.jekyll-cache/
/docs/.sass-cache/
/docs/.bundle/
/docs/vendor/bundle/
```

Do not add broad rules that hide source files elsewhere in the repository.

- [ ] **Step 5: Declare the Ruby and gem versions**

Create `docs/.ruby-version` containing:

```text
3.4
```

Create `docs/Gemfile` with Ruby `~> 3.4.0` and exact versions:

```ruby
source "https://rubygems.org"

ruby "~> 3.4.0"

gem "jekyll", "4.4.1"
gem "kramdown", "2.5.2"
gem "just-the-docs", "0.12.0"
gem "webrick", "1.9.2"

group :test do
    gem "html-proofer", "5.2.2"
end
```

- [ ] **Step 6: Install locally and generate the lockfile**

Run from `docs/` with the Homebrew Ruby selected:

```bash
bundle config set --local path vendor/bundle
bundle install
bundle lock --add-platform x86_64-linux
bundle exec jekyll --version
bundle info kramdown
bundle info html-proofer
```

Expected: dependencies install under ignored `docs/vendor/bundle/`; `Gemfile.lock` is created and lists the local
Darwin platform plus `x86_64-linux`; Jekyll reports 4.4.1, Kramdown reports 2.5.2, and html-proofer reports 5.2.2.

- [ ] **Step 7: Verify and commit only the tooling foundation**

Run:

```bash
git status --short
git check-ignore docs/_site docs/.jekyll-cache docs/.sass-cache docs/.bundle docs/vendor/bundle
git diff --check
git add .gitignore docs/.ruby-version docs/Gemfile docs/Gemfile.lock
git diff --cached --check
git diff --cached --name-only
git commit -m "Add local Jekyll toolchain"
```

Expected: the staged list contains exactly the four declared files; Bundler artifacts remain ignored; unrelated files
remain unstaged.

---

### Task 2: Build the Just the Docs foundation and replacement home page

**Files:**
- Modify: `docs/_config.yml`
- Rewrite: `docs/index.md`

**Interfaces:**
- Consumes: the gem-based Just the Docs theme and current project overview in `README.md`.
- Produces: a searchable site shell and a concise landing page at `/`.

- [ ] **Step 1: Capture the expected pre-change build failure**

Run from `docs/`:

```bash
export PATH="$(brew --prefix ruby@3.4)/bin:$PATH"
bundle exec jekyll build --strict_front_matter
```

Expected: the old `remote_theme` configuration cannot produce the intended locked Just the Docs site, or the build
still identifies the Minimal remote theme. Record the result before replacing the configuration.

- [ ] **Step 2: Replace `_config.yml` with local-first shared configuration**

Configure:

- `title: GAHM2026` and the existing project description;
- `url: ""` and `baseurl: ""` for local serving;
- `repository: RENCI/GAHM2026`;
- `theme: just-the-docs` with no `remote_theme` and no `jekyll-remote-theme` plugin;
- enabled search, heading anchors, and an auxiliary link to `https://github.com/RENCI/GAHM2026` that opens in a new
  tab;
- `markdown: kramdown` and `kramdown.math_engine: mathjax`;
- exclusions for `Gemfile`, `Gemfile.lock`, `LOCAL_DEVELOPMENT.md`, `vendor`, `.bundle`, and `superpowers`.

Do not set `/GAHM2026` in the checked-in config; later validation will pass it on the command line.

- [ ] **Step 3: Rewrite `index.md` as the Home page**

Use front matter:

```yaml
---
layout: default
title: Home
nav_order: 1
permalink: /
---
```

Replace the stale monolithic page with:

- a short GAHM2026 purpose statement and authorship;
- capability bullets for asymmetric parametric fields, three environment modes, gridded/point outputs, WAF, and
  diagnostics;
- a compact pipeline overview from track/config input through GAHM, optional SeparateEnvHur blending, and outputs;
- a default Florence quick-start snippet using only `R = run_GAHM2026;`;
- clear next-step links to all six other site guides using `relative_url`;
- full GitHub links to the top-level README and detailed repository references.

Remove stale names such as `apply_WAF` and `config_Florence` rather than copying the old site verbatim.

- [ ] **Step 4: Build and inspect the foundation**

Run from `docs/`:

```bash
bundle exec jekyll build --strict_front_matter --trace
test -f _site/index.html
test -f _site/assets/js/just-the-docs.js
rg -n 'GAHM2026|Search GAHM2026|run_GAHM2026' _site/index.html
```

Expected: the site builds with Just the Docs assets and the home page contains the current default call. Defer the
full internal-link check until all linked pages exist.

- [ ] **Step 5: Commit the site foundation**

Run:

```bash
git diff --check
git add docs/_config.yml docs/index.md
git diff --cached --check
git diff --cached --name-only
git commit -m "Build Just the Docs site foundation"
```

Expected: exactly `_config.yml` and `index.md` are committed; `_site/` remains ignored.

---

### Task 3: Add the Getting Started, Configuration, and Outputs guides

**Files:**
- Create: `docs/getting-started.md`
- Create: `docs/configuration.md`
- Create: `docs/outputs.md`

**Interfaces:**
- Consumes: `README.md`, `config/config_GAHM2026_default.m`, `documentation/README_config.md`, and
  `run_GAHM2026.m`.
- Produces: concise primary-workflow documentation with links to the detailed repository reference.

- [ ] **Step 1: Add a copy-pasteable Getting Started page**

Use `nav_order: 2` and `permalink: /getting-started/`. Cover:

- MATLAB and Signal Processing Toolbox requirements, Git checkout, and the expected project-root working directory;
- the one-command default Florence run: `R = run_GAHM2026;`;
- automatic IBTrACS download and automatic SeparateEnvHur generation when the type-3 MAT-file is absent;
- the existing-output guard: rename or remove `output/FLORENCE_2018.nc` before rerunning;
- expected default outputs `output/FLORENCE_AL06_2018.mat` and `output/FLORENCE_2018.nc`;
- a minimal plotter example using `GAHM2026Plotter(R)` and `contourMap`;
- base-URL-safe links to Configuration, Outputs, SeparateEnvHur, and Plotting and Diagnostics.

Do not imply that the ignored generated output files are distributed in Git.

- [ ] **Step 2: Add a concise Configuration guide**

Use `nav_order: 4` and `permalink: /configuration/`. Document:

- the shared storm identity and the seven main structs/groups;
- `env_info.type` values 1, 2, and 3 and which type-3 fields are used;
- grid versus point output and WAF behavior at a summary level;
- how to copy `config/config_GAHM2026_default.m` to `config/config_<StormName>.m` and call
  `run_GAHM2026("config_<StormName>")`;
- a full GitHub link to `documentation/README_config.md` for every parameter and output field.

Use the current default config as source of truth for examples, including the actual default time window and output
names; do not reproduce the full parameter tables.

- [ ] **Step 3: Add a concise Outputs guide**

Use `nav_order: 5` and `permalink: /outputs/`. Document:

- the primary `Result` fields for gridded output;
- type-3-only masks/intermediates and the numeric-zero behavior for environment types 1/2 where relevant;
- point-output structures and their coordinate/time contract;
- the default NetCDF path and its combined wind/pressure content;
- the SeparateEnvHur MAT path, top-level `env_vals` variable, key fields, and accepted outer-mask compatibility name;
- links to the Configuration and Plotting pages plus full GitHub links to the detailed reference.

- [ ] **Step 4: Verify routes, navigation metadata, examples, and stale-name absence**

Run from `docs/`:

```bash
bundle exec jekyll build --strict_front_matter
for page in getting-started configuration outputs; do test -f "_site/$page/index.html"; done
rg -n 'FLORENCE_AL06_2018\.mat|FLORENCE_2018\.nc|config_GAHM2026_default|env_info\.type' \
  getting-started.md configuration.md outputs.md
if rg -n "separated\.mat|config_Florence|apply_WAF|run_GAHM2026\(['\"]config_Florence" \
  getting-started.md configuration.md outputs.md; then
    exit 1
fi
```

Expected: all three pretty routes exist, current examples are present, and stale API/config names are absent. Defer
the full internal-link check until all linked pages exist.

- [ ] **Step 5: Commit the core user guides**

Run:

```bash
git diff --check
git add docs/getting-started.md docs/configuration.md docs/outputs.md
git diff --cached --check
git diff --cached --name-only
git commit -m "Add core GAHM2026 user guides"
```

Expected: exactly the three new guide files are committed.

---

### Task 4: Add SeparateEnvHur and plotting workflow guides

**Files:**
- Create: `docs/separate-env-hur.md`
- Create: `docs/plotting.md`

**Interfaces:**
- Consumes: `SeparateEnvHur/README.md`, `PlotEvalScripts/README.md`,
  `PlotEvalScripts/@GAHM2026Plotter/README.md`, and the current plotter class.
- Produces: short operational guides at `/separate-env-hur/` and `/plotting/`.

- [ ] **Step 1: Add the SeparateEnvHur guide**

Use `nav_order: 6` and `permalink: /separate-env-hur/`. Include:

- what the ERA5 vortex separation does and when GAHM invokes it automatically;
- required ERA5 `msl`, `u10`, `v10`, time, longitude, and latitude data plus Signal Processing Toolbox;
- a standalone example using
  `env_vals = SeparateEnvHur("config/config_GAHM2026_default");` after adding `SeparateEnvHur` to the path;
- concise explanations of the filter/output domains, pressure-center search, outer/inner cutlines, independent filter
  isotach, Butterworth filtering, masks, and residual hurricane fields;
- the default `output/FLORENCE_AL06_2018.mat` path and top-level `env_vals` contract;
- links to Configuration, Outputs, Plotting, and the full repository `SeparateEnvHur/README.md`.

- [ ] **Step 2: Add the Plotting and Diagnostics guide**

Use `nav_order: 7` and `permalink: /plotting/`. Include tested default examples for:

- adding `PlotEvalScripts` and constructing `GAHM2026Plotter(R)`;
- a wind contour, pressure contour, radial profile, time-series plot, difference map, metrics, and animation;
- loading SeparateEnvHur output with
  `GAHM2026Plotter.fromSepEnvHur("output/FLORENCE_AL06_2018.mat")`;
- the distinction among `PlotData`, `EnvData`, and `HurData` for SeparateEnvHur input;
- links to the detailed plotting READMEs for the complete method/options reference.

Use the current method signatures and camelCase names; avoid duplicating the long reference tables.

- [ ] **Step 3: Build and audit workflow examples**

Run from `docs/`:

```bash
bundle exec jekyll build --strict_front_matter
test -f _site/separate-env-hur/index.html
test -f _site/plotting/index.html
rg -n 'SeparateEnvHur\("config/config_GAHM2026_default"\)|FLORENCE_AL06_2018\.mat|fromSepEnvHur' \
  separate-env-hur.md plotting.md
if rg -n 'separated\.mat|config_Florence|apply_WAF' separate-env-hur.md plotting.md; then
    exit 1
fi
```

Expected: both routes build, concrete default examples are present, and placeholders/stale names are absent. Defer
the full internal-link check until the derivation page exists.

- [ ] **Step 4: Commit the workflow guides**

Run:

```bash
git diff --check
git add docs/separate-env-hur.md docs/plotting.md
git diff --cached --check
git diff --cached --name-only
git commit -m "Document environmental and plotting workflows"
```

Expected: exactly the two workflow pages are committed.

---

### Task 5: Publish the concise GAHM derivation with rendered equations

**Files:**
- Create: `docs/gahm-derivation.md`
- Create: `docs/_includes/head_custom.html`
- Create (copied): `docs/assets/GAHM2026_derivation_implementation.pdf`

**Interfaces:**
- Consumes: untracked August 4, 2026 source files in `documentation/`.
- Produces: a concise web derivation at `/gahm-derivation/`, browser-rendered MathJax equations, and a downloadable
  byte-for-byte copy of the complete PDF.

- [ ] **Step 1: Record source hashes before copying**

Run:

```bash
shasum -a 256 documentation/GAHM2026_derivation_implementation.docx \
  documentation/GAHM2026_derivation_implementation.pdf
git ls-files documentation/GAHM2026_derivation_implementation.docx \
  documentation/GAHM2026_derivation_implementation.pdf
```

Expected: both files hash successfully and `git ls-files` prints nothing, confirming the authoritative sources remain
untracked.

- [ ] **Step 2: Add pinned MathJax through the theme's custom head hook**

Create `docs/_includes/head_custom.html` so it:

- assigns `window.MathJax` before loading the library;
- enables `\(...\)` inline and `\[...\]` display TeX delimiters and escaped TeX;
- skips `script`, `noscript`, `style`, `textarea`, `pre`, and `code` elements;
- loads exactly `https://cdn.jsdelivr.net/npm/mathjax@3.2.2/es5/tex-mml-chtml.js` with `defer`.

Do not use an unversioned `latest` URL.

- [ ] **Step 3: Copy the complete derivation PDF into the site**

Run:

```bash
mkdir -p docs/assets
cp documentation/GAHM2026_derivation_implementation.pdf \
  docs/assets/GAHM2026_derivation_implementation.pdf
cmp documentation/GAHM2026_derivation_implementation.pdf \
  docs/assets/GAHM2026_derivation_implementation.pdf
```

Expected: `cmp` succeeds; the original source remains untouched.

- [ ] **Step 4: Write the concise derivation page from the August 4 source**

Use `nav_order: 3` and `permalink: /gahm-derivation/`. Define all symbols before use and preserve the source's
notation. Present, in order:

1. Holland pressure profile
   `P(r) = P_c + (P_n-P_c) exp(-A/r^{B_g})` with `A = phi R_mw^{B_g}`;
2. gradient-wind balance including Coriolis;
3. Rossby number `R_o = V_max/(R_mw f)` and the maximum-wind constraint at `R_mw`;
4. the generalized shape relation `phi = 1 + 1/[B_g(1+R_o)]`;
5. the implicit `B_g` equation and the recursive solution concept for `B_g` and `R_mw` using an observed isotach;
6. the final radial gradient-wind profile;
7. the pressure-deficit profile `P(r)-P_n`;
8. the Holland limit `B_g -> e V_max^2 / [(P_n-P_c)/rho_air]` as `R_o -> infinity`.

Author display equations with Kramdown `$$...$$` math blocks; Kramdown 2.5.2 converts them to `\[...\]` in the built
HTML for MathJax 3. Use concise explanatory prose and explicitly attribute Rick Luettich's August 4, 2026 revision,
adapted from Gao (2018). Link the complete PDF with:

```liquid
{{ '/assets/GAHM2026_derivation_implementation.pdf' | relative_url }}
```

Direct readers to it for the detailed implementation, default assumptions, blending discussion, restrictions,
figures, and appendices.

- [ ] **Step 5: Verify source fidelity, publication, and MathJax wiring**

Run from the repository root:

```bash
cmp documentation/GAHM2026_derivation_implementation.pdf \
  docs/assets/GAHM2026_derivation_implementation.pdf
shasum -a 256 documentation/GAHM2026_derivation_implementation.docx \
  documentation/GAHM2026_derivation_implementation.pdf
```

Expected: the PDF copy is identical and both hashes exactly match those recorded before copying.

Run from `docs/`:

```bash
bundle exec jekyll build --strict_front_matter
test -f _site/gahm-derivation/index.html
cmp assets/GAHM2026_derivation_implementation.pdf \
  _site/assets/GAHM2026_derivation_implementation.pdf
rg -n 'mathjax@3\.2\.2/es5/tex-mml-chtml\.js' _site/gahm-derivation/index.html
rg -F '\[' _site/gahm-derivation/index.html
if rg -F '$$' _site/gahm-derivation/index.html; then exit 1; fi
rg -n 'P_n|R_o|B_g|R_\{mw\}|rho|phi' gahm-derivation.md
bundle exec htmlproofer ./_site --disable-external
```

Expected: the route and PDF publish, every derivation page loads pinned MathJax, required notation is present, and
Kramdown converted the math blocks to MathJax delimiters rather than leaking raw `$$`; the PDF/internal links pass.

- [ ] **Step 6: Commit only the derivation deliverables**

Run:

```bash
git add docs/gahm-derivation.md docs/_includes/head_custom.html \
  docs/assets/GAHM2026_derivation_implementation.pdf
git diff --cached --check
git diff --cached --name-only
git commit -m "Add rendered GAHM derivation"
```

Expected: exactly the page, custom head include, and copied PDF are committed; the `documentation/` source files are
not staged.

---

### Task 6: Document local operation and validate the complete local site

**Files:**
- Create: `docs/LOCAL_DEVELOPMENT.md`

**Interfaces:**
- Consumes: the locked site toolchain and complete seven-page source tree.
- Produces: repeatable local build/serve instructions and HTTP-verified local routes.

- [ ] **Step 1: Write local development instructions**

Document:

```bash
brew install ruby@3.4
export PATH="$(brew --prefix ruby@3.4)/bin:$PATH"
cd docs
bundle config set --local path vendor/bundle
bundle install
bundle exec jekyll build --strict_front_matter
bundle exec jekyll serve --livereload --host 127.0.0.1
```

Explain that the site is then available at `http://127.0.0.1:4000/`, the checked-in lockfile should be retained, and
generated/cache/vendor directories are ignored. State clearly that this phase does not publish or enable GitHub
Pages. Keep this file out of the built site through `_config.yml`.

- [ ] **Step 2: Perform a clean strict build and static-link check**

Run from `docs/`:

```bash
rm -rf _site
bundle exec jekyll build --strict_front_matter --trace
bundle exec htmlproofer ./_site --disable-external
find _site -maxdepth 2 -type f | sort
```

Expected: the build and HTML check pass; all seven page routes are present; the PDF and Just the Docs assets are
published; `LOCAL_DEVELOPMENT.md`, `superpowers/`, Gemfiles, and Bundler artifacts are absent from `_site`.

- [ ] **Step 3: Start the local server and verify every public route**

Start from `docs/`:

```bash
bundle exec jekyll serve --host 127.0.0.1 --port 4000 --strict_front_matter
```

While the server runs, execute in a second shell:

```bash
for route in \
  / \
  /getting-started/ \
  /gahm-derivation/ \
  /configuration/ \
  /outputs/ \
  /separate-env-hur/ \
  /plotting/ \
  /assets/GAHM2026_derivation_implementation.pdf; do
    curl --fail --silent --show-error --output /dev/null "http://127.0.0.1:4000$route"
done
```

Expected: all eight requests return HTTP 200. Stop only the Jekyll process started for this check.

- [ ] **Step 4: Audit navigation, search, examples, and equation hooks**

Run from `docs/`:

```bash
for title in 'Home' 'Getting Started' 'GAHM Derivation' 'Configuration' 'Outputs' 'SeparateEnvHur' \
  'Plotting and Diagnostics'; do
    rg -q "title: $title" ./*.md
done
rg -n 'search_enabled: true|theme: just-the-docs|baseurl: ""|url: ""' _config.yml
rg -n 'mathjax@3\.2\.2|FLORENCE_AL06_2018\.mat|FLORENCE_2018\.nc|config_GAHM2026_default' \
  _includes/head_custom.html ./*.md
if rg -n 'remote_theme|jekyll-remote-theme|separated\.mat|config_Florence|apply_WAF' \
  _config.yml ./*.md; then
    exit 1
fi
```

Expected: all seven navigation titles, locked theme settings, current examples, and pinned MathJax are present; stale
theme/API/placeholders are absent.

- [ ] **Step 5: Commit the local development guide**

Run:

```bash
git diff --check
git add docs/LOCAL_DEVELOPMENT.md
git diff --cached --check
git diff --cached --name-only
git commit -m "Document local site development"
```

Expected: only `LOCAL_DEVELOPMENT.md` is committed.

---

### Task 7: Verify future `/GAHM2026/` hosting compatibility and final scope

**Files:**
- Verify only; modify the smallest relevant site file only if a check exposes a real issue.

**Interfaces:**
- Consumes: the completed local site.
- Produces: evidence that the same sources can later be built for `https://renci.github.io/GAHM2026/` without a
  deployment change in this branch.

- [ ] **Step 1: Build with the future production URL and base URL**

Run from `docs/`:

```bash
production_root="$(mktemp -d)"
production_site="$production_root/site"
production_config="$production_root/production.yml"
cat > "$production_config" <<'YAML'
url: "https://renci.github.io"
baseurl: "/GAHM2026"
YAML
bundle exec jekyll build --strict_front_matter --trace \
  --config "_config.yml,$production_config" \
  --destination "$production_site"
test -f "$production_site/index.html"
test -f "$production_site/gahm-derivation/index.html"
test -f "$production_site/assets/GAHM2026_derivation_implementation.pdf"
rg -n 'href="/GAHM2026/|src="/GAHM2026/' "$production_site/index.html" \
  "$production_site/gahm-derivation/index.html"
rm -rf "$production_root"
```

Expected: the alternate build passes, expected files exist, and internal site assets/links carry the `/GAHM2026/`
prefix. The temporary destination is removed.

- [ ] **Step 2: Serve with the future base URL and smoke-test prefixed routes**

Start from `docs/`:

```bash
bundle exec jekyll serve --host 127.0.0.1 --port 4001 --strict_front_matter \
  --baseurl /GAHM2026
```

While it runs, execute:

```bash
for route in \
  /GAHM2026/ \
  /GAHM2026/getting-started/ \
  /GAHM2026/gahm-derivation/ \
  /GAHM2026/configuration/ \
  /GAHM2026/outputs/ \
  /GAHM2026/separate-env-hur/ \
  /GAHM2026/plotting/ \
  /GAHM2026/assets/GAHM2026_derivation_implementation.pdf; do
    curl --fail --silent --show-error --output /dev/null "http://127.0.0.1:4001$route"
done
```

Expected: every prefixed route returns HTTP 200. Stop only the Jekyll process started for this check.

- [ ] **Step 3: Run final Git and publication-scope audits**

Run from the repository root:

```bash
git status --short
git diff --check
git log --oneline --decorate main..HEAD
git diff --name-only main...HEAD -- .github/workflows
git ls-files docs/_site docs/.jekyll-cache docs/.sass-cache docs/.bundle docs/vendor/bundle
git ls-files documentation/GAHM2026_derivation_implementation.docx \
  documentation/GAHM2026_derivation_implementation.pdf
cmp documentation/GAHM2026_derivation_implementation.pdf \
  docs/assets/GAHM2026_derivation_implementation.pdf
```

Expected: only known unrelated files remain untracked; no generated site/tooling artifacts are tracked; no workflow
changed; the authoritative derivation sources remain untracked; and the published PDF copy still matches its source.

- [ ] **Step 4: Correct and commit only issues found by final validation**

If any validation fails, fix the smallest relevant site file, rerun Tasks 6 and 7 checks, and make one focused commit
describing that correction. If all checks pass, do not create an empty cleanup commit and do not push or enable Pages
without an explicit user request.
