# GAHM2026 Call Tree

**Date**: February 7, 2026  
**Entry point**: `run_GAHM2026.m`

---

## Active Files (15 .m files)

| Role | Files |
|------|-------|
| Driver | `run_GAHM2026.m` |
| Orchestrator | `GAHM2026.m` |
| I/O | `readATCFfort22.m`, `readIBTrACS.m`, `readEnvAndHurrFields2.m`, `writeGAHM2026NetCdf.m` |
| GAHM pipeline | `gahm2026Prep.m`, `gahm2026Consistency.m`, `gahm2026Solve.m` |
| Legacy solvers | `GAHM2026v3e.m`, `GAHM2026v4a.m` (removed, logic unified in `gahm2026Solve.m`) |
| Profile computation | `gahmVPradial.m`, `gahmVP.m` |
| Grid operations | `VEnvreg2radial2.m`, `radial2regular.m`, `radialTaper2.m` |
| Post-processing | `applyWAFfromRaster.m` |
| Extracted utilities | `computeRmaxTot.m`, `quadrantUnitVectors.m`, `thetaToQuadrantPair.m`, `turnAngleDeg.m`, `logMsg.m`, `gahmPhysicalConstants.m` |

---

## Execution Trace

### Step 1: `run_GAHM2026.m` (driver function)

Loads configuration from `config/config_GAHM2026_default.m` (or a user-specified config), reads the storm track data once (`readIBTrACS` or `readATCFfort22`), and passes it to both SeparateEnvHur and GAHM2026:

1. Reads track file → `ATCF_data_in`
2. Calls `SeparateEnvHur(sepenvhur, ATCF_data_in)` (if env_type=3 and `.mat` missing)
3. Calls `GAHM2026(storm_info, ATCF_data_in, ...)` (the orchestrator)
4. Calls `writeGAHM2026NetCdf.m` (if `output_info.type == "grid"`)

---

### Step 2: `GAHM2026.m` (orchestrator)

Decomposed into a main function + 7 local helper functions (Phase 3).

#### Phase A: Initialization (one-time setup)

| Function | Condition | Calls | Description |
|----------|-----------|-------|-------------|
| `sliceTrack` | always | — | Slice pre-loaded `ATCF_data_in` to start/end lines |
| `loadEnvFields` | `env_type == 3` | `readEnvAndHurrFields2.m` | Load gridded env & hurricane fields |
| main | `WAF_flag == true` | `readgeoraster` (builtin) | Read Wind Adjustment Factor raster |

#### Phase B: Per-timestep loop (master time loop)

| Function | Condition | Calls | Description |
|----------|-----------|-------|-------------|
| `computeGAHMAtTrackTime` | always | `gahm2026Prep.m` | Initialize GAHM data structure |
| `computeGAHMAtTrackTime` | always | `gahm2026Consistency.m` | Check input consistency, set flags |
| `computeGAHMAtTrackTime` | always | `gahm2026Solve.m` | Compute GAHM parameters (unified solver) |
| `computeRadialProfiles` | always | `gahmVPradial.m` | Compute radial velocity/pressure profiles |
| `interpolateEnvOnRadialGrid` | `env_type == 3` | `VEnvreg2radial2.m` | Interpolate env/hurricane fields to radial grid |
| `applyTaperOnRadialGrid` | `taper_flag == true` | `radialTaper2.m` | Compute and apply taper function |

#### Phase C: Output (after master loop)

| Function | Condition | Calls | Description |
|----------|-----------|-------|-------------|
| `buildRegularGridOutputs` | always | `radial2regular.m` | Interpolate vortex fields to regular grid |
| `buildRegularGridOutputs` | `WAF_flag == true` | `applyWAFfromRaster.m` | Apply Wind Adjustment Factor |
| `buildRegularGridOutputs` | `env_type == 1/2` | `radial2regular.m` | Interpolate env fields to regular grid |
| `buildRegularGridOutputs` | `env_type == 3` | `griddedInterpolant` (builtin) | Interpolate env/hurricane to output grid |

---

### Step 3: `gahm2026Solve.m` (unified solver, Phase 4)

Single entry point replacing direct calls to `GAHM2026v3e.m` / `GAHM2026v4a.m`.
Dispatches to version-specific backends based on `GAHM_constants.version`.

#### Shared logic (in main body)
- Input unpacking, Coriolis computation, quadrant unit vectors
- SVorQuad computation for Gcase 1 (ADCIRC scaling) and Gcase 2 (quadratic solve)
- Error checks (imaginary, negative, exceeds max)
- RmaxQ selection from highest available isotach
- Gap-filling for missing isotachs (flag==0 or 3)
- `computeRmaxTot` for total Rmax and angle

#### Local functions

| Function | Version | Description |
|----------|---------|-------------|
| `solve_flag1or5_v3` | v3 | Iterative Rmax/Bg loop, tracks Rmic & Bgicmax |
| `solve_flag1or5_v4` | v4 | `fsolve` of coupled nondimensional eqs (Bg, c=Rmax/r) |
| `compute_Bg` | both | Dispatcher to version-specific Bg backend |
| `compute_Bg_iterative` | v3 | Two-phase iteration (no toolbox required) |
| `compute_Bg_fsolve` | v4 | `fsolve`-based (requires Optimization Toolbox) |
| `GAHM2026a` | v4 | Full nondimensional GAHM equations for fsolve |
| `GAHM2026b` | v4 | Bg-only GAHM equation for fsolve |

---

### Step 4: `writeGAHM2026NetCdf.m`

Called from `run_GAHM2026.m` L241 if `output_info.type == "grid"`.
Writes `Reggrid_out` and `Reggrid_TC_out` to a NetCDF4 file.

---

## Nested / Local Functions

### `GAHM2026.m` (Phase 3 decomposition)
| Function | Description |
|----------|-------------|
| `sliceTrack` | Slice pre-loaded track to start/end lines |
| `loadEnvFields` | Env/hurricane gridded field loading by env_type |
| `computeGAHMAtTrackTime` | prep → consistency → solve |
| `computeRadialProfiles` | Theta loop calling gahmVPradial |
| `interpolateEnvOnRadialGrid` | Env_type branching for env fields on radial grid |
| `applyTaperOnRadialGrid` | Taper computation and application |
| `buildRegularGridOutputs` | Output grid construction, WAF, blending, masks |

### `gahm2026Prep.m`
| Function | Called When | Description |
|----------|-------------|-------------|
| `VEnvAvg` | `env_type == 3` | Average environmental velocity within Rmax of eye |
| `VEnvRQuad` | `env_type == 3` | Environmental velocity at isotach locations in 4 quadrants |

### `GAHM2026v3e.m` (legacy, no longer called directly)
| Function | Description |
|----------|-------------|
| `compute_Bg` | Custom two-phase iteration (50 iters each form) |

### `GAHM2026v4a.m` (legacy, no longer called directly)
| Function | Description |
|----------|-------------|
| `GAHM2026a` | Nondimensional GAHM equations for fsolve |
| `compute_Bg` | fsolve-based Bg solver |
| `GAHM2026b` | Bg equation for fsolve |

---

## Extracted Utilities (Phase 1)

Previously duplicated logic, now standalone `.m` files:

| File | Replaces | Called From |
|------|----------|-------------|
| `computeRmaxTot.m` | 3 nested `compute_Rmax_tot` copies | `gahm2026Solve.m`, `readATCFfort22.m` |
| `quadrantUnitVectors.m` | 4 inline copies | `gahm2026Solve.m`, `gahm2026Consistency.m`, `gahmVP.m` |
| `thetaToQuadrantPair.m` | ~20-line blocks | `gahmVPradial.m`, `computeRmaxTot.m` |
| `turnAngleDeg.m` | Piecewise turning angle | `gahmVP.m` |
| `logMsg.m` | Dual fprintf pairs | Available for gradual adoption |
| `gahmPhysicalConstants.m` | Magic number literals | Available for gradual adoption |

---

## Call Graph (text form)

```
run_GAHM2026.m
├── readATCFfort22.m               [if ATCF/fort22]
│   └── computeRmaxTot.m             [if ASWIP]
│       └── thetaToQuadrantPair.m
├── readIBTrACS.m                   [if IBTrACS]
├── SeparateEnvHur.m                      [if env_type==3 and .mat missing]
├── GAHM2026.m (ATCF_data_in passed in)
│   ├── sliceTrack [local]
│   ├── loadEnvFields [local]
│   │   └── readEnvAndHurrFields2.m [if env_type==3]
│   ├── readgeoraster (builtin)      [if WAF_flag]
│   │
│   ├── [master time loop]
│   │   ├── computeGAHMAtTrackTime [local]
│   │   │   ├── gahm2026Prep.m
│   │   │   │   ├── VEnvAvg          [nested, if env_type==3]
│   │   │   │   └── VEnvRQuad        [nested, if env_type==3]
│   │   │   ├── gahm2026Consistency.m
│   │   │   │   └── quadrantUnitVectors.m
│   │   │   └── gahm2026Solve.m
│   │   │       ├── quadrantUnitVectors.m
│   │   │       ├── solve_flag1or5_v3 [local, if version==3]
│   │   │       │   └── compute_Bg_iterative [local]
│   │   │       ├── solve_flag1or5_v4 [local, if version==4]
│   │   │       │   └── GAHM2026a    [local, fsolve target]
│   │   │       ├── compute_Bg [local, dispatches by version]
│   │   │       │   ├── compute_Bg_iterative [local, v3]
│   │   │       │   └── compute_Bg_fsolve    [local, v4]
│   │   │       │       └── GAHM2026b [local, fsolve target]
│   │   │       └── computeRmaxTot.m
│   │   │           └── thetaToQuadrantPair.m
│   │   ├── computeRadialProfiles [local]
│   │   │   └── gahmVPradial.m      [for it=1:ntheta]
│   │   │       ├── thetaToQuadrantPair.m
│   │   │       └── gahmVP.m        [for each radial point]
│   │   │           ├── quadrantUnitVectors.m
│   │   │           └── turnAngleDeg.m
│   │   ├── interpolateEnvOnRadialGrid [local]
│   │   │   └── VEnvreg2radial2.m    [if env_type==3]
│   │   └── applyTaperOnRadialGrid [local]
│   │       └── radialTaper2.m      [if taper_flag]
│   │
│   └── buildRegularGridOutputs [local]
│       ├── radial2regular.m         [vortex, env, hurricane fields]
│       └── applyWAFfromRaster.m  [if WAF_flag]
│
└── writeGAHM2026NetCdf.m           [if output type=="grid"]
```
