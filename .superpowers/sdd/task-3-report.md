# Task 3 Report

## Outcome

Implemented ingestion/schema compatibility while preserving repository naming and scoped MAT loading:

- Zero ATCF quadrant radii are normalized to `NaN` immediately after all `RQuad` columns are populated.
- Environmental ingestion prefers `Vortex_mask_outer`, falls back to `Vortex_mask`, and emits `readEnvAndHurrFields2:MissingOuterMaskField` naming both accepted fields when neither exists.
- Added focused behavioral coverage for radius conversion/normalization, both outer-mask schemas, NaN mask normalization, and the missing-field diagnostic.

## TDD evidence

RED command:

```text
/Applications/MATLAB_R2026b.app/bin/matlab -batch "results = runtests('tools/testMergeFeatures.m'); assertSuccess(results)"
```

Expected failures observed before production changes: zero radii remained zero, `Vortex_mask_outer` raised `MATLAB:nonExistentField`, and the missing-field diagnostic did not identify both accepted names.

GREEN rerun: 28 passed, 0 failed, 0 incomplete.

## Additional verification

- `git diff --check`: passed.
- Code Analyzer: `tools/testMergeFeatures.m` had 0 issues. The two production files retain 7 pre-existing findings outside the Task 3 edits (6 in `gahm2026Prep.m`, 1 unused assignment in `readEnvAndHurrFields2.m`); no finding points to a Task 3 change.
- `addpath('tools'); run_tests()`: completed but reported 54 passes and 14 baseline regression failures, primarily TC output NaN-pattern differences. This is consistent with the intentional zero-to-NaN ingestion change, but the user-owned baseline was not updated or investigated outside Task 3 scope.
- `tools/compare_to_baseline.m` was not run.

## Scope and repository state

Only `util/gahm2026Prep.m`, `util/readEnvAndHurrFields2.m`, and `tools/testMergeFeatures.m` were staged for the Task 3 commit. The unrelated tracked change in `util/writeGAHM2026NetCdf.m` and unrelated untracked files were left untouched.

## Review finding fixes

- Hardened the schema-equivalence test with a non-transpose-symmetric mask and an exact normalized-orientation assertion.
- Added a fixture containing distinct `Vortex_mask_outer` and `Vortex_mask` values and verified that the preferred outer field wins.
- Asserted the exact diagnostic phrase `contain Vortex_mask_outer or Vortex_mask.` so the legacy-name check cannot match only the preferred name.
- Documented preferred `Vortex_mask_outer` and legacy `Vortex_mask` fallback in the existing function help.

These tests harden regression coverage for already-correct production behavior; they do not represent a new RED production failure.

## Review fix verification

Focused command:

```text
/Applications/MATLAB_R2026b.app/bin/matlab -batch "results = runtests('tools/testMergeFeatures.m'); assertSuccess(results)"
```

Exact test summary:

```text
Totals:
   29 Passed, 0 Failed, 0 Incomplete.
   1.0001 seconds testing time.
```

Relevant Code Analyzer output:

```text
tools/testMergeFeatures.m: 0 issue(s)
util/readEnvAndHurrFields2.m: 1 issue(s)
 L122 C9 NASGU
```

The single `NASGU` finding is the pre-existing `PnEnvAvg` assignment and is unrelated to the review fixes.
