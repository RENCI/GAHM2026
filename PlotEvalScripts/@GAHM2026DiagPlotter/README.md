# GAHM2026DiagPlotter — Unified Plotting & Diagnostics Class

A `handle` class for plotting and evaluating GAHM2026 output. Accepts data from
either `run_GAHM2026` (Result struct) or the SeparateEnvHur pipeline (.mat file
or pre-loaded struct).

## Quick Start

### From run_GAHM2026 output

```matlab
addpath('PlotEvalScripts')
R   = run_GAHM2026('config_GAHM2026_default');
obj = GAHM2026DiagPlotter(R);

% Contour map at timestep 5
fig = obj.contourMap('mvelcon', 1, 5);

% Radial profiles with multiple field overlays
obj.radialProfile('velrad', {'envhur','env','trackdata'}, 1, 3);

% Time-series diagnostics
obj.timeSeriesPlot({'Vmax','Pc','Rmax'}, 10);

% Export
obj.exportFigure(fig, 'Florence_wind_t5');
```

### From SeparateEnvHur output

```matlab
addpath('PlotEvalScripts')
obj = GAHM2026DiagPlotter.fromSepEnvHur('separated.mat');

% Plot environmental + hurricane combined
obj.contourMap('mvelcon', 1, 5);

% Plot env-only with different color limits
obj.setOpts('wind', 'clims', [0 16]);
obj.contourMap('velcon', 2, 5, obj.EnvData);

% Difference map: env minus hurricane
obj.differenceMap(obj.EnvData, obj.HurData, 'speed', 3, 5);
```

## Constructors

| Constructor | Description |
|---|---|
| `GAHM2026DiagPlotter(Result)` | From `run_GAHM2026` Result struct |
| `GAHM2026DiagPlotter(Result, opts)` | With custom options |
| `GAHM2026DiagPlotter.fromSepEnvHur(sepfile)` | From SeparateEnvHur `.mat` file or struct |
| `GAHM2026DiagPlotter.fromSepEnvHur(sepfile, opts)` | With custom options |

## Public Methods

### Plotting

| Method | Description |
|---|---|
| `contourMap(plotType, figNum, time, plotdata)` | Contour map: `'velcon'`, `'precon'`, `'prequiv'`, `'mvelcon'`, `'mprecon'` |
| `addQuiver(time, plotdata)` | Overlay velocity vectors |
| `radialProfile(plotType, fieldType, figNum, time, theta_inc)` | Radial profiles with multi-overlay support |
| `timeSeriesPlot(fields, figNum)` | Storm parameter time-series |
| `differenceMap(fieldA, fieldB, variable, figNum, time)` | Difference map between two field sets |
| `scatterCompare(X, Y, figNum, ...)` | 1:1 scatter with optional metrics annotation |
| `animate(plotType, figNum, plotdata, filename)` | GIF/MP4 animation |
| `exportFigure(fig, filename)` | Save to PNG or PDF |

### Diagnostics

| Method | Description |
|---|---|
| `computeMetrics(X, Y, varName)` | Bias, RMSE, MAE, R, R², SI with optional CSV export |

### Utility

| Method | Description |
|---|---|
| `setOpts(group, field, value)` | Override one option |
| `resetOpts()` | Restore defaults |
| `syncDatetime(A, B)` | Match two struct arrays by `.datetime` |

## Dependent Properties

| Property | Description |
|---|---|
| `PlotData` | Default TC fields (`Reggrid_TC_out`) |
| `DataGrid` | Grid coordinates (`Reggrid_out`) |
| `Trackdata` | Storm track data |
| `RadialGrid` | Radial grid data (empty for SepEnvHur) |
| `EnvData` | Environmental fields |
| `HurData` | Hurricane-only fields (SepEnvHur) |
| `HasRadialGrid` | Boolean: radial data available? |

## radialProfile — fieldType Options

`fieldType` can be a single string or a cell array for multi-overlay:

| fieldType | Data source | Legend label |
|---|---|---|
| `'envhur'` | `EnvVor_bt` | E+H |
| `'envhur_final'` | `EnvHur_final` | E+H Final |
| `'vor_bt'` | `VVor_bt` | Vor b/t |
| `'vor_at'` | `VVor_at` | Vor a/t |
| `'envvor_bt'` | `EnvVor_bt` | E+V b/t |
| `'env'` | `Env` | Env |
| `'trackdata'` | Trackdata markers | Vmax/isotachs |

Example with multiple overlays:
```matlab
obj.radialProfile('velrad', {'envhur_final','vor_bt','env','trackdata'}, 1, 3, 2);
```

## timeSeriesPlot — Field Options

| Field | Source | Units |
|---|---|---|
| `'Vmax'` | `Trackdata.Vmax_t1` | knots |
| `'Pc'` | `Trackdata.MSLP` or `.Pc` | mb |
| `'Rmax'` | `Trackdata.Rmax_t1` | nm |
| `'Rmax34'` | `max(RQuad_t1(:,1))` | nm |
| `'Rmax50'` | `max(RQuad_t1(:,2))` | nm |
| `'Rmax64'` | `max(RQuad_t1(:,3))` | nm |

## Options (plot_defaults.m)

| Group | Fields |
|---|---|
| `domain` | `.mode`, `.padDeg`, `.fixedLimits` |
| `wind` | `.clims`, `.alpha`, `.colormap` |
| `pres` | `.clims`, `.alpha`, `.colormap` |
| `quiver` | `.stride`, `.scale`, `.color` |
| `coast` | `.show`, `.color`, `.linewidth` |
| `track` | `.color`, `.linewidth`, `.progressive` |
| `radial` | `.isotachs`, `.one2ten`, `.layout` |
| `mask` | `.show`, `.color`, `.linewidth` |
| `anim` | `.gif`, `.mp4`, `.frameRate` |
| `export` | `.dir`, `.format`, `.dpi` |
| `diffmap` | `.colormap`, `.clims` |
| `scatter` | `.showMetrics`, `.csvFile` |
| `timeseries` | `.linewidth`, `.marker`, `.markersize` |
| `time` | `.format` |

## File Listing

```
@GAHM2026DiagPlotter/
├── GAHM2026DiagPlotter.m     (classdef)
├── contourMap.m              (public)
├── addQuiver.m               (public)
├── radialProfile.m           (public — multi-overlay merge)
├── timeSeriesPlot.m          (public — new)
├── differenceMap.m           (public — new)
├── computeMetrics.m          (public — new)
├── scatterCompare.m          (public — metrics annotation)
├── animate.m                 (public)
├── exportFigure.m            (public)
├── syncDatetime.m            (public)
├── fromSepEnvHur.m           (static factory)
├── resolveTime.m             (private)
├── resolveRadialTime.m       (private)
├── getDomain.m               (private)
├── plotTrack.m               (private)
├── plotMaskContours.m        (private)
├── captureGifFrame.m         (private)
├── openMp4.m                 (private)
└── README.md                 (this file)
```
