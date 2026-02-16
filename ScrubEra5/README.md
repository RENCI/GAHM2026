# ScrubEra5

## amplified version of JC's AMS_env.m "code"
## 3 Feb 2026

Extracts and filters tropical cyclone fields from ERA5 reanalysis data. Separates storm-scale features from the background environmental flow using polar coordinate interpolation and spatial filtering techniques.

## Overview

The main function `ScrubEra5.m` processes ERA5 reanalysis data for a specified tropical cyclone, computing:
- Storm center location (based on minimum sea-level pressure)
- Polar coordinate transformation of wind and pressure fields
- Cutline detection at specified wind speed thresholds (10 m/s and 34 kt)
- Basic (environmental) field separation from the total field

## Requirements

- MATLAB
- ERA5 NetCDF data file (e.g., `Florence.nc`) containing:
  - `time` - time 
  - `msl` - Mean sea level pressure
  - `u10` - 10m U-component of wind
  - `v10` - 10m V-component of wind

- IBTrACS track data (`ibtracs.NA.list.v04r01.csv`)
  - Download from https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/csv/
 
## Usage

1. Create a configuration file (e.g., `config.m`) that defines a `CONFIG` struct:
   ```matlab
   CONFIG = struct( ...
       'nc_file', 'Florence.nc', ...
       'track_file', 'ibtracs.NA.list.v04r01.csv', ...
       'storm_name', 'FLORENCE', ...
       'storm_year', 2018, ...
       'storm_start', datetime(2018,9,6,0,0,0), ...
       'storm_end', datetime(2018,9,18,0,0,0), ...
       ...
   );
   ```

2. Call `ScrubEra5` with the path to the config file:
   ```matlab
   env_vals = ScrubEra5('config.m');
   ```

3. Output is also saved as `<STORM_NAME>_<YEAR>.mat` (e.g., `FLORENCE_2018.mat`).

## Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `nc_file` | `'Florence.nc'` | ERA5 NetCDF input file |
| `track_file` | `'ibtracs.NA.list.v04r01.csv'` | IBTrACS track data file |
| `storm_name` | `'FLORENCE'` | Storm name for filtering and output |
| `storm_year` | `2018` | Year of storm |
| `storm_start` | `datetime(2018,9,6,0,0,0)` | Start time for processing |
| `storm_end` | `datetime(2018,9,18,0,0,0)` | End time for processing |
| `resolution` | `0.25` | Grid resolution in degrees (unused) |
| `grid_half_size` | `40` | Half-size of extraction grid (grid points) |
| `output_half_size` | `40` | Half-size of output grid (grid points) |
| `filter_domain_size` | `120` | Domain size for filtering operations |
| `num_radial_points` | `1000` | Number of radial points for polar interpolation |
| `num_azimuth_points` | `360` | Number of azimuthal points |
| `max_radius_deg` | `10` | Maximum radius in degrees for polar grid |
| `wind_threshold_10` | `10` | Wind threshold for outer cutline (m/s) |
| `wind_threshold_34` | `34/1.944` (~17.5) | Wind threshold for inner cutline (34 kt in m/s) |

## Module Structure

| Function | Description |
|----------|-------------|
| `loadTrackData` | Loads IBTrACS storm track data |
| `getERA5Data` | Retrieves ERA5 fields from NetCDF |
| `findPressureCenter` | Locates storm center via minimum SLP |
| `convertToPolarCoords` | Transforms fields to polar coordinates |
| `findCutline` | Detects wind threshold contours |
| `computeBasicField` | Computes environmental background field |
| `storeResults` | Stores timestep results to output arrays |
| `createOutputStruct` | Packages final output structure |

## Output

The output `.mat` file contains a struct named env_vals with:
- Filtered basic (environmental) fields: `basic_slp`, `basic_u`, `basic_v`
- Original fields: `full_slp`, `full_u`, `full_v`
- Storm positions: track coordinates and ERA5-derived center locations
- Cutline masks and distances at both wind thresholds


#### DDS of ERA5 file
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
