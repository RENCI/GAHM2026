---
layout: default
title: Getting Started
nav_order: 2
permalink: /getting-started/
---

# Getting started
{: .no_toc }

1. TOC
{:toc}

---

## Requirements

**MATLAB R2022b or newer.** The `dictionary` type used in
`SeparateEnvHur/getERA5Data.m` and `SeparateEnvHur/createOutputStruct.m` sets the floor.
Development and testing is on R2025b.

| Toolbox | Needed for | When |
|---|---|---|
| Signal Processing | `designfilt`, `filtfilt` in SeparateEnvHur | `env_info.type = 3` only |
| Optimization | `fsolve` | `GAHM_param_info.version = 4` only |
| Mapping | `readgeoraster` | `WAF_info.flag = true` with gridded output only |

Version 3 of the solver is iterative and needs no Optimization Toolbox — it is the default in
every shipped configuration.

## Install

```bash
git clone git@github.com:RENCI/GAHM2026.git
```

Nothing is compiled and there is no install step. Add the repository to the MATLAB path and run
`initGAHM` once per session — it puts `util`, `static`, `PlotEvalScripts`, and `SeparateEnvHur` on
the path and sets the session datetime format:

```matlab
addpath('/path/to/GAHM2026')
initGAHM
```

`run_GAHM2026` can then be called from any working directory that has (or should have) its own
`config/`, `input/`, and `output/` folders — `config/` and `input/` are resolved relative to the
current MATLAB working directory, and `input/`/`output/` are created there on first run if
missing.

## First run

Start with a configuration that needs no reanalysis data. `env_info.type = 1` and `2` derive the
environmental field from the storm's translation velocity, so they need only the track file:

```matlab
cd GAHM2026
R = run_GAHM2026('config_Florence_radtest_type1');
```

That configuration covers a three-hour window of Hurricane Florence (2018-09-12 00Z to 03Z) with
gridded output and no wind adjustment factor — it finishes quickly and exercises the whole
pipeline. Pass the configuration name with **no path and no `.m` extension**; `run_GAHM2026`
resolves it to `config/<name>.m`.

The IBTrACS track file is downloaded automatically the first time it is needed, from
`https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/csv/`,
into `input/`.

On success you get a `Result` struct and, for `output_info.type = "grid"`, a NetCDF file under
`output/`. Diagnostics are written to the file named in `output_info.diagnostics`.

## Running with ERA5 blending

`env_info.type = 3` blends the parametric vortex into a gridded environmental field. That field is
produced by [SeparateEnvHur]({{ site.baseurl }}/separate-env-hur/) from
[ERA5 reanalysis]({{ site.baseurl }}/era5/), read over OPeNDAP from the RENCI THREDDS server — no
download needed.

```matlab
R = run_GAHM2026('config_Florence');
```

If `<env_info.file_name>.mat` does not exist, `run_GAHM2026` runs SeparateEnvHur first and then
continues, so a type-3 run is a single call. The chain only works if the configuration defines a
`sepenvhur` struct; otherwise it errors and asks you to run SeparateEnvHur separately.

To run the separation on its own:

```matlab
addpath('SeparateEnvHur')
env_vals = SeparateEnvHur('config/config_Florence');
```

## Plotting

```matlab
addpath('PlotEvalScripts')
obj = GAHM2026Plotter(R);

fig = obj.contourMap('mvelcon', 1, 20);        % wind speed map at output time 20
obj.radialProfile('velrad', 'envhur', 10, 10); % radial profiles
obj.animate('mvelcon', 1);                     % GIF / MP4 over all times
```

See the [Plotting]({{ site.baseurl }}/plotting/) page for the full class reference.

## Regression tests

The tests in `tools/` are numerical regression checks, not unit tests: they verify that a refactor
does not change results. Generate a baseline on known-good code first, then compare after changes.

```matlab
addpath('tools')
generate_baseline      % run ONCE on known-good code; writes tools/baseline_env*.mat
compare_to_baseline    % after changes; PASS/FAIL per field
```

Non-interactive form, exits non-zero on failure:

```bash
matlab -batch "addpath('tools'); run_tests"
```

Four test configurations run: env types 1 and 2 need only the IBTrACS file; tests 3 and 4 use
`env_info.type = 3` and skip automatically when the SeparateEnvHur `.mat` file is absent.
Tolerances are 1e-10 for velocity, pressure and GAHM parameters, 1e-6 m for distances, and
1e-12 degrees for track coordinates. Comparisons are NaN-pattern aware.

{: .note }
> Baselines are `.mat` files and `.gitignore` excludes `*.mat`, so a fresh clone has none.
> `compare_to_baseline` does nothing until `generate_baseline` has been run locally.

## Notes

- **The output NetCDF must not already exist.** `run_GAHM2026` asserts this before doing any work
  (for `output_info.type = "grid"`). Delete or rename `output/<name>.nc` before rerunning the same
  configuration.
- **`storm_year` must match the processing window.** A mismatch with the start time is a fatal
  error; a mismatch with the end time is a warning, since a storm may cross a year boundary.
- **The storm name must match the track file.** `storm_info.name` is checked against the name in
  the track record and the run aborts on a mismatch. IBTrACS uses all capitals.
- **`.gitignore` excludes `*.mat`, `input/`, and `output/`.** Test baselines, ERA5 files, IBTrACS
  CSVs, and all model output are untracked.
- **`ERROR` is fatal.** All logging goes through `util/logMsg.m`; the `ERROR` level logs and then
  calls `error()`. Use `WARNING` for anything recoverable.
- **Never set a lowercase `hh` datetime format in this session.** `run_GAHM2026` sets the default
  format to `yyyy-MMM-dd HH:mm:ss`. Lowercase `hh` is a 12-hour clock with no AM/PM designator, so
  18:00 renders as `06:00:00` and any text round-trip silently loses 12 hours.

## Where to next

- [Configuration]({{ site.baseurl }}/configuration/) — every parameter, and the output structures.
- [Examples]({{ site.baseurl }}/examples/) — the shipped configurations and what each demonstrates.
- [Derivation of GAHM2026]({{ site.baseurl }}/derivation/) — the model itself.
