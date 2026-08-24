%--------------------------------------------------------------------------
% Unified configuration for SeparateEnvHur and GAHM2026
%
% This script defines all input parameters needed by both run_GAHM2026.m and
% SeparateEnvHur.m.  Shared storm identity parameters are defined once at
% the top and used to derive the project-specific structs.
%
% Usage:
%   R = run_GAHM2026                   — runs with this default config
%   R = run_GAHM2026('config_Florence') — runs a storm-specific config
%
%   This config file can also be used to run SeparateEnvHur.m standalone:
%        addpath('SeparateEnvHur')
%        env_vals = SeparateEnvHur('config/config_GAHM2026_default');
%
% To create a config for a new storm, copy this file and update the shared
% storm identity and SeparateEnvHur sections.
%
%                     2/7/2026   Rick Luettich, UNC/IMS/CNHR/EMES
%                                Brian Blanton, UNC/RENCI
%                     5/2/2026   Rick Luettich, further consolidation of
%                                SeparateEnvHur & GAHM codes, eliminated
%                                hardwires in SeparateEnvHur
%                     8/13,14/2026  Rick Luettich, tested, small corrections
%--------------------------------------------------------------------------

%% ===== Shared storm identity (used by both SeparateEnvHur and GAHM2026) =====
storm_name        = 'FLORENCE';       % IBTrACS uses all caps for names
storm_year        = 2018;
track_file        = 'ibtracs.NA.list.v04r01.csv';
track_type        = "IBTrACS";        % "IBTrACS", "ATCF" or "fort22"
storm_designation = 'AL06';
DEBUG             = false;   % lowercase debug is a matlab command.
GAHM2026_start    = datetime(2018,9,12,0,0,0);  % >= first time in track_file
GAHM2026_end      = datetime(2018,9,17,0,0,0);  % <= last time in track_file

%% ===== Assignment statements based on user input thus far =====
storm_info.track_file     = fullfile('input', track_file);
storm_info.file_type      = track_type;
storm_info.name           = storm_name;
storm_info.year           = num2str(storm_year);
storm_info.designation    = storm_designation;
storm_info.starttime      = GAHM2026_start;
storm_info.endtime        = GAHM2026_end;
storm_info.outputfilename = sprintf('%s_%s_%s', storm_name, storm_designation, num2str(storm_year));

%% ===== GAHM2026 parameter values =====
% See "GAHM2026 Derivation and Implementation" for further information
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
GAHM_compute_info.ntheta = 24;   % # radial lines used to compute GAHM
GAHM_compute_info.nr     = 800;  % # increments along each radial line;
                                 % total radial line length = nr*delr
GAHM_compute_info.delr   = 1000; % radial increment size (meters)

%% ===== Environmental field info =====
% specify how to treat the large scale environmental field
%   env_info.type = 1  env field based on translation speed as found in
%                      ADCIRC. GAHM is added to env field
%   env_info.type = 2  env field based on translation speed e.g., Wang et al
%                      (2021), Lin and Chavas (2012). GAHM is added to env field
%   env_info.type = 3  env field & TC vortex (hurricane) fields determined
%                      from large scale gridded fields (e.g., ERA5). GAHM is
%                      blended with TC vortex field & added to env field
env_info.type = 3;

% only used if env_info.type = 3, otherwise ignored
%   env_info.file_name = file name containing separated environmental and
%                      TC vortex (hurricane) fields. If this file is not found,
%                      it will be automatically created by SeparateEnvHur.m.
%                      The default is derived from the storm identity,
%                      e.g. 'input/FLORENCE_AL06_2018_env'
env_info.file_name = fullfile('input', sprintf('%s_%s_%s_env', storm_name, ...
                                  storm_designation, num2str(storm_year)));

%   parameters that control the taper function used to blend GAHM with the
%   TC vortex field
env_info.taper_flag       = true;  % not available for env_info.type = 1,2
env_info.taper_mindelr2r1 = 0.1;   % minimum value of (r2-r1)/r2; if violated
                                   % r1 is reduced to satisfy this criterion.
                                   % r1 & r2 are the radial distances to the
                                   % inner and outer limits of the taper
env_info.taper_a          = 2;     % adjusts steepness of hyperbolic tangent

%% ===== Wind Adjustment Factor info =====
% The WAF must be computed separately, either for specific output locations
% (output type "points") or as a raster file (output type "grid").
WAF_info.flag      = false;  % set = false if not using
WAF_info.file_name = fullfile('input', 'WAF_15deg_10km_6km_raster_test.tif');
                             % ignored if WAF_info.flag = false

%% ===== SeparateEnvHur parameters =====
% These are only used if env_info.type = 3 and a .mat file containing
% environmental and TC vortex (hurricane) met fields needs to be created as
% part of the run. They are ignored if the fields have been precomputed and
% are available in env_info.file_name (specified above). They are also
% ignored if env_info.type = 1 or 2.

if env_info.type == 3

% verbose output option
    sepenvhur.debug = DEBUG;

% Specify the file containing the large scale gridded input data. Can be
% local or on a remote server. Must contain the full time window between
% GAHM2026_start and GAHM2026_end. Use <year> as a placeholder for the
% storm year; it is resolved at runtime by getERA5Data.
    sepenvhur.background_file = 'https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/regional/na/uvp/<year>/<year>.na.nc';

% Note: the grid increment size is determined from the input grid file. It
% is assumed that the time step = 1 hr.

% Length of the sides (deg) of the square box extracted from the large
% scale gridded input data to apply the digital filter used to separate the
% environmental and TC vortex (hurricane) fields.
    sepenvhur.filter_grid_length = 30;

% Length of the sides (deg) of the square box extracted from the large scale
% gridded input data used to extract isotach cut lines for blending the TC
% vortex (hurricane) field with GAHM. This is also the size of the grid in
% the output .mat file. Must be <= filter_grid_length.
    sepenvhur.output_grid_length = 20;

% Maximum search radius (deg) from the eye location in the track file used
% to search for the storm center in the large scale gridded input data.
% NOTE: unused as of v1.5 — the extraction is centered on the track eye.
    sepenvhur.search_radius = 1.5;

% Isotach values used for the inner and outer blending cutlines (m/s)
    sepenvhur.wind_threshold_outer = 10;
    sepenvhur.wind_threshold_inner = 17.5;

% Isotach value (m/s) and multiplier used to set the half power length scale
% of the filter that separates the environmental and TC vortex fields.
% Half-power scale = average radial dist to filter_isotach * filter_hp_multiplier
% A greater filter_isotach or smaller multiplier increases (decreases) the
% energy in the environmental (TC vortex) field.
    sepenvhur.filter_isotach       = 17.5;
    sepenvhur.filter_hp_multiplier = 25;  % empirical value from J. Chen 2026

% # pt smoother and smoothness variance for smoothing isotach cutlines
    sepenvhur.num_points_smoother     = 3;
    sepenvhur.isotach_smooth_variance = 2000; % in # increments along radial lines

% Otherwise use previously specified values
    sepenvhur.storm_name            = storm_name;
    sepenvhur.storm_year            = storm_year;
    sepenvhur.storm_designation     = storm_designation;
    sepenvhur.track_file            = fullfile('input', track_file);
    sepenvhur.storm_start           = GAHM2026_start;
    sepenvhur.storm_end             = GAHM2026_end;
    sepenvhur.output_dir            = 'output';
    sepenvhur.output_file_name      = env_info.file_name;
    sepenvhur.num_azimuthal_points  = GAHM_compute_info.ntheta;
    sepenvhur.num_radial_points     = GAHM_compute_info.nr;
    sepenvhur.radial_inc            = (sepenvhur.output_grid_length/2)/sepenvhur.num_radial_points;
    sepenvhur.isotach_output_radials = sepenvhur.num_azimuthal_points;  % unused

end

%% ===== Output information =====
% for gridded output:
%    if env_info.type = 1 or 2, the grid is centered on the eye of the storm
%    at the specified output time using nlon, nlat, dellon, dellat below.
%    if env_info.type = 3, the grid matches the outer footprint of the
%    environmental grid using dellon and dellat; nlon, nlat are computed.
%    In that case dellon/dellat can be <, =, > the environmental grid
%    increment, but must divide evenly into its footprint.
% for point output:
%    the number of longitude and latitude values must be equal and are fixed
%    in time. Output is computed at corresponding lon,lat pairs.

output_info.diagnostics = fullfile('output', sprintf('%s_%s_%s_GAHM2026_diagnostics.dat', ...
                              storm_info.name, storm_info.designation, storm_info.year));
output_info.warnings    = fullfile('output', sprintf('%s_%s_GAHM2026_warnings.dat', ...
                              storm_info.name, storm_info.designation, storm_info.year));

output_info.timeinc    = 1;     % output time interval (hrs). If env_info.type=3,
                                % must be an even multiple of the time increment
                                % in the environmental input file (e.g., 1, 2, ...)
output_info.pres_units = "mb";  % pressure units in NetCDF output: "mb" or "Pa"

% Specify the type of output to generate, either on a grid ="grid" or at
% specified points ="points"
output_info.type = "grid";

if output_info.type == "grid"
    output_info.NetCDFfilename = fullfile('output', storm_info.outputfilename);
    output_info.nlon   = 351;      % # lon values (best odd) - ignored for env.type=3
    output_info.nlat   = 351;      % # lat values (best odd) - ignored for env.type=3
    output_info.dellon = 0.05;     % grid increment decimal degrees lon
    output_info.dellat = 0.05;     % grid increment decimal degrees lat
elseif output_info.type == "points"
    output_info.lon = x;
    output_info.lat = y;
else
    disp('output_info.type must be either the string "grid" or "points" ')
end
