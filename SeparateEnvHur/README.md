# SeparateEnvHur

## amplified version of JC's AMS_env.m "code"
## 02 Mar 2026

Extracts and filters tropical cyclone fields from ERA5 reanalysis data. Separates storm-scale features from the background environmental flow using polar coordinate interpolation and spatial filtering techniques.

## Overview

The main function `SeparateEnvHur.m` processes ERA5 reanalysis data for a specified tropical cyclone, computing:
- Storm center location (based on minimum sea-level pressure)
- Polar coordinate transformation of wind and pressure fields
- Cutline detection at specified wind speed thresholds (10 m/s and 34 kt)
- Basic (environmental) field separation from the total field

**Note:** ERA5 raw arrays are read as `[lon×lat×time]` and processing transposes each timestep to `[lat×lon]`.

## Requirements

- MATLAB
- Signal Processing Toolbox (`designfilt`, `filtfilt`)
- ERA5 NetCDF data file containing:
  - `time` - time 
  - `msl` - Mean sea level pressure
  - `u10` - 10m U-component of wind
  - `v10` - 10m V-component of wind

- IBTrACS track data (`ibtracs.NA.list.v04r01.csv`)
  - Download from https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/csv/
 
## Usage

### Recommended: unified config (shared with GAHM2026)

SeparateEnvHur shares a configuration file with GAHM2026.  The default config is `config/config_GAHM2026.m` in the project root; storm-specific configs follow the same pattern (e.g., `config/config_Florence.m`).

Running via `run_GAHM2026` is the simplest approach — it auto-runs SeparateEnvHur when the `.mat` file is missing:

```matlab
>> cd GAHM2026
>> run_GAHM2026                          % uses config/config_GAHM2026.m
>> run_GAHM2026('config_Florence')       % uses config/config_Florence.m
```

To run SeparateEnvHur standalone with a unified config:

```matlab
>> cd GAHM2026
>> addpath('SeparateEnvHur')
>> env_vals = SeparateEnvHur('config/config_GAHM2026');
```

You can also pass a struct directly:

```matlab
>> CONFIG = struct('background_file','path/to/era5.nc', 'storm_name','FLORENCE', ...
>>              'storm_designation','AL062018', ...
>>              'storm_year',2018, 'track_file','input/ibtracs.NA.list.v04r01.csv', ...
>>              'storm_start',datetime(2018,9,10,0,0,0), ...
>>              'storm_end',datetime(2018,9,18,0,0,0), ...
>>              'filter_grid_length',30, 'output_grid_length',20, ...
>>              'search_radius',1.5, ...
>>              'wind_threshold_outer',10, 'wind_threshold_inner',17.5, ... % 34 kt
>>              'filter_isotach',17.5, 'filter_hp_multiplier',25, ...
>>              'num_points_smoother',3, 'isotach_smooth_variance',2000, ...
>>              'num_azimuthal_points',24, 'num_radial_points',800, ...
>>              'radial_inc',(20/2)/800, ...
>>              'output_file_name','output/FLORENCE_AL06_2018_env', ...
>>              'debug',true);
>> [env_vals, CONFIG] = SeparateEnvHur(CONFIG);
```

The second output returns the configuration augmented with values derived from the input file,
notably `CONFIG.dlonlat` (detected grid increment) and `CONFIG.grid_size`.

Output is saved to `output_file_name` with a `.mat` extension. Note that `output_dir`, if set,
is created but is **not** joined to `output_file_name` — see `DECISIONS.md`.

## Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `background_file` | `'/path/to/<year>/<year>.global.nc'` | ERA5 NetCDF input file (`<year>` replaced at runtime) |
| `track_file` | `'ibtracs.NA.list.v04r01.csv'` | IBTrACS track data file |
| `storm_name` | `'FLORENCE'` | Storm name for filtering and output |
| `storm_year` | `2018` | Year of storm |
| `storm_start` | `datetime(2018,9,6,0,0,0)` | Start time for processing |
| `storm_end` | `datetime(2018,9,18,0,0,0)` | End time for processing |
| `filter_grid_length` | `30` | Side length (deg) of the box the digital filter runs on |
| `output_grid_length` | `20` | Side length (deg) of the cutline/output box. Must be <= `filter_grid_length` |
| `search_radius` | `1.5` | Radius (deg) searched for the gridded pressure minimum (diagnostic only) |
| `wind_threshold_outer` | `10` | Outer blending cutline isotach (m/s) |
| `wind_threshold_inner` | `17.5` | Inner blending cutline isotach (m/s, 34 kt) |
| `filter_isotach` | `17.5` | Isotach (m/s) whose mean radius sets the filter length scale |
| `filter_hp_multiplier` | `25` | Filter half-power scale = mean radius to `filter_isotach` x this |
| `num_points_smoother` | `3` | Moving-mean width for cutline smoothing |
| `isotach_smooth_variance` | `2000` | Convergence tolerance for cutline smoothing |
| `num_azimuthal_points` | `24` | Number of polar azimuths (from `GAHM_compute_info.ntheta`) |
| `num_radial_points` | `800` | Number of polar radial points (from `GAHM_compute_info.nr`) |
| `radial_inc` | derived | `(output_grid_length/2)/num_radial_points` |
| `output_file_name` | `env_info.file_name` | Path (no extension) the `.mat` is written to |

### Physical-grid model

As of v1.5, SeparateEnvHur is configured in **degrees**, not numbers of grid cells. The grid
increment is detected from the input file at runtime (`CONFIG.dlonlat`; longitude and latitude
spacing must be equal) and every cell count is derived from it. The output grid is
`output_grid_length/dlonlat + 1` points per side. The same config therefore works unchanged
against input data of any resolution.

The fields `grid_half_size`, `output_half_size`, `filter_domain_size`, `max_radius_deg`,
`num_azimuth_points`, and `search_range` were removed in this change.

### Storm centering

The extraction, polar transform, and cutline searches are centered on the **interpolated track
eye position**, not on the location of minimum sea-level pressure in the gridded input.
`findPressureCenter` still runs each timestep, but only to report the offset between the two as
a debug diagnostic.

### Filter isotach vs. blending isotachs

Three cutlines are computed per timestep. `filter_isotach` sets the half-power length scale of
the Butterworth filter that splits environmental from vortex flow. `wind_threshold_inner` and
`wind_threshold_outer` define the masks used later to blend GAHM with the vortex field. These
are independent — the inner blending isotach no longer doubles as the filter scale.

## Module Structure

| Function | Description |
|----------|-------------|
| `getERA5Data` | Retrieves ERA5 fields from NetCDF |
| `findPressureCenter` | Locates the gridded pressure minimum (diagnostic only) |
| `convertToPolarCoords` | Transforms fields to polar coordinates |
| `findCutline` | Detects wind threshold contours |
| `computeBasicField` | Computes environmental background field |
| `storeResults` | Stores timestep results to output arrays |
| `createOutputStruct` | Packages final output structure |

## Output

The output `.mat` file contains a struct named `env_vals` with:
- Environmental fields: `env_msl`, `env_u10`, `env_v10`
- Hurricane (residual) fields: `hur_msl`, `hur_u10`, `hur_v10`
- Grid coordinates: `Lo`, `La`
- Time vector: `Time`
- Vortex masks: `Vortex_mask_outer`, `Vortex_mask_inner` (files written before v1.5 name the
  outer mask `Vortex_mask`; `readEnvAndHurrFields2` accepts either)
- Best-track positions: `BestTrack_lon`, `BestTrack_lat`
- Cutline distances: `distance_outer`, `distance_inner`
- Storm center: `min_pressure_center_lon`, `min_pressure_center_lat` — despite the names these
  now carry the **track eye** position, since that is what the extraction is centered on
- Metadata: `units`


<!--#### DDS of ERA5 file
```
DDS:
Dataset {
    Grid {
     ARRAY:
        Int16 msl[time = 10248][latitude = 201][longitude = 201];
     MAPS:
        Int32 time[time = 10248];
        Float32 latitude[latitude = 201];
        Float32 longitude[longitude = 201];
    } msl;
    Grid {
     ARRAY:
        Int16 u10[time = 10248][latitude = 201][longitude = 201];
     MAPS:
        Int32 time[time = 10248];
        Float32 latitude[latitude = 201];
        Float32 longitude[longitude = 201];
    } u10;
    Float32 latitude[latitude = 201];
    Float32 longitude[longitude = 201];
    Int32 time[time = 10248];
    Grid {
     ARRAY:
        Int16 v10[time = 10248][latitude = 201][longitude = 201];
     MAPS:
        Int32 time[time = 10248];
        Float32 latitude[latitude = 201];
        Float32 longitude[longitude = 201];
    } v10;
} regional/wna/uvp/2018/2018.wna.nc;
```
-->