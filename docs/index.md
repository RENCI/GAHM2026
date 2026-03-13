---
layout: default
title: GAHM2026
---

# GAHM2026

**Generalized Asymmetric Holland Model for Tropical Cyclone Wind and Pressure Fields**

GAHM2026 is a MATLAB codebase for computing parametric hurricane wind and pressure fields. Given tropical cyclone track data (best-track observations or forecasts), the model solves for the Generalized Asymmetric Holland Model (GAHM) parameters at each timestep, generates azimuthally varying radial wind and pressure profiles, and interpolates them onto a regular lon/lat grid for output.

When paired with the companion **SeparateEnvHur** preprocessor, GAHM2026 can blend its parametric vortex with large-scale environmental fields extracted from ERA5 reanalysis data, producing complete tropical cyclone wind and pressure fields suitable for storm surge and coastal hazard modeling.

Developed by Rick Luettich (UNC/IMS/CNHR/EMES) and Brian Blanton (UNC/RENCI).

---

## Key Features

- **Asymmetric wind profiles** — Computes separate Holland B parameter and radius of maximum winds in each quadrant (NE, SE, SW, NW) at up to three isotach levels (34, 50, 64 kt)
- **Multiple track formats** — Reads IBTrACS, ATCF, and fort.22 track files; auto-downloads IBTrACS data if not present
- **Environmental field blending** — Three environmental velocity options: ADCIRC/ASWIP translation velocity, Lin & Chavas (2012) formulation, or gridded ERA5-derived fields via SeparateEnvHur
- **Taper function** — Smooth blending at the hurricane/environment boundary using a hyperbolic tangent taper
- **Wind Adjustment Factor** — Optional land-roughness correction from GeoTIFF rasters
- **NetCDF and point output** — Gridded NetCDF4 output or evaluation at arbitrary lon/lat points
- **Visualization toolkit** — Object-oriented `GAHM2026Plotter` class for contour maps, radial profiles, scatter comparisons, and GIF/MP4 animations

---

## How It Works

The GAHM extends the classic Holland (1980) pressure profile by incorporating the Coriolis effect into the gradient wind balance and allowing the shape parameter B<sub>g</sub> to vary by quadrant. Given:

- Central pressure P<sub>c</sub> and background pressure P<sub>n</sub>
- Maximum sustained wind speed V<sub>max</sub>
- Radial distances to wind isotachs (34, 50, 64 kt) in four quadrants

the model solves iteratively for B<sub>g</sub> and R<sub>max</sub> in each quadrant, then evaluates the radial wind and pressure profiles:

$$V_g(r) = \sqrt{V_{\max}^2 (1 + R_o^{-1}) \left(\frac{R_{mw}}{r}\right)^{B_g} e^{\varphi[1 - (R_{mw}/r)^{B_g}]} + \left(\frac{rf}{2}\right)^2} - \frac{rf}{2}$$

where R<sub>o</sub> = V<sub>max</sub>/(R<sub>mw</sub> f) is the Rossby number and φ is derived from the constraint that dV<sub>g</sub>/dr = 0 at r = R<sub>mw</sub>.

Two solver backends are available: version 3 (iterative fixed-point) and version 4 (MATLAB `fsolve`), selectable via configuration.

---

## Pipeline Overview

```
┌─────────────────────────────────────────────────────────┐
│  run_GAHM2026.m                                         │
│                                                         │
│  1. Load config (config/config_*.m)                     │
│  2. Download IBTrACS if missing                         │
│  3. Auto-run SeparateEnvHur if env_type=3 and .mat missing   │
│  4. Call GAHM2026.m orchestrator                        │
│  5. Write NetCDF output                                 │
│  6. Return Result struct                                │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│  GAHM2026.m                                             │
│                                                         │
│  Phase A: Read track, load environmental fields         │
│                                                         │
│  Phase B: Per-timestep loop                             │
│    ├─ gahm2026Prep       → initialize GAHM struct      │
│    ├─ gahm2026Consistency → screen & validate inputs   │
│    ├─ gahm2026Solve      → compute Bg, Rmax per quad    │
│    ├─ gahmVPradial       → radial velocity & pressure   │
│    ├─ VEnvreg2radial2    → env fields → radial grid     │
│    └─ radialTaper2       → taper at blending boundary   │
│                                                         │
│  Phase C: Interpolate to output grid                    │
│    ├─ radial2regular     → radial → regular grid        │
│    ├─ apply_WAF          → land roughness adjustment    │
│    └─ blend env + vortex → final TC fields              │
└─────────────────────────────────────────────────────────┘
```

---

## Quick Start

```matlab
cd GAHM2026
R = run_GAHM2026;                          % default config (Florence 2018)
R = run_GAHM2026('config_Florence');       % storm-specific config
```

If `env_info.type = 3` and the SeparateEnvHur `.mat` file does not exist, `run_GAHM2026` will automatically run SeparateEnvHur to generate it before proceeding.

### Plotting

```matlab
addpath('PlotEvalScripts')
obj = GAHM2026Plotter(R);

% Wind speed contour map at timestep 20
fig = obj.contourMap('mvelcon', 1, 20);

% Radial wind profiles at timestep 10
obj.radialProfile('velrad', 10, 10);

% Animated GIF of the full storm
obj.animate('mvelcon', 1);
```

---

## SeparateEnvHur — Environmental Field Extraction

SeparateEnvHur separates tropical cyclone vortex fields from ERA5 reanalysis data to produce gridded environmental and hurricane-scale fields. The algorithm:

1. Loads ERA5 global u10, v10, and mean sea-level pressure
2. Tracks the storm center using the pressure minimum
3. Converts to polar coordinates and identifies wind speed cutlines (inner at 34 kt, outer at a configurable threshold)
4. Applies Butterworth low-pass filtering to extract the environmental (large-scale) field
5. Computes the hurricane field as the residual (total minus environmental)
6. Saves inner and outer vortex masks for blending

SeparateEnvHur can run automatically as part of the GAHM2026 pipeline or standalone:

```matlab
addpath('SeparateEnvHur')
env_vals = SeparateEnvHur('config/config_GAHM2026_default');
```

---

## Configuration

Configuration files live in `config/` and define all parameters for both SeparateEnvHur and GAHM2026. Storm identity is defined once at the top and shared:

```matlab
storm_name        = 'FLORENCE';
storm_year        = 2018;
track_file        = 'ibtracs.NA.list.v04r01.csv';
storm_designation = 'AL06';
storm_start       = datetime(2018,9,10,0,0,0);
storm_end         = datetime(2018,9,18,0,0,0);
```

Key parameter groups:

| Struct | Purpose |
|--------|---------|
| `sepenvhur` | ERA5 file path, grid sizes, wind thresholds, filter parameters |
| `storm_info` | Track file path and format, start/end times |
| `GAHM_param_info` | Holland B limits, boundary layer factor, solver version |
| `GAHM_compute_info` | Radial grid resolution (ntheta, nr, delr) |
| `WAF_info` | Wind Adjustment Factor flag and raster file |
| `env_info` | Environmental field type (1, 2, or 3), taper settings |
| `output_info` | Output format (grid/points), resolution, NetCDF path |

To run a new storm, copy any existing config, update the storm identity section, and call `run_GAHM2026('config_NewStorm')`.

See the [Configuration Reference](https://github.com/renci/gahm2026/blob/main/documentation/README_config.md) for complete parameter documentation.

---

## Directory Layout

```
GAHM2026/
├── run_GAHM2026.m             — driver script
├── GAHM2026.m                 — orchestrator (main + local helpers)
├── config/                    — configuration files
├── util/                      — GAHM pipeline functions
├── input/                     — track data files (IBTrACS, ATCF)
├── output/                    — NetCDF output, warning logs
├── SeparateEnvHur/                 — ERA5 environmental field extraction
├── PlotEvalScripts/           — GAHM2026Plotter class & legacy scripts
├── tools/                     — regression testing harness
└── documentation/             — derivation, call tree, data structures
```

---

## Output

### Result struct (returned by `run_GAHM2026`)

| Field | Contents |
|-------|----------|
| `Reggrid_out` | Grid coordinates, datetime, blending masks |
| `Reggrid_TC_out` | Final blended TC wind (VelU, VelV in m/s) and pressure (mb) |
| `Reggrid_Env_out` | Environmental wind and pressure fields |
| `Reggrid_VVor_invtapHur_out` | GAHM vortex + inverse-tapered hurricane (env_type=3 only) |
| `Trackdata` | Storm track with Rmax, Vmax, and quadrant parameters |
| `GAHM_out` | Per-timestep GAHM solver output |
| `VPrad` | Radial grid data for profile plotting |

### NetCDF output

Gridded output is written to `output/<storm>_<year>.nc` containing combined TC wind velocity and pressure fields at each output time.

---

## References

- Holland, G. J. (1980). An analytic model of the wind and pressure profiles in hurricanes. *Monthly Weather Review*, 108(8), 1212–1218.
- Gao, J. (2018). *Generalized Asymmetric Holland Vortex Model*. Ph.D. dissertation.
- Lin, N. and Chavas, D. (2012). On hurricane parametric wind and applications in storm surge modeling. *Journal of Geophysical Research*, 117, D09120.

---

## License

Contact the authors for licensing information.
