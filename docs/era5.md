---
layout: default
title: ERA5 Data
nav_order: 5
permalink: /era5/
---

# ERA5 reanalysis data
{: .no_toc }

1. TOC
{:toc}

---

## What it is used for

GAHM2026 needs a large-scale meteorological field only when `env_info.type = 3`. In that mode
[SeparateEnvHur]({{ site.baseurl }}/separate-env-hur/) reads gridded 10 m winds and mean sea level
pressure, low-pass filters them to remove the storm's own vortex, and hands the resulting
*environmental* field to GAHM2026, which blends its parametric vortex back into it. Environmental
types `1` and `2` derive the environmental wind from the storm's translation velocity instead and
need no gridded data at all.

The gridded source in use is **ECMWF ERA5** reanalysis on single levels, at 0.25° resolution and
hourly output. Only three variables are required:

| Variable | Long name | Units in file |
|---|---|---|
| `u10` | 10 metre U wind component | `m s**-1` |
| `v10` | 10 metre V wind component | `m s**-1` |
| `msl` | Mean sea level pressure | `Pa` (converted to mb downstream) |

## Where the data lives

The data is hosted on the RENCI THREDDS server and read over OPeNDAP at run time. **Nothing is
downloaded** — `SeparateEnvHur/getERA5Data.m` opens the URL directly and reads the time slice it
needs.

Base URL: `https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/`

| Collection | Path under the base URL | Grid | Time |
|---|---|---|---|
| Global, annual | `global.1/uvp/<year>/<year>.nc` | 1440 × 721 @ 0.25° | hourly, 8760 steps for 2018 |
| Global, monthly | `global.1/uvp/<year>/<MM>.nc` | 1440 × 721 @ 0.25° | hourly, 720 steps for 1961-09 |
| Regional (WNA), annual | `regional/wna/uvp/<year>/<year>.wna.nc` | 201 × 201 @ 0.25° | hourly |
| Regional (WNA), monthly | `regional/wna/uvp/<year>/<YYYYMM>.wna.nc` | 201 × 201 @ 0.25° | hourly, 744 steps for 2018-09 |

The **WNA** (western North Atlantic) subset spans longitude −100° to −50° and latitude 50° down to
0°, covering a typical ADCIRC northwest-Atlantic and Gulf of Mexico domain. It is the default in
the Florence configurations and is far cheaper to read than the global files — 201 × 201 versus
1440 × 721 per timestep, and `getERA5Data` currently reads the full spatial extent of whatever
file it is given.

Some of the older global monthly files carry additional variables (`cp`, `t2m`) alongside the three
GAHM2026 needs. The extra variables are ignored.

## File conventions

Taken from the dataset attributes of `regional/wna/uvp/2018/201809.wna.nc`:

- `Conventions = "CF-1.6"`. The files originate from ECMWF MARS via `grib_to_netcdf`; the monthly
  regional files are time subsets cut with `ncks`.
- `u10`, `v10` and `msl` are stored as `Int16` with `scale_factor` / `add_offset` packing and
  `_FillValue = -32767`. MATLAB's `ncread` unpacks these automatically.
- `time` is `Int32` with units `minutes since 1970-01-01`, calendar `gregorian`.
- `latitude` is **descending** (50 → 0) and `longitude` ascending.

## How GAHM2026 reads it

`SeparateEnvHur/getERA5Data.m` is deliberately tolerant about file details:

- **Time variable name** — accepts either `time` or `valid_time`; anything else is a fatal error.
- **Time units** — parses any `<unit> since <reference>` string, where the unit is milliseconds,
  seconds, minutes, hours or days. The reference time may use a `T` separator, a trailing `Z`, or a
  UTC offset.
- **Longitude convention** — detected from the grid itself and logged. A grid with any negative
  longitude is treated as `-180_180`, otherwise `0_360`.
- **Year placeholder** — a literal `<year>` anywhere in `sepenvhur.background_file` is replaced
  with `storm_year` at run time, so one configuration can be reused across storms in a collection
  that is organized by year.
- **Local files work too** — if the path does not start with `http`, it is checked on disk instead
  of being treated as a URL.
- **Subsetting** — only the time dimension is subset, to the span of the requested track times.
  Spatial subsetting is a `TODO` in the source, so a global file is read at full extent.

Arrays come out of the file as `[lon × lat × time]` and are transposed per timestep to
`[lat × lon]` for the rest of the pipeline.

{: .warning }
> **The grid must have equal longitude and latitude spacing.** SeparateEnvHur detects the increment
> from the input file at run time as `CONFIG.dlonlat` and derives every cell count from it, which
> is what lets the `sepenvhur` parameters be specified in physical degrees rather than grid cells.

## Using it in a configuration

Regional monthly file, from `config/config_Florence.m`:

```matlab
sepenvhur.background_file = ...
    'https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/regional/wna/uvp/2018/201809.wna.nc';
```

Global monthly file for a 1961 storm, from `config/config_Carla_type3.m`:

```matlab
sepenvhur.background_file = ...
    'https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/global.1/uvp/1961/09.nc';
```

With the year placeholder, so the same line serves any storm year:

```matlab
sepenvhur.background_file = ...
    'https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/regional/wna/uvp/<year>/<year>.wna.nc';
```

A local file:

```matlab
sepenvhur.background_file = 'input/era5_Carla_forBlending_1961_09.nc';
```

## Inspecting a file before using it

The OPeNDAP endpoints answer the standard DAS/DDS requests, which is the quickest way to confirm a
file has what you need:

```bash
BASE=https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5
curl -s "$BASE/regional/wna/uvp/2018/201809.wna.nc.das"   # attributes, units, packing
curl -s "$BASE/regional/wna/uvp/2018/201809.wna.nc.dds"   # dimensions and shapes
curl -s "$BASE/regional/wna/uvp/2018/201809.wna.nc.ascii?longitude"   # coordinate values
```

From MATLAB the same URL works with `ncinfo` and `ncread`:

```matlab
url = ['https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/' ...
       'regional/wna/uvp/2018/201809.wna.nc'];
info = ncinfo(url);
{info.Variables.Name}
```

## Bringing your own data

Any NetCDF file — local or OPeNDAP — works as long as it provides:

1. Variables named `u10`, `v10` and `msl`.
2. Coordinate variables `longitude` and `latitude`, equally and identically spaced.
3. A time coordinate named `time` or `valid_time` with a parseable `units` attribute.
4. Times that span the configured processing window.

The source does not have to be ERA5. To pull ERA5 yourself from the Copernicus Climate Data Store
rather than using the RENCI server:

```python
import cdsapi

cdsapi.Client().retrieve(
    "reanalysis-era5-single-levels",
    {
        "product_type": "reanalysis",
        "variable": [
            "10m_u_component_of_wind",
            "10m_v_component_of_wind",
            "mean_sea_level_pressure",
        ],
        "year": "2018",
        "month": "09",
        "day": [f"{d:02d}" for d in range(1, 31)],
        "time": [f"{h:02d}:00" for h in range(24)],
        "area": [50, -100, 0, -50],   # N, W, S, E
        "format": "netcdf",
    },
    "era5_2018_09_wna.nc",
)
```

A CDS account and API key are required. Note that files retrieved from the current CDS often name
the time coordinate `valid_time` rather than `time` — `getERA5Data` handles both.

## Related pages

- [SeparateEnvHur]({{ site.baseurl }}/separate-env-hur/) — what happens to these fields once read.
- [Configuration]({{ site.baseurl }}/configuration/#2-separateenvhur-parameters-sepenvhur) — the
  full `sepenvhur` parameter list.
- [Derivation §4]({{ site.baseurl }}/derivation/#4-blending-with-gridded-large-scale-fields) — the
  blending formulation.
