---
layout: default
title: Outputs
nav_order: 5
permalink: /outputs/
---

# Outputs

`run_GAHM2026` returns a `Result` struct. Output files are generated locally and are not distributed through Git.

## Gridded results

For `output_info.type = "grid"`, the primary fields are:

- `Result.Reggrid_out`: each timestep's `datetime`, `Lon`, and `Lat` coordinates;
- `Result.Reggrid_TC_out`: final combined `VelU`, `VelV` (m/s), and `Press` (mb);
- `Result.Reggrid_Env_out`: environmental `VelU`, `VelV`, and `Press`;
- `Result.Reggrid_VVor_invtapHur_out`: GAHM vortex plus inverse-tapered hurricane intermediate;
- `Result.Trackdata`, `Result.GAHM_out`, and `Result.VPrad`: processed track, solver, and radial-grid diagnostics;
- `Result.storm_info` and `Result.env_info`: the effective storm and environmental configuration.

For `env_info.type = 3`, `Reggrid_out` also has inner `Mask1` and outer `Mask2`, and the
`Reggrid_VVor_invtapHur_out` structure contains the type-3 blending intermediate. Types 1 and 2 omit the mask fields
and return that gridded intermediate as the existing numeric all-zero array.

The default grid run writes `output/FLORENCE_2018.nc`. It contains the final combined tropical-cyclone wind
components and pressure, together with grid coordinates and timestamps.

## Point results

For `output_info.type = "points"`, `Result.Points_TC_out`, `Result.Points_Env_out`, and
`Result.Points_VVor_invtapHur_out` each carry `datetime`, `Lon`, `Lat`, `U10`, `V10`, and `Press`. Coordinates are
fixed paired longitude/latitude locations: the configured arrays must have equal lengths, and every timestep uses the
same pairs. For environment types 1 and 2, the wind and pressure values in `Points_VVor_invtapHur_out` are zero arrays
with the coordinate shape; type 3 contains the blending intermediate.

## SeparateEnvHur MAT-file

The default type-3 intermediate is `output/FLORENCE_AL06_2018.mat`. Its top-level variable is `env_vals`, whose key
fields include `Time`, `Lo`, `La`, environmental `env_msl`, `env_u10`, `env_v10`, hurricane `hur_msl`, `hur_u10`,
`hur_v10`, best-track and minimum-pressure-center coordinates, `Vortex_mask`, and `Vortex_mask_inner`. Readers also
accept the compatible outer-mask name `Vortex_mask_outer` and prefer it when both outer names exist.

## More information

- [Configuration]({{ '/configuration/' | relative_url }})
- [Plotting and Diagnostics]({{ '/plotting/' | relative_url }})
- [Complete configuration and output reference]({{ '/source-documents/configuration-reference/' | relative_url }})
- [Project output overview](https://github.com/RENCI/GAHM2026/blob/main/README.md#output)
