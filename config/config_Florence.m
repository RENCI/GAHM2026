%--------------------------------------------------------------------------
% Unified configuration for ScrubEra5 and GAHM2026
%
% This script defines all input parameters needed by both ScrubEra5 and
% run_GAHM2026.m.  Shared storm identity parameters are defined once at
% the top and used to derive the project-specific structs.
%
% Usage:
%   run_GAHM2026('config_Florence')   — runs GAHM2026 (auto-runs ScrubEra5
%                                        if the EnvFields .mat file is missing)
%   addpath('ScrubEra5'); ScrubEra5('config/config_Florence') — runs ScrubEra5 standalone
%
%                        2/16/2026  Rick Luettich, UNC/IMS/CNHR/EMES
%                                   Brian Blanton, UNC/RENCI
%--------------------------------------------------------------------------

%% ===== Shared storm identity (used by both ScrubEra5 and GAHM2026) =====
storm_name        = 'FLORENCE';
storm_year        = 2018;
track_file        = 'ibtracs.NA.list.v04r01.csv';
storm_designation = 'AL06';
debug             = true;

%% ===== ScrubEra5 parameters =====
%scrub_info.nc_file            = '/Users/bblanton/ees/TDS/ERA5/global/uvp/2018/2018.global.nc';
scrub_info.nc_file            = 'input/09.nc';
scrub_info.storm_start        = datetime(2018,9,10,0,0,0);
scrub_info.storm_end          = datetime(2018,9,18,0,0,0);
scrub_info.grid_half_size     = 40;
scrub_info.output_half_size   = 40;
scrub_info.filter_domain_size = 120;
scrub_info.num_radial_points  = 1000;
scrub_info.num_azimuth_points = 360;
scrub_info.max_radius_deg     = 10;
scrub_info.wind_threshold_10  = 10;       % m/s
scrub_info.wind_threshold_34  = 34/1.944; % 34 kts -> m/s
scrub_info.debug              = true;
scrub_info.output_dir         = 'output';
% Populate shared fields into scrub_info for ScrubEra5 consumption
scrub_info.storm_name  = storm_name;
scrub_info.storm_year  = storm_year;
scrub_info.track_file  = fullfile('input', track_file);

%% ===== GAHM2026 storm / track file info =====
storm_info.file_name   = fullfile('input', track_file);
storm_info.file_type   = "IBTrACS";
storm_info.name        = storm_name;
storm_info.year        = num2str(storm_year);
storm_info.designation = storm_designation;
storm_info.starttime   = '2018091400';
storm_info.endtime     = '2018091500';
storm_info.outputfilename = sprintf('%s_%s', storm_info.name, storm_info.year);

%% ===== GAHM2026 parameter values =====
GAHM_param_info.Vmax_multiplier     = 1;
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
WAF_info.flag      = false;
WAF_info.file_name = 'input/WAF_15deg_10km_6km_raster_test.tif';

%% ===== Environmental field info =====
% env_info.file_name is derived from the shared storm identity so it
% automatically matches the .mat file produced by ScrubEra5.
env_info.type             = 3;
env_info.file_name        = fullfile('output', sprintf('%s_%d', storm_name, storm_year));  % e.g. 'output/FLORENCE_2018'
env_info.taper_flag       = true;
env_info.taper_mindelr2r1 = 0.1;
env_info.taper_a          = 2;

%% ===== Output information =====
output_info.warnings       = fullfile('output', sprintf('%s_%s_GAHM2026_warnings.dat', storm_info.name, storm_info.year));
output_info.NetCDFfilename = ['output/' storm_info.outputfilename];
output_info.timeinc        = 1;
output_info.type           = "grid";
if output_info.type == "grid"
    output_info.nlon   = 351;
    output_info.nlat   = 351;
    output_info.dellon = 0.05;
    output_info.dellat = 0.05;
elseif output_info.type == "points"
    output_info.lon = x;
    output_info.lat = y;
else
    disp('output_info.type must be either the string "grid" or "points" ')
end
