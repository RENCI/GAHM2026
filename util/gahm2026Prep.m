function GAHM = gahm2026Prep(GAHM_constants,env,ATCF_data_in,VEnv_10_10,...
    PscaleEnv,ATCF_line,BTinterval,fid)
%.........................................................................
%  Function to initialize the single time step GAHM datastructure which
%  is then used / modified in gahm2026Consistency.m and finalized in
%  gahm2026Solve.m.
%
%  Includes functions: VEnvAvg() and VEnvRQuad()
%
%  Uses GAHM_constants, TC track file data & gridded environmental data (if
%  specified).
%
%  The environmental velocity is either computed based on the storm
%  translation velocity or it is passed in as a gridded field with a time
%  interval that is an even increment of the TC track file time interval.
%
%  env.type - type of environmental velocity and pressure fields
%             = 1 ADCIRC scheme based on translation vel
%             = 2 0.6*tanslation vel & 20deg ccw rotation (Lin&Chavez 2012)
%             = 3 extract from gridded environmental file
%  env.file_name = file name containing gridded environmental velocity
%                   and pressure input, ignored if env.type =1 or 2
%             assumed to be a matlab .mat file in the data structure:
%             filename.Time(i); - datetime
%             filename.Lo(i,:,:);
%             filename.La(i,nEr:-1:1,:);
%             filename.Vortex_mask(i,nEr:-1:1,:); 0,1=inside,outside cut line
%             filename.env_u10(i,nEr:-1:1,:);   E-W velocity (m/s)
%             filename.env_v10(i,nEr:-1:1,:);   N-S velocity (m/s)
%             filename.env_msl(i,nEr:-1:1,:));  means sea level pressure (mb)
%             must include times that match the track file times
%             may include additional times, e.g., hourly values
%
%   GAHM_constants - data structure with constants needed by GAHM
%       GAHM_constants.Vmax_multiplier
%       GAHM_constants.one2tenF - convert from 1 min to 10 min wind speed
%                                                       (ADCIRC/ASWIP=0.89)
%       GAHM_constants.BLF  - boundary layer factor (ADCIRC/ASWIP=0.9)
%       GAHM_constants.Bmin - lower limit on B
%       GAHM_constants.Bmax - upper limit on B
%       GAHM_constants.SVorMax_10_tblmin - (kts)
%       GAHM_constants.SVorQuad_10_tblmin - (kts)
%       GAHM_constants.rhoa - density of air (kg/m^3) (ADCIRC/ASWIP=1.204)
%       GAHM_constants.pback - (mb) default environmental pressure if not
%                               read in from track file
%       GAHM_constants.version  (3 or 4)
%       GAHM_constants.Bg0M - multiplies B to give initial condition for
%                              iterative solver in GAHM2026v4 & GAHM2026v3
%                              (recom: 1.05)
%       GAHM_constants.c0 - initial condition for c (0<c<1) for iterative
%                              solver in GAHM2026va (recom: 0), ignored
%                              for GAHM2023v3.
%
%   See documentation/GAHM_struct.md for full GAHM data structure definition.
%
% If Pouter is available from the track file it is used for Pback. If not,
% the default value from GAHM_constants is used.
%
%                 7/12/2025   - Rick Luettich
%

    % physical constants
    c = gahmPhysicalConstants();
    NM2M = c.nm2m;
    MS2KT = c.ms2kt;
    earthRadiusInMeters = c.earthRadiusM;
    BLF = GAHM_constants.BLF;
    one2tenF = GAHM_constants.one2tenF;
    rhoa = GAHM_constants.rhoa;
    Pback_def = GAHM_constants.pback_def;
    Vmax_mult = GAHM_constants.Vmax_multiplier;

    % compute GAHM Parameters from track fle at current time level

    datetime_ATCF_line = ATCF_data_in(ATCF_line).datetime;
    LatNS = ATCF_data_in(ATCF_line).lat;
    LonEW = ATCF_data_in(ATCF_line).lon;
    MSLP = ATCF_data_in(ATCF_line).Pmin;
    Vmax = ATCF_data_in(ATCF_line).Vmax;
    Pback = ATCF_data_in(ATCF_line).Pouter;
    if isempty(Pback) || Pback == 0 || isnan(Pback)
        Pback = Pback_def;
    end
    numiso = ATCF_data_in(ATCF_line).numiso;

    skip_GAHM = false;
    if isnan(MSLP)
        logMsg(fid, "WARNING", "track file is missing Central Pressure, skipping this time %s", string(ATCF_data_in(ATCF_line).datetime));
        skip_GAHM = true;
    elseif isnan(Vmax)
        logMsg(fid, "WARNING", "track file is missing Vmax, skipping this time %s", string(ATCF_data_in(ATCF_line).datetime));
        skip_GAHM = true;
    end
    GAHM.skipline = skip_GAHM;
    if skip_GAHM
        return
    end

    SMax_10_10 = Vmax_mult*one2tenF*Vmax/MS2KT; % SMax_10_10 in m/s
    Rmax_in = ATCF_data_in(ATCF_line).RMW*NM2M; % Rmax in m
    RQuad(1:4,1) = ATCF_data_in(ATCF_line).R34(1:4)*NM2M; %34 kt isotachs in m
    RQuad(1:4,2) = ATCF_data_in(ATCF_line).R50(1:4)*NM2M; %50 kt isotachs in m
    RQuad(1:4,3) = ATCF_data_in(ATCF_line).R64(1:4)*NM2M; %64 kt isotachs in m
    RQuad(RQuad == 0) = NaN;
    SQuad_10_10(1:3) = one2tenF*[34, 50, 64]/MS2KT; %isotach values 10 min avg in m/s

    % Compute the translation velocity from backward difference

    if ATCF_line == 1
        LatNS_t1 = LatNS;
        LonEW_t1 = LonEW;
    else
        LatNS_t1 = ATCF_data_in(ATCF_line-1).lat;
        LonEW_t1 = ATCF_data_in(ATCF_line-1).lon;
    end
    VTspeed_10_10 = distance('rh',LatNS_t1, LonEW_t1, LatNS, LonEW, ...
        earthRadiusInMeters)/(BTinterval*3600);
    if isnan(VTspeed_10_10) || VTspeed_10_10 == 0
        VTdirection_10_10 = 0;
        VTspeed_10_10 = 0;
        VTuv_10_10 = [0, 0];
    else
        VTdirection_10_10 = (360-azimuth('rh',LatNS_t1, LonEW_t1, LatNS,LonEW))+90; %translation direction ccw from E
        VTuv_10_10 = [cosd(VTdirection_10_10), sind(VTdirection_10_10)];
    end

    % determine the environmental velocity near eye and at RQuad locations

    if env.type == 1 % ADCIRC/ASWIP approach  (NOAA TR NWS 23 1979) need to include (0.51444)^0.37 to use with m/s
        Gcase = 1;
        SEnv_10_10 = 1.5*(VTspeed_10_10^0.63)*(0.51444^0.37);
        VEnvStar_10_10 = SEnv_10_10*VTuv_10_10;
        VEnvQuad_10_10(1:4,1:3,1) = NaN; % not used for this case
        VEnvQuad_10_10(1:4,1:3,2) = NaN; % not used for this case
        Pscale = 1;
    elseif env.type == 2 % Lin and Chavez (2012)
        Gcase = 2; % environmental velocity specified  at isotach locations
        rotation_matrix_ccw20d = [cosd(-20) -sind(-20); sind(-20) cosd(-20)]; % rotate 20deg ccw in N hemi
        SEnv_10_10 = 0.6*VTspeed_10_10;
        VEnvStar_10_10 = SEnv_10_10*VTuv_10_10*rotation_matrix_ccw20d;
        VEnvQuad_10_10(1:4,1:3,1) = VEnvStar_10_10(1); % Env vel is constant in space
        VEnvQuad_10_10(1:4,1:3,2) = VEnvStar_10_10(2); % Env vel is constant in space
        Pscale = 1;
    elseif env.type == 3 % from gridded env velociy file
        Gcase = 2; % environmental velocity specified  at isotach locations
        itime = find(datetime_ATCF_line == [VEnv_10_10.datetime]);
        if isempty(itime) % didn't find the specified time in the background Enviromental Velocity file
            logMsg(fid, "WARNING", "Failed to find %s in the Environmental file. Skipping this trackfile time", string(datetime_ATCF_line));
            skip_GAHM = true;
            GAHM.skipline = skip_GAHM;
            return
        end
        VEnvStar_10_10 = VEnvAvg(datetime_ATCF_line,LonEW,LatNS,VEnv_10_10,Rmax_in); % compute avg VEnv within Rmax of eye to determine SVMax
        VEnvQuad_10_10 = VEnvRQuad(datetime_ATCF_line,LonEW,LatNS,VEnv_10_10,RQuad); % pull Environmental velocity @ RQuad locations from gridded VEnv input
        Pscale = PscaleEnv(itime);
    end

    % compute Maximum Vortex Velocity and Holland (1980) B

    SEnvStar_10_10 = norm(VEnvStar_10_10); % speed
    if SEnvStar_10_10 == 0
        VEnvStaruv_10_10 = VEnvStar_10_10; % unit vector
    else
        VEnvStaruv_10_10 = VEnvStar_10_10/SEnvStar_10_10; % unit vector
    end
    SVorMax_10_10 = SMax_10_10-SEnvStar_10_10;
    SVorMax_10_10_theta = atan2d(VEnvStaruv_10_10(2),VEnvStaruv_10_10(1))-90; %angle
        % ccw from E where SVorMax occurs
    SVorMax_10_tbl = SVorMax_10_10/BLF;
    deltaP_NpMsq = Pscale*(Pback-MSLP)*100;
    B = SVorMax_10_tbl*SVorMax_10_tbl*rhoa*exp(1)/deltaP_NpMsq;

    % Load GAHM datastructure

    GAHM.datetime = datetime_ATCF_line;
    GAHM.Eye = [LonEW, LatNS];
    GAHM.CP = MSLP; % mb
    GAHM.Pback = Pback; % mb
    GAHM.numiso = numiso;
    GAHM.SMax_10_10 = SMax_10_10;
    GAHM.Rmax_in = Rmax_in;
    GAHM.RQuad = RQuad;
    GAHM.SQuad_10_10 = SQuad_10_10;
    GAHM.VTspeed_10_10 = VTspeed_10_10;
    GAHM.VTdirection_10_10 = VTdirection_10_10;
    GAHM.VEnvStar_10_10 = VEnvStar_10_10;
    GAHM.VEnvQuad_10_10 = VEnvQuad_10_10;
    GAHM.SVorMax_10_10 = SVorMax_10_10;
    GAHM.SVorMax_10_10_theta = SVorMax_10_10_theta;
    GAHM.Pscale = Pscale;
    GAHM.B = B;
    GAHM.Gcase = Gcase;

end % main script end


% function to average the background Environmental Velocity gridded data
% over a specified radial distance from a specified lon,lat.
%
%  datetime = time to find in the background Env Velocity file
%  eyeLon, eyeLat = eye position at datetime
%  VEnv = background Environmental Velocity field
%  rad = radius to average VEnv over
%
%         coded by Rick Luettich 8/8/2024

function VEnvAvg_out = VEnvAvg(datetime,eyeLon,eyeLat,VEnv,rad)

    NM2M = gahmPhysicalConstants().nm2m;

    % find line in VEnv file correspoinding to the desired time

    itime = find(datetime == [VEnv.datetime]);

    if isempty(itime) % didn't find the specified time in the background Enviromental Velocity file
        logMsg(-1, "WARNING", "Failed to find %s in the background Environmental Velocity file. VEnvAvg_out set = NaN", string(datetime));
        VEnvAvg_out(1:2) = NaN;
    else
        rad_arc = nm2deg(rad/NM2M); %convert rad to nautical miles and then arclength (deg)
        longrid = VEnv(itime).lon;
        latgrid = VEnv(itime).lat;
        dist = distance(eyeLon,eyeLat,longrid,latgrid);
        [rows,cols] = find(rad_arc > dist);
        Uavg = 0;
        Vavg = 0;
        if length(rows) == 0
            distmin = min(min(dist));
            [rows,cols] = find((dist-distmin) == 0);
        end
        for i = 1:length(rows)
            Uavg = Uavg+VEnv(itime).VelU(rows(i),cols(i));
            Vavg = Vavg+VEnv(itime).VelV(rows(i),cols(i));
        end
        Uavg = Uavg/length(rows);
        Vavg = Vavg/length(rows);
        VEnvAvg_out = [Uavg Vavg];
    end

end % function end

% function to interpolate the background Environmental Velocity from a
% regular gridded input data structure to the isotach locations along the
% 4 quadrant radials
%
%  datetime = time to find in the background Env Velocity file
%  eyeLon, eyeLat = eye position at datetime
%  VEnv = background Environmental Velocity field
%  RQuad(q=1:4,iso=1:3) = distance (meters) to standard isotachs in 4
%                         quadrants
%
%         coded by Rick Luettich 8/8/2024

function VEnvQuad = VEnvRQuad(datetime,eyeLon,eyeLat,VEnv,RQuad)

    NM2M = gahmPhysicalConstants().nm2m;

    % assume working on standard 4 quadrants

    theta = [45 315 225 135];

    % find line in VEnv file correspoinding to the desired time

    itime = find(datetime == [VEnv.datetime]);

    if isempty(itime) % didn't find the specified time in the background Enviromental Velocity file
        logMsg(-1, "WARNING", "Failed to find %s in the background Environmental Velocity file. VEnvQuad set = NaN", string(datetime));
        VEnvQuad(1:4,1:3,1:2) = NaN;
    else
        longrid = VEnv(itime).lon;
        latgrid = VEnv(itime).lat;
        FU = griddedInterpolant(longrid',latgrid',VEnv(itime).VelU');
        FV = griddedInterpolant(longrid',latgrid',VEnv(itime).VelV');
        for q = 1:4
            az = thetaToAzimuth(theta(q));
            for iso = 1:3
                if isnan(RQuad(q,iso)) || RQuad(q,iso) == 0
                    VEnvQuad(q,iso,1:2) = NaN;
                else
                    RQuad_arc = nm2deg(RQuad(q,iso)/NM2M); %convert r to nautical miles and then arclength (deg)
                    [RQuad_lat,RQuad_lon] = reckon("rh",eyeLat,eyeLon,RQuad_arc,az); %might use track command here
                    VEnvRQuad(q,iso,1) = RQuad_lon;
                    VEnvRQuad(q,iso,2) = RQuad_lat;
                    VEnvQuad(q,iso,1) = FU(RQuad_lon,RQuad_lat);
                    VEnvQuad(q,iso,2) = FV(RQuad_lon,RQuad_lat);
                end
            end
        end
    end

end % function end
