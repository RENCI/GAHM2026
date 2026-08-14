---
layout: default
title: Extended fort.22 Format
parent: Source Documents
nav_order: 6
permalink: /source-documents/fort22-v2/
source_document: documentation/fort22_v2.docx
source_sha256: "20e1d769baa2737f37261cdb6119f48fb0c70d1d6175097f8840c658e1fa3d34"
---

> Converted from the [source DOCX](https://github.com/RENCI/GAHM2026/blob/main/documentation/fort22_v2.docx).

Documentation for the contents of the fort22 extended file that is output from write_fort22_ext.m following the GAHM2024 reorg 7/2025

8/1/2025 Rick Luettich

[Units:]{.underline}

Rmax, RmaxQ, Rmax_out -- nautical miles (n miles)

angles -- deg clockwise from North (i.e., azimuthal convention)

speed- nautical miles / hr (knots or kts)

pressure -- (mb)

[File contents:]{.underline}

col 1: basin abbreviation (e.g., Atlantic = AL)

col 2: storm \# (e.g., 6th storm of year = 06)

col 3: base time (yyyyMMddHH). If the file represents a forecast, (e.g., runtype = OFCL), base time will be constant through the file and represent the time of the forecast initialization. In this case add the offset time (col 6) to get the actual time of the results. If the file represents a reanalysis or historical results (e.g., runtype = BEST or IBTr), the base time will advance through the file and represent the actual time of the results. In this case the offset time should not be added to the base time.

col 4: =base time min (min). A nonzero value indicates that the base time (col 3) is not an even hour. In this case it should be added to the based time (col 3)

col 5: runtype Indicator of the source / type of results present in the file (e.g., BEST, IBTr, OFCL, \...)

col 6: offset time in hrs. If the file represents a forecast, (e.g., runtype = OFCL), the contents of this column (e.g., 0, 6, 12, 18, ...) should be added to the base time (col 3) to determine the actual time of the results. If the file represents a reanalysis or historical results (e.g., runtype -- BEST or IBTr), this column may contain 0 or it may represent the time in hrs from the beginning of the file. In either of these cases, it should not be used to determine the actual time of the results.

col 7: Latitude of eye (deg\*10), with N or S for hemisphere

col 8: Longitude of eye (deg\*10), with E or W to reference degree orientation E or W of GM

col 9: Maximum 1-min sustained wind speed @ 10 meters (kts)

col 10: Minimum sea level pressure (mb)

col 11: Storm type TD, TS, HU..

col 12: isotach value (34,50,64 kts) of the isotach radii (col 14-17)

col 13: radius code, AAA or NEQ. AAA means col 14 has full circle radial info and cols 15-17 are ignored, NEQ means cols 14-17 have quadrant info in the NE, SE, SW, NW quads

col 14: radial dist to specified wind isotach for NE quadrant (n miles)

col 15: radial dist to specified wind isotach for SE quadrant (n miles)

col 16: radial dist to specified wind isotach for SW quadrant (n miles)

col 17: radial dist to specified wind isotach for NW quadrant (n miles)

col 18: pressure of last closed isobar (mb), (e.g. 1010)

col 19: Radial dist to last closed isobar (n miles)

col 20: Radius to maximum winds as read in from the input track file (n miles)

col 21: gust velocity (kt) from input track file

col 22: eye diameter (n mi) from input track file

\*col 23: distance to land (n mi) from input track file =0 @ landfall

\*col 24: background / env direction (deg cw from N) computed internally

\*col 25: background / env speed (kts) computed internally

col 26: translation direction (deg cw from N) from input track file

col 27: translation speed (kts) from input track file

col 28: storm name

\*col 29: time record \# (e.g., 1,2,3,4\...). If multiple isotach values are reported for a given time, they will have the same time record \#

\*col 30: \# isotachs available for a given time record \# (0, 1, 2, 3)

\*col 31-34: GAHM2024 diagnostic flags for the specified isotach in the NE (31), SE (32), SW (33), and NW (34) quadrants. **0** = distance to isotach missing in the track file in the corresponding quadrant; **1** = track file data is fully consistent with GAHM2024 (no exceptions) in the corresponding quadrant; **2** = SVorMax_10_tbl \<= SVorMax_10_tblmin -- the maximum velocity in the track file & the selected environmental velocity yield a maximum vortex velocity at the top of the boundary layer that is less than the specified minimum value. If true, this applies to all quadrants; **3** = SVorQuad_10_tbl \< SVorQuad_10_tblmin -- the isotach velocity in the track file & the selected environmental velocity yield an isotach vortex velocity at the top of the boundary layer that is less than the specified minimum value in the corresponding quadrant; **4** = SVorQuad_10_10 \>= SVorMax_10_10 - the isotach velocity and maximum velocity in the track file & the selected environmental velocity yield an isotach vortex velocity in the corresponding quadrant that is greater than the maximum vortex velocity at the top of the boundary layer for velocity turning angles of 10 deg (assumed at r=Rmax) [and]{.underline} 25 (assumed for r \> 1.2 Rmax). In this case assume Rmax=RQuad, SVorQuad_10_10 = SVorMax_10_10, Bg, A, phi computed with GAHM2024; **5** = SVorQuad_10_10 \>= SVorMax_10_10 - the isotach velocity and maximum velocity in the track file & the selected environmental velocity yield an isotach vortex velocity in the corresponding quadrant that is greater than the maximum vortex velocity at the top of the boundary layer for velocity turning angles of 10 deg (assumed at r=Rmax) [or]{.underline} 25 (assumed for r \> 1.2 Rmax). In this case an intermediate turning angle is estimated that may be more realistic than using either 10 or 25 deg; **9** = Matlab solver (GAHM2024v4) returned either an imaginary value or failed to converge for Rmax and Bg. Values are unreliable.

\*col 35: Holland (1980) B diagnostic flag. **0** = B set to specified lower limit; **1** = B computed value is acceptable; **2** = B set to specified upper limit

\*#col 36-39: Radius to maximum wind computed for the specified isotach in the NE (36), SE (37), SW (38), and NW (39) quadrants

\*col 40: Holland (1980) B parameter

\*col 41-44: GAHM2024-Holland Bg parameter computed for the specified isotach in the NE (41), SE (42), SW (43), and NW (44) quadrants

\^\*col 45: 10-min sustained vortex max wind speed at the top of the boundary layer (SvorMax_10_tbl).

\^\*col 46-49: 10-min sustained vortex wind speed at the top of the boundary layer for the specified isotach in the NE (46), SE (47), SW (48), and NW (49) quadrants (SVorQuad_10_tbl).

\*col 50-53: Radius to maximum winds for the highest available isotach in the NE (50), SE (51), SW (52), and NW (53) quadrants (RmaxQ).

\*col 54: Radius to maximum winds where the winds speed is greatest for the entire storm. Occurs at an angle that is 90 deg from the direction of the environmental velocity (Rmax_tot)

\*col 55: GAHM2024 Holland Bg parameter computed using the Radius to maximum winds where the wind speed is greatest for the entire storm (i.e., where Rmax = Rmax_tot (Bg_tot).

\* preceding a column number indicates this deviates from the standard ATCF variable for that column.

\# preceding a column number indicates a case of no viable isotach values in the specified quadrant. , (col 30 = 0), default values are generated using the input Rmax value (col 20) and Bg = B. These default values are stored in the 34 isotach columns.

[\^ if the data originates from ASWIP, these are Vmax 1-min sustained, top of boundary layer]{.mark}
