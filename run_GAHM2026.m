%--------------------------------------------------------------------------
% Function to execute GAHM2026.m
%
% Usage:
%     run_GAHM2026              — uses default config/config_GAHM2026.m
%     run_GAHM2026('myconfig')  — uses config/myconfig.m
% 
%% Required Matlab scripts:
%     GAHM2026.m - master GAHM26 calc script and all scripts it calls
%     writeGAHM2026NetCDF.m - write gridded output into netCDF file    
%
%% Required input:
%
%    storm info - for track file
%        storm.file_name = file name containing storm input
%        storm.file_type 
%                   = "ATCF" (string) for ATCF BestTrack (a/b deck) file
%                   = "fort22" (string) for GAHM26 fort22 file
%                   = "IBTrACS" (string) for IBTrACS file
%        storm.year = storm year (char 4digits) e.g., '2018'
%                     ignored if single storm ATCF best track input file
%        storm.designation = (char 4digits) basinnum, e.g., 'AL06'
%                     ignored if single storm ATCF best track input file
%        storm.name = storm name  (char) e.g., 'FLORENCE'
%                     ignored if storm.designation specified
%                     ignored if single storm ATCF best track input file
%        storm.starttime = start time for processing as a string in the
%                     format 'yyyymmddhh'  (e.g. '2018091412')
%                     if = 0 (numeric input) use initial time
%        storm.endtime = end time for processing as a string in the
%                     format 'yyyymmddhh'  (e.g. '2018091412')
%                     if = 0 (numeric input) use final time
%
%    environmental info
%        env_info.type - type of environmental velocity and pressure fields
%                 = 1 ADCIRC/ASWIP scheme based on translation vel
%                 = 2 0.6*tanslation vel & 20deg ccw rotation (Lin&Chavez 2012)
%                 = 3 extracted from gridded environmental file
%        env_info.file_name  (.mat extension not included in file_name)
%                 ignored if env_info.type =1 or 2
%                 if env_info.type = 3, matlab.mat file containing gridded 
%                 environmental and hurricane velocity and pressure input           
%                 file should contain the following data structure:
%                     filename.Time(i) - datetime
%                     filename.Lo(i,:,:)
%                     filename.La(i,nEr:-1:1,:)
%                     filename.Vortex_mask(i,nEr:-1:1,:)   0,1=inside,outside outer cut line
%                     filename.Vortex_mask34(i,nEr:-1:1,:) 0,1=inside,outside inner cut line
%                     filename.env_msl(i,nEr:-1:1,:))  env mean sea level pressure (mb)
%                     filename.env_u10(i,nEr:-1:1,:)   env E-W velocity (m/s)
%                     filename.env_v10(i,nEr:-1:1,:)   env N-S velocity (m/s)
%                     filename.hur_msl(i,nEr:-1:1,:))  hur mean sea level pressure (mb)
%                     filename.hur_u10(i,nEr:-1:1,:)   hur E-W velocity (m/s)
%                     filename.hur_v10(i,nEr:-1:1,:)   hur N-S velocity (m/s)
%                     filename.BestTrack_lon(i)
%                     filename.BestTrack_lat(i)
%                     filename.min_pressure_center_lon(i)
%                     filename.min_pressure_center_lat(i)
%                     units - dictionary
%                     must include times that match the track file times 
%                     may include additional times, e.g., hourly values 
%
%    Wind Adjustment Factor info for land roughness wind adjustment
%         WAF_info.flag = true or false
%         WAF_info.file_name = '   .tif'  file name containing WAF raster,
%                                       .tif must be included in file name
%                                       ignored if WAF_info.flag=false
%
%    GAHM_constants - data structure with constants needed by GAHM
%        GAHM_constants.Vmax_multiplier - modify Vmax in track file
%        GAHM_constants.one2tenF - convert from 1 min to 10 min wind speed
%                                                       (ADCIRC/ASWIP=0.89)
%        GAHM_constants.BLF  - boundary layer factor (ADCIRC/ASWIP=0.9)
%        GAHM_constants.Bmin - lower limit on B
%        GAHM_constants.Bmax - upper limit on B
%        GAHM_constants.SVorMax_10_tblmin - (kts)
%        GAHM_constants.SVorQuad_10_tblmin - (kts)
%        GAHM_constants.rhoa - density of air (kg/m^3) (ADCIRC/ASWIP=1.204)
%        GAHM_constants.pback_def - (mb) default environmental pressure if 
%                              not read in from track file
%        GAHM_constants.version  (3 or 4)
%        GAHM_constants.Bg0M - multiplies B to give initial condition for
%                              iterative solver in GAHM26 v4 (recom: 1)
%        GAHM_constants.c0 - initial condition for c (0<c<1) for iterative
%                              solver in GAHM26 (recom: 0)
% 
%    blend_constants - data structure with parameters needed for blending
%        ignored if env_info.type = 1 or 2
%        blend_constants.ntheta - number of radial lines to blend along
%                               (e.g., 24 = every 15 deg)
%        blend_constants.nr -  number of points along each radial line to
%                               compute GAHM speed & pressure values for
%                               blending
%        blend_constants.delr - distance (meters) between points along
%                               each radial line (radial length = nr*delr)
%        blend_constants.taper_flag = true or false - apply a taper
%                               function to GAHM speed and pressure values
%        blend_constants.taper_mindelr2r1  % minimum value for (r2-r1)/r2
%                               If violated r1 is reduced.
%        blend_constants.taper_a - taper coefficient in hyperbolic tan
%                               function (e.g., 2)
%
%   output control variables
%        output_info.warnings - file name to write warning messages
%        output_info.NetCDFfilename - ' ' no extension, .nc will be appended
%        output_info.timeinc - output time interval (hrs) must be <= time between track file snaps
%        output_info.type - "grid" or "points"
%        if output_info.type = "grid"
%            output_info.nlon  - # lon values in regular output grid (best if an odd
%                                               number) ignored for env_info.type=3
%            output_info.nlat -  # lat values in regular output grid (best if an odd
%                                               number) ignored for env_info.type=3
%            output_info.dellon -  grid increment decimal degrees lon
%            output_info.dellat -  grid increment decimal degrees lat
%
%            Notes - the output grid is centered on the storm and moving in
%                    time
%                    if env_info.type=1,2 the output grid extents and
%                    resolution are deteremined by nlon, nlat, dellon,
%                    dellat
%                    if env_info.type=3 the output grid extents are the same
%                    as the gridded input field. The output grid resolution
%                    is determined by dellon, dellat
%         if output.type="points"  
%            output.lon = [lon1, lon2, ...] - longitude locations for output
%            output.lat = [lat1, lat2, ...] - latitude locations for output
%
%%  Output
%
%   if output_info.type="grid"
%        Reggrid_out(i).datetime 
%        Reggrid_out(i).Lon
%        Reggrid_out(i).Lat
%        Reggrid_TC_out(i).VelU  (m/s)
%        Reggrid_TC_out(i).VelV  (m/s)
%        Reggrid_TC_out(i).Press (mb)
%        Reggrid_TC_out(i).Mask1
%        Reggrid_TC_out(i).Mask2
%        Reggrid_Env_out(i).U10 (m/s)
%        Reggrid_Env_out(i).V10 (m/s)
%        Reggrid_Env_out(i).Press (mb)
%
%   if output_info.type="points"
%        Points_TC_out(i).datetime 
%        Points_TC_out(i).Lon
%        Points_TC_out(i).Lat
%        Points_TC_out(i).U10  (m/s)
%        Points_TC_out(i).V10  (m/s)
%        Points_TC_out(i).Press (mb)
%        Points_Env_out(i).datetime
%        Points_Env_out(i).Lon
%        Points_Env_out(i).Lat
%        Points_Env_out(i).U10 (m/s)
%        Points_Env_out(i).V10 (m/s)
%        Points_Env_out(i).Press (mb)
%
%   Radial grid data (always returned):
%        VPrad.r            - radial distance vector (m)
%        VPrad.theta        - azimuthal angle vector (deg)
%        VPrad.VVor(i)      - vortex fields (.VelU, .VelV, .Speed, .Press)
%        VPrad.Env(i)       - environmental fields (env_type=3 only)
%        VPrad.EnvVor(i)    - combined env+vortex fields (env_type=3 only)
%
%%                        2/3/2026  Rick Luettich

function run_GAHM2026(config_name)

if nargin < 1
    config_name = 'config_GAHM2026';
end

addpath('util')

warning off

%% Load configuration parameters
config_file = fullfile('config', config_name);
if ~exist([config_file '.m'], 'file')
    error('Config file not found: %s.m', config_file);
end
run(config_file)

%% Download IBTrACS file if it does not exist
if storm_info.file_type == "IBTrACS" && ~exist(storm_info.file_name,'file')
    ibtracs_url = ['https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/csv/' ...
                   erase(storm_info.file_name,'input/')];
    fprintf('IBTrACS file not found: %s\n', storm_info.file_name);
    fprintf('Downloading from %s ...\n', ibtracs_url);
    try
        websave(storm_info.file_name, ibtracs_url);
        fprintf('Download complete.\n');
    catch ME
        error('Failed to download IBTrACS file: %s', ME.message);
    end
end

%% Check for existing output file before running
if output_info.type == "grid"
    f_out = [output_info.NetCDFfilename '.nc'];
    if exist(f_out,'file')
        error([f_out ' already exists. Delete or rename it before running.'])
    end
end

%% compute and output final TC wind/pressure fields as well as additional diagnostic information


[Reggrid_out, Reggrid_TC_out, Reggrid_Env_out, Reggrid_VVor_invtapHur_out, ...
        Trackdata, GAHM_out, VPrad]= GAHM2026(storm_info,GAHM_param_info, ...
                          GAHM_compute_info,WAF_info,env_info,output_info);

if output_info.type == "grid"
    disp('Writing netCDF output')
    err=writeGAHM2026NetCdf(output_info.NetCDFfilename,Reggrid_out,Reggrid_TC_out);
elseif output_info.type == "points"
    nt=length(Reggrid_out);
    for i=1:nt
        Points_TC_out(i).datetime=Reggrid_out(i).datetime;
        Points_TC_out(i).Lon=Reggrid_out(i).Lon;
        Points_TC_out(i).Lat=Reggrid_out(i).Lat;
        Points_TC_out(i).U10=Reggrid_TC_out(i).VelU;
        Points_TC_out(i).V10=Reggrid_TC_out(i).VelV;
        Points_TC_out(i).Press=Reggrid_TC_out(i).Press;
        Points_Env_out(i).datetime=Reggrid_out(i).datetime;
        Points_Env_out(i).Lon=Reggrid_out(i).Lon;
        Points_Env_out(i).Lat=Reggrid_out(i).Lat;
        Points_Env_out(i).U10=Reggrid_Env_out(i).VelU;
        Points_Env_out(i).V10=Reggrid_Env_out(i).VelV;
        Points_Env_out(i).Press=Reggrid_Env_out(i).Press;        
    end

    disp('Done computing values at output points')
end

end
