---
layout: default
title: Configuration
nav_order: 4
permalink: /configuration/
---

# Configuration

A unified MATLAB configuration controls SeparateEnvHur and GAHM2026. Shared identity values—`storm_name`,
`storm_year`, `track_file`, `storm_designation`, `storm_start`, and `storm_end`—feed both parts of the pipeline.
The remaining settings are organized into seven main structs:

1. `sepenvhur` controls ERA5 extraction and vortex separation.
2. `storm_info` identifies and selects the track.
3. `GAHM_param_info` contains model constants.
4. `GAHM_compute_info` defines the radial computational grid.
5. `WAF_info` controls the optional Wind Adjustment Factor.
6. `env_info` selects and configures the environmental field.
7. `output_info` selects output times, geometry, diagnostics, and NetCDF naming.

## Current default

The source of truth is
[`config/config_GAHM2026_default.m`](https://github.com/RENCI/GAHM2026/blob/main/config/config_GAHM2026_default.m).
It selects Florence (`AL06`, 2018), from `2018-09-14 00:00` through `2018-09-14 12:00`, and uses hourly gridded
output. Its generated paths are `output/FLORENCE_AL06_2018.mat` for the SeparateEnvHur input and
`output/FLORENCE_2018.nc` for the final NetCDF file.

## Environmental modes

Set `env_info.type` to:

- `1` for ADCIRC/ASWIP translation velocity;
- `2` for 0.6 times translation velocity rotated 20 degrees counterclockwise (Lin and Chavas, 2012);
- `3` for gridded environmental fields prepared by SeparateEnvHur.

Only type 3 uses `env_info.file_name`, `env_info.taper_flag`, `env_info.taper_mindelr2r1`, and `env_info.taper_a`.
The filename is a base path without `.mat`; the taper settings control blending at the inner and outer masks.

## Grid, points, and WAF

`output_info.type = "grid"` produces a regular grid. Types 1 and 2 use a storm-centered moving grid configured by
`nlon`, `nlat`, `dellon`, and `dellat`; type 3 adopts the environmental footprint and computes the dimensions at the
requested spacing. `output_info.type = "points"` evaluates fixed, paired longitude/latitude locations; the longitude
and latitude arrays must have equal lengths.

Set `WAF_info.flag = true` to enable land-roughness wind adjustment. Grid output reads a WAF raster; point output
reads a MAT-file containing matching `WAF_points`. The configured file is ignored when the flag is false.

## Create a storm configuration

Copy `config/config_GAHM2026_default.m` to `config/config_<StormName>.m`, update the shared storm identity and any
pipeline settings, then call it by filename without the path or `.m` extension:

```matlab
R = run_GAHM2026("config_<StormName>");
```

For every parameter and output field, see the
[complete configuration reference]({{ '/source-documents/configuration-reference/' | relative_url }}).
Continue to [Outputs]({{ '/outputs/' | relative_url }}) for the returned data structures.
