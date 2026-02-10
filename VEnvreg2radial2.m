% script to interpolate Velocity and Pressure or the mask value from a
% regular gridded input data structure, assumed to match the gridded 
% environmental or hurricane field, to a radial grid defined by r, theta 
% and the eye location
% 
%  itime = pointer to correct time in the gridded file
%  eyeLon, eyeLat = eye position at datetime
%  VEnv = data structure containing gridded Velocity, Pressure, mask fields
%  r = distance (meters) along each radial
%  theta = angles to compute radials along
%
% 
%                Rick Luettich 6/19/2025            

function [VEnvrad PEnvrad]=VEnvreg2radial2(itime,VEnv,eyeLon,eyeLat,r,theta)

theta=squeeze(theta);  % this gets rid of a bogus leading dimension of 1, i.e., (1,:,:) = (:,:) 
r_arc=nm2deg(r/1852);  %convert r to nautical miles and then arclength (deg)
nr=length(r_arc);

mask=false;       % interpolate u,v,p onto radial grid
if itime < 0
    mask=true;    % interpolate mask onto radial grid
    itime = abs(itime);
end

longrid=VEnv(itime).lon;
latgrid=VEnv(itime).lat;
if ~mask
    FU=griddedInterpolant(longrid',latgrid',VEnv(itime).VelU');
    FV=griddedInterpolant(longrid',latgrid',VEnv(itime).VelV');
    FP=griddedInterpolant(longrid',latgrid',VEnv(itime).Press');
else
    FM1=griddedInterpolant(longrid',latgrid',VEnv(itime).mask1');
    FM2=griddedInterpolant(longrid',latgrid',VEnv(itime).mask2');    
end
  
for it=1:length(theta)
    az=90-theta(it);  %compute the bearing angle cw from N
    if az<0
        az=az+360;
    end

    [rad_lat(1:nr),rad_lon(1:nr)] = reckon("rh",eyeLat,eyeLon,r_arc,az);  %might use track command here

    if ~mask
        VEnvrad(it,:,1)=FU(rad_lon',rad_lat');
        VEnvrad(it,:,2)=FV(rad_lon',rad_lat');
        PEnvrad(it,:)=FP(rad_lon',rad_lat');
    else
        VEnvrad(it,:,1)=FM1(rad_lon',rad_lat');
        VEnvrad(it,:,2)=FM2(rad_lon',rad_lat');
        PEnvrad(it,1:nr)=NaN;
    end

    radlon_out(it,:)=rad_lon;
    radlat_out(it,:)=rad_lat;

end



