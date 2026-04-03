function Reggrid_out = radial2regular(longrid,latgrid,eyeLon,eyeLat,r,theta,Vel,Press)
% radial2regular  Interpolate velocity and pressure from radial to regular grid.
%
% Interpolate velocity, speed and pressure from a radial r,theta
% grid to a lon, lat regular grid
%
% theta is assumed to be deg CCW from East
%
%
%         coded by Rick Luettich 7/12/2025
%                  Rick Luettich 1/31/2026 - removed speed

    arguments
        longrid double
        latgrid double
        eyeLon (1,1) double
        eyeLat (1,1) double
        r (1,:) double
        theta
        Vel
        Press
    end

theta = squeeze(theta);  % this gets rid of a bogus leading dimension of 1, i.e., (1,:,:) = (:,:)
Vel = squeeze(Vel);
Press = squeeze(Press);

NM2M = gahmPhysicalConstants().nm2m;

% convert from r,theta coordinates to lon, lat coordinates
    r_arc = nm2deg(r/NM2M);  %convert r to nautical miles and then arclength (deg)
    nr_arc = length(r_arc);

for it=1:length(theta)
    az(it) = thetaToAzimuth(theta(it));
    [VPrad_lat(it,1:nr_arc),VPrad_lon(it,1:nr_arc)] = reckon("rh",eyeLat,eyeLon,r_arc,az(it));
end

% Pack into sequential vectors

ntheta = length(theta);
ntotal = ntheta * nr_arc;
VPscatter_lon = reshape(VPrad_lon', 1, ntotal);
VPscatter_lat = reshape(VPrad_lat', 1, ntotal);
VelUscatter = reshape(Vel(:,:,1)', 1, ntotal);
VelVscatter = reshape(Vel(:,:,2)', 1, ntotal);
Pressscatter = reshape(Press', 1, ntotal);

% put into a scatter dataset (suppress expected duplicate-point warnings
% at r=0 where all radials converge to the eye)

warnState = warning('off', 'MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId');
cleanupWarn = onCleanup(@() warning(warnState));
FVU = scatteredInterpolant(VPscatter_lon',VPscatter_lat',VelUscatter');
FVV = scatteredInterpolant(VPscatter_lon',VPscatter_lat',VelVscatter');
FP = scatteredInterpolant(VPscatter_lon',VPscatter_lat',Pressscatter');

% interpolate from the scatter dataset to the regular grid
Reggrid_out.VelU = FVU(longrid,latgrid);
Reggrid_out.VelV = FVV(longrid,latgrid);
Reggrid_out.Press = FP(longrid,latgrid);

end

