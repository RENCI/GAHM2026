function [VVor_WAF] = applyWAFfromRaster(WAF_raster,WAF_metadata, ...
                                             Reggrid_VVor,longrid,latgrid)
% script to interpolate Wind Adjustment Factors from a gridded raster with
% multiple layers (for wind direction angles) to Reggrid
%
% the WAF raster assumes wind directions are the direction the wind is
% blowing from specified in degrees CW from N.
%
% Sends back Reggrid_VVor data structure with VelU, VelV, Speed modified
% by WAF
%
%                    Rick Luettich  1/31/2026

[nrows_WAF,ncols_WAF,nlays_WAF] = size(WAF_raster);
lon1_WAF = WAF_metadata.LongitudeLimits(1);  % western most lon
lonn_WAF = WAF_metadata.LongitudeLimits(2);  % eastern most lon
lat1_WAF = WAF_metadata.LatitudeLimits(1);   % southern most lat
latn_WAF = WAF_metadata.LatitudeLimits(2);   % northern most lat
dlon_WAF = (lonn_WAF-lon1_WAF)/(ncols_WAF-1);
dlat_WAF = (latn_WAF-lat1_WAF)/(nrows_WAF-1);

% dlon1_WAF=WAF_metadata.SampleSpacingInLongitude; % delta longitude
% dlat1_WAF=WAF_metadata.SampleSpacingInLatitude;  % delta latitude
dlays_WAF = 360/nlays_WAF;                   % delta layer
lonvals_WAF = lon1_WAF:dlon_WAF:lonn_WAF;
latvals_WAF = lat1_WAF:dlat_WAF:latn_WAF;
layvals_WAF = 0:dlays_WAF:360;

% create a 3D mesh to interpolate from
[lon_WAF,lat_WAF,lay_WAF] = meshgrid(lonvals_WAF,latvals_WAF,layvals_WAF);

% reorient WAF raster to put row 1 in south rather than in north to match
% Reggrid orientation
WAF_raster = flipud(WAF_raster);

% add an additional layer = 360 deg that contains the same raster values as
% the first layer = 0 deg to enable interpolation from 0 to 360.
WAF_raster(:,:,nlays_WAF+1) = WAF_raster(:,:,1);

% compute Wdir direction CW from N wind is blowing toward to and then add
% 180 to convert to CW from N wind is blowing from.  Adding 180 does not
% cause dir > 360 because atan2d outputs angles from -180 to 180.
Reggrid_VVor_Wdir_from = atan2d(Reggrid_VVor.VelU,Reggrid_VVor.VelV) + 180;

% Interpolate WAF using the created meshgrid, set WAF=1 for any points
% outside the WAF raster
Reggrid_WAF = interp3(lon_WAF,lat_WAF,lay_WAF,WAF_raster,longrid, ...
                             latgrid, Reggrid_VVor_Wdir_from, 'linear', 1);

% Apply the WAF values to the U & V velocities
VVor_WAF.VelU = Reggrid_WAF.*Reggrid_VVor.VelU;
VVor_WAF.VelV = Reggrid_WAF.*Reggrid_VVor.VelV;
% VVor_WAF.Speed = sqrt(VVor_WAF.VelU.^2 + VVor_WAF.VelV.^2);

end
