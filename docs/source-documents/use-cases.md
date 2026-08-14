---
layout: default
title: GAHM2024 Use Cases
parent: Source Documents
nav_order: 4
permalink: /source-documents/use-cases/
source_document: documentation/Use_cases.docx
source_sha256: "a6c672f475ba6a1c14e7c16c9752a06f52194d0dbb29aed46b8148be2572f4ce"
---

> Converted from the [source DOCX](https://github.com/RENCI/GAHM2026/blob/main/documentation/Use_cases.docx).
> **Draft source:** This document contains incomplete or provisional material.

# GAHM2024 Use Cases

Rick Luettich 1/25/2026

This document provides an overview of use cases for the GAHM2024 parametric tropical cyclone model and it associated capabilities including the application of land roughness and blending with a gridded meteorological data set. In each case the required Matlab scripts, inputs and outputs are described.

The following use cases are considered:

1.  Compute GAHM2024 parameter values and write to an expanded Best Track output file

2.  Compute GAHM2024 wind velocity and pressure values at a series of longitude, latitude positions, with or without blending and land roughness. This case computes the values at exactly the specified input points.

3.  Compute GAHM2024 wind velocity and pressure values on a regular grid of longitude, latitude points. This case computes GAHM2024 values on a radial grid and interpolates the results to the regular grid.

## \

**Use Case 1:** Compute and output GAHM2024 parameter values

Matlab script: run_build_GAHM2024_param_file.m

> %\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--
>
> \% script to run build_GAHM2024_param_file.m for a specified number of
>
> \% storms and either GAHM version 3 or version 4
>
> \%
>
> \% write output to fort.22 like file. WARNING: While the output file has a
>
> \% similar format to ADCIRC\'S fort.22, it should not be used with GAHM
>
> \% (NWS=20) in ADCIRC !!!! Rmax and Bg values are not strictly
>
> \% compatible with the GAHM implementation in ADCIRC.
>
> \%
>
> \%
>
> \% 7/9/2025 Rick Luettich
>
> %\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--

The following control parameters or inputs can be set in the script and are required to run this script:

> [%% GAHM constants]{.underline}
>
> GAHM_constants.Vmax_multiplier=1; % =1 use full Vmax, =0.9 use 90% Vmax, etc.
>
> GAHM_constants.one2tenF=0.89; %convert 1-min windspeed to 10-min wind speed
>
> GAHM_constants.BLF=0.9; %wind speed reduction from top of boundary layer to 10m
>
> GAHM_constants.Bmin=0.5; %minimum allowable value of original Holland B
>
> GAHM_constants.Bmax=2.5; %maximum allowable value of original Holland B
>
> GAHM_constants.SVorMax_10_tblmin=20; %minimum allowable gradient wind velocity at the top of the boundary layer
>
> GAHM_constants.SVorQuad_10_tblmin=5; %minimum allowable quadrant wind velocity at the top of the boundary layer
>
> GAHM_constants.rhoa=1.204; %density of air (kg/m^3^)
>
> GAHM_constants.pback_def=1013; %default background pressure if not specified in environmental field
>
> GAHM_constants.version=4; %GAHM2024 version to use, v3 -- Rick's iterative solver, v4 -- Matlab solvers
>
> GAHM_constants.Bg0M=1.05; %=Bg/M used for iterative solver
>
> GAHM_constants.c0=0; % c0 used for iterative solver
>
> [%% track file info]{.underline}
>
> trackfile_name = \"ibtracs.NA.list.v04r01.csv\"; % track file name containing best track type input data for GAHM2024 (e.g., position, Vmax, central pressure, Vquadrants, etc)
>
> trackfile_type = \"IBTrACS\"; % specific format of track file input. Choices are "IBTrACS", "ATCF", ???
>
> [%% storms to process -- more than one can be specified]{.underline}
>
> storm(1).name = \'FLORENCE\';
>
> storm(1).year = \'2018\';
>
> storm(1).designation = \'AL06\';
>
> storm(1).starttime=0 or \'2018091312\'; % if 0, start at the first time in the track file, otherwise, start at the specified time. This must match a time that is present in both the track file and the Environmental input file (if used).
>
> storm(1).endtime=0 or \'2018091412\'; % if 0, end at the last time in the track file, otherwise, end at the specified time.
>
> [%% type of environmental field]{.underline}
>
> env.type = 1; % =1 use translation velocity as in ASWIP / ADCIRC; = 2 use translation velocity folloiwng Lin and Chavez (ref); = 3 read in from gridded file in .mat format
>
> env_file_name=\'ERA5_output.mat\'; % .mat file contining gridded environmental fields, needed if env.type=3;

**Use Case 2:** Compute GAHM2024 wind velocity and pressure values at a series of longitude, latitude positions. This case computes the values at exactly the specified input points. Options include:

- three choices for the Environmental field

- GAHM only output or include land roughness

- GAHM (and roughness) blended with large scale wind and pressure fields.
