% script to interpolate velocity, speed and pressure from a radial r,theta 
% grid to a lon, lat regular grid
%
% theta is assumed to be deg CCW from East
% 
%  
%         coded by Rick Luettich 7/12/2025       
%                  Rick Luettich 1/31/2026 - removed speed

function Reggrid_out=radial2regular(longrid,latgrid,eyeLon,eyeLat,r,theta,Vel,Press)

theta=squeeze(theta);  % this gets rid of a bogus leading dimension of 1, i.e., (1,:,:) = (:,:) 
Vel=squeeze(Vel);
Press=squeeze(Press);

% earthRadiusInMeters = 6371000;

% convert from r,theta coordinates to lon, lat coordinates
    r_arc=nm2deg(r/1852);  %convert r to nautical miles and then arclength (deg)
    nr_arc=length(r_arc);

for it=1:length(theta)
    az(it)=90-theta(it);  %compute the bearing angle cw from N
    if az(it)<0
        az(it)=az(it)+360;
    end
    [VPrad_lat(it,1:nr_arc),VPrad_lon(it,1:nr_arc)] = reckon("rh",eyeLat,eyeLon,r_arc,az(it));  %might use track command here
end

% Pack into sequential vectors 

ntheta = length(theta);
ntotal = ntheta * nr_arc;
VPscatter_lon = reshape(VPrad_lon', 1, ntotal);
VPscatter_lat = reshape(VPrad_lat', 1, ntotal);
VelUscatter = reshape(Vel(:,:,1)', 1, ntotal);
VelVscatter = reshape(Vel(:,:,2)', 1, ntotal);
Pressscatter = reshape(Press', 1, ntotal);

% put into a scatter dataset

FVU=scatteredInterpolant(VPscatter_lon',VPscatter_lat',VelUscatter');
FVV=scatteredInterpolant(VPscatter_lon',VPscatter_lat',VelVscatter');    
FP=scatteredInterpolant(VPscatter_lon',VPscatter_lat',Pressscatter');

% interpolate from the scatter dataset to the regular grid
Reggrid_out.VelU=FVU(longrid,latgrid);
Reggrid_out.VelV=FVV(longrid,latgrid);    
Reggrid_out.Press=FP(longrid,latgrid);



