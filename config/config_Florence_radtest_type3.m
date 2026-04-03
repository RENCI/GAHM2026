%--------------------------------------------------------------------------
% Unified configuration for SeparateEnvHur and GAHM2026
%
% This script defines all input parameters needed by both SeparateEnvHur and
% run_GAHM2026.m.  Shared storm identity parameters are defined once at
% the top and used to derive the project-specific structs.
%
% Usage:
%   run_GAHM2026('config_Florence')   — runs GAHM2026 (auto-runs SeparateEnvHur
%                                        if the EnvFields .mat file is missing)
%   addpath('SeparateEnvHur'); SeparateEnvHur('config/config_Florence') — runs SeparateEnvHur standalone
%
%                        2/16/2026  Rick Luettich, UNC/IMS/CNHR/EMES
%                                   Brian Blanton, UNC/RENCI
%--------------------------------------------------------------------------

%% ===== Shared storm identity (used by both SeparateEnvHur and GAHM2026) =====
storm_name        = 'FLORENCE';
storm_year        = 2018;
track_file        = 'ibtracs.NA.list.v04r01.csv';
storm_designation = 'AL06';
debug             = true;
storm_start       = datetime(2018,9,12,0,0,0);
storm_end         = datetime(2018,9,12,3,0,0);

%% ===== SeparateEnvHur parameters =====
sepenvhur.background_file     = 'https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/global.1/uvp/2018/09.nc';
%sepenvhur.background_file     = 'https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/global/uvp/2018/09.nc';
%sepenvhur.background_file    = 'https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/global/uvp/<year>/<year>.nc';
%sepenvhur.background_file    = '/Users/bblanton/ees/TDS/ERA5/global/uvp/<year>/<year>.nc';
%sepenvhur.background_file    = 'input/09.nc';
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
sepenvhur.debug              = true;
sepenvhur.output_dir         = 'output';
% Populate shared fields into sepenvhur for SeparateEnvHur consumption
sepenvhur.storm_name        = storm_name;
sepenvhur.storm_year        = storm_year;
sepenvhur.storm_designation = storm_designation;
sepenvhur.track_file        = fullfile('input', track_file);

%% ===== GAHM2026 storm / track file info =====
storm_info.track_file  = fullfile('input', track_file);
storm_info.file_type   = "IBTrACS";
storm_info.name        = storm_name;
storm_info.year        = num2str(storm_year);
storm_info.designation = storm_designation;
storm_info.starttime   = storm_start;
storm_info.endtime     = storm_end;
% storm_info.outputfilename = sprintf('%s_%s_%s', storm_info.name, ...
%    storm_info.designation, storm_info.year);
storm_info.outputfilename = 'Florence_radtest_type3';

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
GAHM_compute_info.nr     = 1600;
GAHM_compute_info.delr   = 500;

%% ===== Wind Adjustment Factor info =====
WAF_info.flag      = false;
WAF_info.file_name = 'input/WAF_15deg_10km_6km_raster_test.tif'; % ignored if WAF.flag=false

%% ===== Environmental field info =====
% env_info.file_name is derived from the shared storm identity so it
% automatically matches the .mat file produced by SeparateEnvHur.
env_info.type             = 3;
env_info.file_name        = fullfile('output', sprintf('%s_%s_%s', storm_name, storm_designation, num2str(storm_year))); % e.g. 'output/FLORENCE_AL06_2018'
% env_info.file_name  = 'FLORENCE_AL06_2018';
env_info.taper_flag       = true;
env_info.taper_mindelr2r1 = 0.1; % minimum value of (r2-r1)/r2 if violated r1 is reduced.
env_info.taper_a          = 2;   % adjusts steepness of hyperbolic tangent taper function (2 is suggested)

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
