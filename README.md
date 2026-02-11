# GAHM2026 — Generalized Asymmetric Holland Model

## amplified version of GAHM2026
## 8 Feb 2026

MATLAB codebase for computing hurricane wind and pressure fields using the Generalized Asymmetric Holland Model (GAHM). The pipeline reads tropical cyclone track data, computes GAHM parameters, generates radial wind/pressure profiles, optionally blends with large-scale gridded environmental fields, and writes output to NetCDF.

Developed by Rick Luettich, University of North Carolina.

---

## Quick Start

1. Open MATLAB and `cd` to this directory.
2. Edit `config/config_GAHM2026.m` to set the storm and processing parameters (see below).
3. Run the driver:

```matlab
>> run_GAHM2026              % uses default config/config_GAHM2026.m
>> run_GAHM2026('myconfig')  % uses config/myconfig.m
```

Output is written to a NetCDF file (for grid output) or returned as MATLAB structs (for point output).

---

## Configuration

All parameters are set in `config/config_GAHM2026.m`. The main sections are described below.

### Storm / Track File

| Parameter | Description | Example |
|-----------|-------------|---------|
| `storm_info.file_name` | Track file path | `'input/ibtracs.NA.list.v04r01.csv'` |
| `storm_info.file_type` | Format: `"ATCF"`, `"fort22"`, or `"IBTrACS"` | `"IBTrACS"` |
| `storm_info.name` | Storm name (all caps for IBTrACS) | `'FLORENCE'` |
| `storm_info.year` | 4-digit year (char) | `'2018'` |
| `storm_info.designation` | Basin + number (char) | `'AL06'` |
| `storm_info.starttime` | Processing start time (`'yyyymmddhh'`), or `0` for beginning of track | `'2018091312'` |
| `storm_info.endtime` | Processing end time (`'yyyymmddhh'`), or `0` for end of track | `'2018091500'` |

**Notes:**
- `starttime` and `endtime` must correspond to times present in the track file. If using gridded environmental fields (`env_info.type = 3`), these times must also be present in the environmental data file.
- Set `starttime = 0` and `endtime = 0` to process the entire track.
- Download from https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/csv/
  - put into "input" directory

### Environmental Fields

| Parameter | Description |
|-----------|-------------|
| `env_info.type` | `1` = ADCIRC/ASWIP (translation velocity), `2` = Lin & Chavez (2012), `3` = gridded fields from `.mat` file |
| `env_info.file_name` | Name of `.mat` file with gridded environmental/hurricane fields (without `.mat` extension). Required only for `type = 3`. |
| `env_info.taper_flag` | `true`/`false` — apply taper function to blend GAHM vortex into environmental fields |

**Notes:**
- For `env_info.type = 1` or `2`, no external environmental data file is needed. For `type = 3`, a `.mat` file (e.g., `Florence.mat`) containing gridded environmental and hurricane velocity/pressure fields is required.
- The env_info.file_name 'mat' file is the output of the separator / scrubber code with variables BestTrack_lat, etc...

### Output

| Parameter | Description |
|-----------|-------------|
| `output_info.type` | `"grid"` for regular lon/lat grid, `"points"` for specific locations |
| `output_info.timeinc` | Output time interval in hours (must be &le; track file interval) |
| `output_info.dellon` / `output_info.dellat` | Grid spacing in degrees |
| `output_info.nlon` / `output_info.nlat` | Grid dimensions (ignored for `env_info.type = 3`) |
| `output_info.NetCDFfilename` | Output NetCDF path (without `.nc`), e.g. `'output/Florence_2018'` |

---

## File Organization

| Directory / File | Description |
|------------------|-------------|
| `run_GAHM2026.m` | Top-level driver function (accepts optional config name) |
| `config/` | Configuration files (default: `config_GAHM2026.m`) |
| `GAHM2026.m` | Master orchestrator |
| `GAHM2026_prep.m` | Initialize GAHM data structure per timestep |
| `GAHM2026_consistency.m` | Input consistency checks and flag setting |
| `GAHM2026_solve.m` | GAHM parameter solver (unified v3/v4) |
| `GAHM_VPradial.m` / `GAHM_VP.m` | Radial wind/pressure profile computation |
| `read_ATCF_fort22.m` / `read_IBTrACS2.m` | Track file readers |
| `writeGAHM2026NetCdf.m` | NetCDF output writer |
| `input/` | Input data files (e.g., IBTrACS track files) |
| `output/` | NetCDF output files (`stormname_year.nc`) |
| `documentation/` | Call tree, data structure reference, refactoring notes |
| `tools/` | Regression testing harness (`generate_baseline.m`, `compare_to_baseline.m`) |
| `PlotEvalScripts/` | Plotting and evaluation scripts |

See `documentation/CALL_TREE.md` for the full execution trace and `documentation/GAHM_struct.md` for the GAHM data structure definition.
