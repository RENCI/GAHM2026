# nws13_combined_netcdf

A MATLAB function that combines ERA5 reanalysis data and GAHM2024 hurricane model data into a single NetCDF file with organized groups.

## What it does

This function takes meteorological data from two different sources and combines them into one well-structured NetCDF file:
- **ERA5 data**: Global reanalysis data from ECMWF
- **GAHM2024 data**: Hurricane vortex model data from MATLAB files

The output file contains two separate groups to keep the data organized and properly attributed.

## Basic Usage

```matlab
nws13_combined_netcdf('era5_data.nc', 'gahm_data.mat', 'combined_output.nc');
```

## Required Inputs

- `era5_file` - Path to your ERA5 NetCDF file
- `gahm_file` - Path to your GAHM2024 .mat file
- `output_file` - Path where you want the combined NetCDF file saved

## Optional Settings

You can customize the output by adding name-value pairs:

```matlab
nws13_combined_netcdf('era5_data.nc', 'gahm_data.mat', 'output.nc', ...
    'Title', 'Hurricane Florence Analysis', ...
    'Institution', 'Your Institution Name', ...
    'MainGroupName', 'ERA5_Data', ...
    'GAHMGroupName', 'Hurricane_Model');
```

### Available Options

- `Title` - Custom title for the dataset (default: auto-generated)
- `Institution` - Your institution name (default: 'RENCI')
- `MainGroupName` - Name for the ERA5 data group (default: 'Main')
- `GAHMGroupName` - Name for the GAHM data group (default: 'Florence2018')
- `ERA5VarNames` - Custom variable names for ERA5 data (advanced)
- `GAHMVarNames` - Custom variable names for GAHM data (advanced)

## What's in the Output File

The combined NetCDF file contains:

### ERA5 Group (Main)
- Time series on a regular grid
- Variables: U10, V10 (wind components), PSFC (pressure)
- Coordinates: longitude, latitude, time

### GAHM Group (Florence2018)
- Time series on a hurricane-following moving grid
- Variables: U10, V10 (wind components), PSFC (pressure)
- Coordinates: longitude, latitude (time-varying), time

## File Requirements

**ERA5 NetCDF file should contain:**
- longitude, latitude, valid_time
- u10, v10 (wind components)
- msl (mean sea level pressure)

**GAHM MAT file should contain:**
- A structure with fields containing VelU, VelV, Press
- A structure with grid information containing Lon, Lat, datetime

## Example Output Structure

```
combined_output.nc
+-- Global attributes (title, institution, etc.)
+-- Main/                    # ERA5 data group
¦   +-- time, lon, lat
¦   +-- U10, V10, PSFC
+-- Florence2018/            # GAHM data group
    +-- time, lon, lat
    +-- U10, V10, PSFC
```

## Error Handling

The function will display helpful error messages if:
- Input files don't exist or can't be read
- Required variables are missing
- File writing permissions are insufficient

## Notes

- Time is standardized to minutes since 1970-01-01 for both datasets
- Pressure units are converted to hPa (mb) for consistency
- The function automatically detects GAHM variable names if they follow standard naming conventions