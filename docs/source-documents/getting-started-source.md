---
layout: default
title: Getting Started (Source Document)
parent: Source Documents
nav_order: 1
permalink: /source-documents/getting-started-source/
source_document: documentation/Getting_Started.docx
source_sha256: "a81ad02aef4bfa77cfdc90f68726bb04c0699063a5e35351c4d1c6edaef8fc47"
---

> Converted from the [source DOCX](https://github.com/RENCI/GAHM2026/blob/main/documentation/Getting_Started.docx).

Parametric Tropical Cyclone Generation using GAHM2026 v1.4 - Getting Started

Developed by Rick Luettich, Brian Blanton, Jianing Chen

8/4/2026

This document will help a user understand and run the Matlab based GAHM2026 v1.4 code base.

## General Considerations

- GAHM2026 utilizes track file data (e.g., IBTracs, ATCF) and can generate either standalone tropical cyclone (TC) wind and pressure fields or TC fields that are blended with gridded large-scale fields (e.g., ERA5).

- GAHM2026 TC fields are comprised of the sum of asymmetric TC vortex fields and environmental fields. The TC vortex fields are computed using a revised version of the Generalized Asymmetric Holland Model developed by Gao (2018) and contained in ADCIRC. The environmental fields are either computed from the storm's translation velocity or by spatially low pass filtering gridded large-scale fields to remove their TC vortex component.

- GAHM2026 can be configured to generate output on a regular (lon, lat) grid that translates with the storm eye (grid mode), e.g., for analyzing wind/pressure fields or as forcing for another model, or at specified (lon, lat) points (point mode), e.g., for comparing with fixed point wind observations.

- GAHM2026 can modify the TC vortex wind speeds using a wind adjustment factor (WAF) that is based on land roughness in the upwind direction.

- General use strategy:

  - Download IBTracs or other track file (note: run_GAHM2026.m can do this if not done ahead of time)

  - If using gridded large-scale fields to specify the environmental fields and / or to blend with the TC fields, create a gridded Environmental + TC Vortex input file. Note, GAHM2026 can do this on the fly if not precomputed. If the environmental fields are based on the TC translation velocity, these are computed on the fly.

  - If using wind adjustment factors, create a WAF file using either make_WAF_z0_block.m or make_WAF_z0_points.m.

  - Edit the configuration script in config/myconfig.m to specify run specifics

## To Run

- [Master run script]{.underline}: run_GAHM2026.m -- assumed to be in main GAHM2026 directory

- [Usage]{.underline}: Result=run_GAHM2026('myconfig')

**Input Files --** all input file names other than 'myconfig.m' are specified in the config file

1.  'myconfig.m' -- *required* configuration file that must be edited for each run. Located in the config/ directory

2.  track_file -- *required* track file (csv) in IBTrACS, ATCF or fort.22 format, located in the input/ directory

3.  large_scale_file -- *optional* large scale gridded wind & pressure fields if specified for use in GAHM2026 run. The files must cover the entire area for GAHM2026 output and can have one of two formats:

    a.  gridded environmental & TC vortex fields -- these may be precomputed and stored in a Matlab .mat file. The default file name is a concatenation of the storm_name, '\_', storm_designation, '\_', storm_year variables as specified in the configuration file. The default location is the output/ directory, (e.g., 'output/FLORENCE_AL06_2018.mat').

    b.  gridded ERA5 fields that include wind velocity (@ 10m elevation) and atmospheric pressure (@ mean sea level) in NetCDF format. If precomputed gridded environmental and TC vortex fields are not available, these will be created using SeparateEnvHur.m. The necessary ERA5 file can either be stored locally (e.g., in the input/ directory) or read from a thredds server (e.g., \'https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/global.1/uvp/ 2018/2018.nc\') -- this example is a global wind velocity & pressure file for 2018

4.  WAF_file -- *optional* file containing Wind Adjustment Factors if specified to adjust for land roughness. The WAF file is pre-computed using make_WAF_z0_xx.m and located in the input/ directory.

> **Output --** For either regular gridded or point output, GAHM2026 will return the 'Result' data structure. For regular gridded output, GAHM2026 will write NetCDF output files upon completion.
>
> 'Result' data structure: (i=1: \# output times)
>
> Result.Trackdata -- Track data
>
> Result.GAHM_out -- parameters computed by the GAHM algorithm (diagnostics)
>
> Result.storm_info -- storm information
>
> Result.env_info -- environmental information
>
> Result.VPrad -- TC vortex (including taper), environmental, and TC vortex (no taper) + environmental field computed along radial lines from the eye. Only populated for "grid" mode, empty for "points" mode.
>
> Additional fields in 'Result' data structure for "points" mode:
>
> Result.Points_TC_out -- full TC fields (TC vortex + Environmental) at specified points
>
> Result.Points_TC_out(i).datetime -- date time of output
>
> Result.Points_TC_out(i).Lon -- longitude of specified points
>
> Result.Points_TC_out(i).Lat -- latitude of specified points
>
> Result.Points_TC_out(i).U10 -- 10 meter, 10 min avg, E wind vel component
>
> Result.Points_TC_out(i).V10 -- 10 meter, 10 min avg, N wind vel component
>
> Result.Points_TC_out(i).Press -- Atmospheric pressure
>
> Result.Points_Env_out -- Environmental field at specified points (diagnostic)
>
> Result.Points_Env_out(i).datetime -- date time of output
>
> Result.Points_Env_out(i).Lon -- longitude of specified points
>
> Result.Points_Env_out(i).Lat -- latitude of specified points
>
> Result.Points_Env_out(i).U10 -- 10 meter, 10 min avg, E wind vel component
>
> Result.Points_Env_out(i).V10 -- 10 meter, 10 min avg, N wind vel component
>
> Result.Points_Env_out(i).Press -- Atmospheric pressure
>
> Results.Points_VVor_invtapHur_out -- TC vortex without blending taper (diagnostic)
>
> Result.Points_VVor_invtapHur \_out(i).datetime -- date time of output
>
> Result.Points_VVor_invtapHur \_out(i).Lon -- longitude of specified points
>
> Result.Points_VVor_invtapHur \_out(i).Lat -- latitude of specified points
>
> Result.Points_VVor_invtapHur \_out(i).U10 -- 10 meter, 10 min avg, E wind vel component
>
> Result.Points_VVor_invtapHur \_out(i).V10 -- 10 meter, 10 min avg, N wind vel component
>
> Result.Points_VVor_invtapHur \_out(i).Press -- Atmospheric pressure
>
> Additional fields in 'Result' data structure for "grid" mode:
>
> Result.Reggrid_out - moving regular grids for each output time
>
> Result.Reggrid_out(i).datetime -- date time of output
>
> Result.Reggrid_out(i).Lon -- longitude values in output grid
>
> Result.Reggrid_out(i).Lat -- latitude values in output grid
>
> Result.Reggrid_TC_out - full TC fields (TC vortex + Environmental) on regular grid
>
> Result.Reggrid_TC_out(i).VelU -- Total TC fields East velocity component
>
> Result.Reggrid_TC_out(i).VelV -- Total TC fields North velocity component
>
> Result.Reggrid_TC_out(i).Press -- Atmospheric pressure
>
> Result.Reggrid_Env_out - Environmental field on regular grid (diagnostic)
>
> Result.Reggrid_Env_out(i).VelU -- East velocity component
>
> Result.Reggrid_Env_out(i).VelV -- North velocity component
>
> Result.Reggrid_Env_out(i).Press -- Atmospheric pressure
>
> Result.Reggrid_VVor_invtapHur_out - TC vortex without blending taper (diagnostic)
>
> Result.Reggrid_VVor_invtapHur_out(i).VelU -- East velocity component
>
> Result.Reggrid_VVor_invtapHur_out(i).VelV -- North velocity component
>
> Result.Reggrid_VVor_InvtapHur_out(i).Press -- Atmospheric pressure
>
> NetCDF output file: (i=1: \# output times)
>
> Reggrid_out - moving regular grids for each output time
>
> Reggrid_out(i).datetime -- date time of output
>
> Reggrid_out(i).Lon -- longitude values in output grid
>
> Reggrid_out(i).Lat -- latitude values in output grid
>
> Reggrid_TC_out - full TC fields (TC vortex + Environmental) on regular grid
>
> Reggrid_TC_out(i).VelU -- Total TC fields East velocity component
>
> Reggrid_TC_out(i).VelV -- Total TC fields North velocity component
>
> Reggrid_TC_out(i).Press -- Atmospheric pressure
