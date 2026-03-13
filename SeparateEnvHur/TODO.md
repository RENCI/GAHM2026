# SeparateEnvHur — Code Review TODO

**Created**: March 7, 2026  
**Updated**: March 9, 2026  
**Source**: Amp code review of all 16 `.m` files + README

---

## 🔴 Likely Bugs — ✅ ALL FIXED

### 1. ✅ Distance factors swapped in `computeDistanceKm.m`
Fixed: `KM_PER_DEG_LON * cosd(ref_lat)` on dx, `KM_PER_DEG_LAT` on dy.

### 2. ✅ `getERA5Data.m` — `size(find(idx),1)` fails for row vectors
Fixed: replaced with `nnz(idx)`.

### 3. ✅ `findCutline.m` — no bounds clamping on cutline index
Fixed: added `isnan(tan_wind)` check in while loop, added `cutlineIdx = min(cutlineIdx, num_radial)` after loop.

### 4. ✅ `convertToPolarCoords.m` — azimuth grid duplicates endpoint
Fixed: `linspace(0, 2*pi, N+1)` then `th = th(1:end-1)`.

### 5. ✅ `logMsg(-1, 'ERROR', ...)` doesn't throw
Already handled: `logMsg` calls `error()` on ERROR level (line 31 of `util/logMsg.m`).

---

## 🟡 Magic Numbers — ✅ ALL ADDRESSED

### Named constants (internal)

| # | Change | Status |
|---|---|---|
| 1 | `computeBasicField.m`: `0.04` → `FILTER_RADIUS_SCALE`, `5` → `FILTER_ORDER`, `4` → `SAMPLE_RATE` | ✅ Done |
| 2 | `computeDistanceKm.m`: `110.54` → `KM_PER_DEG_LAT`, `111.32` → `KM_PER_DEG_LON` | ✅ Done |
| 3 | `findPressureCenter.m`, `SeparateEnvHur.m`: `/ 100` → `* PA2MB` (Pa → mb) | ✅ Done |
| 4 | `findCutline.m`: hardcoded `10` → `CONFIG.max_radius_deg` (3 occurrences) | ✅ Done |
| 5 | `SeparateEnvHur.m`: `* 10 / 1000` → `* CONFIG.max_radius_deg / CONFIG.num_radial_points` | ✅ Done |
| 6 | `SeparateEnvHur.m`: `abs(U+1i*V)` → `hypot(U, V)` | ✅ Done |

### Remaining (deferred — low priority)

| # | File | Magic Number | Notes |
|---|---|---|---|
| 1 | `findCutline.m:11` | `100` (min cutline start idx) | Could derive from config in degrees |
| 2 | `smoothCutline.m:5` | `2000` (convergence tolerance) | Could be config; add max-iteration guard |
| 3 | All cutline helpers | `24` sectors, `15°` spacing | Derive from `num_azimuth_points` in future refactor |

---

## 🟢 Variable Naming — ✅ ALL DONE

| Old | New | Files |
|---|---|---|
| `tem`, `temlon`, `temlat` | `localPsl`, `localLon`, `localLat` | `findPressureCenter` |
| `tem_ave_r` | `meanInnerRadiusDeg` | `SeparateEnvHur.m`, `computeBasicField.m` |
| `count` | `cutlineIdx` | `findCutline`, `smoothCutline`, `ensureConvexCutline`, `extractCutlineCoords`, `applyCircularSmooth` |
| `count_inner` | `cutlineIdx_inner` | `SeparateEnvHur.m` |
| `in` | `isInsideOuter` | `SeparateEnvHur.m`, `findCutline`, `storeResults` |
| `in_inner` | `isInsideInner` | `SeparateEnvHur.m`, `storeResults` |
| `d1` | `lowpassFilter` | `computeBasicField` |
| `cx`, `cy` | `centerLon`, `centerLat` | `findPressureCenter`, `convertToPolarCoords`, `findCutline` |
| `ThisMsl` | `slp` | `SeparateEnvHur.m` |
| `ThisU` | `u10` | `SeparateEnvHur.m` |
| `ThisV` | `v10` | `SeparateEnvHur.m` |
| `ThisWind` | `windSpeed` | `SeparateEnvHur.m` |
| `num` | `numTimes` | `initializeOutputArrays` |
| `tem` (in applyCircularSmooth) | `tripled` | `applyCircularSmooth` |

---

## 🔵 Duplication / Structure — PARTIALLY DONE

| Issue | Status |
|---|---|
| **`abs(U+1i*V)` vs `hypot(U,V)`** | ✅ Fixed |
| **Pa→mb conversion done 2×** | ✅ Both use `PA2MB` constant now (still computed in 2 places; acceptable since they're in different functions) |
| **Window extraction repeated 5×** | Deferred — extract shared `getWindow` helper in future refactor |
| **`griddata` on structured data** | Deferred — replace with `griddedInterpolant` or `interp2` in future refactor |

---

## 📝 Documentation — ✅ ALL FIXED

1. ✅ Output filename corrected to `<STORM_NAME>_<DESIGNATION>_<YEAR>.mat`
2. ✅ Output field names corrected (`env_msl`, `hur_msl`, etc.)
3. ✅ Struct example: added `storm_designation` and `search_range`
4. ✅ Units specified for grid-point parameters
5. ✅ Signal Processing Toolbox dependency added
6. ✅ Array orientation note added
7. ✅ `34/1.944` annotated with constant explanation

---

## ⚡ Performance — PARTIALLY DONE

| Item | Status |
|---|---|
| `false()` pre-allocation for masks | ✅ Done |
| Vectorize `computeDistanceKm` and `computeBearingFlag` | Deferred |
| Filter only needed domain in `applyButterworthFilter2D` | Deferred |
| Replace `griddata` with `griddedInterpolant` | Deferred |

---

## 🗂️ Legacy Cleanup — ✅ DONE

- ✅ Deleted `AMS_env.m.orig`
