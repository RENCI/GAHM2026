# Combining netCDF files into NWS13/NWS30 format

Merges a large-scale background field (e.g. ERA5) and one or more nested
storm-scale fields (e.g. a parametric hurricane model) into a single
grouped NetCDF4 file, for use as ADCIRC NWS13/NWS30 forcing.

Two implementations, functionally equivalent — use whichever fits your
workflow:

| | File | Interface |
|---|---|---|
| Python | `nws13_combine_ranks.py` | CLI args or YAML config |
| MATLAB | `nws13_combine_ranks.m` | function with name-value arguments |

To plot the result, see [README.nws13.class.md](README.nws13.class.md).

---

## Contents

- [Concept: ranks and groups](#concept-ranks-and-groups)
- [Python usage](#python-usage)
- [MATLAB usage](#matlab-usage)
- [Options](#options)
- [Processing pipeline](#processing-pipeline)
- [Variable renaming](#variable-renaming)
- [Output structure](#output-structure)
- [Verifying output](#verifying-output)
- [Constraints and gotchas](#constraints-and-gotchas)

---

## Concept: ranks and groups

A combined file has one netCDF4 group per rank:

- **Rank 1** — the large-scale background field, covering the whole domain
  for the whole run.
- **Ranks 2+** — storm-scale nests, layered on top in order. Each nest
  typically covers a smaller area, a shorter time window, or both, and may
  have coordinates that move with the storm.

Each group carries `rank` and `source` attributes. The root file carries a
`group_order` attribute — a space-separated list of group names, in rank
order — which is how downstream readers discover the groups.

`CARLA_AL03_1961.nc`, included here as an example nest, is output from the
GAHM2026 parametric storm model for Hurricane Carla, 1961.

---

## Python usage

```bash
# YAML config:
python nws13_combine_ranks.py --config example_config.yaml

# CLI arguments:
python ./nws13_combine_ranks.py -o ERA5_CARLA_AL03_1961.nc \
    --main era5.nc:Main:ERA5 \
    --nest "CARLA_AL03_1961.nc:Carla1961:GAHM2026" \
    --epoch 1950-01-01 \
    --encoding PSFC:double,U10:double,V10:double
```

Dependencies: `xarray`, `numpy`, `pyyaml`. No `requirements.txt`; install
manually.

### Input specs

`--main` and `--nest` take a colon-delimited spec:

```
file:group:source[:time_filter]
```

`--nest` is repeatable; ranks are assigned in order (2, 3, ...). The
`source` field may itself contain colons if the whole spec is quoted — the
parser takes field 1 as `file`, field 2 as `group`, treats a trailing field
that looks like a date (≥8 chars, starts with a digit) as `time_filter`,
and joins everything in between as `source`:

```bash
--nest "storm.nc:Florence2018:Florence, BestTrack, Holland:2018-09-05"
```

A spec with fewer than 3 fields is a fatal error.

### YAML config

```yaml
output: /projects/ees/MAPP/nws13test_Sept2018.nc
epoch: "1970-01-01"
institution: RENCI
pressure_units: mb    # 'mb' (default, converts Pa to mb) or 'Pa'

# Global variable encoding applied to all groups
encoding:
  PSFC: double
  U10: double
  V10: double

# Large-scale background field (rank 1)
main:
  file: /projects/ees/TDS/regional/wna/2018/09.wna.nc
  group: Main
  source: ERA5

# Nested domains (rank 2, 3, ... in order)
nests:
  - file: /projects/ees/MAPP/MG_Florence_v2.nc
    group: Florence2018
    source: "Florence, BestTrack, Holland"
    time_filter: "2018-09-05"
```

CLI arguments override config-file values, so a config can be used as a
base and tweaked per run.

---

## MATLAB usage

```matlab
% Main only
nws13_combine_ranks('output.nc', 'era5.nc', 'Main', 'ERA5')

% Main + one nest
nws13_combine_ranks('ERA5_CARLA_AL03_1961.nc', 'era5.nc', 'Main', 'ERA5', ...
    'nests', {{'CARLA_AL03_1961.nc', 'Carla1961', 'GAHM2026'}}, ...
    'epoch', '1950-01-01')

% Main + multiple nests, one with a time filter
nws13_combine_ranks('output.nc', 'era5.nc', 'Main', 'ERA5', ...
    'nests', {{'storm1.nc', 'Florence2018', 'GAHM', '2018-09-05'}, ...
              {'storm2.nc', 'Michael2018', 'GAHM'}}, ...
    'epoch', '1970-01-01')

% Keep PSFC in Pa instead of converting to mb
nws13_combine_ranks('output.nc', 'era5.nc', 'Main', 'ERA5', ...
    'pressure_units', 'Pa')

% Disable deflate compression
nws13_combine_ranks('output.nc', 'era5.nc', 'Main', 'ERA5', ...
    'deflate_level', 0)
```

Signature:

```matlab
nws13_combine_ranks(OUTPUT, MAIN_FILE, MAIN_GROUP, MAIN_SOURCE, ...)
```

`nests` is a cell array of cell arrays, each `{file, group, source}` or
`{file, group, source, time_filter}`. Ranks assigned in order.

All text arguments — including entries inside `nests` — accept a char
vector (`'...'`) or a scalar string (`"..."`); everything is normalized to
char internally, since the low-level `netcdf.*` API is not consistently
string-aware.

Uses MATLAB's built-in low-level `netcdf.*` API. No toolbox dependencies
beyond base MATLAB.

---

## Options

| Python CLI | Python YAML | MATLAB name-value | Default | Effect |
|---|---|---|---|---|
| `-o` / `--output` | `output` | 1st positional | — (required) | Output NetCDF4 path |
| `--main` | `main` | positionals 2–4 | — (required) | Rank 1 dataset |
| `--nest` (repeatable) | `nests` | `'nests'` | none | Rank 2+ datasets |
| `--epoch` | `epoch` | `'epoch'` | `1970-01-01` | Reference epoch for output times |
| `--institution` | `institution` | `'institution'` | `RENCI` | Global `institution` attribute |
| `--encoding` | `encoding` | n/a — always `NC_DOUBLE` | — | Per-variable output dtype |
| `--pressure-units` | `pressure_units` | `'pressure_units'` | `mb` | `mb` or `Pa` |
| `--deflate-level` | `deflate_level` | `'deflate_level'` | `5` | zlib level 0–9; 0 disables |
| n/a | `time_filter` (per input) | 4th nest cell | none | Discard times before this date |

`--encoding` takes `VAR:DTYPE,...`, e.g. `PSFC:double,U10:double,V10:double`.
The MATLAB version has no equivalent flag because it writes PSFC, U10, and
V10 as `NC_DOUBLE` unconditionally.

Deflate is applied to every variable in every group, coordinate variables
included. The MATLAB version skips scalar variables, which have no
dimensions to chunk.

---

## Processing pipeline

Both implementations run the same steps per input file, in
`load_and_prepare`:

1. **Rename** variables, coordinates, and dimensions to canonical output
   names, case-insensitively (see [below](#variable-renaming)).
2. **Convert pressure**, if `pressure_units` is `mb`: divide by 100 **only
   when the source `units` attribute is literally `Pa`**. If the source is
   already `mb` or `hPa`, the conversion is skipped and a message printed —
   dividing again would corrupt the data. The output `units` attribute is
   set to the requested value either way.
3. **Fill missing `long_name`** attributes on PSFC / U10 / V10:

   | Variable | Default `long_name` |
   |---|---|
   | `PSFC` | Surface Pressure |
   | `U10` | 10 metre U wind component |
   | `V10` | 10 metre V wind component |

4. **Expand 1-D coordinates to 2-D.** If `yi` and `xi` are both 1-D, drop
   them and add `lat(yi,xi)` / `lon(yi,xi)` via meshgrid, tagged
   `degrees_north` / `degrees_east`. The `yi`/`xi` **dimensions** persist;
   only the 1-D index variables go away. Nest files usually already have
   multi-dimensional lat/lon and skip this step.
5. **Apply `time_filter`**, if given — drop all times before that datetime,
   subsetting every time-dimensioned variable along with the time vector.
6. **Convert time** to `int32` minutes since `epoch`, with attributes
   `axis=T`, `coordinates=time`, `units="minutes since <epoch> 00:00:00"`,
   `long_name=time`, `calendar=gregorian`.
7. **Stamp** `rank` and `source` as group attributes.

Then the writer creates the output file, writes the `group_order` and
`institution` global attributes, and appends each dataset as a named group.

### Implementation differences

Same output, different mechanics:

- **Python** builds `xr.Dataset` objects and calls `to_netcdf(..., group=)`
  once per group, letting xarray handle encoding and compression.
- **MATLAB** walks `ncinfo` metadata and drives `netcdf.defGrp` /
  `defDim` / `defVar` / `defVarDeflate` / `defVarFill` explicitly, closing
  define mode before writing data with `netcdf.putVar`.
- MATLAB's `ncread` silently applies `scale_factor`/`add_offset` and masks
  `_FillValue` to NaN. When either attribute is present the data is already
  unpacked, so the MATLAB version promotes the output to `NC_DOUBLE` and
  **drops** `scale_factor`, `add_offset`, and `missing_value` from the
  output attributes — otherwise a CF-aware reader would unpack a second
  time.
- MATLAB writes every variable with an explicit START/COUNT hyperslab
  covering the whole array, because `netcdf.putVar`'s 2-argument
  whole-variable form does not work on variables with an unlimited
  dimension.
- MATLAB's `netcdf.defVar` takes dimension IDs in the reverse of ncdump's
  display order. For the meshgrid-expanded coordinates, `nc_dims` is
  therefore listed as `{'xi','yi'}` with the data transposed to match, so
  `lat`/`lon` are declared `(yi,xi)` in the file — the same spatial order as
  `PSFC/U10/V10(time,yi,xi)`.

---

## Variable renaming

Inputs use varying naming conventions. Both implementations apply the same
case-insensitive rename map, so output is consistent:

| Input name | Output name | Notes |
|---|---|---|
| `msl` | `PSFC` | Mean sea level pressure |
| `u10` | `U10` | 10m U wind component |
| `v10` | `V10` | 10m V wind component |
| `latitude` | `yi` (dim) + `lat` (2-D var) | Expanded via meshgrid |
| `longitude` | `xi` (dim) + `lon` (2-D var) | Expanded via meshgrid |

Names not in the map pass through unchanged.

---

## Output structure

```
root:
  group_order = "Main Carla1961"
  institution = "RENCI"

  group: Main (rank=1, source="ERA5")
    dims: time(unlimited), yi, xi
    vars: PSFC(time,yi,xi), U10(...), V10(...),
          lat(yi,xi), lon(yi,xi), time(time)

  group: Carla1961 (rank=2, source="GAHM2026")
    dims: time(unlimited), yi, xi
    vars: PSFC(time,yi,xi), U10(...), V10(...),
          lat(time,yi,xi), lon(time,yi,xi), time(time)
```

Conventions:

- Time is always **`int32` minutes since epoch**; epoch is configurable,
  default `1970-01-01`.
- PSFC, U10, V10 are written as `NC_DOUBLE`.
- Rank 1 has static coordinates; nests commonly have time-varying ones,
  since the nest follows the storm.

---

## Verifying output

```bash
ncdump -h ERA5_CARLA_AL03_1961.nc
```

Then load it in MATLAB and plot — see
[README.nws13.class.md](README.nws13.class.md):

```matlab
obj = nws13('ERA5_CARLA_AL03_1961.nc');
obj.drawSnap(1);
```

---

## Constraints and gotchas

- **Input files must be flat.** Data must live at the root of each input,
  not inside netCDF groups. Grouped inputs are not read.
- **Input `time` must be `minutes since <date>`.** The MATLAB version
  regex-matches exactly that form to compute the epoch offset; other units
  will fail to parse.
- **Pressure conversion keys off the `units` attribute.** An input in
  Pascals with a missing or mislabeled `units` attribute will not be
  converted. Check the printed message.
- **The output file is overwritten**, not appended to.
- **`time_filter` compares against the input's own epoch**, not the output
  epoch.
