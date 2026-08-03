%--------------------------------------------------------------------------
% Unified configuration for SeparateEnvHur and GAHM2026
%
% This script defines all input parameters needed by both SeparateEnvHur and
% run_GAHM2026.m.  Shared storm identity parameters are defined once at
% the top and used to derive the project-specific structs.
%
% Usage:
%   run_GAHM2026                   — runs with this default config
%   run_GAHM2026('config_GAHM2026') — equivalent
%
% To create a config for a new storm, copy this file and update the
% shared storm identity and SeparateEnvHur sections.
%
%                        2/7/2026  Rick Luettich, UNC/IMS/CNHR/EMES
%                                  Brian Blanton, UNC/RENCI
%--------------------------------------------------------------------------

%% ===== Shared storm identity (used by both SeparateEnvHur and GAHM2026) =====
storm_name        = 'FLORENCE';       % IBTrACS uses all caps for names
storm_year        = 2018;
track_file        = 'ibtracs.NA.list.v04r01.csv';
storm_designation = 'AL06';
debug             = false;
storm_start       = datetime(2018,9,14,0,0,0);
storm_end         = datetime(2018,9,14,3,0,0);

%% ===== SeparateEnvHur parameters =====
sepenvhur.background_file    = 'https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/global/uvp/<year>/<year>.nc';
sepenvhur.storm_start        = storm_start;
sepenvhur.storm_end          = storm_end;
sepenvhur.grid_half_size     = 40;
sepenvhur.output_half_size   = 40;
sepenvhur.filter_domain_size = 120;
sepenvhur.num_radial_points  = 1000;
sepenvhur.num_azimuth_points = 360;
sepenvhur.max_radius_deg     = 10;
sepenvhur.search_range       = 6;
MS2KT = gahmPhysicalConstants().ms2kt;
sepenvhur.wind_threshold_outer  = 20/MS2KT; % 20 kts -> m/s
sepenvhur.wind_threshold_inner  = 34/MS2KT; % 34 kts -> m/s
sepenvhur.debug              = debug;
sepenvhur.output_dir         = 'output';
% Populate shared fields into sepenvhur for SeparateEnvHur consumption
sepenvhur.storm_name        = storm_name;
sepenvhur.storm_year        = storm_year;
sepenvhur.storm_designation = storm_designation;
sepenvhur.track_file        = fullfile('input', track_file);

%% ===== GAHM2026 storm / track file info =====
storm_info.track_file     = fullfile('input', track_file);
storm_info.file_type      = "IBTrACS";
storm_info.name           = storm_name;
storm_info.year           = num2str(storm_year);
storm_info.designation    = storm_designation;
storm_info.starttime      = storm_start;
storm_info.endtime        = storm_end;
storm_info.outputfilename = sprintf('%s_%s', storm_info.name, storm_info.year);

%% ===== GAHM2026 parameter values =====
GAHM_param_info.Vmax_multiplier     = 1;    % =1 use full Vmax, =0.9 use 90% Vmax...
GAHM_param_info.one2tenF            = 0.89;
GAHM_param_info.BLF                 = 0.9;
GAHM_param_info.Bmin                = 0.5;
GAHM_param_info.Bmax                = 2.5;
GAHM_param_info.SVorMax_10_tblmin   = 20;
GAHM_param_info.SVorQuad_10_tblmin  = 5;
GAHM_param_info.rhoa                = 1.204;
GAHM_param_info.pback_def           = 1013;
GAHM_param_info.version             = 3;
GAHM_param_info.Bg0M                = 1;
GAHM_param_info.c0                  = 0;

%% ===== Constants for computing wind/pressure field =====
GAHM_compute_info.ntheta = 24;
GAHM_compute_info.nr     = 800;
GAHM_compute_info.delr   = 1000;

%% ===== Wind Adjustment Factor info =====
WAF_info.flag      = false;    % Wind Adjustment Factor based on land roughness
WAF_info.file_name = 'input/WAF_15deg_10km_6km_raster_test.tif'; % ignored if WAF.flag=false

%% ===== Environmental field info =====
% env_info.file_name is derived from the shared storm identity so it
% automatically matches the .mat file produced by SeparateEnvHur.
env_info.type             = 3;  % options are 1, 2 or 3.  If 1 or 2 are selected, the remainder of this section is ignored
env_info.file_name        = fullfile('output', sprintf('%s_%s_%s', storm_name, storm_designation, num2str(storm_year))); % e.g. 'output/FLORENCE_AL06_2018'
env_info.taper_flag       = true;
env_info.taper_mindelr2r1 = 0.1; % minimum value of (r2-r1)/r2 if violated r1 is reduced.
env_info.taper_a          = 2;   % adjusts steepness of hyperbolic tangent taper function (2 is suggested)

%% ===== Output information =====
% for gridded output:
%    if env_info.type =1 or 2, this will be centered on the eye of the storm at the
%    specified output time using nlon, nlat, dellon, dellat specified below
%    if env_info.type =3, this will match the outer footprint of the environmental
%    grid using dellon and dellat specified below.  nlon, nlat will be
%    computed.  Note, in this case dellon and dellat can be <, =, > the grid
%    size in the environmental grid, but it must divide evenly into the footprint
%    of the environmental grid.
% for point output:
%   the number of longitude and latitude values much be equal and are fixed in time.
%   Output is computed a corresponding lon,lat pairs

output_info.diagnostics    = fullfile('output', sprintf('%s_%s_%s_GAHM2026_diagnostics.dat', storm_info.name, storm_info.designation, storm_info.year));
output_info.NetCDFfilename = ['output/' storm_info.outputfilename];
output_info.timeinc        = 1;     % output time interval (hrs) must be <= time between BestTrack snaps
output_info.pres_units     = "mb";  % pressure units in NetCDF output: "mb" or "Pa"
output_info.type           = "grid";
% output_info.type = "points";
if output_info.type == "grid"
    output_info.nlon   = 351;      % # lon values in regular output grid (best if an odd number) - ignored for env.type=3
    output_info.nlat   = 351;      % # lat values in regular output grid (best if an odd number) - ignored for env.type=3
    output_info.dellon = 0.05;     % grid increment decimal degrees lon
    output_info.dellat = 0.05;     % grid increment decimal degrees lat
elseif output_info.type == "points"
    output_info.lon = x;
    output_info.lat = y;
else
    disp ('output_info.type must be either the string "grid" or "points" ')
end
