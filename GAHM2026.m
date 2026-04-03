function [Reggrid_out, Reggrid_TC_out, Reggrid_Env_out, ...
          Reggrid_VVor_invtapHur_out, Trackdata, GAHM_out, VPrad] = ...
          GAHM2026(storm, ATCF_data_in, GAHM_param_info, GAHM_compute_info, WAF_info, ...
          env_info, output, debug)
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
%  Uses gahm2026Solve to compute GAHM parameters (dispatches to v3e or v4a)
%
% Required Matlab scripts:
%     readEnvAndHurrFields2.m - read gridded environmental and
%                          hurricane fields
%     gahm2026Prep.m - initialize the GAHM datastructure each timestep
%         VEnvAvg() - embedded function 7/6/2024 - if env_type=3,
%                      compute average environmental velocity within Rmax
%                      of the eye
%         VEnvQuad() - embedded function 7/6/2025 - if env_type=3,
%                      compute environmental velocity at isotach locations
%                      in 4 quadrants
%     gahm2026Consistency.m - screen input values for consistency with
%                          the GAHM2026 equations each timestep
%     gahm2026Solve.m - compute GAHM2026 parameters (unified v3e/v4a)
%     gahmVPradial.m - compute GAHM velocity and pressure along a
%                        specified theta radial line
%           gahmVP.m - compute GAHM velocity and pressure at a specified
%                        point along a quadrant radial line
%     VEnvreg2radial2.m - interplate regular grid environmental field onto
%                         radial grid
%     radialTaper2.m  - computes the taper function on the radial grid
%     radial2regular.m - interpolates wind velocity (u,v) and pressure from
%                        a radial grid to a regular grid
%
% See documentation/README.md for full configuration reference.
%
%                 7/12/2025   - Rick Luettich
%                 11/4/2025   - Rick Luettich enables env_type=1 to work?
%                  2/2/2026  -  Rick Luettich eliminated nonHurr variables
%                               added inner and outer mask, WAF,
%                               reorganized, checked env_type=1,2,3
%                  2/6/2026  -  Decomposed into local functions
%--------------------------------------------------------------------------

    arguments
        storm (1,1) struct
        ATCF_data_in (1,:) struct
        GAHM_param_info (1,1) struct
        GAHM_compute_info (1,1) struct
        WAF_info (1,1) struct
        env_info (1,1) struct
        output (1,1) struct
        debug (1,1) logical = false
    end

%% transfer / compute needed information

GAHM_version = GAHM_param_info.version;
VMax_mult = GAHM_param_info.Vmax_multiplier;

ntheta = GAHM_compute_info.ntheta;
nr = GAHM_compute_info.nr;
delr = GAHM_compute_info.delr;
r = (0:nr)*delr;
theta(1:ntheta) = (0:ntheta-1)*360/ntheta;

taper_flag = env_info.taper_flag;
env_type = env_info.type;
WAF_flag = WAF_info.flag;

if taper_flag
    taper_constants.ntheta = ntheta;
    taper_constants.nr = nr;
    taper_constants.delr = delr;
    taper_constants.taper_flag = taper_flag;
    taper_constants.taper_mindelr2r1 = env_info.taper_mindelr2r1;
    taper_constants.taper_a = env_info.taper_a;
end

fid = fopen(output.diagnostics, 'at');
cleanupFid = onCleanup(@() fclose(fid));

if debug, logMsg(fid, "DEBUG", "GAHM version=%d, env_type=%d, taper=%d, WAF=%d", GAHM_version, env_type, taper_flag, WAF_flag); end
if debug, logMsg(fid, "DEBUG", "Radial grid: ntheta=%d, nr=%d, delr=%d m (max radius=%.0f km)", ntheta, nr, delr, nr*delr/1000); end

%% Slice storm track to requested time window

[ATCF_startline, ATCF_endline, starttime_dt, endtime_dt] = ...
    sliceTrack(storm, ATCF_data_in);

if debug, logMsg(fid, "DEBUG", "Track sliced: %s, lines %d-%d (%s to %s)", ...
    storm.name, ATCF_startline, ATCF_endline, string(starttime_dt), string(endtime_dt)); end

%% Read gridded environmental/hurricane fields and WAF raster

if debug, logMsg(fid, "DEBUG", "Loading environmental fields ..."); end
[VEnv_10_10, VHur_10_10, BlendingMasks, PscaleEnv] = ...
    loadEnvFields(env_type, env_info, starttime_dt, endtime_dt);
if debug, logMsg(fid, "DEBUG", "Environmental fields loaded."); end

WAF_data = [];
WAF_metadata = [];
if WAF_flag
    if debug, logMsg(fid, "DEBUG", "Loading WAF raster from %s", WAF_info.file_name); end
    [WAF_data, WAF_metadata] = readgeoraster(WAF_info.file_name);
end

%% Main time loop

nBTtime = ATCF_endline - ATCF_startline + 1;
logMsg(fid, "INFO", "Beginning main time loop: %d track time steps", nBTtime);
i = 0;
otime = 0;
VEnvrad_10_10 = [];
PEnvrad = [];
VHurrad_10_10 = [];
PHurrad = [];
BlendingMasksrad = [];

% Pre-allocate arrays that grow inside the main time loop
maxBTinterval = max(hours(diff([ATCF_data_in(ATCF_startline:ATCF_endline).datetime])));
if isempty(maxBTinterval) || isnan(maxBTinterval)
    maxBTinterval = 6;
end
nOutMax = nBTtime * ceil(maxBTinterval / output.timeinc);
VVel_VPrad_10_10 = zeros(nOutMax, ntheta, nr+1, 2);
VSpeed_VPrad_10_10 = zeros(nOutMax, ntheta, nr+1);
VPress_VPrad = zeros(nOutMax, ntheta, nr+1);
LatNS = zeros(1, nOutMax);
LonEW = zeros(1, nOutMax);
datetimeint = NaT(nOutMax, 1);

for itime = 1:nBTtime
    ATCF_line_t2 = ATCF_startline + itime - 1;
    datetime_t2 = ATCF_data_in(ATCF_line_t2).datetime;
    if itime == 1
        ATCF_line_t1 = ATCF_line_t2 - 1;
    end
    if ATCF_line_t2 == 1
        ATCF_line_t1 = ATCF_line_t2;
        datetime_t1 = datetime_t2;
        BTinterval = 1;
    else
        datetime_t1 = ATCF_data_in(ATCF_line_t1).datetime;
        BTinterval = hours(datetime_t2 - datetime_t1);
    end
    if itime ~= 1
        VEnvAvg_10_10_t1 = VEnvAvg_10_10_t2;
        VVel_VPrad_t1 = VVel_VPrad_t2;
        VPress_VPrad_t1 = VPress_VPrad_t2;
        GAHM_t1 = GAHM_t2;
    end

    %% Compute GAHM parameters at current track time

    if debug, logMsg(fid, "DEBUG", "Step %d/%d: %s (BTinterval=%d hrs)", itime, nBTtime, string(datetime_t2), BTinterval); end

    [GAHM_t_new, skipline] = computeGAHMAtTrackTime(GAHM_param_info, ...
        env_info, ATCF_data_in, VEnv_10_10, PscaleEnv, ATCF_line_t2, ...
        BTinterval, fid);
    if skipline
        if debug, logMsg(fid, "DEBUG", "Step %d/%d: skipped", itime, nBTtime); end
        continue
    end
    GAHM_t2 = GAHM_t_new;

    %% Compute radial profiles of vortex velocity and pressure

    if debug, logMsg(fid, "DEBUG", "Computing radial profiles ..."); end
    [VVel_VPrad_t2, VPress_VPrad_t2, RP1, RP2] = computeRadialProfiles( ...
        r, theta, ntheta, nr, GAHM_param_info, GAHM_t2);

    if itime == 1
        datetime_t1 = datetime_t2;
        GAHM_t1 = GAHM_t2;
        VEnvAvg_10_10_t1 = GAHM_t1.VEnvStar_10_10;
        VVel_VPrad_t1 = VVel_VPrad_t2;
        VPress_VPrad_t1 = VPress_VPrad_t2;
    end

    %% Interpolate to desired output times

    int = 1;
    LonEW_t1 = GAHM_t1.Eye(1);
    LatNS_t1 = GAHM_t1.Eye(2);
    LonEW_t2 = GAHM_t2.Eye(1);
    LatNS_t2 = GAHM_t2.Eye(2);
    VEnvAvg_10_10_t2 = GAHM_t2.VEnvStar_10_10;
    Pback_t2 = GAHM_t2.Pback;
    while (int-1)*output.timeinc < BTinterval
        i = i + 1;
        if itime == 1
            int = 1000;
            tfac2 = 1;
            tfac1 = 0;
            datetimeint(1,:) = datetime_t2;
        else
            int = int + 1;
            tfac2 = (int-1)*output.timeinc/BTinterval;
            tfac1 = 1 - tfac2;
            datetimeint(i,:) = datetime_t1 + tfac2*duration(datetime_t2 - datetime_t1);
        end

        % interpolate vortex fields on the radial grid at output times

        LatNS(i) = tfac1*LatNS_t1 + tfac2*LatNS_t2;
        LonEW(i) = tfac1*LonEW_t1 + tfac2*LonEW_t2;
        for it = 1:ntheta
            VVel_VPrad_10_10(i,it,1:nr+1,1) = (VVel_VPrad_t1(it,1:nr+1,1)*tfac1 + ....
                                            VVel_VPrad_t2(it,1:nr+1,1)*tfac2);
            VVel_VPrad_10_10(i,it,1:nr+1,2) = (VVel_VPrad_t1(it,1:nr+1,2)*tfac1 + ....
                                            VVel_VPrad_t2(it,1:nr+1,2)*tfac2);
            VSpeed_VPrad_10_10(i,it,1:nr+1) = squeeze(vecnorm(permute(VVel_VPrad_10_10(i,it,1:nr+1,1:2),[4 1 2 3])));
            VPress_VPrad(i,it,1:nr+1) = VPress_VPrad_t1(it,1:nr+1)*tfac1 + VPress_VPrad_t2(it,1:nr+1)*tfac2;
        end

        % save radial results before applying taper for diagnostic output

        VPrad.VVor_bt(i).VelU  = squeeze(VVel_VPrad_10_10(i,:,:,1));
        VPrad.VVor_bt(i).VelV  = squeeze(VVel_VPrad_10_10(i,:,:,2));
        VPrad.VVor_bt(i).Speed = squeeze(VSpeed_VPrad_10_10(i,:,:));
        VPrad.VVor_bt(i).Press = squeeze(VPress_VPrad(i,:,:));

        % interpolate environmental field on radial grid at output times

        [VEnvrad_10_10, PEnvrad, VHurrad_10_10, PHurrad, BlendingMasksrad] = ...
            interpolateEnvOnRadialGrid(env_type, i, ntheta, nr, r, theta, ...
                VEnv_10_10, VHur_10_10, BlendingMasks, ...
                VSpeed_VPrad_10_10, GAHM_t1, GAHM_t2, ...
                VEnvAvg_10_10_t1, VEnvAvg_10_10_t2, Pback_t2, ...
                tfac1, tfac2, datetimeint, LonEW(i), LatNS(i), fid, ...
                VEnvrad_10_10, PEnvrad, VHurrad_10_10, PHurrad, BlendingMasksrad);

        % apply taper function if enabled

        if env_type == 1 || env_type == 2
            taper_flag_eff = false;
        else
            taper_flag_eff = taper_flag;
        end
        if taper_flag_eff
            [VVel_VPrad_10_10, VPress_VPrad, VHurrad_10_10, PHurrad] = ...
                applyTaperOnRadialGrid(i, ntheta, nr, r, theta, ...
                    env_type, taper_constants, ...
                    BlendingMasksrad, datetimeint, fid, ...
                    VVel_VPrad_10_10, VPress_VPrad, VHurrad_10_10, PHurrad);
            for it = 1:ntheta
               VSpeed_VPrad_10_10(i,it,1:nr+1) = squeeze(vecnorm(permute ...
                            (VVel_VPrad_10_10(i,it,1:nr+1,1:2),[4 1 2 3])));
            end
        end

        % save track information

        Trackdata(i).datetime = datetimeint(i,:);
        Trackdata(i).Lat = LatNS(i);
        Trackdata(i).Lon = LonEW(i);
        Trackdata(i).RQuad_t1(1:4,1:3) = GAHM_t1.RQuad(1:4,1:3);
        Trackdata(i).Vmax_t1 = ATCF_data_in(ATCF_line_t1).Vmax*VMax_mult;
        Trackdata(i).Rmax_t1 = ATCF_data_in(ATCF_line_t1).RMW;
        Trackdata(i).RQuad_t2(1:4,1:3) = GAHM_t2.RQuad(1:4,1:3);
        Trackdata(i).Vmax_t2 = ATCF_data_in(ATCF_line_t2).Vmax*VMax_mult;
        Trackdata(i).Rmax_t2 = ATCF_data_in(ATCF_line_t2).RMW;
        Trackdata(i).RP1(1:ntheta) = RP1(1:ntheta);
        Trackdata(i).RP2(1:ntheta) = RP2(1:ntheta);
    end

    ATCF_line_t1 = ATCF_line_t2;
    otime = otime + 1;
    GAHM_out(otime) = GAHM_t2;

end  % end main time loop

% Trim pre-allocated arrays to actual size
VVel_VPrad_10_10 = VVel_VPrad_10_10(1:i, :, :, :);
VSpeed_VPrad_10_10 = VSpeed_VPrad_10_10(1:i, :, :);
VPress_VPrad = VPress_VPrad(1:i, :, :);
LatNS = LatNS(1:i);
LonEW = LonEW(1:i);
datetimeint = datetimeint(1:i, :);

logMsg(fid, "INFO", "Completed calculations on radial grid. Preparing output");
if debug, logMsg(fid, "DEBUG", "Master time loop complete: %d output time steps produced", i); end

itot = i;

%% Interpolate from radial grid to regular output grid

logMsg(-1, "INFO", "Interpolating from radial grid to regular output grid (%s) ...", output.type);
[Reggrid_out, Reggrid_TC_out, Reggrid_Env_out, Reggrid_VVor_invtapHur_out] = ...
    buildRegularGridOutputs(itot, env_type, ntheta, nr, r, theta, ...
        output, WAF_flag, ...
        VVel_VPrad_10_10, VPress_VPrad, VEnvrad_10_10, PEnvrad, ...
        VHurrad_10_10, PHurrad, ...
        VEnv_10_10, VHur_10_10, BlendingMasks, ...
        LonEW, LatNS, datetimeint, ...
        WAF_data, WAF_metadata);
logMsg(-1, "INFO", "Regular grid interpolation complete.");

%% Package radial grid data for plotting

VPrad.r = r;
VPrad.theta = theta;
NM2M = gahmPhysicalConstants().nm2m;
r_arc = nm2deg(r/NM2M);  %convert r to nautical miles and then arclength (deg)
for ii = 1:itot

    % this is the previous VVor variable.  We need it for the moment so that the radialProfile code still works.
    VPrad.VVor(ii).VelU  = squeeze(VVel_VPrad_10_10(ii,:,:,1));
    VPrad.VVor(ii).VelV  = squeeze(VVel_VPrad_10_10(ii,:,:,2));
    VPrad.VVor(ii).Speed = squeeze(VSpeed_VPrad_10_10(ii,:,:));
    VPrad.VVor(ii).Press = squeeze(VPress_VPrad(ii,:,:));

    VPrad.VVor_at(ii).VelU  = squeeze(VVel_VPrad_10_10(ii,:,:,1));
    VPrad.VVor_at(ii).VelV  = squeeze(VVel_VPrad_10_10(ii,:,:,2));
    VPrad.VVor_at(ii).Speed = squeeze(VSpeed_VPrad_10_10(ii,:,:));
    VPrad.VVor_at(ii).Press = squeeze(VPress_VPrad(ii,:,:));

    % Interpolate final (blended) output back onto radial grid for diagnostic output
    FU = griddedInterpolant(Reggrid_out(ii).Lon',Reggrid_out(ii).Lat',Reggrid_TC_out(ii).VelU');
    FV = griddedInterpolant(Reggrid_out(ii).Lon',Reggrid_out(ii).Lat',Reggrid_TC_out(ii).VelV');
    FP = griddedInterpolant(Reggrid_out(ii).Lon',Reggrid_out(ii).Lat',Reggrid_TC_out(ii).Press');
    for it = 1:length(theta)
        az = thetaToAzimuth(theta(it));
        [rad_lat, rad_lon] = reckon("rh", LatNS(ii), LonEW(ii), r_arc, az);
        VPrad.EnvHur_final(ii).VelU(it,:) = FU(rad_lon', rad_lat');
        VPrad.EnvHur_final(ii).VelV(it,:) = FV(rad_lon', rad_lat');
        VPrad.EnvHur_final(ii).Speed(it,:) = hypot(VPrad.EnvHur_final(ii).VelU(it,:), VPrad.EnvHur_final(ii).VelV(it,:));
        VPrad.EnvHur_final(ii).Press(it,:) = FP(rad_lon', rad_lat');
    end
    if ~isempty(VEnvrad_10_10)
        VPrad.Env(ii).VelU  = squeeze(VEnvrad_10_10(ii,:,:,1));
        VPrad.Env(ii).VelV  = squeeze(VEnvrad_10_10(ii,:,:,2));
        VPrad.Env(ii).Speed = hypot(VPrad.Env(ii).VelU, VPrad.Env(ii).VelV);
        VPrad.Env(ii).Press = squeeze(PEnvrad(ii,:,:));
        % this is the previous EnvVor variable.  We need it for the moment so that the radialProfile code still works.
        VPrad.EnvVor(ii).VelU  = VPrad.VVor(ii).VelU + VPrad.Env(ii).VelU;
        VPrad.EnvVor(ii).VelV  = VPrad.VVor(ii).VelV + VPrad.Env(ii).VelV;
        VPrad.EnvVor(ii).Speed = hypot(VPrad.EnvVor(ii).VelU, VPrad.EnvVor(ii).VelV);
        VPrad.EnvVor(ii).Press = VPrad.VVor(ii).Press + VPrad.Env(ii).Press;

        VPrad.EnvVor_bt(ii).VelU  = VPrad.VVor_bt(ii).VelU + VPrad.Env(ii).VelU;
        VPrad.EnvVor_bt(ii).VelV  = VPrad.VVor_bt(ii).VelV + VPrad.Env(ii).VelV;
        VPrad.EnvVor_bt(ii).Speed = hypot(VPrad.EnvVor_bt(ii).VelU, VPrad.EnvVor_bt(ii).VelV);
        VPrad.EnvVor_bt(ii).Press = VPrad.VVor_bt(ii).Press + VPrad.Env(ii).Press;
    end
end

if debug, logMsg(-1, "DEBUG", "Done."); end

end  % end main function


%% ========================================================================
%  Local helper functions
%  ========================================================================

function [ATCF_startline, ATCF_endline, starttime_dt, endtime_dt] = ...
    sliceTrack(storm, ATCF_data_in)

    if isdatetime(storm.starttime)
        starttime_dt = storm.starttime;
        ATCF_startline = find([ATCF_data_in.datetime] < starttime_dt, 1, 'last') + 1;
        if isempty(ATCF_startline)
            ATCF_startline = 1;
        end
    else
        starttime_dt = datetime(0,0,0);
        ATCF_startline = 1;
    end

    if isdatetime(storm.endtime)
        endtime_dt = storm.endtime;
        ATCF_endline = find([ATCF_data_in.datetime] <= endtime_dt, 1, 'last');
        if isempty(ATCF_endline)
            ATCF_endline = length([ATCF_data_in.datetime]);
        end
    else
        endtime_dt = datetime(0,0,0);
        ATCF_endline = length([ATCF_data_in.datetime]);
    end
end


function [VEnv_10_10, VHur_10_10, BlendingMasks, PscaleEnv] = ...
    loadEnvFields(env_type, env_info, starttime_dt, endtime_dt)

    BlendingMasks = 0;
    if env_type == 1 || env_type == 2
        VEnv_10_10 = 0;
        VHur_10_10 = 0;
        PscaleEnv = 1;
    elseif env_type == 3
        [VEnv_10_10, VHur_10_10, BlendingMasks, PscaleEnv] = ...
                    readEnvAndHurrFields2(env_info, starttime_dt, endtime_dt);
    end
end


function [GAHM_t, skipline] = computeGAHMAtTrackTime(GAHM_param_info, ...
    env_info, ATCF_data_in, VEnv_10_10, PscaleEnv, ATCF_line, ...
    BTinterval, fid)

    GAHMp1 = gahm2026Prep(GAHM_param_info, env_info, ATCF_data_in, VEnv_10_10, ...
                              PscaleEnv, ATCF_line, BTinterval, fid);
    if GAHMp1.skipline
        GAHM_t = GAHMp1;
        skipline = true;
        return
    end

    GAHMp2 = gahm2026Consistency(GAHM_param_info, GAHMp1, fid);

    GAHM_t = gahm2026Solve(GAHMp2, GAHM_param_info, fid);
    skipline = false;
end


function [VVel_VPrad, VPress_VPrad, RP1, RP2] = computeRadialProfiles( ...
    r, theta, ntheta, nr, GAHM_param_info, GAHM_t)

    VVel_VPrad = zeros(ntheta, nr+1, 2);
    VPress_VPrad = zeros(ntheta, nr+1);
    RP1 = zeros(1, ntheta);
    RP2 = zeros(1, ntheta);

    for it = 1:ntheta
        GAHM_VPrad_t = gahmVPradial(r, theta(it), GAHM_param_info, GAHM_t);
        VVel_VPrad(it,1:nr+1,1:2) = GAHM_VPrad_t.VVor_10_10(1:nr+1,1:2);
        VPress_VPrad(it,1:nr+1) = GAHM_VPrad_t.Press(1:nr+1);
        RP1(it) = GAHM_VPrad_t.RP(1);
        RP2(it) = GAHM_VPrad_t.RP(2);
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
        SVorMax_10_10 = GAHM_t1.SVorMax_10_10*tfac1 + GAHM_t2.SVorMax_10_10*tfac2;
        SEnvScaleFactor(1:ntheta,1:nr+1) = VSpeed_VPrad_10_10(i,1:ntheta,1:nr+1)/SVorMax_10_10;
        VEnvrad_10_10(i,1:ntheta,1:nr+1,1) = SEnvScaleFactor(1:ntheta,1:nr+1)* ...
                               (VEnvAvg_10_10_t1(1)*tfac1 + VEnvAvg_10_10_t2(1)*tfac2);
        VEnvrad_10_10(i,1:ntheta,1:nr+1,2) = SEnvScaleFactor(1:ntheta,1:nr+1)* ...
                               (VEnvAvg_10_10_t1(2)*tfac1 + VEnvAvg_10_10_t2(2)*tfac2);
        PEnvrad(i,1:ntheta,1:nr+1) = Pback_t2;
    elseif env_type == 2
        VEnvrad_10_10(i,1:ntheta,1:nr+1,1) = VEnvAvg_10_10_t1(1)*tfac1 + VEnvAvg_10_10_t2(1)*tfac2;
        VEnvrad_10_10(i,1:ntheta,1:nr+1,2) = VEnvAvg_10_10_t1(2)*tfac1 + VEnvAvg_10_10_t2(2)*tfac2;
        PEnvrad(i,1:ntheta,1:nr+1) = Pback_t2;
    elseif env_type == 3
        gtime = find(datetimeint(i,:) == [VEnv_10_10.datetime]);
        if isempty(gtime)
            logMsg(fid, "ERROR", "Failed to find %s in the Environmental file.", string(datetimeint(i,:)));
        end
        [VEnvrad_10_10(i,1:ntheta,1:nr+1,1:2), PEnvrad(i,1:ntheta,1:nr+1)] = ...
                       VEnvreg2radial2(gtime, VEnv_10_10, LonEW_i, LatNS_i, ...
                       r, theta);
        [VHurrad_10_10(i,1:ntheta,1:nr+1,1:2), PHurrad(i,1:ntheta,1:nr+1)] = ...
                       VEnvreg2radial2(gtime, VHur_10_10, LonEW_i, LatNS_i, r, theta);
        [BlendingMasksrad(i,1:ntheta,1:nr+1,1:2), ~] = ...
                       VEnvreg2radial2(-gtime, BlendingMasks, LonEW_i, LatNS_i, r, theta);
    end
end


function [VVel_VPrad_10_10, VPress_VPrad, VHurrad_10_10, PHurrad] = ...
    applyTaperOnRadialGrid(i, ntheta, nr, r, theta, ...
        env_type, taper_constants, ...
        BlendingMasksrad, datetimeint, fid, ...
        VVel_VPrad_10_10, VPress_VPrad, VHurrad_10_10, PHurrad)

    it = ntheta;
    taper_vals(1:ntheta,1:nr+1) = radialTaper2(r, theta(1:it), datetimeint(i,:), ...
                    BlendingMasksrad(i,1:it,1:nr+1,1:2), taper_constants, fid);

    for it = 1:ntheta
        VVel_VPrad_10_10(i,it,1:nr+1,1) = permute(VVel_VPrad_10_10(i,it,1:nr+1,1), ...
                                     [2 3 4 1]).*taper_vals(it,1:nr+1);
        VVel_VPrad_10_10(i,it,1:nr+1,2) = permute(VVel_VPrad_10_10(i,it,1:nr+1,2), ...
                                     [2 3 4 1]).*taper_vals(it,1:nr+1);
        VPress_VPrad(i,it,1:nr+1) = permute(VPress_VPrad(i,it,1:nr+1), ...
                                     [2 3 1]).*taper_vals(it,1:nr+1);
        if env_type == 3
            VHurrad_10_10(i,it,1:nr+1,1) = permute(VHurrad_10_10(i,it,1:nr+1,1), ...
                                     [2 3 4 1]).*taper_vals(it,1:nr+1);
            VHurrad_10_10(i,it,1:nr+1,2) = permute(VHurrad_10_10(i,it,1:nr+1,2), ...
                                     [2 3 4 1]).*taper_vals(it,1:nr+1);
            PHurrad(i,it,1:nr+1) = permute(PHurrad(i,it,1:nr+1), ...
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

for i = 1:itot
    if output.type == "grid"
        logMsg(-1, "INFO", "Interpolating to regular grid %s", datetimeint(i))
        if env_type == 3
            env_nlon = length(VEnv_10_10(i).lon(1,:));
            env_nlat = length(VEnv_10_10(i).lat(:,1));
            longrid1 = VEnv_10_10(i).lon(1,1);
            longridn = VEnv_10_10(i).lon(1,env_nlon);
            latgrid1 = VEnv_10_10(i).lat(1,1);
            latgridn = VEnv_10_10(i).lat(env_nlat,1);
        else
            longrid1 = LonEW(i) - output.dellon*(output.nlon-1)/2;
            latgrid1 = LatNS(i) - output.dellat*(output.nlat-1)/2;
            longridn = longrid1 + (output.nlon-1)*output.dellon;
            latgridn = latgrid1 + (output.nlat-1)*output.dellat;
        end
        [longrid, latgrid] = meshgrid(longrid1:output.dellon:longridn, latgrid1:output.dellat:latgridn);
    elseif output.type == "points"
        logMsg(-1, "INFO", "Interpolating to output points %s", datetimeint(i))
        longrid = output.lon;
        latgrid = output.lat;
    end

    Reggrid_out(i).datetime = datetimeint(i);
    Reggrid_out(i).Lon = longrid;
    Reggrid_out(i).Lat = latgrid;

% interpolate tapered GAHM2026 vortex to regular output grid

    Reggrid_VVor_out(i) = radial2regular(longrid, latgrid, LonEW(i), LatNS(i), ...
                        r, theta, VVel_VPrad_10_10(i,1:ntheta,1:nr+1,1:2), ...
                        VPress_VPrad(i,1:ntheta,1:nr+1));

% apply Wind Adjustment Factor if enabled

    Reggrid_VVor_WAF_out(i) = Reggrid_VVor_out(i);

    if WAF_flag
        Reggrid_VVor_WAF = applyWAFfromRaster(WAF_data, WAF_metadata, ...
                                      Reggrid_VVor_out(i), longrid, latgrid);
        Reggrid_VVor_WAF_out(i).VelU = Reggrid_VVor_WAF.VelU;
        Reggrid_VVor_WAF_out(i).VelV = Reggrid_VVor_WAF.VelV;
    end

% assemble final blended outputs by env_type

    if env_type == 1 || env_type == 2
        Reggrid_Env_out(i) = radial2regular(longrid, latgrid, LonEW(i), LatNS(i), ...
                        r, theta, VEnvrad_10_10(i,1:ntheta,1:nr+1,1:2), ...
                        PEnvrad(i,1:ntheta,1:nr+1));
        Reggrid_TC_out(i).VelU = Reggrid_VVor_WAF_out(i).VelU + Reggrid_Env_out(i).VelU;
        Reggrid_TC_out(i).VelV = Reggrid_VVor_WAF_out(i).VelV + Reggrid_Env_out(i).VelV;
        Reggrid_TC_out(i).Press = Reggrid_VVor_out(i).Press + Reggrid_Env_out(i).Press;

        Reggrid_VVor_invtapHur_out(i) = 0;
        Reggrid_Hur_Env_out = 0;

    elseif env_type == 3
% Input Environmental field
        Reggrid_Env_out(i) = interpFieldToGrid(VEnv_10_10(i), longrid, latgrid);

% Input hurricane field
        Reggrid_Hur0_out = interpFieldToGrid(VHur_10_10(i), longrid, latgrid);

% Input hurricane field with taper applied to radial version
        Reggrid_Hur_out(i) = radial2regular(longrid, latgrid, LonEW(i), LatNS(i), ...
                           r, theta, VHurrad_10_10(i,1:ntheta,1:nr+1,1:2), ...
                           PHurrad(i,1:ntheta,1:nr+1));

% Inverse taper hurricane field
        Reggrid_invtapHur_out.VelU = Reggrid_Hur0_out.VelU - Reggrid_Hur_out(i).VelU;
        Reggrid_invtapHur_out.VelV = Reggrid_Hur0_out.VelV - Reggrid_Hur_out(i).VelV;
        Reggrid_invtapHur_out.Press = Reggrid_Hur0_out.Press - Reggrid_Hur_out(i).Press;

% GAHM + inverse tapered hurricane field
        Reggrid_VVor_invtapHur_out(i).VelU = Reggrid_VVor_WAF_out(i).VelU + Reggrid_invtapHur_out.VelU;
        Reggrid_VVor_invtapHur_out(i).VelV = Reggrid_VVor_WAF_out(i).VelV + Reggrid_invtapHur_out.VelV;
        Reggrid_VVor_invtapHur_out(i).Press = Reggrid_VVor_WAF_out(i).Press + Reggrid_invtapHur_out.Press;

% Environmental + hurricane (should match original)
        Reggrid_Hur0_Env_out(i).VelU = Reggrid_Hur0_out.VelU + Reggrid_Env_out(i).VelU;
        Reggrid_Hur0_Env_out(i).VelV = Reggrid_Hur0_out.VelV + Reggrid_Env_out(i).VelV;
        Reggrid_Hur0_Env_out(i).Press = Reggrid_Hur0_out.Press + Reggrid_Env_out(i).Press;

% Final blended output
        Reggrid_TC_out(i).VelU = Reggrid_VVor_invtapHur_out(i).VelU + Reggrid_Env_out(i).VelU;
        Reggrid_TC_out(i).VelV = Reggrid_VVor_invtapHur_out(i).VelV + Reggrid_Env_out(i).VelV;
        Reggrid_TC_out(i).Press = Reggrid_VVor_invtapHur_out(i).Press + Reggrid_Env_out(i).Press;

% Inner and outer masks
        FM1 = griddedInterpolant(BlendingMasks(i).lon', BlendingMasks(i).lat', ...
                                                 BlendingMasks(i).mask1');
        Reggrid_out(i).Mask1 = FM1(longrid, latgrid);
        FM2 = griddedInterpolant(BlendingMasks(i).lon', BlendingMasks(i).lat', ...
                                                 BlendingMasks(i).mask2');
        Reggrid_out(i).Mask2 = FM2(longrid, latgrid);

    end
end
end
