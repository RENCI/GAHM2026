# GAHM2026 Graphics, Diagnostics, and Visualization

Plotting and evaluation tools for GAHM2026 output fields, radial profiles, parameter comparisons, and objective diagnostics.

There are two ways to produce plots:

1. **`GAHM2026Plotter` class** (recommended) — unified plotting and diagnostics class that accepts output from `run_GAHM2026` *or* from the SeparateEnvHur pipeline.  Provides contour maps, radial profiles (with multi-overlay), scatter comparisons, animation, figure export, time-series diagnostics, difference maps, objective metrics (bias, RMSE, MAE, R², scatter index), and CSV export.
2. **Standalone scripts** (legacy) — the original function-based scripts (`conplot_GAHM2026.m`, `radplot_GAHM2026.m`, etc.) that operate on individual workspace variables.

Both approaches share the same `plot_defaults.m` options struct.

---

## Table of Contents

- [Quick Start — Florence 2018 Demonstration](#quick-start--florence-2018-demonstration)
- [SeparateEnvHur Workflow](#separateenvhur-workflow)
- [GAHM2026Plotter Constructors](#gahm2026plotter-constructors)
- [GAHM2026Plotter Method Reference](#gahm2026plotter-method-reference)
- [Plot Types](#plot-types)
- [Radial Profile — fieldType Options](#radial-profile--fieldtype-options)
- [Time-Series — Field Options](#time-series--field-options)
- [Difference Map — variable Options](#difference-map--variable-options)
- [Computed Metrics](#computed-metrics)
- [Time Argument](#time-argument)
- [Dependent Properties](#dependent-properties)
- [Options Reference](#options-reference)
- [Legacy Scripts](#legacy-scripts)
- [File Listing](#file-listing)
- [Dependencies](#dependencies)

---

## Quick Start — Florence 2018 Demonstration

The following walkthrough uses Hurricane Florence (2018) as configured in `config/config_GAHM2026_default.m`.  Florence made landfall near Wrightsville Beach, NC on September 14 as a Category 1 hurricane.

### 1. Run the model

```matlab
R = run_GAHM2026('config_GAHM2026_default');
```

`run_GAHM2026` returns a `Result` struct containing all output:

| Field | Contents |
|-------|----------|
| `R.Reggrid_out` | Grid coordinates (`.Lon`, `.Lat`), `.datetime`, `.Mask1`, `.Mask2` |
| `R.Reggrid_TC_out` | Final blended TC fields: `.VelU`, `.VelV` (m/s), `.Press` (mb) |
| `R.Reggrid_Env_out` | Environmental fields: `.VelU`, `.VelV` (m/s), `.Press` (mb) |
| `R.Reggrid_VVor_invtapHur_out` | GAHM vortex + inverse-tapered hurricane (env_type=3 only) |
| `R.Trackdata` | Storm track data with Rmax, Vmax, quadrant info |
| `R.GAHM_out` | Per-timestep GAHM parameters |
| `R.VPrad` | Radial grid data: `.r`, `.theta`, `.VVor_bt(i)`, `.VVor_at(i)`, `.Env(i)`, `.EnvVor_bt(i)`, `.EnvHur_final(i)` |
| `R.storm_info` | Storm identity (name, year, designation) |
| `R.env_info` | Environmental field configuration |

### 2. Create the plotter

```matlab
addpath('PlotEvalScripts')
obj = GAHM2026Plotter(R);
```

### 3. Wind speed contour map (single timestep)

Plot the blended TC wind field with mask boundary lines at the 20th timestep (approximately Sep 14, 2018 near landfall):

```matlab
fig = obj.contourMap('mvelcon', 1, 20);
```

The `time` argument accepts an integer index, a `datetime` value, or `[]` (defaults to timestep 1):

```matlab
% by datetime
fig = obj.contourMap('mvelcon', 1, datetime(2018,9,14,12,0,0));
```

### 4. Pressure contour map

```matlab
fig = obj.contourMap('mprecon', 2, 20);
```

### 5. Pressure contours with wind vectors

```matlab
fig = obj.contourMap('prequiv', 3, 20);
```

To add vectors to any existing plot use `addQuiver`:

```matlab
fig = obj.contourMap('precon', 4, 20);    % pressure map, no vectors
obj.addQuiver(20);                        % overlay wind vectors
```

### 6. Plot a different field

Pass an alternate data struct as the last argument:

```matlab
% environmental wind field
fig = obj.contourMap('mvelcon', 5, 20, R.Reggrid_Env_out);

% GAHM vortex + inverse-tapered hurricane field
fig = obj.contourMap('mvelcon', 6, 20, R.Reggrid_VVor_invtapHur_out);
```

### 7. Radial profiles with multi-overlay

Plot multiple field types overlaid on the same subplot panels.  Pass `fieldType` as a cell array:

```matlab
% env+hurricane final, vortex before taper, env-only, and track markers
obj.radialProfile('velrad', {'envhur_final','vor_bt','env','trackdata'}, 1, 3, 2);
```

Single field type (backward compatible):

```matlab
obj.radialProfile('velrad', 'envhur', 2, 10);
```

Pressure profiles (every 4th azimuth):

```matlab
obj.radialProfile('prerad', {'envhur_final','env'}, 3, 20, 4);
```

### 8. Time-series diagnostics

Plot storm parameters over time in a linked tiled layout:

```matlab
fig = obj.timeSeriesPlot({'Vmax','Pc','Rmax'}, 10);
```

Include isotach radii:

```matlab
fig = obj.timeSeriesPlot({'Vmax','Pc','Rmax','Rmax34','Rmax50','Rmax64'}, 11);
```

### 9. Difference maps

Compare two gridded field sets (A minus B) on a diverging colormap:

```matlab
% wind speed difference between TC output and env-only
fig = obj.differenceMap(R.Reggrid_TC_out, R.Reggrid_Env_out, 'speed', 1, 20);

% pressure difference
fig = obj.differenceMap(R.Reggrid_TC_out, R.Reggrid_Env_out, 'press', 2, 20);
```

Control the colormap and color limits:

```matlab
obj.setOpts('diffmap', 'colormap', 'rdbu');
obj.setOpts('diffmap', 'clims', [-30 30]);
fig = obj.differenceMap(R.Reggrid_TC_out, R.Reggrid_Env_out, 'speed', 3, 20);
```

### 10. Objective metrics

Compute bias, RMSE, MAE, R, R², and scatter index between two datasets:

```matlab
metrics = obj.computeMetrics(observed, modeled, 'Wind Speed (kts)');
```

Output struct fields: `N`, `bias`, `RMSE`, `MAE`, `R`, `R2`, `SI`, `varName`.

Export metrics to CSV by setting the scatter option:

```matlab
obj.setOpts('scatter', 'csvFile', 'metrics.csv');
m1 = obj.computeMetrics(obsV, modV, 'Vmax');
m2 = obj.computeMetrics(obsP, modP, 'Pc');
% → rows appended to metrics.csv with header on first write
```

### 11. Scatter comparison with metrics annotation

Enable automatic metrics annotation on scatter plots:

```matlab
obj.setOpts('scatter', 'showMetrics', true);
fig = obj.scatterCompare(X, Y, 1, ...
    'Florence 2018  Rmax Comparison for 34kt isotach', ...
    'Rmax GAHM2026 (nm)', 'Rmax ASWIP (nm)');
```

By-quadrant mode (N×4 matrices) uses NE/SE/SW/NW colors automatically.  By-series mode (N×K with explicit legend labels) is also supported:

```matlab
obj.scatterCompare(X2, Y2, 2, ...
    'Florence 2018  Rmax Comparison', ...
    'Rmax computed (nm)', 'Rmax NHC (nm)', {'BLF=0.75','BLF=0.90'});
```

### 12. Animation

Generate a GIF and MP4 of the wind field over all timesteps:

```matlab
obj.animate('mvelcon', 1);
```

Output files: `GAHM_V.gif` and `GAHM_V.mp4`.

Control animation settings and provide a custom filename:

```matlab
obj.setOpts('anim', 'mp4', false);           % GIF only
obj.animate('mprecon', 1, [], 'Florence_P');  % → Florence_P.gif
```

### 13. Export figures

Save figures to PNG or PDF:

```matlab
fig = obj.contourMap('mvelcon', 1, 20);
obj.exportFigure(fig, 'Florence_wind_t20');   % → output/Florence_wind_t20.png

obj.setOpts('export', 'format', 'pdf');
obj.exportFigure(fig, 'Florence_wind_t20');   % → output/Florence_wind_t20.pdf
```

### 14. Customizing options

All plotting behaviour is controlled by the `opts` struct.  Override individual fields with `setOpts` or restore defaults with `resetOpts`:

```matlab
obj.setOpts('wind', 'clims', [0 100]);
obj.setOpts('domain', 'mode', 'moving');
obj.setOpts('coast', 'color', [0.4 0.4 0.4]);
obj.setOpts('track', 'progressive', false);

% restore everything
obj.resetOpts();
```

---

## SeparateEnvHur Workflow

`GAHM2026Plotter` can ingest SeparateEnvHur output directly via the `fromSepEnvHur` static factory method.  This normalizes the `env_vals` struct into the same `Result` format used by `run_GAHM2026`, enabling all plotting methods.

```matlab
obj = GAHM2026Plotter.fromSepEnvHur('separated.mat');
```

The factory accepts a `.mat` filename (containing `env_vals`) or a pre-loaded struct.  It creates:

| Property | Contents |
|----------|----------|
| `PlotData` | Environmental + hurricane combined (total ERA5) |
| `EnvData` | Environmental component only |
| `HurData` | Hurricane component only |
| `DataGrid` | Grid coordinates and vortex masks (`MaskInner`, `MaskOuter`) |
| `Trackdata` | Best-track lon/lat/datetime |

Default colour-limit presets for each component are stored in `Result.sep_opts`:

```matlab
% Plot env-only with appropriate color scale
obj.setOpts('wind', 'clims', obj.Result.sep_opts.env.wind.clims);  % [0 16]
obj.contourMap('velcon', 1, 5, obj.EnvData);

% Hurricane-only
obj.setOpts('wind', 'clims', obj.Result.sep_opts.hur.wind.clims);  % [0 50]
obj.contourMap('velcon', 2, 5, obj.HurData);

% Difference map: env vs hurricane wind speed
obj.differenceMap(obj.EnvData, obj.HurData, 'speed', 3, 5);
```

**Note:** Radial-grid methods (`radialProfile`) are not available for SeparateEnvHur data since no `VPrad` struct is produced.  The `HasRadialGrid` property returns `false` in this case.

---

## GAHM2026Plotter Constructors

| Constructor | Description |
|-------------|-------------|
| `GAHM2026Plotter(Result)` | From `run_GAHM2026` Result struct |
| `GAHM2026Plotter(Result, opts)` | With custom options struct |
| `GAHM2026Plotter.fromSepEnvHur(sepfile)` | From SeparateEnvHur `.mat` file or struct |
| `GAHM2026Plotter.fromSepEnvHur(sepfile, opts)` | With custom options |

---

## GAHM2026Plotter Method Reference

### Plotting Methods

| Method | Description |
|--------|-------------|
| `contourMap(plotType, figNum, time, plotdata)` | Contour map (pcolor) of wind speed or pressure at one timestep |
| `addQuiver(time, plotdata)` | Overlay velocity vectors on the current axes |
| `radialProfile(plotType, fieldType, figNum, time, theta_inc)` | Radial profiles with multi-overlay support |
| `timeSeriesPlot(fields, figNum)` | Storm parameter time-series in tiled layout |
| `differenceMap(fieldA, fieldB, variable, figNum, time)` | Difference map (A minus B) with diverging colormap |
| `scatterCompare(X, Y, figNum, title, xlabel, ylabel, legend)` | 1:1 scatter plot with optional metrics annotation |
| `animate(plotType, figNum, plotdata, filename)` | GIF/MP4 animation over all timesteps |
| `exportFigure(fig, filename)` | Save figure to PNG or PDF |

### Diagnostic Methods

| Method | Description |
|--------|-------------|
| `computeMetrics(X, Y, varName)` | Compute bias, RMSE, MAE, R, R², scatter index; optional CSV export |

### Utility Methods

| Method | Description |
|--------|-------------|
| `setOpts(group, field, value)` | Override a single option |
| `resetOpts()` | Restore all options to defaults |
| `syncDatetime(A, B)` | Find matching datetime indices between two struct arrays |

### Static Methods

| Method | Description |
|--------|-------------|
| `fromSepEnvHur(sepfile, opts)` | Factory: build plotter from SeparateEnvHur output |

---

## Plot Types

| `plotType` | Used by | Description |
|------------|---------|-------------|
| `'velcon'` | `contourMap` | Wind speed contours with velocity vectors |
| `'precon'` | `contourMap` | Pressure contours |
| `'prequiv'` | `contourMap` | Pressure contours with velocity vectors |
| `'mvelcon'` | `contourMap` | Wind speed contours with mask boundary lines |
| `'mprecon'` | `contourMap` | Pressure contours with mask boundary lines |
| `'velrad'` | `radialProfile` | Radial velocity profiles with isotach markers |
| `'prerad'` | `radialProfile` | Radial pressure profiles |

---

## Radial Profile — `fieldType` Options

`fieldType` can be a single string or a cell array for multi-overlay:

| `fieldType` | Data source | Legend label | Line style |
|-------------|-------------|-------------|------------|
| `'envhur'` | `EnvVor_bt` | E+H | solid, auto-color |
| `'envhur_final'` | `EnvHur_final` | E+H Final | solid, auto-color |
| `'vor_bt'` | `VVor_bt` | Vor b/t | solid, auto-color |
| `'vor_at'` | `VVor_at` | Vor a/t | solid, auto-color |
| `'envvor_bt'` | `EnvVor_bt` | E+V b/t | solid, auto-color |
| `'env'` | `Env` | Env | dashed black (`--k`) |
| `'trackdata'` | Trackdata markers | Vmax/isotachs | `*` and `o`/`x` markers |

Example with multiple overlays:

```matlab
obj.radialProfile('velrad', {'envhur_final','vor_bt','env','trackdata'}, 1, 3, 2);
```

---

## Time-Series — Field Options

| Field | Source | Units |
|-------|--------|-------|
| `'Vmax'` | `Trackdata.Vmax_t1` | knots |
| `'Pc'` | `Trackdata.MSLP` or `.Pc` | mb |
| `'Rmax'` | `Trackdata.Rmax_t1` | nm |
| `'Rmax34'` | `max(RQuad_t1(:,1))` | nm |
| `'Rmax50'` | `max(RQuad_t1(:,2))` | nm |
| `'Rmax64'` | `max(RQuad_t1(:,3))` | nm |

---

## Difference Map — `variable` Options

| `variable` | Computed as | Units |
|------------|-------------|-------|
| `'speed'` | `hypot(A.VelU,A.VelV) - hypot(B.VelU,B.VelV)` | knots |
| `'press'` | `A.Press - B.Press` | mb |

---

## Computed Metrics

`computeMetrics(X, Y, varName)` returns a struct with:

| Field | Description |
|-------|-------------|
| `N` | Number of valid pairs (NaN and zero pairs removed) |
| `bias` | Mean(Y − X) |
| `RMSE` | Root-mean-square error |
| `MAE` | Mean absolute error |
| `R` | Pearson correlation coefficient |
| `R2` | R squared |
| `SI` | Scatter index (RMSE / mean(X)) |
| `varName` | Variable label string |

---

## Time Argument

The `time` parameter in `contourMap`, `addQuiver`, `radialProfile`, and `differenceMap` accepts:

| Type | Example | Behaviour |
|------|---------|-----------|
| integer | `5` | Use timestep index 5 |
| `datetime` | `datetime(2018,9,14,12,0,0)` | Match to nearest available time |
| `[]` or omitted | | Defaults to timestep 1 |

---

## Dependent Properties

| Property | Description |
|----------|-------------|
| `PlotData` | Default TC fields (`Reggrid_TC_out`) |
| `DataGrid` | Grid coordinates (`Reggrid_out`) |
| `Trackdata` | Storm track data |
| `RadialGrid` | Radial grid data (`VPrad`; empty for SepEnvHur) |
| `EnvData` | Environmental fields (`Reggrid_Env_out`) |
| `HurData` | Hurricane-only fields (`Reggrid_Hur_out`; SepEnvHur only) |
| `HasRadialGrid` | Boolean: radial data available? |

---

## Options Reference

Options are managed via `plot_defaults()`.  See that function for current default values.

| Group | Field | Description |
|-------|-------|-------------|
| **domain** | `.mode` | `'moving'` (follows storm) or `'fixed'` |
| | `.padDeg` | Extra padding in degrees (moving mode) |
| | `.fixedLimits` | `[minLon maxLon minLat maxLat]` (fixed mode) |
| **wind** | `.clims` | Color limits for wind speed (kts) |
| | `.alpha` | Transparency |
| | `.colormap` | Colormap name |
| **pres** | `.clims` | Color limits for pressure (mb) |
| | `.alpha` | Transparency |
| | `.colormap` | Colormap name |
| **quiver** | `.stride` | Plot every Nth vector |
| | `.scale` | Quiver scale factor |
| | `.color` | Arrow color |
| **coast** | `.show` | Overlay coastline |
| | `.color` | Coastline color |
| | `.linewidth` | Coastline line width |
| **track** | `.color` | Storm track line color |
| | `.linewidth` | Storm track line width |
| | `.progressive` | Show track up to current time (`true`) or full track (`false`) |
| **radial** | `.isotachs` | Isotach values in knots (e.g., `[34 50 64]`) |
| | `.one2ten` | 1-min to 10-min wind conversion factor |
| | `.layout` | Subplot layout `[rows cols]` per figure |
| **mask** | `.show` | Overlay vortex mask contours |
| | `.color` | Mask contour color |
| | `.linewidth` | Mask contour line width |
| **anim** | `.gif` | Generate animated GIF |
| | `.mp4` | Generate MP4 video |
| | `.frameRate` | Frames per second |
| **export** | `.dir` | Output directory for saved files |
| | `.format` | `'png'`, `'pdf'`, or `'none'` |
| | `.dpi` | Export resolution |
| **diffmap** | `.colormap` | Diverging colormap name (default `'rdbu'`) |
| | `.clims` | Fixed `[lo hi]` color limits; `[]` = auto-symmetric |
| **scatter** | `.showMetrics` | Annotate bias/RMSE/R² on scatter plots |
| | `.csvFile` | Path for appending metrics rows (empty = disabled) |
| **timeseries** | `.linewidth` | Line width |
| | `.marker` | Marker style (e.g., `'o'`) |
| | `.markersize` | Marker size |
| **time** | `.format` | Datetime display format string |

---

## Legacy Scripts

The original function-based scripts have been moved to `PlotEvalScripts/legacy/` for backward compatibility.  Add `legacy/` to the MATLAB path if needed:

```matlab
addpath('PlotEvalScripts/legacy')
```

| File | Description |
|------|-------------|
| `legacy/conplot_GAHM2026.m` | Contour plots with track, coastline, animation |
| `legacy/radplot_GAHM2026.m` | Radial profiles with isotach markers |
| `legacy/radplot_GAHM2026_RL.m` | Expanded radplot with `ftype` cell-array and `timeinds` |
| `legacy/GAHM2026_ASWIP_compare.m` | GAHM2026 vs ASWIP scatter comparisons |
| `legacy/Rmax_compare.m` | Input vs computed Rmax comparison across storms |
| `legacy/prep_separated_fields_4_conplot_GAHM2026.m` | Prep SeparateEnvHur fields for conplot |
| `legacy/run_conplot_GAHM2026.m` | Example contour plot calls |
| `legacy/run_radplot_GAHM2026.m` | Example radial profile calls |

---

## File Listing

```
PlotEvalScripts/
├── @GAHM2026Plotter/
│   ├── GAHM2026Plotter.m     (classdef)
│   ├── contourMap.m              (public)
│   ├── addQuiver.m               (public)
│   ├── radialProfile.m           (public — multi-overlay)
│   ├── timeSeriesPlot.m          (public — time-series diagnostics)
│   ├── differenceMap.m           (public — difference maps)
│   ├── computeMetrics.m          (public — objective metrics)
│   ├── scatterCompare.m          (public — metrics annotation)
│   ├── animate.m                 (public)
│   ├── exportFigure.m            (public)
│   ├── syncDatetime.m            (public)
│   ├── fromSepEnvHur.m           (static factory)
│   ├── resolveTime.m             (private)
│   ├── resolveRadialTime.m       (private)
│   ├── getDomain.m               (private)
│   ├── plotTrack.m               (private)
│   ├── plotMaskContours.m        (private)
│   ├── captureGifFrame.m         (private)
│   ├── openMp4.m                 (private)
│   └── README.md                 (class-level reference)
├── legacy/
│   ├── conplot_GAHM2026.m
│   ├── radplot_GAHM2026.m
│   ├── radplot_GAHM2026_RL.m
│   ├── GAHM2026_ASWIP_compare.m
│   ├── Rmax_compare.m
│   ├── prep_separated_fields_4_conplot_GAHM2026.m
│   ├── run_conplot_GAHM2026.m
│   └── run_radplot_GAHM2026.m
├── plot_defaults.m               (shared options)
├── plot_coastline.m              (shared helper)
├── plot_quiver_scaled.m          (shared helper)
├── radialFindMaskedge.m          (utility)
├── gm.m                          (shared helper)
├── burd.m                        (colormap)
├── rdbu.m                        (colormap)
└── README.md                     (this file)
```

---

## Dependencies

All plotting functions use only MATLAB built-in capabilities.  No external toolboxes or third-party packages are required.  The coastline overlay uses MATLAB's built-in `coastlines` dataset (`load coastlines`).
