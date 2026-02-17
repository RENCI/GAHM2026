# GAHM2026 — Generalized Asymmetric Holland Model <img width="70" height="70" alt="gahm" src="https://github.com/user-attachments/assets/4c152a13-d5ee-423e-bd08-594bfd9de366" />

MATLAB codebase for computing hurricane wind and pressure fields using the Generalized Asymmetric Holland Model (GAHM). The pipeline reads tropical cyclone track data, computes GAHM parameters, generates radial wind/pressure profiles, optionally blends with large-scale gridded environmental fields, and writes output to NetCDF.

When using gridded environmental fields (`env_info.type = 3`), the companion project **ScrubEra5** separates storm-scale features from ERA5 reanalysis data to produce the required environmental input. A unified configuration file lets both projects share storm identity and run as a single pipeline.

Developed by Rick Luettich, University of North Carolina.

---

## Quick Start

```matlab
>> cd GAHM2026
>> run_GAHM2026                        % uses default config/config_GAHM2026.m
>> run_GAHM2026('config_Florence')     % uses config/config_Florence.m
```

If the ScrubEra5 `.mat` file does not exist (e.g., `output/FLORENCE_2018.mat`), `run_GAHM2026` will automatically locate the `ScrubEra5/` subdirectory, run the vortex scrubber to generate it, and then proceed with GAHM2026.

### Running ScrubEra5 separately

You can run ScrubEra5 standalone using the same config file:

```matlab
>> cd GAHM2026
>> addpath('ScrubEra5')
>> env_vals = ScrubEra5('config/config_GAHM2026');      % default config
>> env_vals = ScrubEra5('config/config_Florence');       % storm-specific config
```

---

## Directory Layout

ScrubEra5 lives inside the GAHM2026 directory:

```
GAHM2026/
├── run_GAHM2026.m          — top-level driver
├── GAHM2026.m              — master orchestrator
├── config/
│   ├── config_GAHM2026.m   — default unified config (ScrubEra5 + GAHM2026)
│   └── config_Florence.m   — example storm-specific config
├── util/                   — GAHM computation scripts
├── input/                  — track files (IBTrACS, ATCF, fort22)
├── output/                 — NetCDF output files
├── tools/                  — regression testing harness
├── documentation/          — call tree, data structures, notes
│
└── ScrubEra5/
    ├── ScrubEra5.m             — vortex scrubber entry point
    ├── getERA5Data.m           — ERA5 NetCDF reader
    ├── loadTrackData.m         — IBTrACS track loader
    ├── findCutline.m           — wind threshold contour detection
    ├── computeBasicField.m     — environmental field separation
    ├── createOutputStruct.m    — package output .mat structure
    └── ...                     — additional processing functions
```

---

## Configuration

### Config file layout (`config/config_GAHM2026.m`)

Every config file has four sections. Storm identity parameters are defined once and shared by both ScrubEra5 and GAHM2026.

#### 1. Shared storm identity

These values are defined as plain workspace variables and automatically populated into both the `scrub_info` and `storm_info` structs:

| Variable | Description | Example |
|----------|-------------|---------|
| `storm_name` | Storm name (all caps for IBTrACS) | `'FLORENCE'` |
| `storm_year` | 4-digit year (numeric) | `2018` |
| `track_file` | IBTrACS CSV filename | `'ibtracs.NA.list.v04r01.csv'` |
| `storm_designation` | Basin + number | `'AL06'` |
| `storm_start` | Start time for processing (shared) | `datetime(2018,9,10,0,0,0)` |
| `storm_end` | End time for processing (shared) | `datetime(2018,9,12,0,0,0)` |

#### 2. ScrubEra5 parameters (`scrub_info.*`)

| Parameter | Description | Example |
|-----------|-------------|---------|
| `nc_file` | ERA5 NetCDF input file path | `'/path/to/2018.global.nc'` |
| `grid_half_size` | Half-size of extraction grid (grid points) | `40` |
| `output_half_size` | Half-size of output grid (grid points) | `40` |
| `filter_domain_size` | Domain size for Butterworth filter | `120` |
| `num_radial_points` | Radial points for polar interpolation | `1000` |
| `num_azimuth_points` | Azimuthal points | `360` |
| `max_radius_deg` | Maximum polar grid radius (degrees) | `10` |
| `wind_threshold_outer` | Outer cutline threshold (m/s) | `10` |
| `wind_threshold_inner` | Inner cutline threshold (m/s, 34 kt) | `34/1.944` |
| `debug` | Print debug messages | `true` |

> **Note:** `scrub_info.storm_name`, `scrub_info.storm_year`, `scrub_info.track_file`, `scrub_info.storm_start`, and `scrub_info.storm_end` are automatically populated from the shared variables — do not set them separately. Likewise, `storm_info.starttime` and `storm_info.endtime` are derived from `storm_start` and `storm_end`.

#### 3. GAHM2026 parameters

See [`documentation/README.md`](documentation/README.md) for full parameter documentation.

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

When `run_GAHM2026` is called and `env_info.type == 3`:

1. It checks whether `<env_info.file_name>.mat` exists (e.g., `output/FLORENCE_2018.mat`).
2. If the file exists → proceeds directly to GAHM2026 computation.
3. If the file is missing → locates `ScrubEra5/`, calls `ScrubEra5(scrub_info)`, saves the `.mat` file, and continues to GAHM2026.

```
run_GAHM2026
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

1. Copy `config/config_GAHM2026.m` (or any existing storm config) to `config/config_<StormName>.m`.
2. Update the shared storm identity section:
   ```matlab
   storm_name        = 'MICHAEL';
   storm_year        = 2018;
   track_file        = 'ibtracs.NA.list.v04r01.csv';
   storm_designation = 'AL14';
   ```
3. Update `scrub_info` with the path to the ERA5 data and the desired extraction time window.
4. Update `storm_start` and `storm_end` to set the processing time window (used by both ScrubEra5 and GAHM2026).
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
| Existing `.mat` file already generated | `run_GAHM2026` — skips ScrubEra5, runs GAHM2026 directly |
| New storm with auto-chaining | Copy the default config, update storm identity, and call `run_GAHM2026('config_<Storm>')` |

---

## References

- See `documentation/CALL_TREE.md` for the full GAHM2026 execution trace.
- See `documentation/GAHM_struct.md` for the GAHM data structure definition.
- See `ScrubEra5/README.md` for details on the vortex scrubbing algorithm.
