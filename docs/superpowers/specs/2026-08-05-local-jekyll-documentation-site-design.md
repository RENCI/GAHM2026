# Local Jekyll Documentation Site Design

## Goal

Build a polished, searchable, multi-page GAHM2026 documentation site that runs locally with native Ruby and can later
be deployed unchanged to `https://renci.github.io/GAHM2026/` through GitHub Actions.

## Decisions

- Use Jekyll with the Just the Docs theme.
- Keep all site source under `docs/`.
- Use native Homebrew Ruby and Bundler rather than the outdated macOS system Ruby.
- Build six user-facing pages: Home, Getting Started, Configuration, Outputs, SeparateEnvHur, and Plotting and
  Diagnostics.
- Use a hybrid content model: concise, self-contained guidance for common workflows plus links to detailed repository
  references where duplicating them would create maintenance risk.
- Build and test locally only in this phase. Do not add a deployment workflow or enable GitHub Pages.

## Site structure

| File | Responsibility |
|------|----------------|
| `docs/index.md` | Project overview, capabilities, architecture summary, and next steps |
| `docs/getting-started.md` | Prerequisites and a copy-pasteable default Florence workflow |
| `docs/configuration.md` | Configuration model, environment modes, and links to the complete parameter reference |
| `docs/outputs.md` | Result structures, default MAT/NetCDF paths, and output-mode behavior |
| `docs/separate-env-hur.md` | ERA5 separation workflow, physical settings, masks, and saved `env_vals` contract |
| `docs/plotting.md` | `GAHM2026Plotter` setup and examples for model and SeparateEnvHur output |
| `docs/LOCAL_DEVELOPMENT.md` | Native Ruby installation, dependency setup, build, and local serve instructions |
| `docs/_config.yml` | Shared Just the Docs theme, navigation, search, and repository metadata |
| `docs/Gemfile` / `docs/Gemfile.lock` | Reproducible local Jekyll and theme dependencies |

## Content rules

- Examples must reflect current `main`, including `config_GAHM2026_default`,
  `output/FLORENCE_AL06_2018.mat`, and `output/FLORENCE_2018.nc`.
- Use current camelCase MATLAB API names.
- Keep detailed parameter tables and class references in their existing repository documents unless the website needs a
  short summary for its primary workflow.
- Use Jekyll-aware or base-URL-safe internal links and assets so the site works at both `/` locally and
  `/GAHM2026/` on GitHub Pages.
- Exclude local-development instructions, Bundler artifacts, caches, and generated site output from the published site.

## Local tooling

- Install a current Homebrew Ruby rather than modifying the macOS system Ruby installation.
- Keep gem installation project-local through Bundler.
- Run from `docs/`:

```bash
bundle install
bundle exec jekyll build --strict_front_matter
bundle exec jekyll serve --livereload --host 127.0.0.1
```

- Add `_site/`, `.jekyll-cache/`, `.sass-cache/`, and `vendor/bundle/` to Git ignores.

## GitHub Pages compatibility

The shared configuration will use local defaults with an empty base URL. A later GitHub Actions workflow can invoke
the same locked build with `--url https://renci.github.io --baseurl /GAHM2026`, upload `_site`, and deploy it through
GitHub Pages. This avoids the restricted legacy Pages build environment and ensures the deployed artifact matches the
local build. No workflow or Pages setting is added in this phase.

## Verification

1. Build with strict front matter and no Jekyll errors.
2. Start the server on `127.0.0.1` and verify all six page routes return HTTP 200.
3. Check rendered navigation, search assets, code blocks, internal links, and default output examples.
4. Confirm no generated site, cache, or locally installed gems are staged.
5. Confirm no `.github/workflows` or Pages configuration changes are introduced.
