%--------------------------------------------------------------------------
% Unified configuration for SeparateEnvHur and GAHM2026
%
% This script defines all input parameters needed by both run_GAHM2026.m and
% SeparateEnvHur.m.  Shared storm identity parameters are defined once at
% the top and used to derive the project-specific structs.
%
% Usage:
%   results=run_GAHM2026('config_Florence') — runs GAHM2026 (runs 
%                      SeparateEnvHur.m if env_info.file_name.mat is not found)
%   This config file can also be used to run SeparateEnvHur.m as a stand alone
%        addpath('SeparateEnvHur')
%        SeparateEnvHur('config/config_Florence') — runs SeparateEnvHur
%
%
%                     8/13,14/2026  Rick Luettich - tested, small corrections 
%                     2/16/2026  Rick Luettich, UNC/IMS/CNHR
%                                Brian Blanton, UNC/RENCI
%                     5/2/2026   Rick Luettich, further consolidation of
%                                               SeparateEnvHur & GAHM
%                                               codes, eliminated hardwires
%                                               in SeparateEnvHur
%--------------------------------------------------------------------------

%% ===== Shared storm identity (used by both SeparateEnvHur and GAHM2026) =====
storm_name        = 'FLORENCE';
storm_year        = 2018;
track_file        = 'ibtracs.NA.list.v04r01.csv';
track_type        = "IBTrACS";
storm_designation = 'AL06';
debug             = true;
GAHM2026_start    = datetime(2018,9,10,00,0,0);  % >= first time in track_file
GAHM2026_end      = datetime(2018,9,15,12,0,0);  % <= last time in track file


%% ===== Assignment statements based on user input thus far
storm_info.track_file  = fullfile('input', track_file);
storm_info.file_type   = track_type;
storm_info.name        = storm_name;
storm_info.year        = num2str(storm_year);
storm_info.designation = storm_designation;
storm_info.starttime   = GAHM2026_start;
storm_info.endtime     = GAHM2026_end;


%% ===== GAHM2026 parameter values - See GAHM2026 Derivation and Implementation for further information =====
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

GAHM_compute_info.ntheta            = 24;   % # radial lines used to compute GAHM
GAHM_compute_info.nr                = 2000; % number of increments along each radial
                                            % line, total radial line length = nr*delr
GAHM_compute_info.delr              = 500;  % radial increment size (meters)


%% ===== Environmental field info =====
% specify how to treat the large scale environmental field
%   env_info.type = 1  env field based on translation speed as found in
%                      ADCIRC. GAHM is added to env field
%   env_info.type = 2  env field based on translation speed e.g., Wang et al
%                      (2021), Lin and Chavas (2012). GAHM is added to env field
%   env_info.type = 3  env field & TC vortex (hurricane) fields determined 
%                      from large scale gridded fields (e.g., ERA5). GAHM is 
%                      blended with TC vortex field & added to env field
env_info.type = 2;

% only used if env_info.type = 3, otherwise ignored
%   env_info.file_name = file name containing separated environmental and 
%                      TC vortex (hurricane) fields. If this file is not found,
%                      it will be automatically created by SeperateEnvHur.m. 
%                      The default env_info.file_name is derived from the storm
%                      identity, e.g. 'input/FLORENCE_AL06_2018_env'
env_info.file_name = fullfile('output', sprintf('%s_%s_%s_env', storm_name, ...
                                  storm_designation, num2str(storm_year))); 

%   parameters that control the taper function used to blend GAHM with the 
%   TC vortex field 
env_info.taper_flag       = false;  % not available for env_info.type = 1,2
env_info.taper_mindelr2r1 = 0.1; % minimum value of (r2-r1)/r2 if violated 
                                 % r1 is reduced to satisfy this criterion. 
                                 % r1 & r2 are the radial distances to the 
                                 % inner and outer limits of the taper
env_info.taper_a          = 2;   % adjusts steepness of hyperbolic tangent                                  


%% ===== Wind Adjustment Factor info =====
% if a wind adjustment factor is used to adjust for land roughness. The WAF
% must be computed separately either for specific output locations (output 
% type points) or on as a raster file (output type grid). This can be done 
% using either make_WAF_z0_points.m or make_WAF_z0_block.m   
WAF_info.flag      = false;                       % set = false if not using
WAF_info.file_name = fullfile('input/WAF_15deg_10km_6km_raster_test.tif');
                                                % ignored if WAF.flag=false


%% ===== SeparateEnvHur parameters =====
% These are only used if env_info.type = 3 and a .mat file containing 
% environmental and TC vortex (hurricane) met fields needs to be created as
% part of the run. They are ignored if the fields have been precomputed and
% available in 'env_info.file_name'(specified above). They are also ignored
% if env_info.type = 1 or 2.

if env_info.type == 3

% verbose output option
    sepenvhur.debug              = true;

% Specify the file containing the large scale gridded input data. Can be
% local or on remote server.  Must contain the full time window between 
% GAHM2026_start and GAHM2026_end. 
% sepenvhur.background_file   = 'https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/global.1/uvp/<year>/<year>.nc';
% sepenvhur.background_file    = 'https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/global.1/uvp/2018/2018.nc';
    sepenvhur.background_file    = 'https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/regional/wna/uvp/2018/2018.wna.nc';

% Note: the grid increment size is determined from the input grid file. It
% is assumed that the time step = 1 hr.

% specify the length of the sides (deg) of the square box extracted from the
% large scale gridded input data (e.g., ERA5) to apply the digital filter 
% used to separate the environmental and TC vortex (hurricane) fields.
    sepenvhur.filter_grid_length = 30; 

% specify the length of the sides (deg) of the square box extracted from the
% large scale gridded input data (e.g., ERA5) used to extract isotach cut 
% lines for blending the TC vortex (hurricane) field with GAHM. This is
% also used as the size of the grid in the output .mat file containing the 
% env & TC vortex (hurricane) met fields. This should be less than or equal
% to the filter_grid_length 
    sepenvhur.output_grid_length = 20; 

% Specify a maximum search radius (deg) from the eye location in the track 
% file to search for the center of the storm in the large scale gridded
% input data (e.g., ERA5). This helps to ensure the storm is correctly 
% located in the large scale gridded input data. 
    sepenvhur.search_radius      = 1.5;

% Specify the isotach values to use for the inner and outer blending
% cutlines (m/s)
    sepenvhur.wind_threshold_outer  = 10; 
    sepenvhur.wind_threshold_inner  = 17.5; 

% Specify the isotach value (m/s) and multiplier to use to set the half 
% power length scale of the filter used to separate the environmental and 
% TC vortex (hurricane) fields.  
% Half-power scale = average radial dist to filter_isotach * filter_hp_multiplier
% Specifying a greater filter_threshold or smaller multiplier increases 
% (decreases) the energy in the environmental (TC vortex) field. 
    sepenvhur.filter_isotach        = 17.5;
    sepenvhur.filter_hp_multiplier  = 25;  % emperical value from J. Chen 2026

% # pt smoother and smoothness variance for smoothing isotach cutlines 
    sepenvhur.num_points_smoother = 3;  
    sepenvhur.isotach_smooth_variance = 2000; % in # increments along radial lines

% Otherwise use previously specified values
    sepenvhur.storm_name           = storm_name;
    sepenvhur.storm_year           = storm_year;
    sepenvhur.storm_designation    = storm_designation;
    sepenvhur.track_file           = fullfile('input', track_file);
    sepenvhur.storm_start          = GAHM2026_start;
    sepenvhur.storm_end            = GAHM2026_end;
    sepenvhur.output_dir           = 'output';
    sepenvhur.output_file_name     = env_info.file_name;
    sepenvhur.num_azimuthal_points = GAHM_compute_info.ntheta;
    sepenvhur.num_radial_points    = GAHM_compute_info.nr;
    sepenvhur.radial_inc           = (sepenvhur.output_grid_length/2)/sepenvhur.num_radial_points;
    sepenvhur.isotach_output_radials= sepenvhur.num_azimuthal_points;  % need to eliminate the difference between theses

end

%% ===== Output information =====
output_info.diagnostics    = fullfile('output', sprintf('%s_%s_%s_GAHM2026_diagnostics.dat', storm_info.name, storm_info.designation, storm_info.year));
output_info.warnings       = fullfile('output', sprintf('%s_%s_GAHM2026_warnings.dat', storm_info.name, storm_info.designation, storm_info.year));

output_info.pres_units     = "mb";  % pressure units in NetCDF output: "mb" or "Pa"
output_info.timeinc        = 1;  % output time interval in hours. if env_info.type=3, must be an even multiple of the time inc in the environmental input file (e.g., 1, 2, ...)

% Specify the type of output to generate, either on a grid ="grid" or at 
% specified points ="points"
output_info.type           = "grid";  % either "grid" or "points"

if output_info.type == "grid"
    output_info.NetCDFfilename = fullfile('output', sprintf('%s_%s_%s', ...
                       storm_name, storm_designation, num2str(storm_year))); 
    output_info.nlon   = 351;
    output_info.nlat   = 351;
    output_info.dellon = 0.05;
    output_info.dellat = 0.05;

elseif output_info.type == "points"

% 79 Florence points
    output_info.lon =[-75.8451,-75.8261,-75.8032,-76.1716,-75.7470, ...
    -76.4678,-76.3231,-75.7301,-76.5684,-75.7220,-75.6550,-76.4981, ...
    -75.6581,-75.6990,-75.5929,-76.0092,-75.6634,-76.4198,-76.2006, ...
    -75.5453,-75.5250,-75.8522,-75.4684,-75.4687,-75.4885,-76.2231, ...
    -76.7561,-75.8333,-75.5068,-75.5000,-75.5538,-75.5237,-75.6290, ...
    -75.6222,-75.7041,-76.0052,-77.0367,-77.0997,-77.0478,-77.3514, ...
    -76.9860,-76.6919,-75.4020,-76.2783,-76.8800,-77.3231,-76.4560, ...
    -76.6176,-76.8956,-77.4343,-76.6706,-76.7368,-77.4407,-76.6882, ...
    -77.0633,-77.4872,-76.5284,-77.3730,-77.7219,-77.5538,-77.5493, ...
    -77.6481,-77.7519,-77.8999,-77.7936,-77.7865,-76.9490,-77.7210, ...
    -77.9644,-77.3630,-77.9437,-78.0200,-78.1167,-78.4820,-78.7204, ...
    -77.7430,-79.0990,-74.8350,-71.4830];
    output_info.lat =[ 36.4411, 36.3691, 36.2990, 36.2577, 36.1830, ...
     36.1687, 36.1591, 36.1311, 36.0344, 36.0180, 36.0110, 35.9551, ...
     35.9404, 35.9189, 35.9111, 35.9006, 35.8694, 35.8378, 35.8264, ...
     35.7998, 35.7739, 35.7608, 35.5836, 35.5740, 35.5666, 35.5417, ...
     35.4341, 35.4250, 35.3707, 35.3473, 35.2646, 35.2576, 35.2473, ...
     35.2324, 35.2087, 35.1384, 35.1026, 35.0997, 35.0684, 35.0650, ...
     35.0370, 35.0244, 35.0060, 34.9564, 34.9000, 34.8250, 34.7980, ...
     34.7747, 34.7606, 34.7512, 34.7173, 34.7114, 34.7062, 34.7005, ...
     34.6677, 34.6122, 34.6107, 34.5360, 34.5328, 34.4964, 34.4308, ...
     34.3511, 34.3328, 34.2668, 34.2164, 34.2133, 34.2070, 34.1420, ...
     34.0039, 33.9880, 33.9624, 33.9170, 33.9103, 33.8480, 33.8162, ...
     33.4360, 32.5010, 31.8620, 27.5170];

% Beaufort, NC 
%    output_info.lon = [-76.67062];
%    output_info.lat = [34.71731];
else
    disp('output_info.type must be either the string "grid" or "points" ')
end










