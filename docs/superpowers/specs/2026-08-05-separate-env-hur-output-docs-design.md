# SeparateEnvHur Output Documentation Cleanup

## Goal

Make every active plotting example use the real SeparateEnvHur output contract instead of the nonexistent
`separated.mat` placeholder, and make README examples consistent with the default Florence configuration.

## Source of truth

- `SeparateEnvHur` saves an `env_vals` variable to
  `<output_dir>/<storm_name>_<storm_designation>_<storm_year>.mat`.
- The default configuration therefore produces `output/FLORENCE_AL06_2018.mat`.
- `GAHM2026Plotter.fromSepEnvHur` accepts either that MAT-file path or the returned `env_vals` struct.
- The default gridded GAHM output path is `output/FLORENCE_2018.nc`.

## Changes

1. Replace all active `separated.mat` examples, including class help text, with
   `output/FLORENCE_AL06_2018.mat`.
2. Retain and explain the direct `env_vals` form where it helps users running SeparateEnvHur interactively.
3. Correct stale Florence MAT-file names and the documented `env_info.file_name` derivation.
4. Correct affected README references to the default config name and default output names.
5. State the generic storm/designation/year naming rule near concrete Florence examples.

## Scope

Only active README files and plotting-class help text will change. Runtime MATLAB behavior, configuration values,
generated outputs, historical planning documents, and unrelated workspace changes are out of scope.

## Verification

- Search active documentation and class help for stale placeholder and Florence filename variants.
- Confirm documented config and output names against the current default configuration and writers.
- Load `output/FLORENCE_AL06_2018.mat` through `GAHM2026Plotter.fromSepEnvHur`.
- Run `git diff --check` and confirm only intended documentation/help files changed.
