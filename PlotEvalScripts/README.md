# GAHM2026 Graphics and Visualization

Plotting and evaluation tools for GAHM2026 output fields, radial profiles, and parameter comparisons.

There are two ways to produce plots:

1. **`GAHM2026Plotter` class** (recommended) — object-oriented interface that receives the `Result` struct returned by `run_GAHM2026` and provides methods for contour maps, radial profiles, scatter comparisons, animation, and figure export.
2. **Standalone scripts** — the original function-based scripts (`conplot_blend_GAHM2026.m`, `radplot_blend_GAHM2026.m`, etc.) that operate on individual workspace variables.

Both approaches share the same `plot_defaults.m` options struct.

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
| `R.VPrad` | Radial grid data: `.r`, `.theta`, `.VVor(i)`, `.Env(i)`, `.EnvVor(i)` |
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

### 5. Wind vectors with velocity contours

The `'velcon'` plot type includes quiver arrows automatically.  To add vectors to any existing plot use `addQuiver`:

```matlab
fig = obj.contourMap('precon', 3, 20);    % pressure map, no vectors
obj.addQuiver(20);                        % overlay wind vectors
```

### 6. Plot a different field

Pass an alternate data struct as the last argument:

```matlab
% environmental wind field
fig = obj.contourMap('mvelcon', 4, 20, R.Reggrid_Env_out);

% GAHM vortex + inverse-tapered hurricane field
fig = obj.contourMap('mvelcon', 5, 20, R.Reggrid_VVor_invtapHur_out);
```

### 7. Radial profiles

Plot radial wind speed profiles at timestep 10 (every other azimuthal angle):

```matlab
obj.radialProfile('velrad', 10, 10);
```

Pressure profiles (every 4th azimuth):

```matlab
obj.radialProfile('prerad', 20, 10, 4);
```

### 8. Animation

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

### 9. Export figures

Save figures to PNG or PDF:

```matlab
fig = obj.contourMap('mvelcon', 1, 20);
obj.exportFigure(fig, 'Florence_wind_t20');   % → output/Florence_wind_t20.png

obj.setOpts('export', 'format', 'pdf');
obj.exportFigure(fig, 'Florence_wind_t20');   % → output/Florence_wind_t20.pdf
```

### 10. Scatter comparison

For comparing GAHM2026 parameters against another dataset (e.g., ASWIP), first synchronize the two struct arrays by datetime, then plot:

```matlab
% sync matched timesteps
[ig, ia] = obj.syncDatetime(GAHM_out_BLF090, ASWIP);

% extract N×4 quadrant Rmax data
X = vertcat(GAHM_out_BLF090(ig).Rmax34);
Y = vertcat(ASWIP(ia).Rmax34);

obj.scatterCompare(X, Y, 1, ...
    'Florence 2018  Rmax Comparison for 34kt isotach', ...
    'Rmax GAHM2026 BLF=0.90 (nm)', 'Rmax ASWIP (nm)');
```

For series-based comparisons (non-quadrant), provide explicit legend labels:

```matlab
X2 = [[GAHM_BLF075(ig).Rmax_out]', [GAHM_BLF090(ig).Rmax_out]'];
Y2 = repmat([ASWIP(ia).RMW]', 1, 2);

obj.scatterCompare(X2, Y2, 2, ...
    'Florence 2018  Rmax Comparison', ...
    'Rmax computed (nm)', 'Rmax NHC (nm)', {'BLF=0.75','BLF=0.90'});
```

### 11. Customizing options

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

## GAHM2026Plotter Method Reference

### Plotting Methods

| Method | Description |
|--------|-------------|
| `contourMap(ptype, nplot, time, plotdata)` | Contour map (pcolor) of wind speed or pressure at one timestep |
| `addQuiver(time, plotdata)` | Overlay velocity vectors on the current axes |
| `radialProfile(ptype, nplot, time, theta_inc)` | Radial profiles in subplot panels at one timestep |
| `scatterCompare(X, Y, nplot, title, xlabel, ylabel, legend)` | 1:1 scatter plot — by-quadrant (N×4) or by-series (N×K) |
| `animate(ptype, nplot, plotdata, filename)` | GIF/MP4 animation over all timesteps |
| `exportFigure(fig, filename)` | Save figure to PNG or PDF |

### Utility Methods

| Method | Description |
|--------|-------------|
| `setOpts(group, field, value)` | Override a single option |
| `resetOpts()` | Restore all options to defaults |
| `syncDatetime(A, B)` | Find matching datetime indices between two struct arrays |

### Plot Types

| `ptype` | Used by | Description |
|---------|---------|-------------|
| `'velcon'` | `contourMap` | Wind speed contours with velocity vectors |
| `'precon'` | `contourMap` | Pressure contours |
| `'mvelcon'` | `contourMap` | Wind speed contours with mask boundary lines |
| `'mprecon'` | `contourMap` | Pressure contours with mask boundary lines |
| `'velrad'` | `radialProfile` | Radial velocity profiles with isotach markers |
| `'prerad'` | `radialProfile` | Radial pressure profiles |

### Time Argument

The `time` parameter in `contourMap`, `addQuiver`, and `radialProfile` accepts:

| Type | Example | Behaviour |
|------|---------|-----------|
| integer | `5` | Use timestep index 5 |
| `datetime` | `datetime(2018,9,14,12,0,0)` | Match to nearest available time |
| `[]` or omitted | | Defaults to timestep 1 |

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
| **time** | `.format` | Datetime display format string |

---

## Standalone Scripts (Legacy)

The original function-based scripts remain available for backward compatibility:

| File | Description |
|------|-------------|
| `conplot_blend_GAHM2026.m` | Contour plots with track, coastline, animation |
| `radplot_blend_GAHM2026.m` | Radial profiles with isotach markers |
| `GAHM2026_ASWIP_compare.m` | GAHM2026 vs ASWIP scatter comparisons |
| `Rmax_compare.m` | Input vs computed Rmax comparison across storms |
| `plot_defaults.m` | Default options struct (shared with class) |
| `plot_coastline.m` | Coastline overlay helper |
| `plot_quiver_scaled.m` | Subsampled quiver overlay helper |
| `radial_find_maskedge.m` | Radial mask-edge detection utility |
| `run_conplot_blend_GAHM2026.m` | Example contour plot calls |
| `run_radplot_blend_GAHM2026.m` | Example radial profile calls |

---

## Dependencies

All plotting functions use only MATLAB built-in capabilities.  No external toolboxes or third-party packages are required.  The coastline overlay uses MATLAB's built-in `coastlines` dataset (`load coastlines`).
