function [VVor_WAF] = applyWAFfromPoints(WAF_points,VVor_points, ...
                                             lonpts,latpts,fid)
% script to apply Wind Adjustment Factors to wind velocities at specified
% points using point WAF values.  The data structure containing the point
% WAF values is assumed to contain lon,lat values that match the locations
% where the wind velocities are to be computed. Each WAF location contains
% WAF values for multiple wind directions around the compass dial. The
% script interpolates a final WAF based on the input wind direction.
%
% Returns VVor_WAF.VelU and VVor_WAF.VelV that have been modified by WAF
%
% Wind directions are the direction the wind is blowing from specified in
% degrees CW from N. Col 1 is N (0 deg)
%
% the WAF data structure has the form:
%          WAF_points(1:#_WAF_points).lon
%          WAF_points(1:#_WAF_points).lat
%          WAF_points(1:#_WAF_points).WAF(1:#_wind_directions)
%
% the locations to apply WAF data structures have the form:
%          VVor_points.VelU(1:#_VVor_points)
%          VVor_points.VelV(1:#_VVor_points)
%          lonpts(1:#_VVor_points)
%          latpts(1:#_VVor_points)
%
% the returned data structure VVor_WAF matches the input data structure
% VVor_points
%
%                    Rick Luettich  4/29/2026

arguments
    WAF_points (1,:) struct
    VVor_points (1,1) struct
    lonpts double
    latpts double
    fid (1,1) double
end

npoints_WAF = length(WAF_points);
ndirs_WAF = length(WAF_points(1).WAF);
ddirs_WAF = 360/ndirs_WAF;                 % delta direction
dirvals_WAF = 0:ddirs_WAF:360;

% reorganize for convenience
WAF_lon = zeros(1,npoints_WAF);
WAF_lat = zeros(1,npoints_WAF);
WAF_p1 = zeros(npoints_WAF,ndirs_WAF+1);
for i = 1:npoints_WAF
    WAF_lon(i) = WAF_points(i).lon;
    WAF_lat(i) = WAF_points(i).lat;
    WAF_p1(i,1:ndirs_WAF) = WAF_points(i).WAF(:);
end

% add extra layer = 360 deg with same values as the first layer = 0 deg
WAF_p1(:,ndirs_WAF+1) = WAF_p1(:,1);

npoints_VVor = length(VVor_points.VelU);

% compute Wdir direction CW from N wind is blowing toward to and then add
% 180 to convert to CW from N wind is blowing from.  Adding 180 does not
% cause dir > 360 because atan2d outputs angles from -180 to 180.
VVor_points_Wdir_from = atan2d(VVor_points.VelU,VVor_points.VelV) + 180;

tflon = ismember(lonpts, WAF_lon);
tflat = ismember(latpts, WAF_lat);

VVor_WAF.VelU = zeros(size(VVor_points.VelU));
VVor_WAF.VelV = zeros(size(VVor_points.VelV));

for i = 1:npoints_VVor
    if tflon(i) && tflat(i)
        WAF_lon_index = find(ismember(WAF_lon,lonpts(i)));
        WAF_lat_index = find(ismember(WAF_lat,latpts(i)));
        if WAF_lon_index == WAF_lat_index
            WAF = interp1(dirvals_WAF,WAF_p1(WAF_lon_index,:),VVor_points_Wdir_from(i));
            VVor_WAF.VelU(i) = WAF*VVor_points.VelU(i);
            VVor_WAF.VelV(i) = WAF*VVor_points.VelV(i);
        else % lon,lat for point i does not match a single WAF location
            logMsg(fid, "ERROR", "lon & lat for point %d not in WAF array", i);
        end
    else  % point i was not found in the WAF array
        logMsg(fid, "ERROR", "Point %d not found in WAF array", i);
    end
end

end
