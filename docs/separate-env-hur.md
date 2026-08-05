---
layout: default
title: SeparateEnvHur
nav_order: 6
permalink: /separate-env-hur/
---

# SeparateEnvHur

SeparateEnvHur extracts a tropical-cyclone vortex from ERA5 reanalysis, leaving an environmental background and a
residual hurricane field for GAHM2026's gridded environmental mode. When `env_info.type = 3`, `run_GAHM2026`
automatically runs this preprocessing step if the configured MAT-file does not exist; an existing file is reused.

## Requirements and standalone use

The ERA5 NetCDF input must contain `msl`, `u10`, `v10`, `time`, longitude, and latitude data. The source longitude and
latitude spacing must be uniform and equal. Filtering requires MATLAB's Signal Processing Toolbox (`designfilt` and
`filtfilt`), and storm selection requires the configured IBTrACS track file.

From the repository root, run the default Florence configuration independently with:

```matlab
addpath("SeparateEnvHur")
env_vals = SeparateEnvHur("config/config_GAHM2026_default");
```

See [Configuration]({{ '/configuration/' | relative_url }}) for the unified settings and automatic pipeline usage.

## How separation works

- The **filter domain** is the larger storm-centered square used to estimate the background; the **output domain** is
  the smaller square saved in the result and used for cutline searches.
- At each time, the pressure center is the minimum sea-level pressure within the configured search radius around the
  best-track position.
- Polar interpolation finds an outer cutline at the configured 10 m/s wind threshold and an inner cutline at 34 kt
  (about 17.5 m/s). The cutlines are smoothed circularly across the azimuth seam.
- A separate, independently configured filter isotach determines the filter radius; it is not tied to either cutline.
- A Butterworth spatial filter uses that radius and the half-power multiplier to estimate environmental pressure and
  wind on the larger domain.
- The outer and inner cutlines form `Vortex_mask` and `Vortex_mask_inner`, which downstream type-3 blending uses.
- Subtracting the filtered environmental fields from total ERA5 fields produces the residual hurricane pressure and
  wind fields.

## Output contract

The default configuration writes `output/FLORENCE_AL06_2018.mat`. Its top-level variable is `env_vals`, containing
time and grid coordinates (`Time`, `Lo`, `La`), environmental fields (`env_msl`, `env_u10`, `env_v10`), residual
hurricane fields (`hur_msl`, `hur_u10`, `hur_v10`), inner and outer masks, track and pressure-center coordinates, and
cutline distances. See [Outputs]({{ '/outputs/' | relative_url }}) for the concise pipeline contract, then use
[Plotting and Diagnostics]({{ '/plotting/' | relative_url }}) to inspect the components.

For all configuration fields and implementation details, read the
[full SeparateEnvHur README](https://github.com/RENCI/GAHM2026/blob/main/SeparateEnvHur/README.md).
