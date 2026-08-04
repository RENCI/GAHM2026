# GAHM2026 External Changes Merge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Incorporate the substantive post-divergence work from `/Users/bblanton/Downloads/GAHM2026-main_1p4` into this repository without reverting current naming, formatting, safety improvements, or API compatibility.

**Architecture:** Port two independent feature groups: point-output Wind Adjustment Factor (WAF) support in the main GAHM pipeline, and physical-grid/configurable-cutline support in `SeparateEnvHur`. Treat the external code as a behavioral reference rather than replacement code because it also contains stale implementations and several regressions.

**Tech Stack:** MATLAB, Signal Processing Toolbox, Mapping Toolbox, MATLAB function-based tests, and the existing regression tools under `tools/`.

## Global Constraints

- The source copy is `/Users/bblanton/Downloads/GAHM2026-main_1p4`.
- The target repository is `/Users/bblanton/GitHub/RENCI/GAHM2026`.
- Always retain target-repository filenames and identifier style when a corresponding file already exists.
- Use lowerCamelCase MATLAB function names and double-quoted strings in new code.
- Ignore whitespace, line spacing, operator-spacing, capitalization-only, and underscore-only differences.
- Do not replace a current file wholesale with its external counterpart.
- Preserve current argument validation, preallocation, cleanup objects, helper extraction, and result-field compatibility.
- Exclude generated `input/`, `output/`, backup files, and `SeparateEnvHur/old/` from the merge.
- Preserve the public `Vortex_mask` field; support `Vortex_mask_outer` only as a backward-compatible input alias.
- Add focused tests before each behavioral change and retain the existing numerical regression suite.

---

## Comparison Summary

Most apparent differences are not new work. Semantic comparison against Git history showed that the external plotting files, most utilities, regression tools, and Markdown documents match older repository revisions after formatting and naming are normalized.

The external-only work is concentrated in two areas:

1. Point-output WAF loading, application, and result packaging.
2. `SeparateEnvHur` grid-resolution detection, physical-domain configuration, filter-isotach separation, and configurable cutline resolution.

The external copy also adds a small ATCF radius normalization fix and changes the outer-mask field name.

## Target File Inventory

### Existing code files requiring changes

| File | Required behavior |
|---|---|
| `GAHM2026.m` | Load WAF data according to output type, apply point WAFs, and avoid grid-only radial diagnostics for point output. |
| `run_GAHM2026.m` | Return `Points_VVor_invtapHur_out` without removing existing `Reggrid_*` result fields. |
| `util/gahm2026Prep.m` | Convert zero R34/R50/R64 quadrant radii to `NaN`. |
| `util/readEnvAndHurrFields2.m` | Accept `Vortex_mask_outer` while retaining `Vortex_mask` compatibility. |
| `config/config_GAHM2026_default.m` | Provide the new physical-grid and cutline/filter configuration fields. |
| `SeparateEnvHur/SeparateEnvHur.m` | Coordinate the physical-grid, filter-isotach, generalized cutline, and output-name behavior. |
| `SeparateEnvHur/applyCircularSmooth.m` | Generalize smoothing width and cutline length. |
| `SeparateEnvHur/computeBasicField.m` | Derive filter domain and sample rate from physical grid spacing. |
| `SeparateEnvHur/computeDistanceKm.m` | Support the configured number of azimuths instead of 24 fixed directions. |
| `SeparateEnvHur/convertToPolarCoords.m` | Derive extraction and radial dimensions from physical settings. |
| `SeparateEnvHur/ensureConvexCutline.m` | Remove the fixed 24-point convexity target and retain bounded iteration. |
| `SeparateEnvHur/extractCutlineCoords.m` | Extract every configured cutline direction. |
| `SeparateEnvHur/findCutline.m` | Generalize azimuth/radial searches while preserving NaN and bounds handling. |
| `SeparateEnvHur/initializeOutputArrays.m` | Allocate arrays using derived grid and azimuth dimensions. |
| `SeparateEnvHur/smoothCutline.m` | Use configurable smoothing controls while retaining the iteration cap. |
| `SeparateEnvHur/storeResults.m` | Select and store a physically sized output domain. |

### New code and test files

| File | Responsibility |
|---|---|
| `util/applyWAFfromPoints.m` | Apply direction-dependent WAF values to paired output coordinates. |
| `tools/testMergeFeatures.m` | Focused synthetic tests for point WAF, mask compatibility, radius normalization, and generalized cutline geometry. |

### Documentation files requiring updates

| File | Required update |
|---|---|
| `README.md` | Document point WAF behavior and `Points_VVor_invtapHur_out`. |
| `documentation/README_config.md` | Document point-WAF MAT schema and new `SeparateEnvHur` parameters. |
| `SeparateEnvHur/README.md` | Replace the fixed-cell configuration with the physical-grid model. |

### Optional example files

The following external files are scenario-specific examples rather than runtime dependencies. Add adapted versions only if the Florence 79-point and WAF comparison cases should be reproducible from this repository:

- `config/config_Florence_79points_type3.m`
- `config/config_Florence_grid_type3_WAF.m`
- `config/config_Florence_grid_type3_no_WAF.m`

Do not copy these files unchanged; convert them to the final target configuration schema.

---

### Task 1: Add a robust point-WAF helper

**Files:**
- Create: `util/applyWAFfromPoints.m`
- Create: `tools/testMergeFeatures.m`
- Modify: `tools/run_tests.m`

**Interfaces:**
- Consumes: a `wafPoints` struct array with scalar `lon`, scalar `lat`, and equal-length `WAF` vectors; a vortex struct containing `VelU` and `VelV`; and matching longitude/latitude output arrays.
- Produces: `vortexWaf`, initialized from the complete input vortex struct, with adjusted `VelU`, `VelV`, and `Speed` when `Speed` exists.
- Function signature: `vortexWaf = applyWAFfromPoints(wafPoints, vortexPoints, longitudePoints, latitudePoints)`.

- [ ] **Step 1: Add failing synthetic tests**

Create function-based tests that verify:

1. A wind from 0 degrees uses the first WAF direction.
2. A wind from 90 degrees interpolates the expected directional WAF.
3. The 0/360-degree seam is continuous.
4. Coordinate pairs are matched together. A longitude from one WAF point and latitude from another must not count as a match.
5. Missing and duplicate coordinate pairs raise specific errors.
6. Input array shape, pressure, and unrelated structure fields are preserved.

Use synthetic WAF directions at 0, 90, 180, and 270 degrees so expected values can be asserted exactly. Register `tools/testMergeFeatures.m` with `tools/run_tests.m` before the baseline comparison.

- [ ] **Step 2: Run the focused tests and verify failure**

Run:

```bash
matlab -batch "results = runtests('tools/testMergeFeatures.m'); assertSuccess(results)"
```

Expected: failure because `applyWAFfromPoints` does not exist.

- [ ] **Step 3: Implement paired-coordinate WAF interpolation**

Implementation requirements:

- Validate equal output coordinate and velocity element counts.
- Validate a nonempty WAF struct and equal direction counts for every WAF point.
- Compute meteorological wind-from direction as `mod(atan2d(VelU, VelV) + 180, 360)`.
- Treat WAF directions as evenly spaced clockwise from north, append 360 degrees using the 0-degree value, and interpolate linearly.
- Match longitude/latitude pairs together using one documented numeric tolerance.
- Require exactly one WAF point per output point.
- Initialize the result from `vortexPoints`, then replace velocity fields without dropping pressure or metadata.
- Recompute `Speed` only when the input contains that field.
- Use stable error identifiers under the `applyWAFfromPoints:*` namespace.

Do not reproduce the external helper's independent longitude/latitude `ismember` calls or its uninitialized output structure.

- [ ] **Step 4: Run focused and existing regression tests**

Run:

```bash
matlab -batch "results = runtests('tools/testMergeFeatures.m'); assertSuccess(results)"
matlab -batch "addpath('tools'); run_tests()"
```

Expected: focused tests pass and existing gridded WAF baselines remain unchanged.

- [ ] **Step 5: Commit the helper independently**

```bash
git add util/applyWAFfromPoints.m tools/testMergeFeatures.m tools/run_tests.m
git commit -m "Add point wind adjustment factors"
```

---

### Task 2: Integrate point WAF into the main GAHM pipeline

**Files:**
- Modify: `GAHM2026.m:108-120`
- Modify: `GAHM2026.m:305-344`
- Modify: `GAHM2026.m:516-567`
- Modify: `run_GAHM2026.m:121-160`
- Modify: `tools/testMergeFeatures.m`

**Interfaces:**
- Consumes: the Task 1 `applyWAFfromPoints` helper.
- Produces: unchanged grid behavior plus point WAF support and `Result.Points_VVor_invtapHur_out`.

- [ ] **Step 1: Add failing integration assertions**

Add tests or a compact synthetic point-run fixture that verifies:

- Grid output still loads a raster with `readgeoraster`.
- Point output loads a MAT variable named `WAF_points` without injecting MAT variables into function scope.
- A missing `WAF_points` variable produces a clear configuration error.
- Point output does not construct a `griddedInterpolant` from coordinate vectors.
- `Result.Points_VVor_invtapHur_out` contains `datetime`, `Lon`, `Lat`, `U10`, `V10`, and `Press`.
- Existing `Result.Reggrid_*` fields remain available for point output.

- [ ] **Step 2: Run the focused tests and verify failure**

Run:

```bash
matlab -batch "results = runtests('tools/testMergeFeatures.m'); assertSuccess(results)"
```

Expected: point-WAF dispatch and point intermediate-result assertions fail.

- [ ] **Step 3: Load WAF data by output type**

In `GAHM2026.m`, preserve `WAF_data` and `WAF_metadata` initialization. When WAF is enabled:

- For `output.type == "grid"`, retain `readgeoraster`.
- For `output.type == "points"`, use scoped `load(WAF_info.file_name, "WAF_points")`, validate the returned field, and assign it to `WAF_data`.
- Reject unsupported output types through the existing validation/error style.

- [ ] **Step 4: Dispatch WAF application by output type**

In `buildRegularGridOutputs`, retain `applyWAFfromRaster` for grids and call `applyWAFfromPoints` for points. Continue applying WAF only to vortex velocity before environmental wind is added; do not adjust pressure.

- [ ] **Step 5: Guard grid-only radial diagnostics**

Wrap the `VPrad.EnvHur_final` `griddedInterpolant` block in `if output.type == "grid"`. Preserve `VPrad.VVor`, `VPrad.EnvVor`, current preallocation, `thetaToAzimuth`, and the extracted interpolation helpers.

- [ ] **Step 6: Add point intermediate-result packaging**

In `run_GAHM2026.m`, construct `Points_VVor_invtapHur_out` alongside `Points_TC_out` and `Points_Env_out`, then assign it to `Result.Points_VVor_invtapHur_out`. Do not clear or conditionally remove the existing `Reggrid_*` fields.

- [ ] **Step 7: Verify focused and regression behavior**

Run:

```bash
matlab -batch "results = runtests('tools/testMergeFeatures.m'); assertSuccess(results)"
matlab -batch "addpath('tools'); run_tests()"
```

Expected: point tests pass and all existing grid baselines remain unchanged.

- [ ] **Step 8: Commit the integration**

```bash
git add GAHM2026.m run_GAHM2026.m tools/testMergeFeatures.m
git commit -m "Integrate WAF for point output"
```

---

### Task 3: Normalize missing radii and support both outer-mask schemas

**Files:**
- Modify: `util/gahm2026Prep.m:99-104`
- Modify: `util/readEnvAndHurrFields2.m:47-49`
- Modify: `util/readEnvAndHurrFields2.m:106-111`
- Modify: `tools/testMergeFeatures.m`

**Interfaces:**
- Produces: `NaN` for unavailable quadrant radii and identical `Masks(i).mask2` output from either accepted outer-mask field name.

- [ ] **Step 1: Add failing tests**

Add tests that construct:

- ATCF radius data containing zeros and verify normalized `RQuad` values are `NaN` while nonzero radii retain their converted values.
- Minimal environmental MAT structures using `Vortex_mask` and `Vortex_mask_outer` separately, verifying both produce the same outer mask.
- A structure with neither outer-mask field, verifying a specific error identifies both accepted names.

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
matlab -batch "results = runtests('tools/testMergeFeatures.m'); assertSuccess(results)"
```

Expected: zero-radius normalization and `Vortex_mask_outer` compatibility assertions fail.

- [ ] **Step 3: Normalize zero quadrant radii once at ingestion**

Immediately after populating all three `RQuad` columns in `gahm2026Prep.m`, replace zero entries with `NaN`. Retain downstream zero/NaN guards for backward compatibility.

- [ ] **Step 4: Read either outer-mask field without broad workspace loading**

Keep scoped `S = load(env.file_name)` and explicit `env_vals = S.env_vals`. Prefer `Vortex_mask_outer` when present and otherwise use `Vortex_mask`; emit a clear error if neither exists. Do not port the external unscoped `load` statement.

- [ ] **Step 5: Verify and commit**

Run:

```bash
matlab -batch "results = runtests('tools/testMergeFeatures.m'); assertSuccess(results)"
matlab -batch "addpath('tools'); run_tests()"
```

Then commit:

```bash
git add util/gahm2026Prep.m util/readEnvAndHurrFields2.m tools/testMergeFeatures.m
git commit -m "Normalize missing isotachs and mask inputs"
```

---

### Task 4: Define the physical-grid `SeparateEnvHur` configuration

**Files:**
- Modify: `config/config_GAHM2026_default.m:28-48`
- Modify: `SeparateEnvHur/SeparateEnvHur.m:91-158`
- Modify: `tools/testMergeFeatures.m`

**Interfaces:**
- Produces these validated internal configuration values: `gridSpacingDegrees`, `outputGridSize`, `filterHalfWidth`, `outputHalfWidth`, `searchRange`, `numAzimuthPoints`, `numRadialPoints`, and `radialIncrementDegrees`.
- Retains compatibility with the current fixed-cell fields for one migration period by translating them at the configuration boundary rather than throughout helper functions.

- [ ] **Step 1: Add configuration tests**

Test a 0.25-degree synthetic grid and assert:

- A 20-degree output box produces 81 points per side.
- A 30-degree filter box produces a 60-cell half-width.
- A 1.5-degree pressure-center radius produces a six-cell search range.
- Non-square grid spacing fails with a tolerance-aware error.
- Physical lengths that do not map to an integer number of cells fail before array allocation.

- [ ] **Step 2: Add physical configuration fields**

Add documented defaults corresponding to the external design:

- `filter_grid_length`
- `output_grid_length`
- `search_radius`
- `filter_isotach`
- `filter_hp_multiplier`
- `num_points_smoother`
- `isotach_smooth_variance`
- azimuth/radial counts derived from `GAHM_compute_info.ntheta` and `GAHM_compute_info.nr`

Keep target naming conventions when finalizing field names. Do not silently mix the old cell-count interpretation with the new degree interpretation.

- [ ] **Step 3: Derive grid-dependent values once**

In `SeparateEnvHur.m`, compute longitude and latitude increments from the loaded coordinate vectors, compare them with a numeric tolerance, and derive all cell counts once. Validate array dimensions before entering the processing loop.

- [ ] **Step 4: Separate filter and blending isotachs**

Find a cutline using `filter_isotach` to determine the filter half-power length. Continue finding inner and outer cutlines independently for blending masks. Do not reuse the inner blending isotach implicitly as the filter scale.

- [ ] **Step 5: Preserve current safety behavior**

Retain:

- the `arguments` block and optional preloaded ATCF data;
- `readIBTrACS` rather than the external snake_case predecessor;
- current logical mask representation;
- current `fullfile` output-directory handling;
- current logging and pressure conversion style.

If a configured output filename is supported, resolve it consistently with `output_dir`; do not reproduce the external behavior that creates one directory while saving to an unrelated path.

- [ ] **Step 6: Run focused configuration tests**

Run:

```bash
matlab -batch "results = runtests('tools/testMergeFeatures.m'); assertSuccess(results)"
```

Expected: all physical-grid derivation tests pass.

- [ ] **Step 7: Commit the configuration boundary**

```bash
git add config/config_GAHM2026_default.m SeparateEnvHur/SeparateEnvHur.m tools/testMergeFeatures.m
git commit -m "Configure SeparateEnvHur in physical units"
```

---

### Task 5: Generalize `SeparateEnvHur` cutline and filter helpers

**Files:**
- Modify: `SeparateEnvHur/applyCircularSmooth.m`
- Modify: `SeparateEnvHur/computeBasicField.m`
- Modify: `SeparateEnvHur/computeDistanceKm.m`
- Modify: `SeparateEnvHur/convertToPolarCoords.m`
- Modify: `SeparateEnvHur/ensureConvexCutline.m`
- Modify: `SeparateEnvHur/extractCutlineCoords.m`
- Modify: `SeparateEnvHur/findCutline.m`
- Modify: `SeparateEnvHur/initializeOutputArrays.m`
- Modify: `SeparateEnvHur/smoothCutline.m`
- Modify: `SeparateEnvHur/storeResults.m`
- Modify: `tools/testMergeFeatures.m`

**Interfaces:**
- Consumes: normalized configuration values produced by Task 4.
- Produces: consistently sized polar fields, cutline vectors, distance vectors, masks, and output arrays for any supported azimuth count and square input-grid spacing.

- [ ] **Step 1: Add geometry and dimension tests**

Use synthetic circular wind fields to test 24 and 360 azimuths. Assert:

- The polar angle vector contains each direction once and does not duplicate 0/360 degrees.
- Cutline, distance, and output-array dimensions equal the configured azimuth count.
- Every extracted cutline coordinate uses the corresponding polar row.
- NaN wind values terminate a radial search.
- Smoothing and convexity loops stop at their configured iteration bounds.
- Output-domain indexing fails clearly when a storm is too close to a source-grid edge.

- [ ] **Step 2: Generalize smoothing helpers**

Pass the azimuth count and smoothing width explicitly to `applyCircularSmooth`. Replace fixed slices such as rows 25:48 with a middle-third slice derived from the input length. Use configured tolerance in `smoothCutline` while retaining `MAX_ITER`. Add a similar bounded-iteration rule to `ensureConvexCutline`.

- [ ] **Step 3: Generalize polar coordinates and cutline extraction**

Derive the radial extent from the physical output box. Generate azimuths with the current endpoint-safe pattern: create one extra 360-degree endpoint and remove it. Do not copy the external `linspace(0, 2*pi, N)` expression because it duplicates the first direction and misaligns rows with nominal angles.

Extract one cutline coordinate from each polar row. Use actual array sizes as the source of truth instead of duplicating dimensions across configuration fields.

- [ ] **Step 4: Generalize radial cutline search**

Search each configured azimuth using matching polar-row angles. Preserve the current `isnan(tangentialWind)` termination. Round and clamp start/search indices, make the maximum search radius explicit, and validate coordinate-domain bounds before `inpolygon` and array slicing.

- [ ] **Step 5: Generalize filtering and distances**

In `computeBasicField`, derive the sample rate as the reciprocal of grid spacing and derive the filter half-power wavelength from filter-isotach radius times the configured multiplier. In `computeDistanceKm`, derive angle increments from vector length and retain the current longitude/latitude distance scaling.

- [ ] **Step 6: Generalize output allocation and storage**

Allocate logical masks and distance arrays using derived grid size and azimuth count. Keep internal `mask` and public `Vortex_mask` names. Select the storage window with the validated physical output half-width.

- [ ] **Step 7: Run focused and full regression tests**

Run:

```bash
matlab -batch "results = runtests('tools/testMergeFeatures.m'); assertSuccess(results)"
matlab -batch "addpath('tools'); run_tests()"
```

Expected: synthetic geometry tests pass. Existing GAHM baselines remain unchanged unless they explicitly regenerate `SeparateEnvHur` output using the new configuration.

- [ ] **Step 8: Commit the generalized helper set**

```bash
git add SeparateEnvHur/applyCircularSmooth.m SeparateEnvHur/computeBasicField.m \
    SeparateEnvHur/computeDistanceKm.m SeparateEnvHur/convertToPolarCoords.m \
    SeparateEnvHur/ensureConvexCutline.m SeparateEnvHur/extractCutlineCoords.m \
    SeparateEnvHur/findCutline.m SeparateEnvHur/initializeOutputArrays.m \
    SeparateEnvHur/smoothCutline.m SeparateEnvHur/storeResults.m \
    tools/testMergeFeatures.m
git commit -m "Generalize SeparateEnvHur cutline geometry"
```

---

### Task 6: Update documentation and optional Florence examples

**Files:**
- Modify: `README.md:254-290`
- Modify: `documentation/README_config.md:107-186`
- Modify: `documentation/README_config.md:208-223`
- Modify: `SeparateEnvHur/README.md:31-115`
- Optional create: adapted Florence configuration files listed above

**Interfaces:**
- Documents the final interfaces implemented in Tasks 1-5.

- [ ] **Step 1: Document point WAF input and output**

Specify that point WAF files are MAT-files containing `WAF_points`, where every element has scalar `lon`, scalar `lat`, and a directionally ordered `WAF` vector beginning at north and proceeding clockwise at equal angular increments. Document coordinate-pair matching and the error behavior for missing/duplicate points.

Add `Result.Points_VVor_invtapHur_out` to the output tables while retaining the generic result fields.

- [ ] **Step 2: Document physical `SeparateEnvHur` settings**

Replace fixed grid-cell examples with physical-degree settings. Explain grid-spacing detection, the filter domain, output domain, pressure-center search radius, filter isotach, filter multiplier, azimuth/radial resolution, and smoothing controls.

- [ ] **Step 3: Document mask compatibility**

Keep `Vortex_mask` as the produced field and state that readers also accept `Vortex_mask_outer` for files generated by the external code copy.

- [ ] **Step 4: Adapt examples only if retained**

If the Florence scenarios are needed, copy their scientific inputs and output locations into configs that use the final target field names. Do not include generated MAT, NetCDF, TIFF auxiliary, or diagnostics output files.

- [ ] **Step 5: Check documentation references**

Run:

```bash
rg 'apply_WAF_from_points|GAHM2026_prep|read_Env_and_Hurr_fields2|Vortex_mask_outer' README.md documentation SeparateEnvHur config
```

Expected: old function filenames do not appear as active API names; `Vortex_mask_outer` appears only in compatibility documentation.

- [ ] **Step 6: Commit documentation**

```bash
git add README.md documentation/README_config.md SeparateEnvHur/README.md config
git commit -m "Document merged WAF and environment separation features"
```

---

### Task 7: Final verification and review

**Files:**
- Review all files listed in the target inventory.

- [ ] **Step 1: Run MATLAB Code Analyzer on changed MATLAB files**

Use MATLAB's `checkcode` on every changed `.m` file and resolve newly introduced warnings.

- [ ] **Step 2: Run focused tests**

```bash
matlab -batch "results = runtests('tools/testMergeFeatures.m'); assertSuccess(results)"
```

Expected: all focused tests pass.

- [ ] **Step 3: Run numerical regression tests**

```bash
matlab -batch "addpath('tools'); run_tests()"
```

Expected: all available regression cases pass. Cases that require unavailable local ERA5 or WAF data may be reported as skipped, not passed.

- [ ] **Step 4: Run representative workflows**

Run one representative case for each supported path when its input data is available:

1. Grid output without WAF.
2. Grid output with raster WAF.
3. Point output without WAF.
4. Point output with point WAF.
5. `SeparateEnvHur` on a 0.25-degree input grid.

Verify output dimensions, timestamps, finite velocity/pressure values, mask fields, WAF-adjusted vortex winds, and result-structure compatibility.

- [ ] **Step 5: Review the final diff for accidental historical regressions**

Confirm that the merge did not introduce:

- snake_case external function names;
- unscoped `load` calls;
- global warning suppression;
- removed preallocation;
- removed `onCleanup` objects;
- duplicated 0/360-degree polar rows;
- unbounded smoothing loops;
- the external `Vortex_mask_outer` producer rename;
- removal of existing `Result.Reggrid_*` fields;
- generated input or output artifacts.

## Explicitly Rejected External Changes

The following external differences are intentionally not part of this merge:

- Removal of main-loop preallocation in `GAHM2026.m`.
- Duplicated interpolation code that replaces `interpFieldToGrid`.
- Removal of backward-compatible `VPrad.VVor` and `VPrad.EnvVor` fields.
- Clearing or omitting `Reggrid_*` fields for point output.
- Global `warning off` behavior.
- Unscoped MAT-file loading into function workspaces.
- The `Vortex_mask` to `Vortex_mask_outer` producer rename.
- The duplicate polar endpoint in external `convertToPolarCoords.m`.
- Removal of NaN cutline termination and smoothing iteration limits.
- Plotting, utility, and regression-tool files that are semantic equivalents of older Git revisions.
- `documentation/Documentation_run_GAHM2026.docx`, which uses obsolete APIs and contains unresolved draft text.
- Generated files under `input/`, `output/`, and archival files under `SeparateEnvHur/old/`.
