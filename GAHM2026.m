%.........................................................................
% 
%  Function to compute GAHM2026 wind and pressure fields on a lon,lat grid 
%  that is centered on the eye of the storm. This version will skip extra 
%  track file entries that are not at the regular track interval 
% (e.g., 3 hrs or 6 hrs).
% 
%  If gridded environmental and hurricane field are specified, the 
%  GAHM2026 fields can be blended into the hurricane field and then added
%  to the environmental field.  
%
%  The environmental velocity is either computed based on the storm 
%  translation velocity (for non-blending cases) or it is read in as a 
%  gridded field (for blending). In the latter case, the gridded data
%  must contain times that are aligned with the times in the TC track file, 
%  although they may have a smaller time interval (e.g., TC track data 
%  every 3 or 6 hrs, environmental data every hour). Output is computed in 
%  multiples (e.g., 1, 2, 3...) of the env data time interval.  
%
%  Uses GAHM2026_solve to compute GAHM parameters (dispatches to v3e or v4a)
%
% Required Matlab scripts:
%     read_ATCF_fort22 - read track input in ATCF or fort22 format
%     read_IBTrACS     - read track input in IBTrACS format
%     read_Env_and_Hurr_fields2.m - read gridded environmental and
%                          hurricane fields
%     GAHM2026_prep.m - initialize the GAHM datastructure each timestep
%         VEnvAvg() - embedded function 7/6/2024 - if env_type=3, 
%                      compute average environmental velocity within Rmax 
%                      of the eye
%         VEnvQuad() - embedded function 7/6/2025 - if env_type=3, 
%                      compute environmental velocity at isotach locations 
%                      in 4 quadrants
%     GAHM2026_consistency.m - screen input values for consistency with
%                          the GAHM2026 equations each timestep
%     GAHM2026_solve.m - compute GAHM2026 parameters (unified v3e/v4a)
%     GAHM_VPradial.m - compute GAHM velocity and pressure along a
%                        specified theta radial line
%           GAHM_VP.m - compute GAHM velocity and pressure at a specified
%                        point along a quadrant radial line
%     VEnvreg2radial2.m - interplate regular grid environmental field onto
%                         radial grid
%     radial_taper2.m  - computes the taper function on the radial grid
%     radial2regular.m - interpolates wind velocity (u,v) and pressure from
%                        a radial grid to a regular grid
%
% Required input:
%    storm info - for track file
%        storm.file_name = file name containing storm input
%        storm.file_type 
%                   = "ATCF" (string) for ATCF BestTrack (a/b deck) file
%                   = "fort22" (string) for GAHM2026 fort22 file
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
%    GAHM_param_info - constants needed to compute GAHM parameters
%        GAHM_param_info.Vmax_multiplier - modify Vmax in track file
%        GAHM_param_info.one2tenF - convert from 1 min to 10 min wind speed
%                                                       (ADCIRC/ASWIP=0.89)
%        GAHM_param_info.BLF  - boundary layer factor (ADCIRC/ASWIP=0.9)
%        GAHM_param_info.Bmin - lower limit on B
%        GAHM_param_info.Bmax - upper limit on B
%        GAHM_param_info.SVorMax_10_tblmin - (kts)
%        GAHM_param_info.SVorQuad_10_tblmin - (kts)
%        GAHM_param_info.rhoa - density of air (kg/m^3) (ADCIRC/ASWIP=1.204)
%        GAHM_param_info.pback_def - (mb) default environmental pressure if 
%                              not read in from track file
%        GAHM_param_info.version  (3 or 4)
%        GAHM_param_info.Bg0M - multiplies B to give initial condition for
%                              iterative solver in GAHM2026v4a & GAHM2026v3e
%                              (recom: 1)
%        GAHM_param_info.c0 - initial condition for c (0<c<1) for iterative
%                              solver in GAHM2026va (recom: 0), ignored
%                              for GAHM2023v3e.
% 
%    GAHM_compute_info - information needed to compute GAHM wind and
%                        pressure fields on radial grid using GAHM 
%                        parameter values
%        GAHM_compute_info.ntheta - number of radial lines to compute GAHM
%                            along (e.g., 24 = every 15 deg)
%        GAHM_compute_info.nr -  number of points along each radial line to
%                               compute GAHM speed & pressure values
%        GAHM_compute_info.delr - distance (meters) between points along
%                               each radial line (radial length = nr*delr)
%
%    env_info - information needed to process the environmental field. All
%            subsequent env_info entries are ignored unless env_info.type=3
%        env_info.type - type of environmental velocity and pressure fields
%                 = 1 ADCIRC/ASWIP scheme based on translation vel
%                 = 2 0.6*tanslation vel & 20deg ccw rotation (Lin&Chavez 2012)
%                 = 3 extract from gridded environmental file
%        env_info.file_name = file name containing gridded environmental velocity 
%                 and pressure input, ignored if env_type =1 or 2
%                 if env_type=3, matlab.mat file with the data structure:
%                     filename.Time(i) - datetime
%                     filename.Lo(i,:,:)
%                     filename.La(i,nEr:-1:1,:)
%                     filename.Vortex_mask(i,nEr:-1:1,:) 0,1=inside,outside 
%                                                            outer cut line
%                     filename.Vortex_mask34(i,nEr:-1:1,:) 0,1=inside,outside
%                                                            inner cut line
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
%        env_info.taper_flag = true or false - apply a taper
%                               function to GAHM speed and pressure values
%        env_info.taper_mindelr2r1  % minimum value for (r2-r1)/r2
%                               If violated r1 is reduced.
%        env_info.taper_a - taper coefficient in hyperbolic tan function 
%                               (e.g., 2)
%
%   output control variables
%        output.timeinc - output time interval (hrs) must be <= time between track file snaps
%        output.nlon  - # lon values in regular output grid (best if an odd
%                                           number) ignored for env_type=3
%        output.nlat -  # lat values in regular output grid (best if an odd
%                                           number) ignored for env_type=3
%        output.dellon -  grid increment decimal degrees lon
%        output.dellat -  grid increment decimal degrees lat
%        output.warnings - file name to write warning messages
%        Note - if env_type=3 the output domain is the same as the ded 
%               gridded input field using the resolution specified by 
%               output.dellon, output.dellat
%
%   See documentation/GAHM_struct.md for full GAHM data structure definition.
%
%                 7/12/2025   - Rick Luettich
%                 11/4/2025   - Rick Luettich enables env_type=1 to work?
%                  2/2/2026  -  Rick Luettich eliminated nonHurr variables
%                               added inner and outer mask, WAF,
%                               reorganized, checked env_type=1,2,3
%                  2/6/2026  -  Decomposed into local functions
%--------------------------------------------------------------------------
%
function [Reggrid_out, Reggrid_TC_out, Reggrid_Env_out, ...
          Reggrid_VVor_invtapHur_out, Trackdata, GAHM_out, VPrad] = ...
          GAHM2026(storm,GAHM_param_info,GAHM_compute_info,WAF_info,...
          env_info,output,debug)

if nargin < 7, debug = false; end

%% transfer / compute needed information

GAHM_version=GAHM_param_info.version;
VMax_mult=GAHM_param_info.Vmax_multiplier;

ntheta=GAHM_compute_info.ntheta;
nr=GAHM_compute_info.nr;
delr=GAHM_compute_info.delr;
r=(0:nr)*delr;
theta(1:ntheta)=(0:ntheta-1)*360/ntheta;

taper_flag=env_info.taper_flag;
env_type=env_info.type;
WAF_flag=WAF_info.flag;

if taper_flag
    taper_constants.ntheta=ntheta;
    taper_constants.nr=nr;
    taper_constants.delr=delr;
    taper_constants.taper_flag=taper_flag;
    taper_constants.taper_mindelr2r1=env_info.taper_mindelr2r1;
    taper_constants.taper_a=env_info.taper_a; 
end
 
fid=fopen(output.warnings,'wt');

if debug, fprintf('[DEBUG:GAHM2026] GAHM version=%d, env_type=%d, taper=%d, WAF=%d\n', GAHM_version, env_type, taper_flag, WAF_flag); end
if debug, fprintf('[DEBUG:GAHM2026] Radial grid: ntheta=%d, nr=%d, delr=%d m (max radius=%.0f km)\n', ntheta, nr, delr, nr*delr/1000); end

%% Read in storm track information & find beginning and ending lines

[ATCF_data_in, ATCF_startline, ATCF_endline, starttime_dt, endtime_dt] = ...
    readAndSliceTrack(storm);

if debug, fprintf('[DEBUG:GAHM2026] Track loaded: %s, lines %d-%d (%s to %s)\n', ...
    storm.name, ATCF_startline, ATCF_endline, string(starttime_dt), string(endtime_dt)); end

%% Read gridded environmental/hurricane fields and WAF raster

if debug, fprintf('[DEBUG:GAHM2026] Loading environmental fields ...\n'); end
[VEnv_10_10, VHur_10_10, BlendingMasks, PscaleEnv] = ...
    loadEnvFields(env_type, env_info, starttime_dt, endtime_dt);
if debug, fprintf('[DEBUG:GAHM2026] Environmental fields loaded.\n'); end

WAF_data = [];
WAF_metadata = [];
if WAF_flag
    if debug, fprintf('[DEBUG:GAHM2026] Loading WAF raster from %s\n', WAF_info.file_name); end
    [WAF_data,WAF_metadata]=readgeoraster(WAF_info.file_name);    
end

%% Master time loop

nBTtime=ATCF_endline-ATCF_startline+1;
fprintf('[INFO:GAHM2026] Beginning master time loop: %d track time steps\n', nBTtime);
i=0;
otime=0;
VEnvrad_10_10 = [];
PEnvrad = [];
VHurrad_10_10 = [];
PHurrad = [];
BlendingMasksrad = [];

for itime=1:nBTtime
    ATCF_line_t2=ATCF_startline+itime-1;
    datetime_t2=ATCF_data_in(ATCF_line_t2).datetime;    
    if itime==1
        ATCF_line_t1=ATCF_line_t2-1;     
    end
    if ATCF_line_t2 == 1
        ATCF_line_t1=ATCF_line_t2;
        datetime_t1=datetime_t2;
        BTinterval=1;
    else
        datetime_t1=ATCF_data_in(ATCF_line_t1).datetime;                           
        BTinterval=hours(datetime_t2-datetime_t1);
    end
    if itime ~=1
        VEnvAvg_10_10_t1=VEnvAvg_10_10_t2; 
        VVel_VPrad_t1=VVel_VPrad_t2;  
        VPress_VPrad_t1=VPress_VPrad_t2; 
        GAHM_t1=GAHM_t2;
    end

    %% Compute GAHM parameters at current track time

    if debug, fprintf('[DEBUG:GAHM2026]   Step %d/%d: %s (BTinterval=%d hrs)\n', itime, nBTtime, string(datetime_t2), BTinterval); end

    [GAHM_t_new, skipline] = computeGAHMAtTrackTime(GAHM_param_info, ...
        env_info, ATCF_data_in, VEnv_10_10, PscaleEnv, ATCF_line_t2, ...
        BTinterval, fid);
    if skipline
        if debug, fprintf('[DEBUG:GAHM2026]   Step %d/%d: skipped\n', itime, nBTtime); end
        continue
    end
    GAHM_t2 = GAHM_t_new;
              
    %% Compute radial profiles of vortex velocity and pressure

    if debug, fprintf('[DEBUG:GAHM2026]   Computing radial profiles ...\n'); end
    [VVel_VPrad_t2, VPress_VPrad_t2, RP1, RP2] = computeRadialProfiles( ...
        r, theta, ntheta, nr, GAHM_param_info, GAHM_t2);

    if itime == 1
        datetime_t1=datetime_t2;      
        GAHM_t1 = GAHM_t2;
        VEnvAvg_10_10_t1=GAHM_t1.VEnvStar_10_10;
        VVel_VPrad_t1=VVel_VPrad_t2;
        VPress_VPrad_t1=VPress_VPrad_t2;
    end
 
    %% Interpolate to desired output times

    int=1;
    LonEW_t1=GAHM_t1.Eye(1);
    LatNS_t1=GAHM_t1.Eye(2);
    LonEW_t2=GAHM_t2.Eye(1);
    LatNS_t2=GAHM_t2.Eye(2);    
    VEnvAvg_10_10_t2=GAHM_t2.VEnvStar_10_10;
    Pback_t2=GAHM_t2.Pback;
    while (int-1)*output.timeinc < BTinterval        
        i=i+1;
        if itime==1
            int=1000;
            tfac2=1;
            tfac1=0;
            datetimeint(1,:)=datetime_t2;
        else
            int=int+1;
            tfac2=(int-1)*output.timeinc/BTinterval;
            tfac1=1-tfac2;
            datetimeint(i,:)=datetime_t1+tfac2*duration(datetime_t2-datetime_t1);
        end

        % interpolate vortex fields on the radial grid at output times

        LatNS(i)=tfac1*LatNS_t1+tfac2*LatNS_t2;
        LonEW(i)=tfac1*LonEW_t1+tfac2*LonEW_t2;
        for it=1:ntheta
            VVel_VPrad_10_10(i,it,1:nr+1,1)=(VVel_VPrad_t1(it,1:nr+1,1)*tfac1 + ....
                                            VVel_VPrad_t2(it,1:nr+1,1)*tfac2);
            VVel_VPrad_10_10(i,it,1:nr+1,2)=(VVel_VPrad_t1(it,1:nr+1,2)*tfac1 + ....
                                            VVel_VPrad_t2(it,1:nr+1,2)*tfac2);
            VSpeed_VPrad_10_10(i,it,1:nr+1)=squeeze(vecnorm(permute(VVel_VPrad_10_10(i,it,1:nr+1,1:2),[4 1 2 3])));  
            VPress_VPrad(i,it,1:nr+1)=VPress_VPrad_t1(it,1:nr+1)*tfac1 + VPress_VPrad_t2(it,1:nr+1)*tfac2;
        end

        % interpolate environmental field on radial grid at output times

        [VEnvrad_10_10, PEnvrad, VHurrad_10_10, PHurrad, BlendingMasksrad] = ...
            interpolateEnvOnRadialGrid(env_type, i, ntheta, nr, r, theta, ...
                VEnv_10_10, VHur_10_10, BlendingMasks, ...
                VSpeed_VPrad_10_10, GAHM_t1, GAHM_t2, ...
                VEnvAvg_10_10_t1, VEnvAvg_10_10_t2, Pback_t2, ...
                tfac1, tfac2, datetimeint, LonEW(i), LatNS(i), fid, ...
                VEnvrad_10_10, PEnvrad, VHurrad_10_10, PHurrad, BlendingMasksrad);

        % apply taper function if enabled

        if env_type==1 || env_type==2
            taper_flag_eff=false;
        else
            taper_flag_eff=taper_flag;
        end
        if taper_flag_eff
            [VVel_VPrad_10_10, VPress_VPrad, VHurrad_10_10, PHurrad] = ...
                applyTaperOnRadialGrid(i, ntheta, nr, r, theta, ...
                    env_type, taper_constants, ...
                    BlendingMasksrad, datetimeint, fid, ...
                    VVel_VPrad_10_10, VPress_VPrad, VHurrad_10_10, PHurrad);
        end
        
        % save track information

        Trackdata(i).datetime=datetimeint(i,:);
        Trackdata(i).Lat=LatNS(i);
        Trackdata(i).Lon=LonEW(i);
        Trackdata(i).RQuad_t1(1:4,1:3)=GAHM_t1.RQuad(1:4,1:3);
        Trackdata(i).Vmax_t1=ATCF_data_in(ATCF_line_t1).Vmax*VMax_mult;
        Trackdata(i).Rmax_t1=ATCF_data_in(ATCF_line_t1).RMW;
        Trackdata(i).RQuad_t2(1:4,1:3)=GAHM_t2.RQuad(1:4,1:3);
        Trackdata(i).Vmax_t2=ATCF_data_in(ATCF_line_t2).Vmax*VMax_mult;
        Trackdata(i).Rmax_t2=ATCF_data_in(ATCF_line_t2).RMW;
        Trackdata(i).RP1(1:ntheta)=RP1(1:ntheta);
        Trackdata(i).RP2(1:ntheta)=RP2(1:ntheta);        
    end

    ATCF_line_t1=ATCF_line_t2;
    otime=otime+1;
    GAHM_out(otime)=GAHM_t2;

end  % end master time loop

fprintf('%s \n',' Completed calculations on radial grid. Preparing output')
if debug, fprintf('[DEBUG:GAHM2026] Master time loop complete: %d output time steps produced\n', i); end

itot=i;
fclose(fid);

%% Interpolate from radial grid to regular output grid

fprintf('[INFO:GAHM2026] Interpolating from radial grid to regular output grid (%s) ...\n', output.type);
[Reggrid_out, Reggrid_TC_out, Reggrid_Env_out, Reggrid_VVor_invtapHur_out] = ...
    buildRegularGridOutputs(itot, env_type, ntheta, nr, r, theta, ...
        output, WAF_flag, ...
        VVel_VPrad_10_10, VPress_VPrad, VEnvrad_10_10, PEnvrad, ...
        VHurrad_10_10, PHurrad, ...
        VEnv_10_10, VHur_10_10, BlendingMasks, ...
        LonEW, LatNS, datetimeint, ...
        WAF_data, WAF_metadata);
fprintf('[INFO:GAHM2026] Regular grid interpolation complete.\n');

%% Package radial grid data for plotting

VPrad.r = r;
VPrad.theta = theta;
for ii = 1:itot
    VPrad.VVor(ii).VelU  = squeeze(VVel_VPrad_10_10(ii,:,:,1));
    VPrad.VVor(ii).VelV  = squeeze(VVel_VPrad_10_10(ii,:,:,2));
    VPrad.VVor(ii).Speed = squeeze(VSpeed_VPrad_10_10(ii,:,:));
    VPrad.VVor(ii).Press = squeeze(VPress_VPrad(ii,:,:));
    if ~isempty(VEnvrad_10_10)
        VPrad.Env(ii).VelU  = squeeze(VEnvrad_10_10(ii,:,:,1));
        VPrad.Env(ii).VelV  = squeeze(VEnvrad_10_10(ii,:,:,2));
        VPrad.Env(ii).Speed = hypot(VPrad.Env(ii).VelU, VPrad.Env(ii).VelV);
        VPrad.Env(ii).Press = squeeze(PEnvrad(ii,:,:));
        VPrad.EnvVor(ii).VelU  = VPrad.VVor(ii).VelU + VPrad.Env(ii).VelU;
        VPrad.EnvVor(ii).VelV  = VPrad.VVor(ii).VelV + VPrad.Env(ii).VelV;
        VPrad.EnvVor(ii).Speed = hypot(VPrad.EnvVor(ii).VelU, VPrad.EnvVor(ii).VelV);
        VPrad.EnvVor(ii).Press = VPrad.VVor(ii).Press + VPrad.Env(ii).Press;
    end
end

if debug, fprintf('[DEBUG:GAHM2026] Done.\n'); end

end  % end main function


%% ========================================================================
%  Local helper functions
%  ========================================================================

function [ATCF_data_in, ATCF_startline, ATCF_endline, starttime_dt, endtime_dt] = ...
    readAndSliceTrack(storm)

    if storm.file_type == "ATCF" || storm.file_type == "fort22"
        ATCF_data_in=read_ATCF_fort22(storm.file_name,storm.file_type);
    elseif storm.file_type == "IBTrACS"
        ATCF_data_in=read_IBTrACS2(storm);
    end

    if convertCharsToStrings(ATCF_data_in(1).sname_cha) == convertCharsToStrings(storm.name)
        fprintf('%s %s %s %s\n',storm.designation,storm.year,storm.name,' found in track file' )
    else
        fprintf('%s %s %s %s\n',storm.designation,storm.year,storm.name,' not found in track file. RUN TERMINATED' )
        error('Storm %s not found in track file', storm.name)
    end

    starttime_dtv=datevec(storm.starttime,'yyyymmddhh');
    starttime_dt = datetime(0,0,0);
    if sum(starttime_dtv) == 0
        ATCF_startline=1; 
    else
        starttime_dt=datetime(starttime_dtv);
        ATCF_startline=find([ATCF_data_in.datetime] < starttime_dt,1,'last')+1;
        if isempty(ATCF_startline)
            ATCF_startline=1;
        end
    end

    endtime_dtv=datevec(storm.endtime,'yyyymmddhh');
    endtime_dt = datetime(0,0,0);
    if sum(endtime_dtv) == 0
        ATCF_endline=length([ATCF_data_in.datetime]);  
    else
        endtime_dt=datetime(endtime_dtv);
        ATCF_endline=find([ATCF_data_in.datetime] <= endtime_dt,1,'last');
        if isempty(ATCF_endline)
            ATCF_endline=length([ATCF_data_in.datetime]);
        end
    end
end


function [VEnv_10_10, VHur_10_10, BlendingMasks, PscaleEnv] = ...
    loadEnvFields(env_type, env_info, starttime_dt, endtime_dt)

    BlendingMasks = 0;
    if env_type == 1 || env_type == 2
        VEnv_10_10=0;
        VHur_10_10=0;
        PscaleEnv=1;
    elseif env_type == 3
        [VEnv_10_10,VHur_10_10,BlendingMasks,PscaleEnv] = ...
                    read_Env_and_Hurr_fields2(env_info,starttime_dt,endtime_dt);
    end
end


function [GAHM_t, skipline] = computeGAHMAtTrackTime(GAHM_param_info, ...
    env_info, ATCF_data_in, VEnv_10_10, PscaleEnv, ATCF_line, ...
    BTinterval, fid)

    GAHMp1=GAHM2026_prep(GAHM_param_info,env_info,ATCF_data_in,VEnv_10_10,...
                              PscaleEnv,ATCF_line,BTinterval,fid);
    if GAHMp1.skipline
        GAHM_t = GAHMp1;
        skipline = true;
        return
    end

    GAHMp2=GAHM2026_consistency(GAHM_param_info,GAHMp1,fid);

    GAHM_t = GAHM2026_solve(GAHMp2,GAHM_param_info,fid);
    skipline = false;
end


function [VVel_VPrad, VPress_VPrad, RP1, RP2] = computeRadialProfiles( ...
    r, theta, ntheta, nr, GAHM_param_info, GAHM_t)

    for it=1:ntheta   
        GAHM_VPrad_t=GAHM_VPradial(r,theta(it),GAHM_param_info,GAHM_t);
        VVel_VPrad(it,1:nr+1,1:2)=GAHM_VPrad_t.VVor_10_10(1:nr+1,1:2);      
        VPress_VPrad(it,1:nr+1)=GAHM_VPrad_t.Press(1:nr+1); 
        RP1(it)=GAHM_VPrad_t.RP(1);
        RP2(it)=GAHM_VPrad_t.RP(2);
    end
end


function [VEnvrad_10_10, PEnvrad, VHurrad_10_10, PHurrad, BlendingMasksrad] = ...
    interpolateEnvOnRadialGrid(env_type, i, ntheta, nr, r, theta, ...
        VEnv_10_10, VHur_10_10, BlendingMasks, ...
        VSpeed_VPrad_10_10, GAHM_t1, GAHM_t2, ...
        VEnvAvg_10_10_t1, VEnvAvg_10_10_t2, Pback_t2, ...
        tfac1, tfac2, datetimeint, LonEW_i, LatNS_i, fid, ...
        VEnvrad_10_10, PEnvrad, VHurrad_10_10, PHurrad, BlendingMasksrad)

    if env_type == 1        
        SVorMax_10_10=GAHM_t1.SVorMax_10_10*tfac1+GAHM_t2.SVorMax_10_10*tfac2;
        SEnvScaleFactor(1:ntheta,1:nr+1)=VSpeed_VPrad_10_10(i,1:ntheta,1:nr+1)/SVorMax_10_10;
        VEnvrad_10_10(i,1:ntheta,1:nr+1,1)=SEnvScaleFactor(1:ntheta,1:nr+1)* ...
                               (VEnvAvg_10_10_t1(1)*tfac1+VEnvAvg_10_10_t2(1)*tfac2);
        VEnvrad_10_10(i,1:ntheta,1:nr+1,2)=SEnvScaleFactor(1:ntheta,1:nr+1)* ...
                               (VEnvAvg_10_10_t1(2)*tfac1+VEnvAvg_10_10_t2(2)*tfac2);            
        PEnvrad(i,1:ntheta,1:nr+1)=Pback_t2;
    elseif env_type == 2
        VEnvrad_10_10(i,1:ntheta,1:nr+1,1)=VEnvAvg_10_10_t1(1)*tfac1+VEnvAvg_10_10_t2(1)*tfac2;
        VEnvrad_10_10(i,1:ntheta,1:nr+1,2)=VEnvAvg_10_10_t1(2)*tfac1+VEnvAvg_10_10_t2(2)*tfac2;               
        PEnvrad(i,1:ntheta,1:nr+1)=Pback_t2;
    elseif env_type == 3    
        gtime=find(datetimeint(i,:)==[VEnv_10_10.datetime]);
        if isempty(gtime)
            fprintf ('%s %s %s\n','Failed to find ',datetime,[' in the' ...
                     ' Environmental file. RUN TERMINATED'])        
            fprintf (fid,'%s %s %s\n','Failed to find ',datetime,[' in' ...
                     'the Environmental file. RUN TERMINATED']);
            return            
        end
        [VEnvrad_10_10(i,1:ntheta,1:nr+1,1:2), PEnvrad(i,1:ntheta,1:nr+1)]= ...
                       VEnvreg2radial2(gtime,VEnv_10_10,LonEW_i,LatNS_i, ...
                       r,theta);            
        [VHurrad_10_10(i,1:ntheta,1:nr+1,1:2), PHurrad(i,1:ntheta,1:nr+1)]= ...
                       VEnvreg2radial2(gtime,VHur_10_10,LonEW_i,LatNS_i,r,theta); 
        [BlendingMasksrad(i,1:ntheta,1:nr+1,1:2), Dummy(i,1:ntheta,1:nr+1)]= ...
                       VEnvreg2radial2(-gtime,BlendingMasks,LonEW_i,LatNS_i,r,theta);
    end
end


function [VVel_VPrad_10_10, VPress_VPrad, VHurrad_10_10, PHurrad] = ...
    applyTaperOnRadialGrid(i, ntheta, nr, r, theta, ...
        env_type, taper_constants, ...
        BlendingMasksrad, datetimeint, fid, ...
        VVel_VPrad_10_10, VPress_VPrad, VHurrad_10_10, PHurrad)

    it = ntheta;
    taper_vals(1:ntheta,1:nr+1)=radial_taper2(r,theta(1:it),datetimeint(i,:), ...
                    BlendingMasksrad(i,1:it,1:nr+1,1:2),taper_constants,fid);           

    for it=1:ntheta
        VVel_VPrad_10_10(i,it,1:nr+1,1)=permute(VVel_VPrad_10_10(i,it,1:nr+1,1), ...
                                     [2 3 4 1]).*taper_vals(it,1:nr+1);
        VVel_VPrad_10_10(i,it,1:nr+1,2)=permute(VVel_VPrad_10_10(i,it,1:nr+1,2), ...
                                     [2 3 4 1]).*taper_vals(it,1:nr+1);            
        VPress_VPrad(i,it,1:nr+1)=permute(VPress_VPrad(i,it,1:nr+1), ...
                                     [2 3 1]).*taper_vals(it,1:nr+1);
        if env_type==3
            VHurrad_10_10(i,it,1:nr+1,1)=permute(VHurrad_10_10(i,it,1:nr+1,1), ...
                                     [2 3 4 1]).*taper_vals(it,1:nr+1);
            VHurrad_10_10(i,it,1:nr+1,2)=permute(VHurrad_10_10(i,it,1:nr+1,2), ...
                                     [2 3 4 1]).*taper_vals(it,1:nr+1);            
            PHurrad(i,it,1:nr+1)=permute(PHurrad(i,it,1:nr+1), ...
                                     [2 3 1]).*taper_vals(it,1:nr+1);
        end
    end
end


function [Reggrid_out, Reggrid_TC_out, Reggrid_Env_out, Reggrid_VVor_invtapHur_out] = ...
    buildRegularGridOutputs(itot, env_type, ntheta, nr, r, theta, ...
        output, WAF_flag, ...
        VVel_VPrad_10_10, VPress_VPrad, VEnvrad_10_10, PEnvrad, ...
        VHurrad_10_10, PHurrad, ...
        VEnv_10_10, VHur_10_10, BlendingMasks, ...
        LonEW, LatNS, datetimeint, ...
        WAF_data, WAF_metadata)

for i=1:itot
    if output.type == "grid"
        fprintf(' %s %s \n','Interpolating to regular grid',datetimeint(i))
        if env_type == 3
            env_nlon=length(VEnv_10_10(i).lon(1,:));
            env_nlat=length(VEnv_10_10(i).lat(:,1));
            longrid1=VEnv_10_10(i).lon(1,1);
            longridn=VEnv_10_10(i).lon(1,env_nlon);
            latgrid1=VEnv_10_10(i).lat(1,1);
            latgridn=VEnv_10_10(i).lat(env_nlat,1);
        else
            longrid1=LonEW(i)-output.dellon*(output.nlon-1)/2;
            latgrid1=LatNS(i)-output.dellat*(output.nlat-1)/2;
            longridn=longrid1+(output.nlon-1)*output.dellon;
            latgridn=latgrid1+(output.nlat-1)*output.dellat;
        end
        [longrid,latgrid]=meshgrid(longrid1:output.dellon:longridn, latgrid1:output.dellat:latgridn);
    elseif output.type == "points"
        fprintf(' %s %s \n','Interpolating to output points',datetimeint(i))        
        longrid=output.lon;
        latgrid=output.lat;
    end

    Reggrid_out(i).datetime=datetimeint(i);
    Reggrid_out(i).Lon=longrid;
    Reggrid_out(i).Lat=latgrid;

% interpolate tapered GAHM2026 vortex to regular output grid

    Reggrid_VVor_out(i)=radial2regular(longrid,latgrid,LonEW(i),LatNS(i),...
                        r,theta,VVel_VPrad_10_10(i,1:ntheta,1:nr+1,1:2), ...                        
                        VPress_VPrad(i,1:ntheta,1:nr+1));

% apply Wind Adjustment Factor if enabled

    Reggrid_VVor_WAF_out(i)=Reggrid_VVor_out(i);

    if WAF_flag
        Reggrid_VVor_WAF=apply_WAF_from_raster(WAF_data,WAF_metadata, ...
                                      Reggrid_VVor_out(i),longrid,latgrid);
        Reggrid_VVor_WAF_out(i).VelU=Reggrid_VVor_WAF.VelU;
        Reggrid_VVor_WAF_out(i).VelV=Reggrid_VVor_WAF.VelV;
    end

% assemble final blended outputs by env_type

    if env_type==1 || env_type==2         
        Reggrid_Env_out(i)=radial2regular(longrid,latgrid,LonEW(i),LatNS(i),...
                        r,theta,VEnvrad_10_10(i,1:ntheta,1:nr+1,1:2), ...
                        PEnvrad(i,1:ntheta,1:nr+1));
        Reggrid_TC_out(i).VelU=Reggrid_VVor_WAF_out(i).VelU+Reggrid_Env_out(i).VelU;
        Reggrid_TC_out(i).VelV=Reggrid_VVor_WAF_out(i).VelV+Reggrid_Env_out(i).VelV;
        Reggrid_TC_out(i).Press=Reggrid_VVor_out(i).Press+Reggrid_Env_out(i).Press;

        Reggrid_VVor_invtapHur_out(i)=0;
        Reggrid_Hur_Env_out=0;

    elseif env_type==3       
% Input Environmental field        
        FU=griddedInterpolant(VEnv_10_10(i).lon',VEnv_10_10(i).lat', ...
                                                 VEnv_10_10(i).VelU');  
        Reggrid_Env_out(i).VelU=FU(longrid,latgrid);
        FV=griddedInterpolant(VEnv_10_10(i).lon',VEnv_10_10(i).lat', ...
                                                 VEnv_10_10(i).VelV'); 
        Reggrid_Env_out(i).VelV=FV(longrid,latgrid);
        FP=griddedInterpolant(VEnv_10_10(i).lon',VEnv_10_10(i).lat', ...
                                                 VEnv_10_10(i).Press');
        Reggrid_Env_out(i).Press=FP(longrid,latgrid);

% Input hurricane field        
        FU=griddedInterpolant(VHur_10_10(i).lon',VHur_10_10(i).lat', ...  
                                                 VHur_10_10(i).VelU');
        Reggrid_Hur0_out.VelU=FU(longrid,latgrid);
        FV=griddedInterpolant(VHur_10_10(i).lon',VHur_10_10(i).lat', ...
                                                 VHur_10_10(i).VelV');
        Reggrid_Hur0_out.VelV=FV(longrid,latgrid);
        FP=griddedInterpolant(VHur_10_10(i).lon',VHur_10_10(i).lat', ...
                                                 VHur_10_10(i).Press');
        Reggrid_Hur0_out.Press=FP(longrid,latgrid);
     
% Input hurricane field with taper applied to radial version
        Reggrid_Hur_out(i)=radial2regular(longrid,latgrid,LonEW(i),LatNS(i),...
                           r,theta,VHurrad_10_10(i,1:ntheta,1:nr+1,1:2), ...                         
                           PHurrad(i,1:ntheta,1:nr+1));

% Inverse taper hurricane field
        Reggrid_invtapHur_out.VelU=Reggrid_Hur0_out.VelU-Reggrid_Hur_out(i).VelU;
        Reggrid_invtapHur_out.VelV=Reggrid_Hur0_out.VelV-Reggrid_Hur_out(i).VelV;        
        Reggrid_invtapHur_out.Press=Reggrid_Hur0_out.Press-Reggrid_Hur_out(i).Press;        

% GAHM + inverse tapered hurricane field
        Reggrid_VVor_invtapHur_out(i).VelU=Reggrid_VVor_WAF_out(i).VelU+Reggrid_invtapHur_out.VelU;    
        Reggrid_VVor_invtapHur_out(i).VelV=Reggrid_VVor_WAF_out(i).VelV+Reggrid_invtapHur_out.VelV;    
        Reggrid_VVor_invtapHur_out(i).Press=Reggrid_VVor_WAF_out(i).Press+Reggrid_invtapHur_out.Press;            
      
% Environmental + hurricane (should match original)
        Reggrid_Hur0_Env_out(i).VelU=Reggrid_Hur0_out.VelU+Reggrid_Env_out(i).VelU;
        Reggrid_Hur0_Env_out(i).VelV=Reggrid_Hur0_out.VelV+Reggrid_Env_out(i).VelV;
        Reggrid_Hur0_Env_out(i).Press=Reggrid_Hur0_out.Press+Reggrid_Env_out(i).Press;

% Final blended output
        Reggrid_TC_out(i).VelU=Reggrid_VVor_invtapHur_out(i).VelU+Reggrid_Env_out(i).VelU;
        Reggrid_TC_out(i).VelV=Reggrid_VVor_invtapHur_out(i).VelV+Reggrid_Env_out(i).VelV;        
        Reggrid_TC_out(i).Press=Reggrid_VVor_invtapHur_out(i).Press+Reggrid_Env_out(i).Press;

% Inner and outer masks
        FM1=griddedInterpolant(BlendingMasks(i).lon',BlendingMasks(i).lat', ...
                                                 BlendingMasks(i).mask1');
        Reggrid_out(i).Mask1=FM1(longrid,latgrid);
        FM2=griddedInterpolant(BlendingMasks(i).lon',BlendingMasks(i).lat', ...
                                                 BlendingMasks(i).mask2'); 
        Reggrid_out(i).Mask2=FM2(longrid,latgrid);

    end
end
end
