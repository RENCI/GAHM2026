%--------------------------------------------------------------------------
% Configuration for GAHM2026
%
% This script defines all input parameters needed by run_GAHM2026.m.
% Edit this file to change storm, GAHM constants, environmental field,
% WAF, and output settings. Then run run_GAHM2026.m.
%
% See run_GAHM2026.m header comments for full documentation of
% each parameter.
%
%                        2/7/2026  Rick Luettich, UNC/IMS/CNHR/EMES 
%                                  Brian Blanton, UNC/RENCI
%--------------------------------------------------------------------------

%% storm / track file info
storm_info.file_name = 'input/ibtracs.NA.list.v04r01.csv';
storm_info.file_type = "IBTrACS";
storm_info.name='FLORENCE';   %IBTrACS uses all caps for names
storm_info.year = '2018';              
storm_info.designation = 'AL06';  
% start,end dates for processing
% 0 for start,end of track in IBTrACS
% otherwise, YYYYMMDDHH, must be in both the track & gridded input files (if used).
%storm_info.starttime = 0;          
%storm_info.endtime = 0;            
storm_info.starttime='2018091400';  
storm_info.endtime='2018091500';   
storm_info.outputfilename=sprintf('%s_%s',storm_info.name,storm_info.year);

%% GAHM2026 parameter values
GAHM_param_info.Vmax_multiplier=1; % =1 use full Vmax, =0.9 use 90% Vmax...
GAHM_param_info.one2tenF=0.89;
GAHM_param_info.BLF=0.9;
GAHM_param_info.Bmin=0.5;
GAHM_param_info.Bmax=2.5;
GAHM_param_info.SVorMax_10_tblmin=20;
GAHM_param_info.SVorQuad_10_tblmin=5;
GAHM_param_info.rhoa=1.204;
GAHM_param_info.pback_def=1013; 
GAHM_param_info.version=3;  
GAHM_param_info.Bg0M=1;
GAHM_param_info.c0=0;

%% specify constants for computing wind/pressure field using GAHM2026 
GAHM_compute_info.ntheta=24;
GAHM_compute_info.nr=800;
GAHM_compute_info.delr=1000;

%% specify info for using land roughness based Wind Adjustment Factor
WAF_info.flag=true;    % Wind Adjustment Factor based on land roughness
WAF_info.file_name='input/WAF_15deg_10km_6km_raster_test.tif'; % name of .tif file with gridded WAF values, ignored if WAF.flag=false

%% specify info for large scale gridded wind / pressure field
env_info.type=3; % options are 1, 2 or 3.  If 1 or 2 are selected, the remainder of this section is ignored
env_info.file_name='EnvFields';  % name of intermediate .mat file contining gridded environmental fields.
env_info.taper_flag=true;
env_info.taper_mindelr2r1=0.1; % minimum value of (r2-r1)/r2 if violated r1 is reduced.
env_info.taper_a=2;   % adjusts steepness of hyperbolic tangent taper function (2 is suggested)

%% Output information
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

output_info.warnings=sprintf('%s_%s_GAHM2026_warnings.dat',storm_info.name,storm_info.year);
output_info.NetCDFfilename=['output/' storm_info.outputfilename];
output_info.timeinc=1;     % output time interval (hrs) must be <= time between BestTrack snaps
output_info.type = "grid";
% output_info.type = "points";
if output_info.type == "grid"
    output_info.nlon=351;      % # lon values in regular output grid (best if an odd number) - ignored for env.type=3
    output_info.nlat=351;      % # lat values in regular output grid (best if an odd number) - ignored for env.type=3
    output_info.dellon=0.05;   % grid increment decimal degrees lon 
    output_info.dellat=0.05;   % grid increment decimal degrees lat 
elseif output_info.type == "points"
    output_info.lon=x;
    output_info.lat=y;
%    output_info.lon=[  ];
%    output_info.lat=[  ];    
else
    disp ('output_info.type must be either the string "grid" or "points" ')
end
