---
layout: default
title: ASWIP fort.22 Format
parent: Source Documents
nav_order: 5
permalink: /source-documents/aswip-fort22/
source_document: documentation/ASWIP_fort22.docx
source_sha256: "59ab0796dd9cf63f1d7ae4cb153845de76cb369b1c2b2a05a0b7e429b97f320b"
---

> Converted from the [source DOCX](https://github.com/RENCI/GAHM2026/blob/main/documentation/ASWIP_fort22.docx).
> **Draft source:** This document contains incomplete or provisional material.

Documentation for the contents of the fort22 file that is output from ASWIP

5/29/2025 Rick Luettich

[Units:]{.underline}

Rmax, RmaxQ, Rmax_out -- nautical miles (n miles)

angles -- deg clockwise from North (i.e., azimuthal convention)

speed- nautical miles / hr (knots or kts)

pressure -- (mb)

[File contents:]{.underline}

col 1: basin abbreviation (e.g., Atlantic = AL)

col 2: storm \# (e.g., 6th storm of year = 06)

col 3: base time (yyyyMMddHH). If the file represents a forecast, (e.g., runtype = OFCL), base time will be constant through the file and represents the time of the forecast initialization. Add the offset time (col 6) to get the actual time of the results. If the file represents a reanalysis or historical results (e.g., runtype = BEST or IBTr), the base time will advance through the file and represents the actual time of the results. In this case the offset time should not be added to the base time.

col 4: =not used -- {blank - base time min (min). A nonzero value indicates that the base time (col 3) is not an even hour. In this case it should be added to the based time (col 3)}

col 5: runtype Indicator of the source / type of results present in the file (e.g., BEST, IBTr, OFCL, \...) (*need to check on options other than BEST)*

col 6: offset time in hrs. If the file represents a forecast, (e.g., runtype = OFCL), the contents of this column (e.g., 0, 6, 12, 18, ...) should be added to the base time (col 3) to determine the actual time of the results. If the file represents a reanalysis or historical results (e.g., runtype -- BEST or IBTr), this column may contain 0 or it may represent the time in hrs from the beginning of the file. In either of these cases, it should not be used to determine the actual time of the results. (*need to confirm behavior if runtype=OFCL*).

col 7: Latitude of eye (deg\*10), with N or S for hemisphere

col 8: Longitude of eye (deg\*10), with E or W to reference degree orientation E or W of GM

col 9: Maximum 1-min sustained wind speed @ 10 meters (kts)

col 10: Minimum sea level pressure (mb)

col 11: not used -- {blank - storm type}

col 12: isotach value (0, 34,50,64 kts) of the isotach radii (col 14-17)

col 13: radius code, NEQ. NEQ means cols 14-17 have quadrant info in the NE, SE, SW, NW quads.

col 14: radial dist to specified wind isotach for NE quadrant (n miles)

col 15: radial dist to specified wind isotach for SE quadrant (n miles)

col 16: radial dist to specified wind isotach for SW quadrant (n miles)

col 17: radial dist to specified wind isotach for NW quadrant (n miles)

col 18: pressure of last closed isobar (mb), (ASWIP sets to 1013)

col 19: not used -- {blank - Radial dist to last closed isobar (n miles)}

col 20: Rmax as read in from the input track file (n miles)

col 21: not used -- {blank - gust velocity (kt) from input track file}

col 22: not used -- {blank - eye diameter (n mi) from input track file}

\*col 23: not used -- {blank - distance to land from input track file =0 @ landfall}

\*col 24: not used -- {blank - background / env direction (deg cw from N) computed internally}

\*col 25: not used -- {blank - background / env speed (kts) computed internally}

col 26: translation direction (deg cw from N) from input track file}

col 27: translation speed (kts) from input track file}

col 28: storm name

\*col 29: not used -- {1 - time record \# (e.g., 1,2,3,4\...). If multiple isotach values are reported for a given time, they will have the same time record #}

\*col 30: \# lines in the file

\*col 31: flag for isotach NE quadrant 0=do not use, 1=ok to use Rmax, Bg, wind speed

\*col 32: flag for isotach SE quadrant 0=do not use, 1=ok to use Rmax, Bg, wind speed

\*col 33: flag for isotach SW quadrant 0=do not use, 1=ok to use Rmax, Bg, wind speed

\*col 34: flag for isotach NW quadrant 0=do not use, 1=ok to use Rmax, Bg, wind speed

\*#col 35: Rmax computed for NE quadrant for specified isotach

\*#col 36: Rmax computed for SE quadrant for specified isotach

\*#col 37: Rmax computed for SW quadrant for specified isotach

\*#col 38: Rmax computed for NW quadrant for specified isotach

\*col 39: Holland B parameter computed using the Holland 1980 formula

\*col 40: GAHM-Holland Bg parameter NE quadrant for specified isotach

\*col 41: GAHM-Holland Bg parameter SE quadrant for specified isotach

\*col 42: GAHM-Holland Bg parameter SW quadrant for specified isotach

\*col 43: GAHM-Holland Bg parameter NW quadrant for specified isotach

\*col 44: Vmax_vortex 1-min sustained, top of the boundary layer in NE quadrant (I checked the ASWIP code and this is true the best I could tell, RL 5/2/2025. All seem to be the same except possibly if they violate a consistency criterion. This is most likely to occur for the 64kt isotach)

\*col 45: Vmax_vortex 1-min sustained, top of the boundary layer in SE quadrant

\*col 46: Vmax_vortex 1-min sustained, top of the boundary layer in SW quadrant

\*col 47: Vmax_vortex 1-min sustained, top of the boundary layer in NW quadrant
