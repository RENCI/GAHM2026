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
| `debug` | logical | Enable debug output | `true` |
| `storm_start` | datetime | Start time for processing | `datetime(2018,9,10,0,0,0)` |
| `storm_end` | datetime | End time for processing | `datetime(2018,9,18,0,0,0)` |

`storm_start` and `storm_end` define the processing time window for both SeparateEnvHur (ERA5 extraction) and GAHM2026 (track slicing). They are automatically propagated into `sepenvhur.storm_start`, `sepenvhur.storm_end`, `storm_info.starttime`, and `storm_info.endtime`.

---

### 2. SeparateEnvHur Parameters (`sepenvhur.*`)

Controls ERA5 data extraction and vortex scrubbing. The fields `storm_name`, `storm_year`, `storm_designation`, `track_file`, `storm_start`, and `storm_end` are populated from the shared variables — do not set them separately.

| Parameter | Type | Description | Default/Example |
|-----------|------|-------------|-----------------|
| `background_file` | char | Path to ERA5 NetCDF input file. Use `<year>` as a placeholder for the storm year (resolved at runtime by `getERA5Data`) | `'/path/to/<year>/<year>.global.nc'` |
| `storm_start` | datetime | Start time (from shared) | `storm_start` |
| `storm_end` | datetime | End time (from shared) | `storm_end` |
| `filter_grid_length` | numeric | Side length of the square filter extraction domain (degrees) | `30` |
| `output_grid_length` | numeric | Side length of the square output and isotach-search domain (degrees) | `20` |
| `search_radius` | numeric | Physical half-width (degrees) of the square pressure-center search window centered on the track location | `1.5` |
| `wind_threshold_outer` | numeric | Wind speed threshold for outer cutline (m/s) | `10` |
| `wind_threshold_inner` | numeric | Wind speed threshold for inner cutline (m/s) | `34/1.944` (~17.5, i.e. 34 kt) |
| `filter_isotach` | numeric | Independent isotach used to derive the filtering radius (m/s) | `17.5` |
| `filter_hp_multiplier` | numeric | Multiplier on mean filter-isotach radius for Butterworth half-power wavelength | `25` |
| `num_points_smoother` | numeric | Circular cutline smoothing width (azimuth samples) | `3` |
| `isotach_smooth_variance` | numeric | Variance convergence tolerance for isotach smoothing | `2000` |
| `debug` | logical | Print debug messages | `true` |
| `output_dir` | char | Output directory for `.mat` file | `'output'` |
| `storm_name` | char | Storm name (from shared) | `storm_name` |
| `storm_year` | numeric | Storm year (from shared) | `storm_year` |
| `storm_designation` | char | Basin + storm number (from shared) | `storm_designation` |
| `track_file` | char | Track data file path | `fullfile('input', track_file)` |

SeparateEnvHur detects source-grid spacing from strictly monotonic, uniform longitude and latitude vectors; both
directions must have equal spacing. It converts all three physical settings to cell counts. Each setting must span an
integer number of cells, while `filter_grid_length` and `output_grid_length` must span even cell counts so their
domains are centered. Filtering uses the larger `filter_grid_length` square; saved fields and all cutline searches use
the `output_grid_length` square. The filter isotach is independent of the inner and outer output-mask isotachs, and its
mean cutline radius multiplied by `filter_hp_multiplier` is the Butterworth half-power wavelength.

Unified configs set `num_azimuth_points = GAHM_compute_info.ntheta` and
`num_radial_points = GAHM_compute_info.nr`. Azimuth samples cover one revolution without duplicating the seam. Radial
samples include the storm center and the `output_grid_length/2` endpoint, so the increment is
`(output_grid_length/2)/(num_radial_points-1)`. The smoothing width and variance tolerance control circular isotach
smoothing across the azimuth seam.

The physical-degree settings above are the current interface. For one-period compatibility, legacy fixed-cell mode is
available only when `filter_domain_size`, `grid_half_size`, `output_half_size`, `search_range`, and `max_radius_deg`
are all supplied together. Partial legacy settings and combinations of legacy and physical-degree settings are
rejected. In legacy mode only, omitted filtering and smoothing controls retain their legacy defaults.

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
| `starttime` | datetime | Start time for processing (from shared `storm_start`). Set to `0` to use first track time | `storm_start` |
| `endtime` | datetime | End time for processing (from shared `storm_end`). Set to `0` to use last track time | `storm_end` |
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
| `file_name` | char | Grid output: WAF raster (`.tif`). Point output: point-WAF MAT-file. Ignored if `flag = false` | `'input/WAF_15deg_10km_6km_raster_test.tif'` |

For point output, the MAT-file must contain `WAF_points`, a struct array whose elements each have real, numeric, finite,
scalar `lon` and `lat` fields and a nonempty real, numeric, finite `WAF` vector. All vectors have equal length and
represent equal angular increments beginning at north and proceeding clockwise. Longitude and latitude are each
matched independently using an absolute tolerance of `1.0e-8` degrees. `applyWAFfromPoints` reports distinct clear
errors when a requested coordinate pair has zero matches or multiple matches.

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
| `Vortex_mask(i,:,:)` | (nt, nlat, nlon) | Produced outer cutline mask (0 = inside, 1 = outside) |
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

SeparateEnvHur produces `Vortex_mask`. Readers accept the compatible external-copy field `Vortex_mask_outer` as well
as the legacy/current `Vortex_mask`; `readEnvAndHurrFields2` prefers `Vortex_mask_outer` when both are present.

---

### 8. Output Control (`output_info.*`)

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `diagnostics` | char | File path for diagnostic messages | `fullfile('output', '<NAME>_<DESIG>_<YEAR>_GAHM2026_diagnostics.dat')` |
| `NetCDFfilename` | char | Base output NetCDF path (`.nc` appended automatically) | `'output/<NAME>_<YEAR>'` |
| `timeinc` | numeric | Output time interval (hours). Must be ≤ track file snapshot interval | `1` |
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
| | `.Mask1` | 0/1 | Inner blending mask |
| | `.Mask2` | 0/1 | Outer blending mask |
| `Reggrid_TC_out(i)` | `.VelU` | m/s | Total TC E-W wind velocity |
| | `.VelV` | m/s | Total TC N-S wind velocity |
| | `.Press` | mb | Total TC pressure |
| `Reggrid_Env_out(i)` | `.VelU` | m/s | Environmental E-W velocity |
| | `.VelV` | m/s | Environmental N-S velocity |
| | `.Press` | mb | Environmental pressure |
| `Reggrid_VVor_invtapHur_out(i)` | `.VelU` | m/s | GAHM vortex + inverse-tapered hurricane E-W velocity (`env_info.type = 3`) |
| | `.VelV` | m/s | GAHM vortex + inverse-tapered hurricane N-S velocity (`env_info.type = 3`) |
| | `.Press` | mb | GAHM vortex + inverse-tapered hurricane pressure (`env_info.type = 3`) |

`Reggrid_out(i).Mask1` (inner) and `Reggrid_out(i).Mask2` (outer) are present only when `env_info.type = 3`;
environment types 1 and 2 do not create these fields.

For `env_info.type = 3`, `Reggrid_VVor_invtapHur_out` is the structure array described above. For
`env_info.type = 1` or `2`, it is the existing numeric all-zero intermediate array rather than a structure array.

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
| `Points_VVor_invtapHur_out(i)` | `.datetime`, `.Lon`, `.Lat` | —/degrees | Point coordinates and timestamp |
| | `.U10`, `.V10` | m/s | GAHM vortex + inverse-tapered hurricane velocity for type 3; zero arrays for types 1 and 2 |
| | `.Press` | mb | GAHM vortex + inverse-tapered hurricane pressure for type 3; zero array for types 1 and 2 |

When `output_info.type = "points"`, `Points_VVor_invtapHur_out` always contains `datetime`, `Lon`, `Lat`, `U10`,
`V10`, and `Press`. For `env_info.type = 1` or `2`, its wind and pressure fields are zero arrays with the same shape as
the point coordinates. For `env_info.type = 3`, they contain the GAHM vortex + inverse-tapered hurricane values.

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
   storm_start       = datetime(2018,10,7,0,0,0);
   storm_end         = datetime(2018,10,12,0,0,0);
   ```
3. Update `sepenvhur.background_file` with the path to the ERA5 data (use `<year>` as a placeholder for the storm year).
4. Adjust GAHM model parameters as needed.
5. Run:
   ```matlab
   >> run_GAHM2026('config_Michael')
   ```
