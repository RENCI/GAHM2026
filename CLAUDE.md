# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

MATLAB implementation of the Generalized Asymmetric Holland Model (GAHM). Reads tropical
cyclone track data (IBTrACS/ATCF/fort22), computes GAHM parameters per track time, builds
radial wind/pressure profiles, optionally blends them into gridded environmental fields
derived from ERA5, and writes NetCDF. Authors: Rick Luettich (UNC/IMS), Brian Blanton (UNC/RENCI).

## Commands

All commands assume the MATLAB working directory is the repo root — `run_GAHM2026` uses
relative paths (`config/`, `input/`, `output/`, `addpath('util')`) and will not work from elsewhere.

```matlab
R = run_GAHM2026;                     % default config/config_GAHM2026_default.m
R = run_GAHM2026('config_Florence');  % config/config_Florence.m (no path, no .m)
```

Regression tests (numerical, not unit tests — they verify refactors don't change results):

```matlab
addpath('tools')
generate_baseline      % run ONCE on known-good code; writes tools/baseline_env*.mat
compare_to_baseline    % after changes; PASS/FAIL per field
```

CI / non-interactive, exits non-zero on failure:

```bash
matlab -batch "addpath('tools'); run_tests"
```

Baselines are gitignored (`*.mat`), so `generate_baseline` must be run locally before
`compare_to_baseline` will do anything. Tests 3 and 4 (env_type=3) auto-skip when the
SeparateEnvHur `.mat` file is absent. Tolerances: 1e-10 for velocity/pressure/GAHM params,
1e-6 m for distances, 1e-12 deg for track lat/lon; comparisons are NaN-pattern-aware.

Standalone vortex separation:

```matlab
addpath('SeparateEnvHur')
env_vals = SeparateEnvHur('config/config_Florence');   % or SeparateEnvHur(sepenvhurStruct, ATCF_data_in)
```

The `mcp__matlab` MCP server is available for static analysis (`check_matlab_code`) and
execution against the user's live MATLAB session.

## Architecture

Three cooperating pipelines sharing one config file and `util/`.

**1. Driver — `run_GAHM2026.m`.** Sets path, `run()`s the config script, opens the diagnostics
log, validates `storm_year` against `storm_start`/`storm_end`, downloads IBTrACS if missing,
reads the track **once** into `ATCF_data_in`, auto-runs SeparateEnvHur if `env_info.type == 3`
and the env `.mat` is missing, calls `GAHM2026`, writes NetCDF, packages the `Result` struct.

**2. Orchestrator — `GAHM2026.m`** (main function + 7 local helpers). Phases:
- *Init*: `sliceTrack` (trim track to time window), `loadEnvFields` → `readEnvAndHurrFields2`
  (type 3 only), `readgeoraster` for the WAF raster.
- *Per-track-time loop*: `gahm2026Prep` (build GAHM struct) → `gahm2026Consistency`
  (screen inputs, set flags) → `gahm2026Solve` (compute B, Bg, Rmax per quadrant/isotach) →
  `gahmVPradial`/`gahmVP` (radial profiles) → `VEnvreg2radial2` (env onto radial grid, type 3) →
  `radialTaper2` (blend taper).
- *Output*: `radial2regular` (radial → regular grid), `applyWAFfromRaster`, `griddedInterpolant`
  for the type-3 env grid.

`util/gahm2026Solve.m` is the numerical core and the single entry point for both solver
versions; it dispatches on `GAHM_param_info.version` (3 = iterative, no toolbox; 4 = `fsolve`,
needs Optimization Toolbox). The old `GAHM2026v3e.m`/`GAHM2026v4a.m` files are gone — their
logic lives in local functions there.

**3. SeparateEnvHur/** — separates storm-scale features from ERA5 reanalysis to produce the
gridded environmental field required by `env_info.type = 3`. `getERA5Data` (reads NetCDF,
local or THREDDS OPeNDAP URL) → `convertToPolarCoords` → `findCutline`/`smoothCutline`/
`ensureConvexCutline` (wind-threshold contours, run three times: filter isotach, inner and
outer blending isotachs) → `applyButterworthFilter2D`/`computeBasicField` (env/hurricane
split) → `createOutputStruct`.

The extraction is centered on the **interpolated track eye**, not the gridded pressure
minimum. `findPressureCenter` still runs each timestep but only reports the offset as a
debug diagnostic. Note that the `min_pressure_center_lon`/`_lat` fields in the output struct
therefore carry the *track* position despite their names.

**Plotting — `PlotEvalScripts/@GAHM2026Plotter/`.** Class taking either a `run_GAHM2026`
`Result` or (via the static `fromSepEnvHur`) a SeparateEnvHur output struct. Methods:
`contourMap`, `radialProfile`, `differenceMap`, `timeSeriesPlot`, `scatterCompare`,
`computeMetrics`, `animate`, `exportFigure`. `PlotEvalScripts/legacy/` holds the superseded
function-based scripts.

### Config files are scripts, not functions

`config/config_*.m` are plain scripts `run()` into the driver's workspace. They define shared
storm identity variables (`storm_name`, `storm_year`, `storm_designation`, `track_file`,
`track_type`, `GAHM2026_start`, `GAHM2026_end`, `debug`) at the top, then derive the structs
consumed downstream: `sepenvhur`, `storm_info`, `GAHM_param_info`, `GAHM_compute_info`,
`WAF_info`, `env_info`, `output_info`. The shared identity variables are copied into both
`sepenvhur.*` and `storm_info.*` — never set the duplicated fields independently.
`sepenvhur.output_file_name` is set to `env_info.file_name` so the auto-chain finds what
SeparateEnvHur writes; changing one without the other silently breaks it. To add a storm, copy
an existing config, edit the identity block and the ERA5 path.

Config *field* names are snake_case — the one place in the repo that is not lowerCamelCase.
That follows the v1.5 upstream schema deliberately (see `DECISIONS.md`); do not "fix" it.

`SeparateEnvHur` is configured in **physical degrees**, not grid cells. The grid increment is
detected from the input file at runtime (`CONFIG.dlonlat`) and every cell count is derived
from it, so a config works unchanged across input resolutions:

| Field | Meaning |
|---|---|
| `filter_grid_length` | side length (deg) of the box the digital filter runs on |
| `output_grid_length` | side length (deg) of the cutline/output box; output grid is `output_grid_length/dlonlat + 1` per side |
| `filter_isotach`, `filter_hp_multiplier` | filter half-power scale = mean radius to `filter_isotach` × multiplier |
| `wind_threshold_inner`, `wind_threshold_outer` | isotachs (m/s) for the two blending cutlines |
| `num_azimuthal_points`, `num_radial_points`, `radial_inc` | polar grid resolution; tied to `GAHM_compute_info.ntheta`/`nr` |
| `num_points_smoother`, `isotach_smooth_variance` | cutline smoothing controls |

Dead fields carried for upstream compatibility but never read: `output_info.warnings`,
`sepenvhur.isotach_output_radials`.

`env_info.type`: `1` = ADCIRC/ASWIP translation velocity, `2` = Lin & Chavez (2012)
(0.6× translation, rotated 20° CCW), `3` = gridded field from SeparateEnvHur. Types 1 and 2
ignore everything else in `env_info` and need no ERA5 data — they're the cheap test path.

`output_info.type`: `"grid"` writes a NetCDF on a regular lon/lat grid; `"points"` returns
structs at the `output_info.lon`/`.lat` pairs and writes no NetCDF. The returned `Result` is
shaped accordingly — `Reggrid_*` for grid, `Points_*` for points, and the
`*_VVor_invtapHur_out` member only when `env_info.type == 3`. Always present: `Trackdata`,
`GAHM_out`, `VPrad`, `storm_info`, `env_info`.

### Domain conventions

Documented canonically in `documentation/GAHM_struct.md`; follow it rather than restating it.
- Index `q = 1:4` → NE, SE, SW, NW. Index `iso = 1:3` → 34, 50, 64 kt. Slot `iso+1 = 4` holds
  defaults for when no isotach has a value.
- Suffix `_10_10` means 10-minute average at 10 m elevation. `_10_tblmin` is a table minimum.
- Units throughout: speed m/s, distance m, pressure mb, density kg/m³.
- Physical constants come from `util/gahmPhysicalConstants()` — no magic numbers like
  `1.944` or `1852` in new code.

### Logging

Everything goes through `util/logMsg.m`; the caller name is filled in from `dbstack`.

```matlab
logMsg(fid, "INFO", "step %d complete", i);
logMsg(fid, "ERROR", "File not found: %s", f);   % logs, then calls error() — terminates
logMsg(-1,  "DEBUG", "grid=%dx%d", nx, ny);      % fid = -1 → stdout only
```

`ERROR` is fatal by design. Use it for genuine aborts, `WARNING` otherwise.

## Gotchas

- `run_GAHM2026` **asserts the output NetCDF does not already exist**. Delete or rename
  `output/<name>.nc` before rerunning the same config.
- `.gitignore` excludes `*.mat`, `input/`, `output/`, `*~`, `*.asv`. Test baselines, ERA5
  files, IBTrACS CSVs, and all model output are untracked — don't assume a fresh clone has them.
- ERA5 paths may contain a literal `<year>` placeholder, substituted by `getERA5Data` at runtime.
- `run_GAHM2026` sets the session default datetime format to `yyyy-MMM-dd HH:mm:ss`. Never use
  a lowercase `hh` format here — that is a 12-hour clock with no AM/PM designator, so 18:00
  renders as `06:00:00` and any text round-trip loses 12 hours. Datetime *values* are unaffected
  by the display format; the risk is anything that converts a datetime to text. Code that writes
  a datetime into a file must set `.Format` explicitly rather than inherit the session default —
  `writeGAHM2026NetCdf` does this to keep the CF `time:units` attribute ISO 8601, since
  `cftime`/`netCDF4` cannot parse a month-name form like `2018-Sep-14`.
- ERA5 arrays are read `[lon×lat×time]` and transposed per timestep to `[lat×lon]`.
- Toolbox dependencies: Signal Processing (`designfilt`/`filtfilt` in SeparateEnvHur),
  Optimization (`fsolve`, only for `GAHM_param_info.version = 4`), Mapping (`readgeoraster`,
  only when `WAF_info.flag = true`). Version 3 avoids the Optimization Toolbox.
- `documentation/CALL_TREE.md` is the maintained execution trace — update it when the call
  structure changes.
- SeparateEnvHur writes `Vortex_mask_outer`; `readEnvAndHurrFields2` also accepts the legacy
  `Vortex_mask` so older `.mat` files still load.
- Point WAF files are MAT-files containing `WAF_points`, an array with scalar `.lon`, scalar
  `.lat`, and a `.WAF` vector of factors ordered clockwise from north at equal increments.
  Coordinates must match `output_info.lon`/`.lat` exactly — `applyWAFfromPoints` matches by
  equality and errors on any unmatched point.
- Three known defects are carried forward verbatim from v1.5 (polar-azimuth misalignment,
  uncapped `smoothCutline` loop, `output_dir` not joined to `output_file_name`). They are
  commented at the site and recorded in `DECISIONS.md` — do not silently "fix" them without
  regenerating baselines.

## Reference docs

`docs/configuration.md` (every config parameter — moved here from `documentation/README_config.md`),
`documentation/GAHM_struct.md` (GAHM data structure), `documentation/CALL_TREE.md` (execution trace),
`PlotEvalScripts/README.md` (plotter class), `SeparateEnvHur/README.md` (scrubbing algorithm),
`tools/README.md` (regression harness).

## Documentation site

Published at <https://renci.github.io/GAHM2026/>, built by `.github/workflows/pages.yml` from two
sources. **Do not hand-edit generated markdown.**

- `documentation/*.docx` are authoritative for the narrative documents. `tools/docs/build_docs.py`
  renders each one listed in `docs/_data/docx_pages.yml` with pandoc, post-processes it
  (`\#(n)` equation numbers → `\tag{n}`, bold section paragraphs → headings, pandoc image/span
  syntax → HTML), and writes it into the `_docs_build/` staging directory. Generated markdown is
  **never committed**.
- `docs/*.md` are hand-written pages, edited directly: `index.md`, `getting-started.md`,
  `configuration.md`, `era5.md`, `examples.md`, `track-files.md`, `separate-env-hur.md`,
  `plotting.md`.

Superseded GAHM2024-era documents were moved to `documentation/archive/` and are excluded from the
site; see `documentation/archive/README.md` for what replaced each.

Local preview: `python tools/docs/build_docs.py --clean`, then
`cd docs && bundle exec jekyll serve --source ../_docs_build`.

Theme is just-the-docs via `remote_theme`; MathJax is wired in `docs/_includes/head_custom.html`.
If the .docx sources are ever restyled to use Word Heading 1/2/3 styles, pandoc emits real headings
and the `BOLD_NUMBERED_HEADING` fallback in `build_docs.py` becomes unnecessary.
