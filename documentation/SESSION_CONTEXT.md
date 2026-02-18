# GAHM2026 Refactoring Session Context

**Last updated**: February 17, 2026  
**Purpose**: Continuity document for resuming work in a new session.

---

## Project Overview

MATLAB codebase for computing hurricane wind and pressure fields using the Generalized Asymmetric Holland Model (GAHM). Developed by Rick Luettich at UNC/IMS/CNHR/EMES and Brian Blanton at UNC/RENCI. The pipeline reads tropical cyclone track data, computes GAHM parameters, generates radial wind/pressure profiles, optionally blends with gridded environmental fields, and writes output to NetCDF.

**Entry point**: `run_GAHM2026.m` → loads config from `config/` → calls `GAHM2026.m` → returns `Result` struct

---

## Current State

All five refactoring phases are complete. All naming uses GAHM2026 consistently. Directory structure organized with `input/` and `output/` directories. Graphics/visualization fully modernized with the `GAHM2026Plotter` class (7 build phases complete). ScrubEra5 subproject updated to share the same IBTrACS file as GAHM2026.

### Active Files

| Role | Files |
|------|-------|
| Driver | `run_GAHM2026.m` (returns `Result` struct) |
| Configuration | `config/config_GAHM2026_default.m` (Florence 2018, unified: ScrubEra5 + GAHM2026) |
| Configuration | `config/config_Florence.m` (short Florence run for testing) |
| Orchestrator | `GAHM2026.m` |
| GAHM pipeline | `util/GAHM2026_prep.m`, `util/GAHM2026_consistency.m`, `util/GAHM2026_solve.m` |
| Profile computation | `util/GAHM_VPradial.m`, `util/GAHM_VP.m` |
| I/O | `util/read_ATCF_fort22.m`, `util/read_IBTrACS.m`, `util/read_Env_and_Hurr_fields2.m`, `util/writeGAHM2026NetCdf.m` |
| Grid operations | `util/VEnvreg2radial2.m`, `util/radial2regular.m`, `util/radial_taper2.m` |
| Post-processing | `util/apply_WAF_from_raster.m` |
| Extracted utilities | `util/computeRmaxTot.m`, `util/quadrantUnitVectors.m`, `util/thetaToQuadrantPair.m`, `util/turnAngleDeg.m`, `util/logMsg.m`, `util/GAHM_physical_constants.m` |
| Plotting class | `PlotEvalScripts/@GAHM2026Plotter/` (15 .m files) |
| Plotting helpers | `PlotEvalScripts/plot_defaults.m`, `plot_coastline.m`, `plot_quiver_scaled.m` |
| Legacy plot scripts | `PlotEvalScripts/conplot_blend_GAHM2026.m`, `radplot_blend_GAHM2026.m`, etc. |

### Directory Structure

| Directory | Contents |
|-----------|----------|
| `config/` | Configuration files (default: `config_GAHM2026_default.m`) |
| `util/` | All supporting MATLAB functions (pipeline, I/O, grid ops, utilities) |
| `input/` | Input data files (e.g., `ibtracs.NA.list.v04r01.csv`) |
| `output/` | NetCDF output files (`stormname_year.nc`) |
| `documentation/` | Call tree, data structure reference, refactoring notes, this file |
| `tools/` | Regression testing harness |
| `ScrubEra5/` | ERA5 environmental field extraction subproject (uses shared config from `config/`) |
| `PlotEvalScripts/` | Plotting class, legacy scripts, helpers |

### Documentation

| File | Contents |
|------|----------|
| `README.md` | High-level usage guide, quick start, configuration reference |
| `documentation/GAHM_struct.md` | Canonical GAHM data structure definition |
| `documentation/CALL_TREE.md` | Full execution trace and call graph |
| `documentation/REFACTORING_PLAN.md` | Original 5-phase refactoring plan (all phases complete) |
| `documentation/phase3context.md` | Detailed Phase 3 decomposition context |
| `documentation/SESSION_CONTEXT.md` | This file |
| `PlotEvalScripts/README.md` | GAHM2026Plotter class guide with Florence 2018 demo |

### Regression Testing

| File | Purpose |
|------|---------|
| `tools/generate_baseline.m` | Runs pipeline, saves outputs to `.mat` baselines |
| `tools/compare_to_baseline.m` | Re-runs and compares all fields with tolerances |
| `tools/README.md` | Usage documentation for the tools |

**Important**: After changes, baselines should be regenerated:
```matlab
>> cd /Users/bblanton/GitHub/RENCI/GAHM2026
>> generate_baseline
>> compare_to_baseline
```

### Output Variables from `run_GAHM2026.m`

`run_GAHM2026` returns a `Result` struct containing:

| Field | Contents |
|-------|----------|
| `Result.Reggrid_out` | Grid coordinates (`.Lon`, `.Lat`), `.datetime`, `.Mask1`, `.Mask2` |
| `Result.Reggrid_TC_out` | Final blended TC fields: `.VelU`, `.VelV` (m/s), `.Press` (mb) |
| `Result.Reggrid_Env_out` | Environmental fields: `.VelU`, `.VelV` (m/s), `.Press` (mb) |
| `Result.Reggrid_VVor_invtapHur_out` | GAHM vortex + inverse-tapered hurricane (env_type=3 only; 0 for env_type 1,2) |
| `Result.Trackdata` | Storm track data with `.Rmax_t1`, `.Vmax_t1`, `.RQuad_t1`, quadrant info |
| `Result.GAHM_out` | Per-timestep GAHM parameters |
| `Result.VPrad` | Radial grid data: `.r`, `.theta`, `.VVor(i)`, `.Env(i)`, `.EnvVor(i)` |
| `Result.storm_info` | Storm identity (name, year, designation) |
| `Result.env_info` | Environmental field configuration |
| `Result.Points_TC_out` | (if output_type="points") Point TC output |
| `Result.Points_Env_out` | (if output_type="points") Point environmental output |

The `VPrad` struct packages radial-grid data for plotting. `.Env` and `.EnvVor` sub-structs are populated only when `env_info.type = 3`.

---

## Work Completed

### Phase 0: Regression Testing Harness
- Created `tools/generate_baseline.m` and `tools/compare_to_baseline.m`
- Three test configurations: env_type=1 (lightweight), env_type=3 (51×51), env_type=3 full Florence (351×351)

### Phase 1: Extract Duplicated Utilities
1. `computeRmaxTot.m` — replaced 3 nested copies
2. `quadrantUnitVectors.m` — replaced 4 inline copies
3. `thetaToQuadrantPair.m` — replaced duplicated ~20-line blocks
4. `logMsg.m` — dual stdout+file logging (ready for gradual adoption)
5. `GAHM_physical_constants.m` — centralized constants (ready for gradual adoption)
6. `turnAngleDeg.m` — replaced piecewise turning angle

### Phase 2: Fix In-Place Code Smells
1. Removed duplicate MSLP/Vmax validation in `GAHM2026_prep.m`
2. Guarded against LatNS==0 in `quadrantUnitVectors.m`
3. Fixed function/filename mismatch
4. Standardized kt-to-m/s conversion (`1.944`)
5. Pre-allocated arrays in `radial2regular.m`

### Phase 3: Decompose Orchestrator
Decomposed `GAHM2026.m` from 660-line monolith into ~190-line main + 7 local helpers:
`readAndSliceTrack`, `loadEnvFields`, `computeGAHMAtTrackTime`, `computeRadialProfiles`, `interpolateEnvOnRadialGrid`, `applyTaperOnRadialGrid`, `buildRegularGridOutputs`

### Phase 4: Unify v3e/v4a Solvers
Created `GAHM2026_solve.m` as unified entry point. Shared code extracted; version-specific backends (`compute_Bg_iterative` for v3, `compute_Bg_fsolve` for v4) dispatched by `compute_Bg`. Original `GAHM2026v3e.m` and `GAHM2026v4a.m` deleted.

### Phase 5: Documentation Cleanup
Created `documentation/GAHM_struct.md`. Replaced 50+ line duplicated GAHM struct comment blocks with one-line references.

### Post-Refactoring: Naming and Organization (Feb 8, 2026)
1. **Naming consistency**: Replaced all occurrences of `GAHM2024` → `GAHM2026` and `GAHM26_` → `GAHM2026_` across all files, function names, variable names, comments, and documentation. Renamed all affected files.
2. **Removed `not_needed/` directory** and cleaned documentation references.
3. **Created `input/` directory**: Moved `ibtracs.NA.list.v04r01.csv` into `input/`. Updated file paths.
4. **Created `output/` directory**: Output NetCDF files use `stormname_year` naming.
5. **Early output file check**: Added check in `run_GAHM2026.m` to error if the output NetCDF file already exists.
6. **Added `VPrad` output**: Modified `GAHM2026.m` to return radial grid data as 7th output.

### Graphics Modernization: Standalone Scripts (Feb 8, 2026)

Created a standardized plotting framework in `PlotEvalScripts/`:

**New files:**
- `plot_defaults.m` — Central `opts` struct with all configurable settings
- `plot_quiver_scaled.m` — Built-in `quiver` wrapper replacing external `vecplot`
- `plot_coastline.m` — Built-in coastline overlay replacing external `plotcoast`

**Modernized files:**
- `conplot_blend_GAHM2026.m` — Accepts optional `opts` struct; removed all external dependencies
- `radplot_blend_GAHM2026.m` — Rewritten to accept `VPrad` struct; accepts optional `opts`
- `run_conplot_blend_GAHM2026.m`, `run_radplot_blend_GAHM2026.m` — Updated

### ScrubEra5 Integration (Feb 16, 2026)
- Moved the IBTrACS CSV from `ScrubEra5/` to `input/` so both GAHM2026 and ScrubEra5 use the same file.

### Unified Config (Feb 16, 2026)
- Promoted the unified config pattern to the default `config/config_GAHM2026_default.m`. Every config now includes both `scrub_info` (ScrubEra5 parameters) and the GAHM2026 parameter structs, with shared storm identity defined once at the top.
- Deleted `ScrubEra5/config.m` — ScrubEra5 is now driven from config files in `config/`.

### GAHM2026Plotter Class (Feb 17, 2026)

Built an object-oriented plotting and evaluation class in 7 phases. The class lives in `PlotEvalScripts/@GAHM2026Plotter/` (15 .m files).

#### `run_GAHM2026.m` change
- Changed signature to `function Result = run_GAHM2026(config_name)`.
- Added `Result` struct packaging all output variables at the end.
- Backward compatible: calling without capturing the return value still works.

#### GAHM2026Plotter class (new)

`GAHM2026Plotter.m` — `handle` class, stores `Result` struct + `Opts`. Dependent properties (`PlotData`, `DataGrid`, `Trackdata`, `VPrad`) provide shortcuts. Constructor accepts `Result` and optional `opts` struct.

**Public methods:**

| File | Method | Phase | Description |
|------|--------|-------|-------------|
| `contourMap.m` | `contourMap(ptype, fign, time, plotdata)` | 2 | Single-timestep pcolor map (wind or pressure) |
| `addQuiver.m` | `addQuiver(time, plotdata)` | 3 | Standalone velocity vector overlay |
| `radialProfile.m` | `radialProfile(ptype, fign, time, theta_inc)` | 4 | Radial wind/pressure profiles in subplots |
| `scatterCompare.m` | `scatterCompare(X, Y, fign, ...)` | 5 | 1:1 scatter (by-quadrant N×4 or by-series N×K) |
| `syncDatetime.m` | `syncDatetime(A, B)` | 5 | Match two struct arrays by `.datetime` field |
| `animate.m` | `animate(ptype, fign, plotdata, filename)` | 6 | GIF/MP4 animation loop over all timesteps |
| `exportFigure.m` | `exportFigure(fig, filename)` | 7 | Save figure to PNG or PDF via `opts.export` |

**Private helpers:**

| File | Purpose |
|------|---------|
| `resolveTime.m` | Convert index or datetime → gridded timestep index |
| `resolveRadialTime.m` | Convert index or datetime → VPrad timestep index |
| `getDomain.m` | Compute axis limits (moving or fixed mode) |
| `plotTrack.m` | Storm track line overlay |
| `plotMaskContours.m` | Inner/outer mask boundary contours |
| `captureGifFrame.m` | Append figure frame to GIF file |
| `openMp4.m` | Create and open VideoWriter for MP4 |

#### Key design decisions

1. **Single-timestep plotting** — `contourMap` and `radialProfile` plot one timestep per call (specified by integer index or datetime). This decouples frame rendering from animation, making it easy to inspect individual times or build custom loops.
2. **`Result` struct pattern** — `run_GAHM2026` returns all outputs in one struct. The plotter constructor takes this struct, avoiding scattered workspace variables.
3. **`plot_defaults()` shared** — Both the class and legacy standalone scripts use the same `plot_defaults.m` options struct.
4. **Separate method files** — Each public and private method is in its own `.m` file inside `@GAHM2026Plotter/`, following MATLAB `@folder` class conventions.
5. **`plotdata` override** — `contourMap`, `addQuiver`, and `animate` accept an optional `plotdata` argument to plot any field struct (e.g., `Reggrid_Env_out`, `Reggrid_VVor_invtapHur_out`) instead of the default `Reggrid_TC_out`.

#### PlotEvalScripts file tree

```
PlotEvalScripts/
├── @GAHM2026Plotter/
│   ├── GAHM2026Plotter.m        (classdef)
│   ├── contourMap.m              (public)
│   ├── addQuiver.m               (public)
│   ├── radialProfile.m           (public)
│   ├── scatterCompare.m          (public)
│   ├── syncDatetime.m            (public)
│   ├── animate.m                 (public)
│   ├── exportFigure.m            (public)
│   ├── resolveTime.m             (private)
│   ├── resolveRadialTime.m       (private)
│   ├── getDomain.m               (private)
│   ├── plotTrack.m               (private)
│   ├── plotMaskContours.m        (private)
│   ├── captureGifFrame.m         (private)
│   └── openMp4.m                 (private)
├── README.md                     (rewritten — Florence 2018 demo)
├── conplot_blend_GAHM2026.m      (legacy, unchanged)
├── radplot_blend_GAHM2026.m      (legacy, unchanged)
├── GAHM2026_ASWIP_compare.m      (legacy, unchanged)
├── Rmax_compare.m                 (legacy, unchanged)
├── plot_defaults.m                (shared options)
├── plot_coastline.m               (shared helper)
├── plot_quiver_scaled.m           (shared helper)
├── radial_find_maskedge.m         (utility)
├── run_conplot_blend_GAHM2026.m   (legacy driver)
└── run_radplot_blend_GAHM2026.m   (legacy driver)
```

---

## Possible Future Work

- Gradually adopt `logMsg.m` to replace duplicated `fprintf` pairs throughout codebase
- Gradually adopt `GAHM_physical_constants.m` to replace magic number literals
- Time-series diagnostics: Vmax, central pressure, Rmax, isotach radii vs time
- Difference maps between field pairs (diverging colormap)
- Objective metrics: bias, RMSE, MAE, correlation → CSV summary
- Bias/RMSE annotations on scatter plots
- Driver script producing complete evaluation for one storm
- MATLAB Live Script template for publishable storm reports

---

## How to Resume

In a new Amp session:

> "load documentation/SESSION_CONTEXT.md"

Additional context files if needed:
- `documentation/CALL_TREE.md` — execution flow
- `documentation/REFACTORING_PLAN.md` — original plan (historical)
- `documentation/phase3context.md` — Phase 3 decomposition details
- `documentation/GAHM_struct.md` — data structure reference
- `README.md` — user-facing documentation
- `PlotEvalScripts/README.md` — GAHM2026Plotter class guide with Florence 2018 demo

### Quick Test

```matlab
R   = run_GAHM2026('config_GAHM2026_default');
addpath('PlotEvalScripts')
obj = GAHM2026Plotter(R);
obj.setOpts('anim', 'gif', false);
obj.setOpts('anim', 'mp4', false);
fig = obj.contourMap('mvelcon', 1, 20);
obj.exportFigure(fig, 'Florence_test');
obj.radialProfile('velrad', 10, 5);
```
