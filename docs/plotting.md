---
layout: default
title: Plotting and Diagnostics
nav_order: 7
permalink: /plotting/
---

# Plotting and Diagnostics

`GAHM2026Plotter` provides maps, radial profiles, time-series diagnostics, comparisons, metrics, animation, and figure
export for a `Result` returned by `run_GAHM2026`.

## Start with a GAHM2026 result

From the repository root, add the plotting directory and construct the plotter:

```matlab
R = run_GAHM2026("config_GAHM2026_default");
addpath("PlotEvalScripts")
plotter = GAHM2026Plotter(R);
```

These examples use timestep 5 from the default run where a time argument is required:

```matlab
% Wind and pressure contours
windFigure = plotter.contourMap("mvelcon", 1, 5);
pressureFigure = plotter.contourMap("mprecon", 2, 5);

% Radial wind profiles: final blend, untapered vortex, environment, and track markers
plotter.radialProfile("velrad", ...
    {"envhur_final", "vor_bt", "env", "trackdata"}, 3, 5, 2);

% Track-parameter time series
timeFigure = plotter.timeSeriesPlot({"Vmax", "Pc", "Rmax"}, 4);

% Final tropical-cyclone field minus environment-only wind speed
differenceFigure = plotter.differenceMap( ...
    R.Reggrid_TC_out, R.Reggrid_Env_out, "speed", 5, 5);

% Paired-array objective diagnostics
observed = [42, 50, 61, 70, 78];
modeled = [44, 49, 63, 68, 81];
metrics = plotter.computeMetrics(observed, modeled, "Wind Speed (kts)");

% Animate all timesteps
plotter.animate("mvelcon", 6);
```

With the default options, animation writes `output/GAHM_V.gif` and `output/GAHM_V.mp4`. `computeMetrics` returns the
valid-pair count, bias, RMSE, MAE, correlation, R-squared, scatter index, and variable label. Time arguments may also
be `datetime` values; consult the references below for all plot types, field selections, and options.

## Plot SeparateEnvHur components

Load the default intermediate directly:

```matlab
addpath("PlotEvalScripts")
plotter = GAHM2026Plotter.fromSepEnvHur("output/FLORENCE_AL06_2018.mat");

plotter.contourMap("mvelcon", 1, 5);                    % PlotData
plotter.contourMap("velcon", 2, 5, plotter.EnvData);   % environment only
plotter.contourMap("velcon", 3, 5, plotter.HurData);   % residual hurricane only
plotter.differenceMap(plotter.EnvData, plotter.HurData, "speed", 4, 5);
```

For SeparateEnvHur input, `PlotData` is the combined environmental plus residual-hurricane field reconstructed from
ERA5, `EnvData` is the filtered environmental component, and `HurData` is the residual hurricane component. This
source has no radial grid, so `radialProfile` is unavailable. See the
[SeparateEnvHur guide]({{ '/separate-env-hur/' | relative_url }}) and [Outputs]({{ '/outputs/' | relative_url }}) for
the source MAT-file contract.

## Complete reference

The detailed references list every method, plot type, field selector, and option:

- [PlotEvalScripts workflow and method reference](https://github.com/RENCI/GAHM2026/blob/main/PlotEvalScripts/README.md)
- [GAHM2026Plotter class reference](https://github.com/RENCI/GAHM2026/blob/main/PlotEvalScripts/%40GAHM2026Plotter/README.md)
