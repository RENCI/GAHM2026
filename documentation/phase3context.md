# GAHM2026 Phase 3 Session Context

**Last updated**: February 7, 2026  
**Purpose**: Detailed context for Phase 3 (decompose GAHM2026.m) and bug fix.

---

## Phase 3 Summary

Decomposed the 660-line `GAHM2026.m` monolith into a ~190-line main function plus 7 local helper functions. The external signature is unchanged.

### Local Functions Extracted

| Function | Lines | Responsibility |
|----------|-------|----------------|
| `readAndSliceTrack(storm)` | ~40 | Read track file (ATCF/IBTrACS), validate storm name, find ATCF start/end lines, return `starttime_dt`/`endtime_dt` |
| `loadEnvFields(env_type, env_info, ...)` | ~15 | Load gridded env/hurricane fields if env_type=3; return dummies for env_type=1/2 |
| `computeGAHMAtTrackTime(...)` | ~30 | Calls `GAHM2026_prep` → `GAHM2026_consistency` → `GAHM2026v3e`/`v4a`; returns GAHM struct + skip flag |
| `computeRadialProfiles(r, theta, ...)` | ~10 | Theta loop calling `GAHM_VPradial`; returns radial velocity/pressure arrays + RP1/RP2 diagnostics |
| `interpolateEnvOnRadialGrid(...)` | ~35 | Env_type branching: type 1 scales by vortex speed, type 2 uniform, type 3 calls `VEnvreg2radial2` for env/hur/masks |
| `applyTaperOnRadialGrid(...)` | ~25 | Computes taper via `radial_taper2`, applies to vortex and (if env_type=3) hurricane radial fields |
| `buildRegularGridOutputs(...)` | ~125 | Output grid construction, `radial2regular` interpolation, WAF application, env_type branching for blended outputs, mask interpolation |

### Main Function Flow (after decomposition)

```
GAHM2026
├── Setup: transfer params, build r/theta arrays, taper_constants
├── readAndSliceTrack → ATCF_data_in, start/end lines
├── loadEnvFields → VEnv_10_10, VHur_10_10, BlendingMasks, PscaleEnv
├── WAF raster loading (if enabled)
├── Master time loop (for itime=1:nBTtime):
│   ├── computeGAHMAtTrackTime → GAHM_t2
│   ├── computeRadialProfiles → VVel_VPrad_t2, VPress_VPrad_t2
│   └── Time interpolation while-loop:
│       ├── Interpolate vortex on radial grid (inline)
│       ├── interpolateEnvOnRadialGrid
│       ├── applyTaperOnRadialGrid (if taper enabled)
│       └── Save Trackdata
└── buildRegularGridOutputs → Reggrid_out, Reggrid_TC_out, etc.
```

---

## Bug Found and Fixed

### Problem: "Unrecognized field name 'Eye'"

When `computeGAHMAtTrackTime` returned `skipline=true`, the initial implementation assigned the partial GAHM struct (from `GAHM2026_prep`, which lacks the `Eye` field) to `GAHM_t2` before the `continue`. On the next iteration, `GAHM_t1 = GAHM_t2` propagated this partial struct, and `GAHM_t1.Eye(1)` failed.

**Original code behavior**: When `GAHMp1.skipline` was true, `continue` was called *before* `GAHM_t2` was assigned, so `GAHM_t2` retained its value from the previous successful iteration.

### Fix

Changed from:
```matlab
[GAHM_t2, skipline] = computeGAHMAtTrackTime(...);
if skipline
    continue
end
```

To:
```matlab
[GAHM_t_new, skipline] = computeGAHMAtTrackTime(...);
if skipline
    continue
end
GAHM_t2 = GAHM_t_new;
```

This preserves the original semantics: `GAHM_t2` is only updated after a successful computation.

---

## Key Design Decisions

1. **Local functions, not separate .m files**: All helpers are local functions within `GAHM2026.m`. This avoids MATLAB path issues and keeps the refactoring mechanical and reversible.

2. **Accumulator arrays passed through**: `VEnvrad_10_10`, `PEnvrad`, `VHurrad_10_10`, `PHurrad`, `BlendingMasksrad` are passed into and returned from `interpolateEnvOnRadialGrid` and `applyTaperOnRadialGrid`. This is because MATLAB doesn't support in-place modification of arrays across function boundaries without handle objects.

3. **Initialized empty arrays before loop**: `VEnvrad_10_10`, `PEnvrad`, `VHurrad_10_10`, `PHurrad`, `BlendingMasksrad`, `WAF_data`, `WAF_metadata` are initialized to `[]` before the master loop to avoid "undefined variable" errors when they're passed to helper functions but not used for certain env_type values.

4. **Storm-not-found uses `error()` instead of `return`**: In the original monolith, `return` in the storm validation block exited the entire function. In the local `readAndSliceTrack`, `return` only exits the helper. Changed to `error()` to propagate the failure correctly.

---

## Variables Consumed by Each Section

### Master time loop produces (indexed by output time `i`):
- `VVel_VPrad_10_10(i, 1:ntheta, 1:nr+1, 1:2)` — tapered vortex velocity on radial grid
- `VPress_VPrad(i, 1:ntheta, 1:nr+1)` — tapered vortex pressure on radial grid
- `VEnvrad_10_10(i, 1:ntheta, 1:nr+1, 1:2)` — env velocity on radial grid
- `PEnvrad(i, 1:ntheta, 1:nr+1)` — env pressure on radial grid
- `VHurrad_10_10(i, ...)` — tapered hurricane velocity on radial grid (env_type=3 only)
- `PHurrad(i, ...)` — tapered hurricane pressure on radial grid (env_type=3 only)
- `LonEW(i)`, `LatNS(i)` — interpolated eye position
- `datetimeint(i)` — interpolated datetime
- `Trackdata(i)` — diagnostic track info struct

### buildRegularGridOutputs consumes all of the above plus:
- `VEnv_10_10`, `VHur_10_10`, `BlendingMasks` — original gridded fields (for env_type=3 direct interpolation)
- `WAF_data`, `WAF_metadata` — WAF raster (if enabled)
- `output` struct — grid/points configuration

---

## Remaining Phases

### Phase 4: Unify v3e/v4a Solvers (completed)
- Created `GAHM2026_solve.m` (~560 lines) as unified entry point
- Extracted shared code: input unpacking, SVorQuad computation, RmaxQ selection, gap-filling, computeRmaxTot call
- Unified `compute_Bg` dispatcher with two backends (iterative vs fsolve)
- Version-specific local functions: `solve_flag1or5_v3`, `solve_flag1or5_v4`, `compute_Bg_iterative`, `compute_Bg_fsolve`, `GAHM2026a`, `GAHM2026b`
- Updated call site in `GAHM2026.m` `computeGAHMAtTrackTime`
- Original `GAHM2026v3e.m` and `GAHM2026v4a.m` retained

### Phase 5: Documentation Cleanup (~3 hours)
- Centralize duplicated GAHM struct docs into `documentation/GAHM_struct.md`
- Replace 5+ per-file copies with single reference

---

## How to Resume

```
Read documentation/phase3context.md and documentation/REFACTORING_PLAN.md and continue with Phase 5.
```

Regenerate baseline before starting Phase 5:
```matlab
>> cd /Users/bblanton/GitHub/RENCI/GAHM2026
>> generate_baseline
>> compare_to_baseline
```
