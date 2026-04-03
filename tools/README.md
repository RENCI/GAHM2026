# GAHM2026 Regression Testing Tools

Scripts for verifying that code refactoring does not change numerical results.

## Quick Start

In MATLAB, from the `GAHM2026` project directory:

```matlab
% 1. add tools dir to path
addpath('tools')

% 2. Generate baseline (run once before refactoring)
generate_baseline

% 3. After making code changes, verify results match
compare_to_baseline
```

## Scripts

### `generate_baseline.m`

Runs the `GAHM2026` pipeline and saves key output fields to `.mat` files for later comparison. Four test configurations are executed:

| Test | env_type | Description | Data Required |
|------|----------|-------------|---------------|
| 1 | 1 | ADCIRC/ASWIP environmental velocity | `ibtracs.NA.list.v04r01.csv` only |
| 2 | 2 | Lin & Chavez (2012) environmental velocity | `ibtracs.NA.list.v04r01.csv` only |
| 3 | 3 | Gridded environmental fields + taper + WAF (51×51) | `Florence.mat`, WAF raster |
| 4 | 3 | Full Florence (351×351) | `Florence.mat`, WAF raster |

Tests 3 and 4 are automatically skipped if `Florence.mat` is not present.

Tests 1 and 2 are lightweight (no gridded env file needed). All tests use the storm configuration from `run_GAHM2026.m` (Hurricane Florence, 2018-09-13 12Z to 2018-09-15 00Z).

**Output files** (not committed to git):
- `tools/baseline_env1.mat` — baseline for env_type=1
- `tools/baseline_env2.mat` — baseline for env_type=2
- `tools/baseline_env3.mat` — baseline for env_type=3

### `compare_to_baseline.m`

Re-runs the pipeline with identical parameters and compares all key fields against the saved baseline. Reports PASS/FAIL for each field with maximum absolute and relative differences.

**Fields compared**:

| Category | Fields | Tolerance |
|----------|--------|-----------|
| TC velocity | `VelU`, `VelV` | 1e-10 m/s |
| TC pressure | `Press` | 1e-10 mb |
| Env velocity | `VelU`, `VelV` | 1e-10 m/s |
| Env pressure | `Press` | 1e-10 mb |
| GAHM scalar params | `B`, `SVorMax_10_10` | 1e-10 |
| GAHM matrix params | `Bg`, `phi`, `flag` | 1e-10 (flags: exact) |
| GAHM distances | `Rmax`, `RmaxQ`, `Rmax_in`, `Rmax_tot` | 1e-6 m |
| Track data | `Lat`, `Lon` | 1e-12 deg |

All comparisons are NaN-aware: matching NaN patterns pass, mismatched NaN patterns fail.

**Example output**:
```
=== GAHM2026 Regression Comparison ===

--- Test 1: env_type=1 (ADCIRC/ASWIP) ---
  Baseline generated: 06-Feb-2026 14:30:00
  Run completed in 45.2 seconds
  Timesteps: 37 (match)
  Gridded TC output:
    PASS: TC_VelU              max_abs=0.00e+00  max_rel=0.00e+00
    PASS: TC_VelV              max_abs=0.00e+00  max_rel=0.00e+00
    PASS: TC_Press             max_abs=0.00e+00  max_rel=0.00e+00
  GAHM parameters (13 track times):
    PASS: GAHM.B               max_abs=0.00e+00  max_rel=0.00e+00
    ...

=== SUMMARY ===
  PASS: 15
  FAIL: 0
  Result: ALL CHECKS PASSED
```
