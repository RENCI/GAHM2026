# `nws13_combine_ranks`

`nws13_combine_ranks` combines a main meteorological NetCDF dataset and zero
or more nested NetCDF datasets into one grouped NetCDF4 file. Each input is
written to its own named group and assigned a priority rank: the main dataset
has rank 1, and nests have ranks 2, 3, and so on in the order supplied.

## Signature

```matlab
nws13_combine_ranks(output_file, main_file, main_group, main_source, varargin)
```

`varargin` contains the optional name-value pairs described below. The
implementation uses `inputParser`, so calls can use either `Name=Value` syntax
or the traditional quoted-name syntax shown in the examples.

## Required inputs

- `output_file`: path of the NetCDF4 file to create.
- `main_file`: path of the main (rank 1) NetCDF input file.
- `main_group`: output group name for the main dataset, such as `"Main"`.
- `main_source`: source description stored on the main group, such as `"ERA5"`.

Each text input accepts either a character vector (`'...'`) or a scalar string
(`"..."`). The same is true for text values in the options and nest entries.

## Name-value options

- `'nests'`: cell array of nest specifications. Each specification is a cell
  array with one of these forms:

  ```matlab
  {file, group, source}
  {file, group, source, timeFilter}
  ```

  `timeFilter` is a date or date-time string accepted by `datenum`. When
  supplied, only records on or after that value are retained. Nests default to
  `{}` and receive ranks 2, 3, and so on in their listed order.
- `'epoch'`: reference date used for output time values and units. The default
  is `'1970-01-01'`; output time units are
  `minutes since <epoch> 00:00:00`.
- `'institution'`: value of the output file's global `institution` attribute.
  The default is `'RENCI'`.
- `'pressure_units'`: output units for `PSFC`. Use `'mb'` (the default) to
  divide input pressure values by 100, or `'Pa'` to leave the values unchanged.

Examples use the lowercase option names shown above. By default,
`inputParser` also accepts case-insensitive and unambiguous partial matches.

## Examples

Create an output containing only the main dataset:

```matlab
nws13_combine_ranks('output.nc', 'era5.nc', 'Main', 'ERA5');
```

Add one nested dataset and use a 1950 epoch:

```matlab
nws13_combine_ranks('output.nc', 'era5.nc', 'Main', 'ERA5', ...
    'nests', {{'storm.nc', 'Carla1961', 'GAHM2026'}}, ...
    'epoch', '1950-01-01');
```

Add multiple nests and filter the first nest by time:

```matlab
nws13_combine_ranks('output.nc', 'era5.nc', 'Main', 'ERA5', ...
    'nests', {{'storm1.nc', 'Florence2018', 'GAHM', '2018-09-05'}, ...
              {'storm2.nc', 'Michael2018', 'GAHM'}}, ...
    'epoch', '1970-01-01');
```

Keep surface pressure in pascals:

```matlab
nws13_combine_ranks('output.nc', 'era5.nc', 'Main', 'ERA5', ...
    'pressure_units', 'Pa');
```

Scalar strings are also accepted:

```matlab
nws13_combine_ranks("output.nc", "era5.nc", "Main", "ERA5", ...
    "institution", "RENCI");
```

## Input expectations and transformations

Input files must be readable by `ncinfo`/`ncread` and contain an exact `time`
variable whose `units` attribute has the form `minutes since <date-time>`.
All input variables are copied, with these canonical renames:

| Input name | Output name |
|------------|-------------|
| `msl` | `PSFC` |
| `u10` | `U10` |
| `v10` | `V10` |
| `latitude` | `yi` |
| `longitude` | `xi` |

Name matching for these renames is case-insensitive. `PSFC`, `U10`, and `V10`
are written as doubles. If `yi` and `xi` are one-dimensional, they are expanded
to two-dimensional `lat` and `lon` variables aligned with the data fields.

## Output structure

The output is a NetCDF4 file with one group per input dataset:

```text
output.nc
+-- global attributes: group_order, institution
+-- Main/                    # rank="1", source="ERA5"
|   +-- time, coordinates, and data variables
+-- Florence2018/            # rank="2", source="GAHM"
    +-- time, coordinates, and data variables
```

The global `group_order` attribute lists group names in rank order. Every group
has `rank` and `source` attributes. Time values are converted to integer minutes
relative to the selected output epoch.
