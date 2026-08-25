---
layout: default
title: Input Track Files
nav_order: 7
has_children: true
permalink: /track-files/
---

# Input track files

GAHM2026 reads three track formats, selected with `storm_info.file_type`:

| `file_type` | Format | Notes |
|---|---|---|
| `"IBTrACS"` | IBTrACS v04 CSV | Multi-storm file; `storm_info.designation` selects the storm. Downloaded automatically if absent |
| `"ATCF"` | ATCF a-deck / b-deck | Single storm per file; `designation` is ignored |
| `"fort22"` | ADCIRC `fort.22` (NWS=20) | ATCF-like, column-compatible |

The child pages document the two `fort.22` variants in detail:

- **[GAHM2026 fort.22]({{ site.baseurl }}/track-files/gahm2026-fort22/)** — the extended file
  written by `write_fort22_ext.m`, carrying the per-quadrant GAHM parameters computed by GAHM2026.
- **[ASWIP fort.22]({{ site.baseurl }}/track-files/aswip-fort22/)** — the file produced by the
  ASWIP preprocessor to drive GAHM inside ADCIRC.

{: .warning }
> The extended file written by GAHM2026 has a format similar to ADCIRC's `fort.22` but **must not**
> be used with GAHM (`NWS=20`) in ADCIRC. The $R_{mw}$ and $B_g$ values are not strictly compatible
> with the GAHM implementation in ADCIRC.

## Where the track data comes from

IBTrACS v04r01 CSV files are published by NOAA NCEI at
<https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/csv/>.
Place the file in `input/`; `run_GAHM2026` downloads it if it is not found.

Track files are parsed by `util/readIBTrACS.m` (shared by GAHM2026 and SeparateEnvHur) or by the
ATCF/fort.22 reader, then trimmed to the configured processing window by `sliceTrack` inside
`GAHM2026.m`.

## Units

Track quantities follow the ATCF conventions, not the SI units used internally:

| Quantity | Track file units | Internal units |
|---|---|---|
| Isotach radii, $R_{mw}$ | nautical miles | meters |
| Wind speed | knots, 1-min sustained at 10 m | m/s, 10-min average |
| Pressure | mb | mb |
| Angles | degrees clockwise from north | degrees clockwise from north |

Conversions use the constants in `util/gahmPhysicalConstants.m`. The 1-min to 10-min conversion
factor is `GAHM_param_info.one2tenF` (0.89); see
[Derivation §2]({{ site.baseurl }}/derivation/#2-implementation).
