function [radnum] = radialFindMaskedge(longrid, latgrid, mask, centerLon, centerLat, r, theta)
% script to read in a gridded mask file with interior values=1 and exterior
% values = NaN, and find the radial distance from a presctibed lon,lat
% where the mask goes from 1 to NaN.
%
%         coded by Rick Luettich 8/17/2024
%   changed functon name & converted to looking for 0->1 rather than
%           NaN->1 transition 11/7/2024  RL

theta = squeeze(theta);  % this gets rid of a bogus leading dimension of 1, i.e., (1,:,:) = (:,:)
mask = squeeze(mask);
longrid = squeeze(longrid);
latgrid = squeeze(latgrid);
mask = squeeze(mask);

% put data into a gridded interpolant objects

FM = griddedInterpolant(longrid',latgrid',mask');

% convert radial values from r,theta coordinates to lon, lat coordinates
    NM2M = gahmPhysicalConstants().nm2m;
    r_arc = nm2deg(r/NM2M);  %convert r to nautical miles and then arclength (deg)
    nr = length(r_arc);

for it = 1:length(theta)
    az(it) = 90 - theta(it);  %compute the bearing angle cw from N
    if az(it) < 0
        az(it) = az(it) + 360;
    end
    [rad_lat(1:nr),rad_lon(1:nr)] = reckon("rh",centerLat,centerLon,r_arc,az(it));  %might use track command here

% interpolate from the regular grid to the radial locations
    mask_radial(:) = FM(rad_lon',rad_lat');
%    radnum(it)=find(~isnan(mask_radial),1);
    radnum(it) = find(mask_radial ~= 0,1);
end

end
