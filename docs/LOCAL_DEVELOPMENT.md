# Local development

Install and select Homebrew Ruby 3.4, then install the locked dependencies and build the site:

```bash
brew install ruby@3.4
export PATH="$(brew --prefix ruby@3.4)/bin:$PATH"
cd docs
bundle config set --local path vendor/bundle
bundle install
bundle exec jekyll build --strict_front_matter
bundle exec jekyll serve --livereload --host 127.0.0.1
```

The site is then available at <http://127.0.0.1:4000/>. Retain the checked-in `Gemfile.lock` so local builds use the locked toolchain. Generated, cache, and vendor directories are ignored and should not be committed.

These commands are for local development only. They do not publish the site or enable GitHub Pages.

## Updating source documents

Install Pandoc, then run the updater from the repository root:

```bash
brew install pandoc

./tools/update-docs
./tools/update-docs --all
./tools/update-docs documentation/Derivation_and_Implementation.docx
./tools/update-docs --check
```

The normal command uses stored checksums to automatically regenerate pages whose source DOCX files changed.
Generated Markdown pages and media are checked in. Use `--all` to regenerate every source document, or pass an
explicit DOCX path to update only that document. The `--check` command verifies generated content and the built site;
it additionally requires the Ruby and Bundler setup above.

Review the results, then commit the DOCX source and its generated Markdown and media changes together.
