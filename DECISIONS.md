# Decisions

## 2026-08-21 — Merge of GAHM2026 v1.5 into `newMerge_to_1.5`

**Chosen:** Adopt the behavior of the external v1.5 tree
(`GAHM2026-main_v1p5`) as authoritative, expressed in this repository's
naming and structural conventions.

**Alternatives:** (a) Replace this tree wholesale with v1.5, discarding the
lowerCamelCase renaming, formatting overhaul, input validation, and the
`tools/` regression harness. (b) Treat v1.5 as a reference and port only
selected features, as the earlier `merge_plan.md` on branch `mergeWithRick`
proposed for v1.4.

**Why:** v1.5 carries roughly six months of substantive work that never
reached this repository — point output, point-based Wind Adjustment Factors,
a physical-units rewrite of `SeparateEnvHur`, storm centering on the track
eye, and three numerical corrections. This repository diverged along an
orthogonal axis (naming, formatting, validation, tests). A raw diff between
the trees is dominated by cosmetic noise; the real new work is concentrated
in about a dozen files. Taking v1.5's behavior and this repository's form
keeps both bodies of work.

**Trade-offs:** Regression baselines are invalidated (see below). Some v1.5
defects are carried forward deliberately rather than fixed.

**Revisit if:** Rick's line diverges again without being merged back
promptly, in which case the two trees should be reconciled to a single
upstream rather than repeatedly re-merged.

---

## 2026-08-21 — Naming precedence in the v1.5 merge

**Chosen:** This repository's function and file names win
(`gahm2026Solve`, `readIBTrACS`, `applyWAFfromRaster`, ...). Config *field*
names follow v1.5 (`num_azimuthal_points`, `filter_grid_length`, ...).

**Alternatives:** Take v1.5's snake_case names throughout; or rename v1.5's
config fields to match a camelCase convention.

**Why:** User decision. The naming exception was scoped explicitly to
function naming, so configuration data keys follow the new code. Renaming
config fields would silently break any config file Rick distributes.

**Trade-offs:** Config files are now the one place in the repository where
snake_case is the convention. Documented in `CLAUDE.md`.

**Revisit if:** A future pass normalizes configuration schema handling.

---

## 2026-08-21 — NetCDF writer kept from this repository

**Chosen:** Keep this repository's `util/writeGAHM2026NetCdf.m`
(no netCDF group wrapper, `NC_DOUBLE` pressure, `output_info.pres_units`
selecting mb or Pa, 4-argument signature). Update v1.5's 3-argument call
site rather than reverting the writer.

**Alternatives:** Take v1.5's writer as part of "new code wins".

**Why:** v1.5's copy predates deliberate work on `main` in this repository:
`8d85720` removed group writing, `0e37001` fixed a `time_units` problem, and
`pres_units` was added afterward. Here "new code" is actually the older
code; taking it would silently revert three fixes.

**Trade-offs:** One deviation from the otherwise uniform "v1.5 wins" rule.
Configs must supply `output_info.pres_units`; it defaults to mb when absent.

**Revisit if:** Rick's line adds NetCDF output changes of its own.

---

## 2026-08-21 — Outer vortex mask renamed to `Vortex_mask_outer`

**Chosen:** `SeparateEnvHur/createOutputStruct.m` now emits
`Vortex_mask_outer` (v1.5 behavior). `util/readEnvAndHurrFields2.m` accepts
either `Vortex_mask_outer` or the legacy `Vortex_mask`, preferring the
former, and errors clearly if neither is present.

**Alternatives:** Keep producing `Vortex_mask`; or rename with no read-side
compatibility.

**Why:** The rename is a producer/consumer contract change on a `.mat`
artifact. Accepting both names on read costs one `isfield` check and no
behavioral change, and keeps every previously generated environmental file
loadable — including `tools/FLORENCE_AL06_2018.mat`, which the regression
harness depends on.

**Trade-offs:** A small amount of compatibility code that should eventually
be removed.

**Revisit if:** All environmental `.mat` files in circulation have been
regenerated.

---

## 2026-08-21 — SeparateEnvHur centers on the track eye

**Chosen:** Adopt v1.5's change (dated 8/18/2026 upstream): the extraction,
polar transform, and cutline search are centered on the interpolated track
eye position rather than on the location of minimum sea-level pressure in
the gridded input. `findPressureCenter` is still called each timestep, but
only to report the offset as a diagnostic.

**Why:** Rick's change. It removes a dependence on the gridded analysis
resolving the storm center, which is unreliable for weak or sheared storms.

**Trade-offs:** This is the single largest numerical change in the merge.
The `min_pressure_center_lon` / `min_pressure_center_lat` fields in the
output struct now carry the *track* position, not the pressure minimum —
the field names are now misleading. Left as-is to match v1.5.

**Revisit if:** Those output field names are cleaned up, in which case
rename them to `vortex_center_*` and restore the true pressure-minimum
diagnostic alongside.

---

## 2026-08-21 — Regression baselines regenerated, delta recorded

**Chosen:** Verify the existing baselines against pre-merge `HEAD`, freeze
them, record a delta report, then regenerate.

**Provenance:** Pre-merge baselines validated at commit
`8c4d6beb82523b1048cf968e18ddc76f27a8f4fc` (51/51 checks passing). Frozen
copies in `tools/premerge/` (gitignored). Delta recorded in
`tools/merge_v1p5_delta_report.txt`.

**Outcome:** The only numerical change measurable against the pre-merge
baseline came from normalizing zero quadrant radii to `NaN` in
`gahm2026Prep.m`, which *removes* NaN holes from the output (494 of 2601
cells at the affected timesteps) rather than introducing any. Every GAHM
parameter and track coordinate was bit-identical. Post-merge baselines were
regenerated with the merged SeparateEnvHur and pass 68/68; `generate_baseline`
now prefers a local ERA5 file so the suite no longer needs network access.

**Why:** The user flagged up front that baselines would not match. Silently
regenerating would discard the only evidence of which quantities the merge
actually moved.

**Trade-offs:** One extra full regression run.

**Revisit if:** Never — this is a one-time record of the merge.

---

## 2026-08-21 — Known v1.5 defects carried forward

**Chosen:** Port these verbatim rather than fixing them during the merge, so
results match Rick's runs bit-for-bit. Each is commented at the site.

1. **Polar-row / azimuth misalignment.** `convertToPolarCoords.m` builds
   `th = linspace(0, 2*pi, n_angle)`, which spaces rows by `2*pi/(n_angle-1)`
   and duplicates the 0/360-degree direction. `findCutline.m` and
   `computeDistanceKm.m` both assume row `j` sits at `j*360/n_angle` degrees.
   At `n_angle = 24` the conventions drift by up to ~15 degrees, so the
   cutline is evaluated against wind components from the wrong azimuth. A
   self-consistent form would be `th_deg = (1:n_angle)*(360/n_angle)`.
2. **Unbounded smoothing loop.** `smoothCutline.m` iterates until the
   variance change falls below `isotach_smooth_variance`, with no iteration
   cap. `ensureConvexCutline.m` has a `limit = 500` guard; this does not.
3. **Output directory ignored.** `SeparateEnvHur.m` creates
   `CONFIG.output_dir` but does not join it to `CONFIG.output_file_name`,
   so the directory it creates need not be the one it writes to.

**Why:** User decision — reproducing Rick's numbers exactly takes priority
over correctness of these three during the merge itself.

**Trade-offs:** Defect 1 affects results. Defects 2 and 3 are robustness and
housekeeping.

**Revisit if:** Open an issue per defect and fix on a separate branch, with
a fresh baseline, so each numerical change is attributable.

---

## 2026-08-21 — One v1.5 defect fixed because it is fatal

**Chosen:** Restore `track.search_range = round(CONFIG.search_radius/CONFIG.dlonlat);`
in `SeparateEnvHur.m`, a line v1.5 commented out.

**Why:** v1.5 commented out the assignment but still calls
`findPressureCenter`, whose first statement is `search_range = track.search_range;`.
As delivered, v1.5's `SeparateEnvHur.m` throws
`Unrecognized field name "search_range"` on the first timestep and cannot
run at all. Porting it verbatim would have shipped non-executing code.

**Trade-offs:** A deviation from "port verbatim". It has no numerical
effect: centering comes from the track position, and `search_range` now
only bounds the diagnostic pressure-minimum search. It also makes the
documented `sepenvhur.search_radius` parameter live rather than dead.

**Revisit if:** Rick confirms he intended to delete `findPressureCenter`
entirely, in which case remove the call and the parameter together.
