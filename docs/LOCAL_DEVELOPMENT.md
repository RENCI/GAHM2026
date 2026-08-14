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
