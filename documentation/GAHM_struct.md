# GAHM Data Structure Definition

**Canonical reference** — all files should reference this document rather than
duplicating the definition inline.

---

## Index Conventions

| Symbol | Meaning |
|--------|---------|
| `q` | Quadrant number: `1:4` → NE, SE, SW, NW |
| `iso` | Isotach number: `1:3` → 34, 50, 64 kt (`SQuad_1_10 = [34, 50, 64]/1.944` m/s) |
| `iso+1 = 4` | Reserved for the case when none of the isotachs have values; default values are computed and placed here |

---

## Units

| Quantity | Unit |
|----------|------|
| Speed, velocity | m/s (unless otherwise specified) |
| Distance | m (unless otherwise specified) |
| Pressure | mb |
| Density | kg/m³ |

---

## GAHM Struct Fields

### Identification & Location

| Field | Description |
|-------|-------------|
| `GAHM.datetime` | Current date & time (`datetime` format) |
| `GAHM.Eye` | `[LonEW, LatNS]` (deg); lon < 0 west of GM, lat > 0 north of equator |

### Environmental Velocity Model

| Field | Description |
|-------|-------------|
| `GAHM.Gcase` | Environmental velocity form: `1` = `SEnv_10_10` varies radially as `SVQuad_10_10 / SVMax_10_10` (ADCIRC/ASWIP); `2` = `VEnv_10_10` specified throughout the area (e.g., from a gridded field) |

### Pressure

| Field | Description |
|-------|-------------|
| `GAHM.CP` | Central pressure (mb) |
| `GAHM.Pscale` | Scaling factor applied to the pressure deficit |
| `GAHM.Pback` | Background pressure (mb) |

### Wind Speeds

| Field | Description |
|-------|-------------|
| `GAHM.SMax_10_10` | Max speed (m/s) from input track file |
| `GAHM.SQuad_10_10(iso)` | Isotach speeds (m/s), 10-min avg @ 10 m |
| `GAHM.SVorMax_10_10` | Max vortex velocity, 10-min avg @ 10 m |
| `GAHM.SVorMax_10_10_theta` | Angle (deg, CCW from E) where `SVorMax_10_10` occurs |
| `GAHM.SVorQuad_10_10(q, iso)` | Vortex speed at each quadrant/isotach (set by solver) |

### Translation & Environmental Velocity

| Field | Description |
|-------|-------------|
| `GAHM.VTspeed_10_10` | Translation speed (m/s) |
| `GAHM.VTdirection_10_10` | Translation direction (deg, CCW from E) |
| `GAHM.VEnvStar_10_10` | Average environmental velocity near eye (m/s) |
| `GAHM.VEnvQuad_10_10(q, iso, 1:2)` | Environmental velocity at isotach locations in each quadrant (m/s) |
| `GAHM.VEnv_10_10` | Environmental background velocity, 10-min avg @ 10 m. In ADCIRC/ASWIP: `1.5 * Vt^0.63 * (0.51444^0.37)`. Alternatives: Lin & Chavez (2012), or gridded field (depends on `Gcase`). |

### Radial Distances

| Field | Description |
|-------|-------------|
| `GAHM.Rmax_in` | Radius of maximum winds (m) from input track file |
| `GAHM.RQuad(q, iso)` | Radial distance (m) to isotachs |
| `GAHM.Rmax(q, iso+1)` | Rmax computed by GAHM for each quadrant/isotach. Position 4 = NaN or default if all isotach values are NaN. |
| `GAHM.RmaxQ(q)` | Rmax for the strongest isotach in each quadrant |

### Holland B and GAHM Parameters

| Field | Description |
|-------|-------------|
| `GAHM.B` | Holland (1980) B |
| `GAHM.Bg(q, iso+1)` | GAHM generalized Holland B |
| `GAHM.A(q, iso+1)` | Original Holland A |
| `GAHM.phi(q, iso+1)` | GAHM phi |
| `GAHM.Ro(q, iso+1)` | Rossby number |

### Solver Diagnostics (version-specific)

| Field | Description |
|-------|-------------|
| `GAHM.Rmic(q, iso+1)` | Number of Rmax iterations (v3 only; NaN for v4) |
| `GAHM.Bgicmax(q, iso+1)` | Max Bg iterations within an Rmax loop (v3 only; NaN for v4). > 50 = alternate equation used; > 100 = convergence failed. |

### Flags

| Field | Description |
|-------|-------------|
| `GAHM.numiso` | Number of isotachs with values |
| `GAHM.flag(q, iso)` | Per-quadrant/isotach flag (0–9) |
| `GAHM.flag_B` | B-limit flag: `0` = Bmin applied, `1` = OK, `2` = Bmax applied |
| `GAHM.flag_exit` | `0` = OK, `9` = terminate |
| `GAHM.skipline` | `true` = skip this timestep (missing data) |
| `GAHM.turnangle(q, iso)` | Turning angle (10–25 deg) for each quadrant/isotach |

---

## Flag Values Reference

| Value | Meaning |
|-------|---------|
| `0` | No isotach data available; use defaults |
| `1` | All consistency checks passed |
| `2` | `SVorMax_10_tbl < SVorMax_10_tblmin`; use track-file Rmax |
| `3` | `SVorQuad_10_tbl < SVorQuad_10_tblmin`; Rmax copied from neighboring isotach |
| `4` | `SVorMax_10_10 < SVorQuad_10_10` for both turning angles; set Rmax = RQuad |
| `5` | `SVorMax_10_10 < SVorQuad_10_10` for one turning angle; intermediate turning angle estimated |

---

## Constants & Assumptions

| Symbol | Value | Description |
|--------|-------|-------------|
| `omega` | `0.00007272` rad/s | Earth rotation rate |
| `f` | `2 * omega * sin(lat)` 1/s | Coriolis parameter |
| Turning angle | piecewise function of `r / Rmax` | `r < Rmax`: `10 * r/Rmax`; `r < 1.2 * Rmax`: `10 + 75*(r/Rmax - 1)`; `r >= 1.2 * Rmax`: `25` deg. CCW in Northern Hemisphere. |

---

## Select Variable Definitions

| Variable | Description |
|----------|-------------|
| `SMax_1_10` | Maximum wind speed (m/s), 1-min sustained @ 10 m, from best-track file after unit conversion. Aligned with `VEnvStar_10_10`. |
| `SMax_10_tbl` | `SMax_10_10` at top of boundary layer |
| `SVorMax_10_10` | `SMax_10_10 − SEnvStar_10_10` |
| `SVorMax_10_tbl` | Vortex component of `SMax_10_tbl` |
| `SQuad_1_10(3)` | 1-min sustained speed (m/s) of 3 isotachs @ 10 m (34, 50, 64 kt → m/s) |
| `SQuad_10_10(3)` | 10-min avg `SQuad_1_10` |
| `SQuad_10_tbl(3)` | `SQuad_10_10` at top of boundary layer |
| `SVorQuad_10_tbl(3)` | Vortex component of `SQuad_10_tbl` |
| `VVorQuaduv_tbl(4, 3)` | `SVorQuad_10_tbl` unit vectors in the 4 quadrants |
| `deltaP_NpMsq` | Central pressure deficit (N/m²) = 100 × mb |
| `VEnv_10_10` | Environmental background velocity, 10-min avg @ 10 m. Total = Env + Vortex. |
| `SEnv_10_10` | Speed of `VEnv_10_10` |
| `VEnvStar_10_10` | Average environmental velocity near eye (within `r = Rmax_in`) |
| `SEnvStar_10_10` | Speed of `VEnvStar_10_10` |
| `VEnvStaruv_10_10` | Unit vector of `VEnvStar_10_10` |
| `VEnvQuad_10_10` | Environmental velocity at 3 isotach locations in 4 quadrants |
| `RQuad(4, 3)` | Radial distance (m) in 4 quadrants (NE, SE, SW, NW) for 3 isotachs (34, 50, 64 kt) |
| `B` | Holland (1980) B = `SVorMax_10_tbl² × rhoa × e / deltaP_NpMsq` |
