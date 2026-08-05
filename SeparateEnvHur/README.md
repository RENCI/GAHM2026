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

SeparateEnvHur shares a configuration file with GAHM2026. The default config is
`config/config_GAHM2026_default.m` in the project root; storm-specific configs follow the same pattern (for example,
`config/config_Ian.m`).

Running via `run_GAHM2026` is the simplest approach — it auto-runs SeparateEnvHur when the `.mat` file is missing:

```matlab
>> cd GAHM2026
>> run_GAHM2026                          % uses config/config_GAHM2026_default.m
```

To run SeparateEnvHur standalone with a unified config:

```matlab
>> cd GAHM2026
>> addpath('SeparateEnvHur')
>> env_vals = SeparateEnvHur('config/config_GAHM2026_default');
```

You can also pass a struct directly:

```matlab
>> CONFIG = struct('background_file','path/to/era5.nc', 'storm_name','FLORENCE', ...
>>              'storm_designation','AL06', ...
>>              'storm_year',2018, 'track_file','input/ibtracs.NA.list.v04r01.csv', ...
>>              'storm_start',datetime(2018,9,10,0,0,0), ...
>>              'storm_end',datetime(2018,9,18,0,0,0), ...
>>              'filter_grid_length',30, 'output_grid_length',20, ...
>>              'search_radius',1.5, 'num_radial_points',800, ...
>>              'num_azimuth_points',24, ...
>>              'wind_threshold_outer',10, 'wind_threshold_inner',34/1.944, ... % 34 kt ≈ 17.5 m/s (1 kt = 1/1.944 m/s)
>>              'filter_isotach',17.5, 'filter_hp_multiplier',25, ...
>>              'num_points_smoother',3, 'isotach_smooth_variance',2000, ...
>>              'debug',true);
>> env_vals = SeparateEnvHur(CONFIG);
```

Output uses `<STORM_NAME>_<DESIGNATION>_<YEAR>.mat`. If `output_dir` is set, the file is saved there; the default
config therefore writes `output/FLORENCE_AL06_2018.mat`. The MAT-file contains the top-level `env_vals` struct.

## Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `background_file` | `'/path/to/<year>/<year>.global.nc'` | ERA5 NetCDF input file (`<year>` replaced at runtime) |
| `track_file` | `'ibtracs.NA.list.v04r01.csv'` | IBTrACS track data file |
| `storm_name` | `'FLORENCE'` | Storm name for filtering and output |
| `storm_year` | `2018` | Year of storm |
| `storm_start` | `datetime(2018,9,6,0,0,0)` | Start time for processing |
| `storm_end` | `datetime(2018,9,18,0,0,0)` | End time for processing |
| `filter_grid_length` | `30` | Side length of square filter extraction domain (degrees) |
| `output_grid_length` | `20` | Side length of square output and isotach-search domain (degrees) |
| `search_radius` | `1.5` | Physical half-width (degrees) of the square pressure-center search window centered on the track location |
| `num_radial_points` | GAHM `nr` | Number of radial points for polar interpolation |
| `num_azimuth_points` | GAHM `ntheta` | Number of azimuthal points |
| `wind_threshold_outer` | `10` | Wind threshold for outer cutline (m/s) |
| `wind_threshold_inner` | `34/1.944` (~17.5) | Wind threshold for inner cutline (34 kt in m/s) |
| `filter_isotach` | `17.5` | Independent isotach used to determine filter radius (m/s) |
| `filter_hp_multiplier` | `25` | Multiplier on mean filter-isotach radius for half-power wavelength |
| `num_points_smoother` | `3` | Circular cutline smoothing width (azimuth samples) |
| `isotach_smooth_variance` | `2000` | Variance convergence tolerance for isotach smoothing |

The source longitude and latitude spacing is detected at runtime and must be uniform and equal. Physical lengths must
map to integer cell counts; filter and output side lengths must span even counts. Filtering uses the larger filter
domain, while saved fields and cutline searches use the output domain. Unified configs derive azimuth and radial counts
from GAHM's `ntheta` and `nr`. Azimuths cover 360° without a duplicate seam; radial samples include both zero and the
`output_grid_length/2` endpoint. Smoothing is circular across the azimuth seam and is controlled by the two settings
above.

The physical-degree settings are the current interface. For one-period compatibility, legacy fixed-cell mode is
available only when `filter_domain_size`, `grid_half_size`, `output_half_size`, `search_range`, and `max_radius_deg`
are all supplied together. Partial legacy settings and combinations of legacy and physical-degree settings are
rejected. In legacy mode only, omitted filtering and smoothing controls retain their legacy defaults.

## Module Structure

| Function | Description |
|----------|-------------|
| `getERA5Data` | Retrieves ERA5 fields from NetCDF |
| `findPressureCenter` | Locates storm center via minimum SLP |
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
- Vortex masks: `Vortex_mask`, `Vortex_mask_inner`
- Best-track positions: `BestTrack_lon`, `BestTrack_lat`
- Cutline distances: `distance_outer`, `distance_inner`
- Pressure center: `min_pressure_center_lon`, `min_pressure_center_lat`
- Metadata: `units`

SeparateEnvHur produces `Vortex_mask`. Downstream readers accept both it and the external-copy compatibility name
`Vortex_mask_outer`; `readEnvAndHurrFields2` prefers `Vortex_mask_outer` if both fields exist, while this repository's
producer retains `Vortex_mask`.


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
