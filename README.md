# GAHM2026 — Generalized Asymmetric Holland Model <img width="70" height="70" alt="gahm" src="https://github.com/user-attachments/assets/4c152a13-d5ee-423e-bd08-594bfd9de366" />

MATLAB codebase for computing hurricane wind and pressure fields using the Generalized Asymmetric Holland Model (GAHM). The pipeline reads tropical cyclone track data, computes GAHM parameters, generates radial wind/pressure profiles, optionally blends with large-scale gridded environmental fields, and writes output to NetCDF.

When using gridded environmental fields (`env_info.type = 3`), the companion project **ScrubEra5** separates storm-scale features from ERA5 reanalysis data to produce the required environmental input. A unified configuration file lets both projects share storm identity and run as a single pipeline.

Developed by Rick Luettich, University of North Carolina.

---

## Quick Start

### One-command pipeline (recommended)

With the unified config, a single MATLAB call runs ScrubEra5 (if needed) and then GAHM2026:

```matlab
>> cd GAHM2026
>> run_GAHM2026('config_Florence')
```

If `FLORENCE_2018.mat` does not exist, `run_GAHM2026` will automatically locate the `ScrubEra5/` subdirectory, run the vortex scrubber to generate it, and then proceed with GAHM2026.

### Running each step separately

You can still run each step independently:

```matlab
% Step 1 — generate environmental fields
>> cd GAHM2026
>> addpath('ScrubEra5')
>> env_vals = ScrubEra5('ScrubEra5/config.m');          % original ScrubEra5 config
>> env_vals = ScrubEra5('config/config_Florence');       % or unified config

% Step 2 — run GAHM2026 (the .mat file is already in the working directory)
>> run_GAHM2026('config_Florence')
```

### Using the legacy GAHM2026-only config

The original config file still works for cases where the `.mat` file already exists:

```matlab
>> run_GAHM2026                        % uses config/config_GAHM2026.m
>> run_GAHM2026('config_GAHM2026')     % equivalent
```

---

## Directory Layout

ScrubEra5 lives inside the GAHM2026 directory:

```
GAHM2026/
├── run_GAHM2026.m          — top-level driver
├── GAHM2026.m              — master orchestrator
├── config/
│   ├── config_Florence.m   — unified config (ScrubEra5 + GAHM2026)
│   └── config_GAHM2026.m   — legacy GAHM2026-only config
├── util/                   — GAHM computation scripts
├── input/                  — track files (IBTrACS, ATCF, fort22)
├── output/                 — NetCDF output files
├── tools/                  — regression testing harness
├── documentation/          — call tree, data structures, notes
│
└── ScrubEra5/
    ├── ScrubEra5.m             — vortex scrubber entry point
    ├── config.m                — original standalone config
    ├── getERA5Data.m           — ERA5 NetCDF reader
    ├── loadTrackData.m         — IBTrACS track loader
    ├── findCutline.m           — wind threshold contour detection
    ├── computeBasicField.m     — environmental field separation
    ├── createOutputStruct.m    — package output .mat structure
    └── ...                     — additional processing functions
```

---

## Configuration

### Unified config (`config/config_Florence.m`)

The unified config has four sections. Storm identity parameters are defined once and shared by both projects.

#### 1. Shared storm identity

These values are defined as plain workspace variables and automatically populated into both the `scrub_info` and `storm_info` structs:

| Variable | Description | Example |
|----------|-------------|---------|
| `storm_name` | Storm name (all caps for IBTrACS) | `'FLORENCE'` |
| `storm_year` | 4-digit year (numeric) | `2018` |
| `track_file` | IBTrACS CSV filename | `'ibtracs.NA.list.v04r01.csv'` |
| `storm_designation` | Basin + number | `'AL06'` |

#### 2. ScrubEra5 parameters (`scrub_info.*`)

| Parameter | Description | Example |
|-----------|-------------|---------|
| `nc_file` | ERA5 NetCDF input file path | `'/path/to/2018.global.nc'` |
| `storm_start` | Start time for ERA5 extraction | `datetime(2018,9,10,0,0,0)` |
| `storm_end` | End time for ERA5 extraction | `datetime(2018,9,12,0,0,0)` |
| `grid_half_size` | Half-size of extraction grid (grid points) | `40` |
| `output_half_size` | Half-size of output grid (grid points) | `40` |
| `filter_domain_size` | Domain size for Butterworth filter | `120` |
| `num_radial_points` | Radial points for polar interpolation | `1000` |
| `num_azimuth_points` | Azimuthal points | `360` |
| `max_radius_deg` | Maximum polar grid radius (degrees) | `10` |
| `wind_threshold_10` | Outer cutline threshold (m/s) | `10` |
| `wind_threshold_34` | Inner cutline threshold (m/s, 34 kt) | `34/1.944` |
| `debug` | Print debug messages | `true` |

> **Note:** `scrub_info.storm_name`, `scrub_info.storm_year`, and `scrub_info.track_file` are automatically populated from the shared variables — do not set them separately.

#### 3. GAHM2026 parameters

These are identical to the legacy config. See the tables below and the comments in `config/config_GAHM2026.m` or `run_GAHM2026.m` for full documentation.

| Struct | Key parameters |
|--------|---------------|
| `storm_info` | Track file path/type, start/end times (derived from shared variables) |
| `GAHM_param_info` | GAHM model constants (B limits, BLF, version, etc.) |
| `GAHM_compute_info` | Radial grid resolution (`ntheta`, `nr`, `delr`) |
| `WAF_info` | Wind Adjustment Factor flag and raster file |
| `env_info` | Environmental field type, taper settings |
| `output_info` | Output format, grid resolution, NetCDF path |

#### 4. Automatic linkage

The `env_info.file_name` is derived from the shared storm identity:

```matlab
env_info.file_name = sprintf('%s_%d', storm_name, storm_year);  % e.g. 'FLORENCE_2018'
```

This matches the output filename that ScrubEra5 produces (`FLORENCE_2018.mat`), so the two projects are linked without any manual coordination.

---

## Auto-chaining: How It Works

When `run_GAHM2026` is called with a unified config and `env_info.type == 3`:

1. It checks whether `<env_info.file_name>.mat` exists (e.g., `FLORENCE_2018.mat`).
2. If the file exists → proceeds directly to GAHM2026 computation.
3. If the file is missing **and** `scrub_info` is available in the workspace:
   - Locates `ScrubEra5/` as a subdirectory (i.e., `./ScrubEra5/`).
   - Calls `ScrubEra5(scrub_info)`, passing the struct directly.
   - ScrubEra5 runs, saves the `.mat` file, and control returns to GAHM2026.
4. If the file is missing **and** `scrub_info` is not available (legacy config):
   - An error is raised with instructions to run ScrubEra5 separately or use a unified config.

```
run_GAHM2026('config_Florence')
  │
  ├── Load config → storm_info, scrub_info, env_info, ...
  ├── Download IBTrACS if missing
  ├── Check for FLORENCE_2018.mat
  │     │
  │     └── Missing? ──► ScrubEra5(scrub_info)
  │                         ├── Load ERA5 NetCDF
  │                         ├── Extract & filter vortex
  │                         └── Save FLORENCE_2018.mat
  │
  ├── GAHM2026 computation
  └── Write NetCDF output
```

---

## Creating a Config for a New Storm

1. Copy `config/config_Florence.m` to `config/config_<StormName>.m`.
2. Update the shared storm identity section:
   ```matlab
   storm_name        = 'MICHAEL';
   storm_year        = 2018;
   track_file        = 'ibtracs.NA.list.v04r01.csv';
   storm_designation = 'AL14';
   ```
3. Update `scrub_info` with the path to the ERA5 data and the desired extraction time window.
4. Update `storm_info.starttime` and `storm_info.endtime` to set the GAHM2026 processing window (must fall within the ScrubEra5 time range).
5. Adjust any model parameters as needed.
6. Run:
   ```matlab
   >> run_GAHM2026('config_Michael')
   ```

---

## Input Data

### IBTrACS track file

Download from: https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/csv/

Place in `GAHM2026/input/`. If not found, `run_GAHM2026` will attempt to download it automatically.

### ERA5 reanalysis data

ERA5 NetCDF files must contain variables `msl`, `u10`, `v10`, and `time` (or `valid_time`). The file path is specified in `scrub_info.nc_file`.

---

## Output

### Gridded output (`output_info.type = "grid"`)

A NetCDF file is written to `output/<storm>_<year>.nc` containing:
- Combined TC wind and pressure fields (`Reggrid_TC_out`)
- Environmental fields (`Reggrid_Env_out`)
- Grid coordinates and timestamps (`Reggrid_out`)

### Point output (`output_info.type = "points"`)

MATLAB structs are returned to the workspace with wind velocity (U10, V10) and pressure at specified lon/lat locations.

### ScrubEra5 intermediate output

The `.mat` file (e.g., `FLORENCE_2018.mat`) contains the `env_vals` struct with:
- Environmental fields: `env_msl`, `env_u10`, `env_v10`
- Hurricane fields: `hur_msl`, `hur_u10`, `hur_v10`
- Vortex masks: `Vortex_mask`, `Vortex_mask34`
- Grid coordinates: `Lo`, `La`
- Track positions: `BestTrack_lon/lat`, `min_pressure_center_lon/lat`

---

## Backward Compatibility

| Scenario | What to do |
|----------|------------|
| Existing `EnvFields.mat` with legacy config | `run_GAHM2026` or `run_GAHM2026('config_GAHM2026')` — works unchanged |
| Existing `config.m` in ScrubEra5 | `ScrubEra5('config.m')` — works unchanged |
| New storm with auto-chaining | Create a unified config and call `run_GAHM2026('config_<Storm>')` |

---

## References

- See `documentation/CALL_TREE.md` for the full GAHM2026 execution trace.
- See `documentation/GAHM_struct.md` for the GAHM data structure definition.
- See `ScrubEra5/README.md` for details on the vortex scrubbing algorithm.
