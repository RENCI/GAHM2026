# GAHM2026 Call Tree

**Date**: February 7, 2026  
**Entry point**: `run_GAHM2026.m`

---

## Active Files (15 .m files)

| Role | Files |
|------|-------|
| Driver | `run_GAHM2026.m` |
| Orchestrator | `GAHM2026.m` |
| I/O | `read_ATCF_fort22.m`, `read_IBTrACS.m`, `read_Env_and_Hurr_fields2.m`, `writeGAHM2026NetCdf.m` |
| GAHM pipeline | `GAHM2026_prep.m`, `GAHM2026_consistency.m`, `GAHM2026_solve.m` |
| Legacy solvers | `GAHM2026v3e.m`, `GAHM2026v4a.m` (removed, logic unified in `GAHM2026_solve.m`) |
| Profile computation | `GAHM_VPradial.m`, `GAHM_VP.m` |
| Grid operations | `VEnvreg2radial2.m`, `radial2regular.m`, `radial_taper2.m` |
| Post-processing | `apply_WAF_from_raster.m` |
| Extracted utilities | `computeRmaxTot.m`, `quadrantUnitVectors.m`, `thetaToQuadrantPair.m`, `turnAngleDeg.m`, `logMsg.m`, `GAHM_physical_constants.m` |

---

## Execution Trace

### Step 1: `run_GAHM2026.m` (driver function)

Loads configuration from `config/config_GAHM2026.m` (or a user-specified config) and makes two calls:

1. **Line 236**: Calls `GAHM2026.m` (the orchestrator)
2. **Line 241**: Calls `writeGAHM2026NetCdf.m` (if `output_info.type == "grid"`)

---

### Step 2: `GAHM2026.m` (orchestrator)

Decomposed into a main function + 7 local helper functions (Phase 3).

#### Phase A: Initialization (one-time setup)

| Function | Condition | Calls | Description |
|----------|-----------|-------|-------------|
| `readAndSliceTrack` | `file_type == "ATCF"/"fort22"` | `read_ATCF_fort22.m` | Read track file, find start/end lines |
| `readAndSliceTrack` | `file_type == "IBTrACS"` | `read_IBTrACS.m` | Read IBTrACS track file |
| `loadEnvFields` | `env_type == 3` | `read_Env_and_Hurr_fields2.m` | Load gridded env & hurricane fields |
| main | `WAF_flag == true` | `readgeoraster` (builtin) | Read Wind Adjustment Factor raster |

#### Phase B: Per-timestep loop (master time loop)

| Function | Condition | Calls | Description |
|----------|-----------|-------|-------------|
| `computeGAHMAtTrackTime` | always | `GAHM2026_prep.m` | Initialize GAHM data structure |
| `computeGAHMAtTrackTime` | always | `GAHM2026_consistency.m` | Check input consistency, set flags |
| `computeGAHMAtTrackTime` | always | `GAHM2026_solve.m` | Compute GAHM parameters (unified solver) |
| `computeRadialProfiles` | always | `GAHM_VPradial.m` | Compute radial velocity/pressure profiles |
| `interpolateEnvOnRadialGrid` | `env_type == 3` | `VEnvreg2radial2.m` | Interpolate env/hurricane fields to radial grid |
| `applyTaperOnRadialGrid` | `taper_flag == true` | `radial_taper2.m` | Compute and apply taper function |

#### Phase C: Output (after master loop)

| Function | Condition | Calls | Description |
|----------|-----------|-------|-------------|
| `buildRegularGridOutputs` | always | `radial2regular.m` | Interpolate vortex fields to regular grid |
| `buildRegularGridOutputs` | `WAF_flag == true` | `apply_WAF_from_raster.m` | Apply Wind Adjustment Factor |
| `buildRegularGridOutputs` | `env_type == 1/2` | `radial2regular.m` | Interpolate env fields to regular grid |
| `buildRegularGridOutputs` | `env_type == 3` | `griddedInterpolant` (builtin) | Interpolate env/hurricane to output grid |

---

### Step 3: `GAHM2026_solve.m` (unified solver, Phase 4)

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
| `readAndSliceTrack` | Track file I/O + start/end line finding |
| `loadEnvFields` | Env/hurricane gridded field loading by env_type |
| `computeGAHMAtTrackTime` | prep → consistency → solve |
| `computeRadialProfiles` | Theta loop calling GAHM_VPradial |
| `interpolateEnvOnRadialGrid` | Env_type branching for env fields on radial grid |
| `applyTaperOnRadialGrid` | Taper computation and application |
| `buildRegularGridOutputs` | Output grid construction, WAF, blending, masks |

### `GAHM2026_prep.m`
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
| `computeRmaxTot.m` | 3 nested `compute_Rmax_tot` copies | `GAHM2026_solve.m`, `read_ATCF_fort22.m` |
| `quadrantUnitVectors.m` | 4 inline copies | `GAHM2026_solve.m`, `GAHM2026_consistency.m`, `GAHM_VP.m` |
| `thetaToQuadrantPair.m` | ~20-line blocks | `GAHM_VPradial.m`, `computeRmaxTot.m` |
| `turnAngleDeg.m` | Piecewise turning angle | `GAHM_VP.m` |
| `logMsg.m` | Dual fprintf pairs | Available for gradual adoption |
| `GAHM_physical_constants.m` | Magic number literals | Available for gradual adoption |

---

## Call Graph (text form)

```
run_GAHM2026.m
├── GAHM2026.m
│   ├── readAndSliceTrack [local]
│   │   ├── read_ATCF_fort22.m       [if ATCF/fort22]
│   │   │   └── computeRmaxTot.m     [if ASWIP]
│   │   │       └── thetaToQuadrantPair.m
│   │   └── read_IBTrACS.m           [if IBTrACS]
│   ├── loadEnvFields [local]
│   │   └── read_Env_and_Hurr_fields2.m [if env_type==3]
│   ├── readgeoraster (builtin)      [if WAF_flag]
│   │
│   ├── [master time loop]
│   │   ├── computeGAHMAtTrackTime [local]
│   │   │   ├── GAHM2026_prep.m
│   │   │   │   ├── VEnvAvg          [nested, if env_type==3]
│   │   │   │   └── VEnvRQuad        [nested, if env_type==3]
│   │   │   ├── GAHM2026_consistency.m
│   │   │   │   └── quadrantUnitVectors.m
│   │   │   └── GAHM2026_solve.m
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
│   │   │   └── GAHM_VPradial.m      [for it=1:ntheta]
│   │   │       ├── thetaToQuadrantPair.m
│   │   │       └── GAHM_VP.m        [for each radial point]
│   │   │           ├── quadrantUnitVectors.m
│   │   │           └── turnAngleDeg.m
│   │   ├── interpolateEnvOnRadialGrid [local]
│   │   │   └── VEnvreg2radial2.m    [if env_type==3]
│   │   └── applyTaperOnRadialGrid [local]
│   │       └── radial_taper2.m      [if taper_flag]
│   │
│   └── buildRegularGridOutputs [local]
│       ├── radial2regular.m         [vortex, env, hurricane fields]
│       └── apply_WAF_from_raster.m  [if WAF_flag]
│
└── writeGAHM2026NetCdf.m           [if output type=="grid"]
```
