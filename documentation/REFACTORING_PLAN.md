# GAHM2026 Refactoring Plan

**Date**: February 6, 2026  
**Codebase**: GAHM2026 (Generalized Asymmetric Holland Model)  
**Author of code**: Rick Luettich, RENCI/UNC  
**Analysis by**: Amp AI assistant

---

## Summary

The GAHM2026 codebase computes hurricane wind and pressure fields using the Generalized Asymmetric Holland Model. The pipeline reads tropical cyclone track data (ATCF, IBTrACS formats), computes GAHM parameters, generates radial wind/pressure profiles, optionally blends with gridded environmental fields, and writes output to NetCDF.

This plan is organized into five phases from lowest-risk/highest-payoff to more structural changes.

---

## File Inventory

| File | Role | Lines |
|------|------|-------|
| `run_GAHM2026.m` | Top-level driver script (sets parameters, calls blend) | ~260 |
| `run_build_GAHM2026_param_file.m` | Top-level driver for param file generation | ~small |
| `GAHM2026.m` | **Master orchestrator** (monolith) | ~660 |
| `build_GAHM2026_param_file.m` | Param file builder (prep+consistency+solve loop) | ~250 |
| `GAHM2026_prep.m` | Initialize GAHM data structure per timestep | ~365 |
| `GAHM2026_consistency.m` | Input consistency checks and flag setting | ~380 |
| `GAHM2026v3e.m` | GAHM parameter solver v3 (custom iteration) | ~575 |
| `GAHM2026v4a.m` | GAHM parameter solver v4 (fsolve-based) | ~632 |
| `GAHM_VP.m` | Compute velocity/pressure at a single radial point | ~91 |
| `GAHM_VPradial.m` | Compute velocity/pressure along a radial line | ~168 |
| `radial_taper2.m` | Hyperbolic tangent taper function | ~95 |
| `radial2regular.m` | Interpolate radial grid to regular lon/lat grid | ~57 |
| `regular2radial.m` | Interpolate regular grid to radial grid | ~35 |
| `VEnvreg2radial2.m` | Interpolate environmental fields to radial grid | ~62 |
| `read_ATCF_fort22.m` | Read ATCF/fort22 format track files | ~658 |
| `read_IBTrACS2.m` | Read IBTrACS format track files | ~118 |
| `read_Env_and_Hurr_fields2.m` | Read gridded environmental/hurricane fields | ? |
| `writeGAHM2026NetCdf.m` | Write output to NetCDF | ~114 |
| `apply_WAF_from_raster.m` | Apply Wind Adjustment Factor from raster | ~55 |
| `write_fort22_ext.m` | Write extended fort.22 output | ? |

---

## Issues Identified

### 1. Code Duplication

#### 1.1 `compute_Rmax_tot` duplicated 3 times
- `GAHM2026v3e.m` lines 527-563 (nested function `compute_Rmax_tot`)
- `GAHM2026v4a.m` lines 596-632 (nested function `compute_Rmax_tot`)
- `read_ATCF_fort22.m` lines 621-657 (nested function `compute_Rmax_out`, same logic different name)

#### 1.2 Quadrant unit vectors computed 4 times
Identical 4-line block:
```matlab
VVorQuaduv_tbl(1,:)=[-1,1]/norm([-1,1])*(LatNS/abs(LatNS));
VVorQuaduv_tbl(2,:)=[1,1]/norm([1,1])*(LatNS/abs(LatNS));
VVorQuaduv_tbl(3,:)=[1,-1]/norm([1,-1])*(LatNS/abs(LatNS));
VVorQuaduv_tbl(4,:)=[-1,-1]/norm([-1,-1])*(LatNS/abs(LatNS));
```
Appears in: `GAHM2026v3e.m` L213-216, `GAHM2026v4a.m` L204-207, `GAHM2026_consistency.m` L211-214, `GAHM_VP.m` L59-62

#### 1.3 Theta-to-quadrant interpolation logic duplicated
The "identify which radials theta falls between" block (~20 lines) in:
- `GAHM_VPradial.m` L64-85
- `compute_Rmax_tot` (and its 3 copies above)

#### 1.4 Warning/error messages printed twice
Every `fprintf(...)` is followed by `fprintf(fid,...)` throughout the codebase. Affects:
- `GAHM2026_consistency.m` (most severe, ~20 pairs)
- `GAHM2026_prep.m`
- `GAHM2026v3e.m` / `GAHM2026v4a.m`
- `radial_taper2.m`
- `GAHM2026.m`

#### 1.5 GAHM data structure documentation copy-pasted into 5+ files
The 80+ line comment block documenting the GAHM struct appears in:
- `GAHM2026v3e.m` L85-137
- `GAHM2026v4a.m` L73-125
- `GAHM2026_consistency.m` L81-131
- `GAHM2026_prep.m` L52-102
- `GAHM2026.m` L68-146

#### 1.6 Duplicate MSLP/Vmax validation in `GAHM2026_prep.m`
Lines 135-147 and 249-262 perform the exact same check.

### 2. Magic Numbers
- `omega = 0.00007272` (appears in v3e, v4a, GAHM_VP)
- `earthRadiusInMeters = 6371000` (appears in prep, read_ATCF)
- `1852` (nm-to-m, used ~15 times across files)
- `1.944` vs `1.94384` (kt-to-m/s, inconsistent between files)
- `0.51444` (kt-to-m/s alternate form)
- Turning angle breakpoints: `1.2`, `10`, `25`, `75`

### 3. Monolithic `GAHM2026.m`
660+ lines doing at least 8 distinct jobs: track I/O, time looping, GAHM parameter computation, radial profile calculation, time interpolation, environmental field handling, taper application, output grid interpolation, WAF application, blended output assembly.

### 4. Function/Filename Mismatch
`GAHM2026.m` declares function `blend_GAHM2026b(...)` -- MATLAB requires these to match.

### 5. LatNS Division by Zero
`LatNS/abs(LatNS)` used in 4+ files; divides by zero if storm crosses equator.

### 6. No Pre-allocation
`radial2regular.m` L32-43 concatenates arrays in a loop instead of pre-allocating.

### 7. v3e/v4a Version Split
Both solvers share ~70% identical code (input unpacking, SVorQuad computation, RmaxQ selection, gap-filling). They differ only in the `compute_Bg` implementation (v3: custom iteration; v4: `fsolve` requiring Optimization Toolbox).

---

## Refactoring Plan

### Phase 0: Safety Net (prerequisite, ~2 hours) -- COMPLETED

Regression testing harness created in `tools/`:

- **`tools/generate_baseline.m`** — Runs the pipeline with two configurations (env_type=1 lightweight, env_type=3 full with Florence.mat) and saves key output fields to `.mat` baseline files.
- **`tools/compare_to_baseline.m`** — Re-runs the pipeline and compares all key fields against the saved baseline with configurable tolerances. Reports PASS/FAIL per field with max absolute and relative differences.

**Checked fields**: TC velocity (VelU, VelV), pressure, environmental fields, GAHM parameters (B, Bg, phi, Rmax, RmaxQ, Rmax_tot, SVorMax, flags), and track data (Lat, Lon).

**Tolerances**: velocity 1e-10 m/s, pressure 1e-10 mb, distance 1e-6 m, parameters 1e-10, flags exact match.

**Usage**:
1. Before refactoring: `>> generate_baseline` (saves `tools/baseline_env1.mat`, `tools/baseline_env3.mat`)
2. After each refactor: `>> compare_to_baseline` (re-runs and compares)

---

### Phase 1: Extract Duplicated Utilities (high ROI, low risk, ~6 hours)

#### 1.1 Extract `computeRmaxTot.m`
- Standalone function: `[Rmax, theta] = computeRmaxTot(RmaxQ, Venv_xy)`
- Replace 3 nested/local copies (v3e, v4a, read_ATCF)

#### 1.2 Extract `quadrantUnitVectors.m`
- Standalone function: `V = quadrantUnitVectors(LatNS)` returning 4x2 array
- Replace 4 copies

#### 1.3 Extract `thetaToQuadrantPair.m`
- Standalone function: `[RP, IF] = thetaToQuadrantPair(thetaDeg)`
- Use in `GAHM_VPradial` and `computeRmaxTot`

#### 1.4 Create `logMsg.m`
- Standalone function: `logMsg(fid, level, fmt, varargin)`
- Prints to stdout and (if fid valid) to file
- Supports `'WARN'`/`'ERROR'`/`'INFO'` prefixes
- Replace all doubled `fprintf` pairs

#### 1.5 Create `GAHM_physical_constants.m`
- Returns struct with: `omega`, `earthRadiusM`, `nm2m=1852`, `kt2ms=0.514444`, `ms2kt=1/kt2ms`
- Replace magic number literals gradually

#### 1.6 Extract `turnAngleDeg.m`
- Standalone function: `ta = turnAngleDeg(r, RmaxQ)`
- Encapsulates the piecewise turning angle formula

---

### Phase 2: Fix In-Place Code Smells (targeted, ~4 hours)

#### 2.1 Remove duplicate MSLP/Vmax validation
- In `GAHM2026_prep.m`, remove second block (L249-262)
- Single early-return at L135-151

#### 2.2 Guard against LatNS == 0
- Add: `hemiSign = sign(LatNS); if hemiSign==0, hemiSign=1; end`
- In all files computing unit vectors

#### 2.3 Fix function/filename mismatch
- In `GAHM2026.m`, change `function ... = blend_GAHM2026b(...)` to `GAHM2026(...)`

#### 2.4 Standardize kt-to-m/s conversion
- Use single constant from Phase 1.5 everywhere
- Fix inconsistency between `1.944` and `1.94384`

#### 2.5 Pre-allocate in `radial2regular.m`
- Pre-allocate `VPscatter_lon`, `VPscatter_lat`, etc. before loop

---

### Phase 3: Decompose `GAHM2026.m` (~1-2 days)

Break the 660-line monolith into focused functions. Keep top-level signature stable.

| New Function | Responsibility |
|-------------|----------------|
| `readAndSliceTrack.m` | Wraps `read_ATCF_fort22`/`read_IBTrACS2` + start/end time slicing |
| `computeGAHMAtTrackTime.m` | One timestep: prep -> consistency -> solve (selects v3/v4) |
| `computeRadialProfiles.m` | `for it=1:ntheta` loop calling `GAHM_VPradial` |
| `interpolateInTime.m` | Time-interpolation of radial fields between track snaps |
| `loadEnvOnRadialGrid.m` | env_type 1/2/3 branching for environmental fields |
| `applyTaperOnRadialGrid.m` | Compute + apply taper to vortex and hurricane fields |
| `interpolateToOutputGrid.m` | Calls `radial2regular`; handles grid vs points |
| `assembleBlendedOutputs.m` | Constructs final `Reggrid_TC_out`, `Reggrid_Env_out`, etc. |

The orchestrator shrinks to ~100-150 lines.

---

### Phase 4: Unify v3e/v4a Solvers (~1-2 days)

#### 4.1 Create `GAHM2026_solve.m`
- Single entry point: `GAHM_out = GAHM2026_solve(GAHM_in, GAHM_constants, fid)`
- Dispatches based on `GAHM_constants.version`

#### 4.2 Extract shared code (~70% of both files)
- Input unpacking
- SVorQuad computation for Gcase 1 and 2
- RmaxQ selection
- Post-solve gap-filling for missing isotachs
- `computeRmaxTot` call

#### 4.3 Unify `compute_Bg` with two backends
- `[Bg, exitflag] = computeBg(B, Ro, opts)`
- Backend A: `computeBg_iterative` (current v3 logic)
- Backend B: `computeBg_fsolve` (current v4 logic)
- Auto-detect Optimization Toolbox: `license('test','Optimization_Toolbox')`

#### 4.4 Normalize outputs
- v3-specific outputs (`Rmic`, `Bgicmax`): keep in struct, set to NaN in v4

---

### Phase 5: Documentation Cleanup (~3 hours)

#### 5.1 Centralize GAHM struct documentation
- Create `documentation/GAHM_struct.md` with canonical definition
- Replace 5+ per-file copies with: `% See documentation/GAHM_struct.md for full data structure definition.`

#### 5.2 Slim per-file headers
- Keep only function-specific inputs/outputs documentation
- Remove duplicated variable definitions

---

## Risks & Guardrails

| Risk | Guardrail |
|------|-----------|
| Numerical drift from refactoring | Phase 0 regression harness; compare after every commit |
| `LatNS == 0` division by zero | Phase 2.2 guard |
| v4 requires Optimization Toolbox (`fsolve`) | Unified solver detects toolbox, falls back to v3 |
| `squeeze`/`permute` shape bugs | Standardize expected array dims at function boundaries |
| Breaking MATLAB function/filename rules | Phase 2.3 alignment |

---

## Priority Quick List (Top 10 Actions)

1. Create regression comparison harness (`tools/compare_runs.m`)
2. Create `logMsg.m` and replace duplicated `fprintf` pairs
3. Extract `computeRmaxTot.m` and use everywhere (including `read_ATCF_fort22`)
4. Extract `quadrantUnitVectors.m` utility
5. Extract `thetaToQuadrantPair.m` utility
6. Centralize physical constants (omega, Earth radius, kt<->m/s, nm<->m)
7. Remove duplicate MSLP/Vmax validation in `GAHM2026_prep.m`
8. Add `LatNS==0` guard
9. Fix function/filename mismatch in `GAHM2026.m`
10. Decompose `GAHM2026.m` into focused functions

---

## Notes

- **Do not delete v3 or v4**: both have value. v3 has no toolbox dependency; v4 uses more robust `fsolve`. Unify behind one interface.
- **OOP rewrite not recommended**: procedural pipeline is appropriate for this codebase once modularized.
- **Consider advanced path** (domain model, unit testing framework, formal unit handling) only if multiple contributors need stable APIs or performance becomes a bottleneck.
