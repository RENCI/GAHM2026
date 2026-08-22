# GAHM2026 Configuration Reference

Complete reference for all configuration parameters used by GAHM2026 and SeparateEnvHur.

Configuration files are located in `config/` and follow the naming convention `config_<StormName>.m`. The default config is `config/config_GAHM2026.m`. See the top-level [README](../README.md) for usage examples and auto-chaining behavior.

---

## Config File Layout

Every config file has the following sections. Storm identity parameters are defined once as plain MATLAB workspace variables and automatically populated into both the `sepenvhur` and `storm_info` structs.

### 1. Shared Storm Identity

These variables are used by both SeparateEnvHur and GAHM2026:

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `storm_name` | char | Storm name (all caps for IBTrACS) | `'FLORENCE'` |
| `storm_year` | numeric | 4-digit year | `2018` |
| `track_file` | char | IBTrACS CSV filename | `'ibtracs.NA.list.v04r01.csv'` |
| `storm_designation` | char | Basin + storm number | `'AL06'` |
| `track_type` | string | Track file format: `"IBTrACS"`, `"ATCF"` or `"fort22"` | `"IBTrACS"` |
| `debug` | logical | Enable debug output | `true` |
| `GAHM2026_start` | datetime | Start time for processing | `datetime(2018,9,10,0,0,0)` |
| `GAHM2026_end` | datetime | End time for processing | `datetime(2018,9,18,0,0,0)` |

`GAHM2026_start` and `GAHM2026_end` define the processing time window for both SeparateEnvHur (ERA5 extraction) and GAHM2026 (track slicing). They are automatically propagated into `sepenvhur.storm_start`, `sepenvhur.storm_end`, `storm_info.starttime`, and `storm_info.endtime`.

---

### 2. SeparateEnvHur Parameters (`sepenvhur.*`)

Controls gridded (ERA5) data extraction and vortex scrubbing. The fields `storm_name`, `storm_year`, `storm_designation`, `track_file`, `storm_start`, and `storm_end` are populated from the shared variables — do not set them separately.

As of v1.5 these parameters are specified in **physical degrees**, not numbers of grid cells. The grid increment is detected from the input file at runtime (`CONFIG.dlonlat`, requires equal longitude and latitude spacing) and all cell counts are derived from it, so one config works across input resolutions.

| Parameter | Type | Description | Default/Example |
|-----------|------|-------------|-----------------|
| `background_file` | char | Path to gridded NetCDF input (local or OPeNDAP URL). Use `<year>` as a placeholder for the storm year (resolved at runtime by `getERA5Data`) | `'.../<year>/<year>.nc'` |
| `storm_start` | datetime | Start time (from shared `GAHM2026_start`) | `GAHM2026_start` |
| `storm_end` | datetime | End time (from shared `GAHM2026_end`) | `GAHM2026_end` |
| `filter_grid_length` | numeric | Side length (deg) of the square box the digital filter runs on | `30` |
| `output_grid_length` | numeric | Side length (deg) of the cutline/output box. Must be <= `filter_grid_length`. Output grid is `output_grid_length/dlonlat + 1` per side | `20` |
| `search_radius` | numeric | Max radius (deg) around the track eye searched for the gridded pressure minimum. Diagnostic only — the extraction is centered on the track eye | `1.5` |
| `wind_threshold_outer` | numeric | Outer blending cutline isotach (m/s) | `10` |
| `wind_threshold_inner` | numeric | Inner blending cutline isotach (m/s) | `17.5` |
| `filter_isotach` | numeric | Isotach (m/s) whose mean radius sets the filter length scale | `17.5` |
| `filter_hp_multiplier` | numeric | Filter half-power scale = mean radius to `filter_isotach` x this. Larger `filter_isotach` or smaller multiplier moves energy into the environmental field | `25` |
| `num_points_smoother` | numeric | Moving-mean width used to smooth isotach cutlines | `3` |
| `isotach_smooth_variance` | numeric | Convergence tolerance for cutline smoothing | `2000` |
| `num_azimuthal_points` | numeric | Number of polar azimuths; set from `GAHM_compute_info.ntheta` | `24` |
| `num_radial_points` | numeric | Number of polar radial points; set from `GAHM_compute_info.nr` | `800` |
| `radial_inc` | numeric | `(output_grid_length/2)/num_radial_points` | derived |
| `output_file_name` | char | Path (no extension) the `.mat` is written to; set to `env_info.file_name` | `env_info.file_name` |
| `output_dir` | char | Directory created before saving. **Note:** not joined to `output_file_name` — see `DECISIONS.md` | `'output'` |
| `debug` | logical | Print debug messages | `true` |
| `isotach_output_radials` | numeric | Carried for upstream compatibility; never read | `num_azimuthal_points` |

**Removed in v1.5** (replaced by the physical fields above): `grid_half_size`, `output_half_size`, `filter_domain_size`, `max_radius_deg`, `num_azimuth_points`, `search_range`.

---

### 3. Storm / Track File Info (`storm_info.*`)

Identifies the storm and track file for GAHM2026. Most fields are derived from the shared identity variables.

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `track_file` | char | Full path to track data file | `fullfile('input', track_file)` |
| `file_type` | string | Track file format: `"ATCF"`, `"fort22"`, or `"IBTrACS"` | `"IBTrACS"` |
| `name` | char | Storm name | `storm_name` |
| `year` | char | Storm year (4-digit string) | `num2str(storm_year)` |
| `designation` | char | Basin + storm number (e.g., `'AL06'`). Ignored for single-storm ATCF files | `storm_designation` |
| `starttime` | datetime | Start time for processing (from shared `GAHM2026_start`). Set to `0` to use first track time | `GAHM2026_start` |
| `endtime` | datetime | End time for processing (from shared `GAHM2026_end`). Set to `0` to use last track time | `GAHM2026_end` |
| `outputfilename` | char | Base output filename | `sprintf('%s_%s', name, year)` |

---

### 4. GAHM Model Parameters (`GAHM_param_info.*`)

Constants that control the GAHM parametric wind model.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `Vmax_multiplier` | numeric | Multiplier for Vmax from track file (1 = use full Vmax) | `1` |
| `one2tenF` | numeric | Conversion factor from 1-min to 10-min wind speed (ADCIRC/ASWIP = 0.89) | `0.89` |
| `BLF` | numeric | Boundary layer reduction factor (ADCIRC/ASWIP = 0.9) | `0.9` |
| `Bmin` | numeric | Lower limit on Holland B parameter | `0.5` |
| `Bmax` | numeric | Upper limit on Holland B parameter | `2.5` |
| `SVorMax_10_tblmin` | numeric | Minimum 10-min vortex max wind speed (kts) | `20` |
| `SVorQuad_10_tblmin` | numeric | Minimum 10-min vortex quadrant wind speed (kts) | `5` |
| `rhoa` | numeric | Density of air (kg/m³) (ADCIRC/ASWIP = 1.204) | `1.204` |
| `pback_def` | numeric | Default background pressure (mb), used if not in track file | `1013` |
| `version` | numeric | GAHM solver version: `3` (v3e) or `4` (v4a) | `3` |
| `Bg0M` | numeric | Multiplier on B for initial guess in iterative solver (recommended: 1) | `1` |
| `c0` | numeric | Initial condition for c (0 < c < 1) in iterative solver (recommended: 0). Ignored for version 3 | `0` |

---

### 5. Radial Grid Parameters (`GAHM_compute_info.*`)

Controls the radial grid on which GAHM wind and pressure fields are computed.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `ntheta` | numeric | Number of azimuthal radial lines (e.g., 24 = every 15°) | `24` |
| `nr` | numeric | Number of points along each radial line | `800` |
| `delr` | numeric | Spacing between radial points (meters). Radial length = `nr × delr` | `1000` |

---

### 6. Wind Adjustment Factor (`WAF_info.*`)

Controls land-roughness-based wind speed adjustment.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `flag` | logical | Enable WAF correction | `false` |
| `file_name` | char | WAF data file. Ignored if `flag = false`. For `output_info.type = "grid"` this is a GeoTIFF raster with one layer per wind direction, read by `applyWAFfromRaster`. For `output_info.type = "points"` this is a MAT-file containing `WAF_points`, read by `applyWAFfromPoints` | `'input/WAF_15deg_10km_6km_raster_test.tif'` |

#### Point WAF MAT schema (`output_info.type = "points"`)

The MAT-file must contain a variable named `WAF_points`, a struct array in which each element is one output location:

| Field | Description |
|-------|-------------|
| `lon` | scalar longitude; must match an `output_info.lon` value exactly |
| `lat` | scalar latitude; must match the corresponding `output_info.lat` value exactly |
| `WAF` | vector of adjustment factors for evenly spaced wind directions, ordered clockwise from north starting at 0 deg |

Wind direction is the direction the wind blows *from*. A 360 deg column equal to the 0 deg column is appended internally so interpolation wraps. Every output point must match exactly one WAF point; unmatched or ambiguous coordinates raise an error. The WAF is applied to vortex velocity only, before the environmental wind is added; pressure is not adjusted.

---

### 7. Environmental Field Info (`env_info.*`)

Controls how the large-scale environmental velocity and pressure fields are handled. All fields after `type` are ignored unless `type = 3`.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `type` | numeric | Environmental field method: `1` = ADCIRC/ASWIP translation velocity, `2` = 0.6 × translation vel + 20° CCW rotation (Lin & Chavez 2012), `3` = gridded environmental field from SeparateEnvHur | `3` |
| `file_name` | char | Base path to `.mat` file (no extension). Derived from shared storm identity. Ignored for type 1 or 2 | `fullfile('output', sprintf('%s_%d', storm_name, storm_year))` |
| `taper_flag` | logical | Apply taper function to GAHM speed and pressure at blending boundary | `true` |
| `taper_mindelr2r1` | numeric | Minimum value of (r2−r1)/r2. If violated, r1 is reduced | `0.1` |
| `taper_a` | numeric | Steepness coefficient for hyperbolic tangent taper function (recommended: 2) | `2` |

#### Gridded Environmental File Format (`env_info.type = 3`)

When `env_info.type = 3`, the `.mat` file (produced by SeparateEnvHur) must contain a struct with:

| Field | Dimensions | Description |
|-------|-----------|-------------|
| `Time(i)` | (nt) | datetime array |
| `Lo(i,:,:)` | (nt, nlat, nlon) | Longitude grid |
| `La(i,:,:)` | (nt, nlat, nlon) | Latitude grid |
| `Vortex_mask_outer(i,:,:)` | (nt, nlat, nlon) | Outer cutline mask (0 = inside, 1 = outside). Files written before v1.5 carry this as `Vortex_mask`; `readEnvAndHurrFields2` accepts either name |
| `Vortex_mask_inner(i,:,:)` | (nt, nlat, nlon) | Inner cutline mask (0 = inside, 1 = outside) |
| `env_msl(i,:,:)` | (nt, nlat, nlon) | Environmental mean sea level pressure (mb) |
| `env_u10(i,:,:)` | (nt, nlat, nlon) | Environmental E-W wind velocity (m/s) |
| `env_v10(i,:,:)` | (nt, nlat, nlon) | Environmental N-S wind velocity (m/s) |
| `hur_msl(i,:,:)` | (nt, nlat, nlon) | Hurricane mean sea level pressure (mb) |
| `hur_u10(i,:,:)` | (nt, nlat, nlon) | Hurricane E-W wind velocity (m/s) |
| `hur_v10(i,:,:)` | (nt, nlat, nlon) | Hurricane N-S wind velocity (m/s) |
| `BestTrack_lon(i)` | (nt) | Best-track storm center longitude |
| `BestTrack_lat(i)` | (nt) | Best-track storm center latitude |
| `min_pressure_center_lon(i)` | (nt) | ERA5-derived storm center longitude |
| `min_pressure_center_lat(i)` | (nt) | ERA5-derived storm center latitude |
| `units` | dictionary | Units metadata |

Times must include all track file times; additional times (e.g., hourly) are permitted.

---

### 8. Output Control (`output_info.*`)

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `diagnostics` | char | File path for diagnostic messages | `fullfile('output', '<NAME>_<DESIG>_<YEAR>_GAHM2026_diagnostics.dat')` |
| `NetCDFfilename` | char | Base output NetCDF path (`.nc` appended automatically) | `'output/<NAME>_<YEAR>'` |
| `warnings` | char | File path for warning messages. Carried for upstream compatibility; never read | `fullfile('output', '<NAME>_<DESIG>_GAHM2026_warnings.dat')` |
| `timeinc` | numeric | Output time interval (hours). Must be ≤ track file snapshot interval. For `env_info.type = 3` must be an even multiple of the environmental file time increment | `1` |
| `pres_units` | string | Pressure units in the NetCDF output: `"mb"` or `"Pa"` | `"mb"` |
| `type` | string | Output type: `"grid"` or `"points"` | `"grid"` |

#### Grid output (`output_info.type = "grid"`)

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `nlon` | numeric | Number of longitude values (odd recommended). Ignored for `env_info.type = 3` | `351` |
| `nlat` | numeric | Number of latitude values (odd recommended). Ignored for `env_info.type = 3` | `351` |
| `dellon` | numeric | Grid spacing in longitude (decimal degrees) | `0.05` |
| `dellat` | numeric | Grid spacing in latitude (decimal degrees) | `0.05` |

**Notes on grid output:**
- For `env_info.type = 1` or `2`: the output grid is centered on the storm eye and moves in time. Grid extents are determined by `nlon`, `nlat`, `dellon`, `dellat`.
- For `env_info.type = 3`: the output grid matches the footprint of the environmental input field. `dellon`/`dellat` set the resolution (can be coarser or finer than the input grid, but must divide evenly into the footprint). `nlon`/`nlat` are computed automatically.

#### Point output (`output_info.type = "points"`)

| Parameter | Type | Description |
|-----------|------|-------------|
| `lon` | array | Longitude values for output points |
| `lat` | array | Latitude values for output points |

The number of longitude and latitude values must be equal and are fixed in time.

---

## Output Data Structures

### Grid output (`output_info.type = "grid"`)

| Struct | Field | Units | Description |
|--------|-------|-------|-------------|
| `Reggrid_out(i)` | `.datetime` | — | Timestamp |
| | `.Lon` | degrees | Longitude grid |
| | `.Lat` | degrees | Latitude grid |
| `Reggrid_TC_out(i)` | `.VelU` | m/s | Total TC E-W wind velocity |
| | `.VelV` | m/s | Total TC N-S wind velocity |
| | `.Press` | mb | Total TC pressure |
| | `.Mask1` | 0/1 | Outer blending mask |
| | `.Mask2` | 0/1 | Inner blending mask |
| `Reggrid_Env_out(i)` | `.U10` | m/s | Environmental E-W velocity |
| | `.V10` | m/s | Environmental N-S velocity |
| | `.Press` | mb | Environmental pressure |

### Point output (`output_info.type = "points"`)

| Struct | Field | Units | Description |
|--------|-------|-------|-------------|
| `Points_TC_out(i)` | `.datetime` | — | Timestamp |
| | `.Lon` | degrees | Output point longitudes |
| | `.Lat` | degrees | Output point latitudes |
| | `.U10` | m/s | TC E-W wind velocity |
| | `.V10` | m/s | TC N-S wind velocity |
| | `.Press` | mb | TC pressure |
| `Points_Env_out(i)` | `.datetime` | — | Timestamp |
| | `.Lon` | degrees | Output point longitudes |
| | `.Lat` | degrees | Output point latitudes |
| | `.U10` | m/s | Environmental E-W velocity |
| | `.V10` | m/s | Environmental N-S velocity |
| | `.Press` | mb | Environmental pressure |

### Radial grid data (always returned)

| Struct | Field | Description |
|--------|-------|-------------|
| `VPrad` | `.r` | Radial distance vector (m) |
| | `.theta` | Azimuthal angle vector (degrees) |
| | `.VVor(i)` | Vortex fields: `.VelU`, `.VelV`, `.Speed`, `.Press` |
| | `.Env(i)` | Environmental fields (`env_info.type = 3` only) |
| | `.EnvVor(i)` | Combined env + vortex fields (`env_info.type = 3` only) |

---

## Creating a Config for a New Storm

1. Copy `config/config_GAHM2026.m` (or any existing storm config) to `config/config_<StormName>.m`.
2. Update the shared storm identity section:
   ```matlab
   storm_name        = 'MICHAEL';
   storm_year        = 2018;
   track_file        = 'ibtracs.NA.list.v04r01.csv';
   storm_designation = 'AL14';
   GAHM2026_start    = datetime(2018,10,7,0,0,0);
   GAHM2026_end      = datetime(2018,10,12,0,0,0);
   ```
3. Update `sepenvhur.background_file` with the path to the ERA5 data (use `<year>` as a placeholder for the storm year).
4. Adjust GAHM model parameters as needed.
5. Run:
   ```matlab
   >> run_GAHM2026('config_Michael')
   ```
