---
layout: default
title: Home
nav_order: 1
permalink: /
---

# GAHM2026

GAHM2026 is a MATLAB implementation of the Generalized Asymmetric Holland Model for producing parametric tropical
cyclone wind and pressure fields from observed or forecast storm tracks. It was developed by Rick Luettich
(UNC/IMS/CNHR/EMES) and Brian Blanton (UNC/RENCI).

## Capabilities

- Builds asymmetric parametric wind and pressure fields with quadrant-specific model parameters and isotach radii.
- Supports three environmental-flow modes: ADCIRC/ASWIP translation velocity, the Lin and Chavas (2012)
  formulation, or gridded fields prepared with SeparateEnvHur.
- Produces gridded NetCDF fields or evaluates wind and pressure at requested points.
- Optionally applies a land-roughness Wind Adjustment Factor (WAF).
- Provides diagnostics and plotting tools for maps, radial profiles, comparisons, and animations.

## Pipeline at a glance

1. `run_GAHM2026` loads the storm track and unified configuration.
2. GAHM solves the asymmetric vortex parameters and computes radial wind and pressure profiles.
3. For gridded environmental mode, SeparateEnvHur can prepare ERA5-derived fields for blending with the parametric
   vortex.
4. The pipeline interpolates the result to a regular grid or requested points, applies optional WAF processing, and
   returns diagnostics while writing configured outputs.

## Quick start

From the repository root, run the default Florence example:

```matlab
R = run_GAHM2026;
```

The default configuration uses Florence (2018). If its SeparateEnvHur intermediate file is absent, the driver creates
it before continuing.

## Continue with the guides

- [Getting Started]({{ '/getting-started/' | relative_url }}) — install requirements and run the first example.
- [GAHM Derivation]({{ '/gahm-derivation/' | relative_url }}) — understand the model equations and assumptions.
- [Configuration]({{ '/configuration/' | relative_url }}) — select a storm, environmental mode, and output settings.
- [Outputs]({{ '/outputs/' | relative_url }}) — interpret returned structures and generated files.
- [SeparateEnvHur]({{ '/separate-env-hur/' | relative_url }}) — prepare and blend gridded environmental fields.
- [Plotting and Diagnostics]({{ '/plotting/' | relative_url }}) — inspect maps, profiles, comparisons, and animations.

## Repository references

- [Project README](https://github.com/RENCI/GAHM2026/blob/main/README.md)
- [Complete configuration reference](https://github.com/RENCI/GAHM2026/blob/main/documentation/README_config.md)
- [Execution call tree](https://github.com/RENCI/GAHM2026/blob/main/documentation/CALL_TREE.md)
- [GAHM data structure](https://github.com/RENCI/GAHM2026/blob/main/documentation/GAHM_struct.md)
- [SeparateEnvHur reference](https://github.com/RENCI/GAHM2026/blob/main/SeparateEnvHur/README.md)
- [Plotting class reference](https://github.com/RENCI/GAHM2026/blob/main/PlotEvalScripts/README.md)
