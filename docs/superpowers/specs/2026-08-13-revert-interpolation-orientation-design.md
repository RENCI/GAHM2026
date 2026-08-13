# Revert Grid Interpolation Orientation

## Goal

Restore the grid interpolation behavior from commit `5677a06`, which passes
all 68 saved regression checks, while preserving unrelated changes made by
commit `2e7956d` and later commits.

## Scope

- In `util/interpFieldToGrid.m`, evaluate the velocity and pressure
  interpolants with `longrid` and `latgrid` without transposing either target
  grid.
- In `GAHM2026.m`, evaluate both blending-mask interpolants with `longrid` and
  `latgrid` without transposing either target grid.
- Do not revert the whole `2e7956d` commit, change baselines, or modify NWS13
  files.

## Verification

- Run the focused MATLAB unit tests.
- Run `tools/run_tests.m` against the existing August 5 baselines and require
  all 68 baseline comparisons to pass.
- Run MATLAB Code Analyzer on both changed source files.
