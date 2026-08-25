---
layout: default
title: Plotting
nav_order: 9
permalink: /plotting/
---

# Plotting and diagnostics
{: .no_toc }

The `GAHM2026Plotter` class.

1. TOC
{:toc}

---

`GAHM2026Plotter` is a unified plotting and diagnostics class that accepts output from
`run_GAHM2026` *or* from [SeparateEnvHur]({{ site.baseurl }}/separate-env-hur/). It provides
contour maps, radial profiles with multi-overlay, difference maps, time-series diagnostics,
scatter comparisons with objective metrics, animation, and figure export.

It needs **no toolboxes** — everything uses built-in MATLAB capability. The coastline overlay uses
MATLAB's built-in `coastlines` dataset.

The original function-based scripts still exist under `PlotEvalScripts/legacy/`; they operate on
individual workspace variables and are superseded by the class.

```matlab
addpath('PlotEvalScripts')
obj = GAHM2026Plotter(R);
```

## Constructors

| Constructor | From |
|---|---|
| `GAHM2026Plotter(Result)` | A `run_GAHM2026` result struct |
| `GAHM2026Plotter(Result, opts)` | …with a custom options struct |
| `GAHM2026Plotter.fromSepEnvHur(sepfile)` | A SeparateEnvHur `.mat` file or a preloaded struct |
| `GAHM2026Plotter.fromSepEnvHur(sepfile, opts)` | …with a custom options struct |

## Methods

### Plotting

| Method | Description |
|---|---|
| `contourMap(plotType, figNum, time, plotdata)` | Contour map (`pcolor`) of wind speed or pressure at one time |
| `addQuiver(time, plotdata)` | Overlay velocity vectors on the current axes |
| `radialProfile(plotType, fieldType, figNum, time, theta_inc)` | Radial profiles, with multi-overlay |
| `timeSeriesPlot(fields, figNum)` | Storm parameters over time in a linked tiled layout |
| `differenceMap(fieldA, fieldB, variable, figNum, time)` | A minus B on a diverging colormap |
| `scatterCompare(X, Y, figNum, title, xlabel, ylabel, legend)` | 1:1 scatter, optionally annotated with metrics |
| `animate(plotType, figNum, plotdata, filename)` | GIF/MP4 over all times |
| `exportFigure(fig, filename)` | Save to PNG or PDF |

### Diagnostics and utilities

| Method | Description |
|---|---|
| `computeMetrics(X, Y, varName)` | Bias, RMSE, MAE, R, R², scatter index; optional CSV append |
| `setOpts(group, field, value)` | Override a single option |
| `resetOpts()` | Restore all defaults |
| `syncDatetime(A, B)` | Match datetime indices between two struct arrays |

## Plot types

| `plotType` | Used by | Description |
|---|---|---|
| `'velcon'` | `contourMap` | Wind speed contours with velocity vectors |
| `'precon'` | `contourMap` | Pressure contours |
| `'prequiv'` | `contourMap` | Pressure contours with velocity vectors |
| `'mvelcon'` | `contourMap` | Wind speed contours with mask boundary lines |
| `'mprecon'` | `contourMap` | Pressure contours with mask boundary lines |
| `'velrad'` | `radialProfile` | Radial velocity profiles with isotach markers |
| `'prerad'` | `radialProfile` | Radial pressure profiles |

## The `time` argument

`contourMap`, `addQuiver`, `radialProfile`, and `differenceMap` all accept:

| Type | Example | Behavior |
|---|---|---|
| integer | `5` | Timestep index 5 |
| `datetime` | `datetime(2018,9,14,12,0,0)` | Nearest available time |
| `[]` or omitted | | Timestep 1 |

## Worked examples

Using Hurricane Florence as configured in `config/config_GAHM2026_default.m`. Florence made
landfall near Wrightsville Beach, NC on 14 September as a Category 1 hurricane.

```matlab
R   = run_GAHM2026('config_GAHM2026_default');
obj = GAHM2026Plotter(R);
```

**Contour maps.** Blended TC wind with mask boundaries near landfall, then pressure, then pressure
with vectors:

```matlab
fig = obj.contourMap('mvelcon', 1, 20);
fig = obj.contourMap('mvelcon', 1, datetime(2018,9,14,12,0,0));  % same, by datetime
fig = obj.contourMap('mprecon', 2, 20);
fig = obj.contourMap('prequiv', 3, 20);
```

Vectors can be added to any existing plot:

```matlab
fig = obj.contourMap('precon', 4, 20);
obj.addQuiver(20);
```

**A different field.** Pass an alternate data struct last:

```matlab
fig = obj.contourMap('mvelcon', 5, 20, R.Reggrid_Env_out);              % environmental only
fig = obj.contourMap('mvelcon', 6, 20, R.Reggrid_VVor_invtapHur_out);   % vortex + inv-taper hurricane
```

**Radial profiles.** `fieldType` may be a single string or a cell array to overlay several:

```matlab
obj.radialProfile('velrad', {'envhur_final','vor_bt','env','trackdata'}, 1, 3, 2);
obj.radialProfile('velrad', 'envhur', 2, 10);
obj.radialProfile('prerad', {'envhur_final','env'}, 3, 20, 4);   % every 4th azimuth
```

| `fieldType` | Source | Legend | Style |
|---|---|---|---|
| `'envhur'` | `EnvVor_bt` | E+H | solid |
| `'envhur_final'` | `EnvHur_final` | E+H Final | solid |
| `'vor_bt'` | `VVor_bt` | Vor b/t | solid |
| `'vor_at'` | `VVor_at` | Vor a/t | solid |
| `'envvor_bt'` | `EnvVor_bt` | E+V b/t | solid |
| `'env'` | `Env` | Env | dashed black |
| `'trackdata'` | Track markers | Vmax / isotachs | `*` and `o`/`x` |

**Time series.**

```matlab
fig = obj.timeSeriesPlot({'Vmax','Pc','Rmax'}, 10);
fig = obj.timeSeriesPlot({'Vmax','Pc','Rmax','Rmax34','Rmax50','Rmax64'}, 11);
```

Available fields: `'Vmax'` (kt), `'Pc'` (mb), `'Rmax'` (nm), and `'Rmax34'`/`'Rmax50'`/`'Rmax64'`,
the maximum isotach radius across quadrants (nm).

**Difference maps.** `variable` is `'speed'` (knots) or `'press'` (mb):

```matlab
fig = obj.differenceMap(R.Reggrid_TC_out, R.Reggrid_Env_out, 'speed', 1, 20);
obj.setOpts('diffmap', 'colormap', 'rdbu');
obj.setOpts('diffmap', 'clims', [-30 30]);
fig = obj.differenceMap(R.Reggrid_TC_out, R.Reggrid_Env_out, 'press', 2, 20);
```

**Metrics and scatter.** `computeMetrics` returns `N`, `bias`, `RMSE`, `MAE`, `R`, `R2`, `SI`, and
`varName`; NaN and zero pairs are dropped. Setting `csvFile` appends a row per call, writing the
header on first use.

```matlab
obj.setOpts('scatter', 'csvFile', 'metrics.csv');
metrics = obj.computeMetrics(observed, modeled, 'Wind Speed (kts)');

obj.setOpts('scatter', 'showMetrics', true);
fig = obj.scatterCompare(X, Y, 1, ...
    'Florence 2018  Rmax Comparison for 34kt isotach', ...
    'Rmax GAHM2026 (nm)', 'Rmax ASWIP (nm)');
```

An N×4 input is plotted by quadrant with NE/SE/SW/NW colors automatically; an N×K input with
explicit labels is plotted by series:

```matlab
obj.scatterCompare(X2, Y2, 2, 'Florence 2018  Rmax Comparison', ...
    'Rmax computed (nm)', 'Rmax NHC (nm)', {'BLF=0.75','BLF=0.90'});
```

**Animation and export.**

```matlab
obj.animate('mvelcon', 1);                     % GAHM_V.gif and GAHM_V.mp4
obj.setOpts('anim', 'mp4', false);
obj.animate('mprecon', 1, [], 'Florence_P');   % Florence_P.gif only

fig = obj.contourMap('mvelcon', 1, 20);
obj.exportFigure(fig, 'Florence_wind_t20');    % output/Florence_wind_t20.png
obj.setOpts('export', 'format', 'pdf');
obj.exportFigure(fig, 'Florence_wind_t20');    % output/Florence_wind_t20.pdf
```

## Plotting SeparateEnvHur output

`fromSepEnvHur` normalizes an `env_vals` struct into the same shape a `Result` has, so every
method works:

```matlab
obj = GAHM2026Plotter.fromSepEnvHur('separated.mat');   % or a preloaded struct
```

| Property | Contents |
|---|---|
| `PlotData` | Environmental + hurricane combined (total ERA5) |
| `EnvData` | Environmental component only |
| `HurData` | Hurricane component only |
| `DataGrid` | Grid coordinates and vortex masks (`MaskInner`, `MaskOuter`) |
| `Trackdata` | Best-track lon/lat/datetime |

Sensible color limits per component are carried in `Result.sep_opts`:

```matlab
obj.setOpts('wind', 'clims', obj.Result.sep_opts.env.wind.clims);   % [0 16]
obj.contourMap('velcon', 1, 5, obj.EnvData);

obj.setOpts('wind', 'clims', obj.Result.sep_opts.hur.wind.clims);   % [0 50]
obj.contourMap('velcon', 2, 5, obj.HurData);

obj.differenceMap(obj.EnvData, obj.HurData, 'speed', 3, 5);
```

{: .note }
> `radialProfile` is unavailable for SeparateEnvHur data — no `VPrad` struct is produced. The
> `HasRadialGrid` property returns `false` in that case.

## Options

All behavior is controlled by an options struct managed by `plot_defaults()`. Override a single
field with `setOpts(group, field, value)` and restore everything with `resetOpts()`.

```matlab
obj.setOpts('wind', 'clims', [0 100]);
obj.setOpts('domain', 'mode', 'moving');
obj.setOpts('coast', 'color', [0.4 0.4 0.4]);
obj.setOpts('track', 'progressive', false);
obj.resetOpts();
```

| Group | Fields |
|---|---|
| `domain` | `.mode` (`'moving'` follows the storm, or `'fixed'`), `.padDeg`, `.fixedLimits` |
| `wind` | `.clims` (kt), `.alpha`, `.colormap` |
| `pres` | `.clims` (mb), `.alpha`, `.colormap` |
| `quiver` | `.stride`, `.scale`, `.color` |
| `coast` | `.show`, `.color`, `.linewidth` |
| `track` | `.color`, `.linewidth`, `.progressive` |
| `radial` | `.isotachs`, `.one2ten`, `.layout` |
| `mask` | `.show`, `.color`, `.linewidth` |
| `anim` | `.gif`, `.mp4`, `.frameRate` |
| `export` | `.dir`, `.format` (`'png'`/`'pdf'`/`'none'`), `.dpi` |
| `diffmap` | `.colormap` (default `'rdbu'`), `.clims` (`[]` = auto-symmetric) |
| `scatter` | `.showMetrics`, `.csvFile` |
| `timeseries` | `.linewidth`, `.marker`, `.markersize` |
| `time` | `.format` |

Current default values are in `PlotEvalScripts/plot_defaults.m`.

## Dependent properties

| Property | Contents |
|---|---|
| `PlotData` | Default TC fields (`Reggrid_TC_out`) |
| `DataGrid` | Grid coordinates (`Reggrid_out`) |
| `Trackdata` | Storm track data |
| `RadialGrid` | Radial grid data (`VPrad`; empty for SeparateEnvHur input) |
| `EnvData` | Environmental fields (`Reggrid_Env_out`) |
| `HurData` | Hurricane-only fields (SeparateEnvHur input only) |
| `HasRadialGrid` | Whether radial data is available |

---

The class-level reference in `PlotEvalScripts/README.md` carries the exhaustive file listing and
the legacy script inventory.
