# Task 2 Report

## Outcome

Integrated point WAF handling into `GAHM2026.m` and packaged the point vortex/intermediate hurricane result in `run_GAHM2026.m`. Grid WAF behavior remains dispatched through `readgeoraster` and `applyWAFfromRaster`; point WAF uses scoped MAT loading and `applyWAFfromPoints`.

## RED evidence

Before production edits, ran:

```text
/Applications/MATLAB_R2026b.app/bin/matlab -batch "results = runtests('tools/testMergeFeatures.m'); assertSuccess(results)"
```

Result: exit code 1. The three new integration tests failed because point WAF loading/dispatch, the grid-only diagnostic guard, and `Points_VVor_invtapHur_out` packaging were absent. Only after this failure were the external reference source sections consulted.

## Implementation decisions

- Preserved `WAF_data` and `WAF_metadata` initialization.
- Grid WAF continues to call `readgeoraster` and `applyWAFfromRaster`.
- Point WAF uses `load(WAF_info.file_name, "WAF_points")`, validates `isfield`, and raises `GAHM2026:MissingWafPoints` with a configuration-oriented message when absent.
- WAF changes only vortex `VelU`/`VelV`; pressure still comes from the unadjusted vortex before environmental pressure is added.
- Guarded only the final `griddedInterpolant` radial diagnostic with `output.type == "grid"`; retained `VPrad.VVor`, `VPrad.EnvVor`, `thetaToAzimuth`, and interpolation helpers.
- Preallocated all three point result struct arrays and added the six required fields to `Points_VVor_invtapHur_out`.
- Retained every generic `Result.Reggrid_*` assignment in point mode.

## Validation

Focused tests after implementation and again after commit:

```text
/Applications/MATLAB_R2026b.app/bin/matlab -batch "results = runtests('tools/testMergeFeatures.m'); assertSuccess(results)"
```

Result: exit code 0; 18 passed, 0 failed, 0 incomplete (final run: 0.51404 seconds).

MATLAB Code Analyzer:

```text
/Applications/MATLAB_R2026b.app/bin/matlab -batch "files={'GAHM2026.m','run_GAHM2026.m','tools/testMergeFeatures.m'}; for k=1:numel(files), issues=checkcode(files{k},'-id'); fprintf('%s: %d issues\n',files{k},numel(issues)); end"
```

Result: command exited 0. `GAHM2026.m`: 38 issues (existing AGROW/NASGU findings); `run_GAHM2026.m`: 1 issue (existing unused netCDF return value); `tools/testMergeFeatures.m`: 0 issues. Point packaging preallocation removed the new AGROW findings from `run_GAHM2026.m`.

Also ran `git diff --check` successfully before commit. Per instruction, no baseline, `run_tests`, or `compare_to_baseline` command was run.

## Commit

`d5f5516` — `Integrate WAF for point output`

Only `GAHM2026.m`, `run_GAHM2026.m`, and `tools/testMergeFeatures.m` were committed. The unrelated modification to `util/writeGAHM2026NetCdf.m` and unrelated untracked files were left untouched and unstaged.

## Concerns

- The focused suite exercises the Task 1 point-WAF numerical helper directly, while main-pipeline dispatch/loading and result packaging are verified structurally rather than through a full synthetic GAHM run. No compact fixture was available without reproducing substantial track/config dependencies.
- Existing Code Analyzer findings remain in production files; none were introduced by the point packaging change, and broad cleanup was outside this task.

## Behavioral review fixes

### RED evidence

Before creating the top-level helpers, the focused suite reported 17 passed and 7 failed
(5 incomplete). The failures were the expected undefined-helper failures for
`loadWAFData`, `applyWAFforOutput`, and `createPointOutputs`, including wrong-error-ID
failures where the required stable errors could not yet be raised.

### Behavioral coverage and results

The focused command was:

```text
/Applications/MATLAB_R2026b.app/bin/matlab -batch "results = runtests('tools/testMergeFeatures.m'); fprintf('passed=%d failed=%d incomplete=%d\n',nnz([results.Passed]),nnz([results.Failed]),nnz([results.Incomplete])); assertSuccess(results)"
```

Final result: 24 passed, 0 failed, 0 incomplete in 0.64347 seconds. Behavioral tests
cover scoped point MAT loading and cleanup, missing `WAF_points`, invalid output types,
directional point and synthetic raster dispatch, preservation of pressure and arbitrary
metadata, optional `Speed` replacement, and all point output field names, datetimes,
values, and shapes. Type-1/2 numeric-zero intermediate results produce coordinate-shaped
zero arrays; type-3 structures preserve their values. One explicitly named structural
test retains generic caller assignments because `run_GAHM2026` has no practical fixture
seam. The only other source assertion is explicitly limited to the grid-only radial
diagnostic guard because a complete GAHM track/environment fixture is disproportionate.

### Files and interfaces

- `util/loadWAFData.m`: `[wafData, wafMetadata] = loadWAFData(outputType, fileName)`.
- `util/applyWAFforOutput.m`: dispatches by output type and preserves the complete vortex
  structure while replacing adjusted velocity and optional speed.
- `util/createPointOutputs.m`: creates TC, environment, and intermediate point structures,
  including safe type-1/2 numeric-zero handling.
- `GAHM2026.m` and `run_GAHM2026.m`: call those helpers without changing WAF pressure
  ordering or generic result assignments.
- `tools/testMergeFeatures.m`: replaces broad source inspection with behavioral tests.

The complete fix is committed as `Test point WAF integration behavior`; its exact hash is
reported in the task completion response after Git creates the commit object.

### Code Analyzer comparison and concerns

Analyzer results after the fixes: `GAHM2026.m` 37 pre-existing AGROW/NASGU findings
(previous report: 38), `run_GAHM2026.m` 1 pre-existing NASGU finding, and zero findings in
the test and all three new helpers. No new analyzer findings were introduced. `git diff
--check` passed. Per instruction, no baseline, `compare_to_baseline`, or `run_tests` command
was run. Full pipeline execution remains outside the focused fixture; the two narrow
structural assertions document that limitation.
