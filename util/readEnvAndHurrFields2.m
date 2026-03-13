function [VEnv_10_10,VHur_10_10,Masks,PscaleEnv] = readEnvAndHurrFields2 ...
 (env,starttime_dt,endtime_dt)
%.........................................................................
%
%  Script to read in gridded Environmental, Hurricane, and Mask fields
%  created by the vortex scrubbing routine for use with GAHM2026 if
%  env.type=3
%
%      env.type - type of environmental velocity and pressure fields
%             = 1 ADCIRC scheme based on translation vel
%             = 2 0.6*tanslation vel & 20deg ccw rotation (Lin&Chavez 2012)
%             = 3 extract from gridded environmental file
%      env.file_name = file name containing gridded environmental velocity
%                   and pressure input, ignored if env.type =1 or 2
%             assumed to be a matlab .mat file in the data structure:
%             filename.Time(i); - datetime
%             filename.Lo(i,:,:);
%             filename.La(i,nEr:-1:1,:);
%             filename.Vortex_mask(i,nEr:-1:1,:) 0,1=inside,outside outer
%                                                    cut line
%             filename.Vortex_mask_inner(i,nEr:-1:1,:) 0,1=inside,outside inner
%                                                    cut line
%             filename.env_u10(i,nEr:-1:1,:);   E-W velocity (m/s)
%             filename.env_v10(i,nEr:-1:1,:);   N-S velocity (m/s)
%             filename.env_msl(i,nEr:-1:1,:));  means sea level pressure (mb)
%             must include times that match the track file times
%             may include additional times, e.g., hourly values
%
%   the input la and lo are checked and if necessary reordered to make sure
%   lat and lon are in ascending order
%
%   This only sends back the portion of the Environmental & Hurricane file
%   encompassed by starttime and endtime.
%
%   Note: PscaleEnv hardwired = 1, needs to be revisited in the future.
%
%                 2/3/2026   - Rick Luettich
%

% Read in and setup the Environmental field. Assumes env.type == 3

load (env.file_name); % assumed to be a Matlab '.mat' file
% %env_vals=eval(env.file_name(1:length(env.file_name)-4));  %rename the env data structure if included .mat on the end
%env_vals=eval(env.file_name);    %rename the env data structure
% env_vals=load(env.file_name);
[~, nEr, nEc] = size(env_vals.Lo);
startline = find(starttime_dt == [env_vals.Time]);
if isempty(startline) % didn't find the specified time in the background Enviromental Velocity file
 logMsg(-1, "ERROR", "Failed to find the starting time %s in the Environmental file.", string(starttime_dt));
end
endline = find(endtime_dt == [env_vals.Time]);
if isempty(endline) % didn't find the specified time in the background Enviromental Velocity file
 logMsg(-1, "ERROR", "Failed to find the ending time %s in the Environmental file.", string(endtime_dt));
end
numline = endline-startline+1;
VEnv_10_10(numline).lon = 0;
VHur_10_10(numline).lon = 0;
PscaleEnv(numline) = 0;
Masks(numline).lon = 0;

i = 0;
for nl = startline:endline
 i = i+1;
 VEnv_10_10(i).datetime = env_vals.Time(nl);
 VEnv_10_10(i).lon = squeeze(env_vals.Lo(nl,:,:));
 VEnv_10_10(i).lat = squeeze(env_vals.La(nl,:,:));
 lon1 = 1;
 lonn = nEc;
 dlon = 1;
 lat1 = 1;
 latn = nEr;
 dlat = 1;
 if VEnv_10_10(i).lon(1,1) > VEnv_10_10(i).lon(1,2) && VEnv_10_10(i).lat(1,1) > VEnv_10_10(i).lat(2,1)
 lon1 = nEc;
 lonn = 1;
 dlon = -1;
 lat1 = nEr;
 latn = 1;
 dlat = -1;
 VEnv_10_10(i).lon = squeeze(env_vals.Lo(nl,:,lon1:dlon:lonn));
 VEnv_10_10(i).lat = squeeze(env_vals.La(nl,lat1:dlat:latn,:));
 elseif VEnv_10_10(i).lon(1,1) > VEnv_10_10(i).lon(1,2)
 lon1 = nEc;
 lonn = 1;
 dlon = -1;
 VEnv_10_10(i).lon = squeeze(env_vals.Lo(nl,:,lon1:dlon:lonn));
 elseif VEnv_10_10(i).lat(1,1) > VEnv_10_10(i).lat(2,1)
 lat1 = nEr;
 latn = 1;
 dlat = -1;
 VEnv_10_10(i).lat = squeeze(env_vals.La(nl,lat1:dlat:latn,:));
 end
 VEnv_10_10(i).lon = squeeze(env_vals.Lo(nl,:,lon1:dlon:lonn));
 VEnv_10_10(i).lat = squeeze(env_vals.La(nl,lat1:dlat:latn,:));
 VEnv_10_10(i).VelU = squeeze(env_vals.env_u10(nl,lat1:dlat:latn,lon1:dlon:lonn)); % m/s
 VEnv_10_10(i).VelV = squeeze(env_vals.env_v10(nl,lat1:dlat:latn,lon1:dlon:lonn)); % m/s
 VEnv_10_10(i).Press = squeeze(env_vals.env_msl(nl,lat1:dlat:latn,lon1:dlon:lonn)); % mb
 VHur_10_10(i).lon = squeeze(env_vals.Lo(nl,:,lon1:dlon:lonn));
 VHur_10_10(i).lat = squeeze(env_vals.La(nl,lat1:dlat:latn,:));
 VHur_10_10(i).VelU = squeeze(env_vals.hur_u10(nl,lat1:dlat:latn,lon1:dlon:lonn)); % m/s
 VHur_10_10(i).VelV = squeeze(env_vals.hur_v10(nl,lat1:dlat:latn,lon1:dlon:lonn)); % m/s
 VHur_10_10(i).Press = squeeze(env_vals.hur_msl(nl,lat1:dlat:latn,lon1:dlon:lonn)); % mb
 Masks(i).lon = squeeze(env_vals.Lo(nl,:,lon1:dlon:lonn));
 Masks(i).lat = squeeze(env_vals.La(nl,lat1:dlat:latn,:));
 Masks(i).mask1 = squeeze(env_vals.Vortex_mask_inner(nl,lat1:dlat:latn,lon1:dlon:lonn)); %inner mask
 Masks(i).mask1(isnan(Masks(i).mask1)) = 0; %convert NaNs in mask to 0
 Masks(i).mask2 = squeeze(env_vals.Vortex_mask(nl,lat1:dlat:latn,lon1:dlon:lonn)); %outer mask
 Masks(i).mask2(isnan(Masks(i).mask2)) = 0; %convert NaNs in mask to 0
 numones = sum(sum(Masks(i).mask2));
 PnEnvAvg = sum(sum(Masks(i).mask2.*VEnv_10_10(i).Press))/numones; % average pressure outside the cutline
%    PscaleEnv(i)=(env_vals.PcdefHur(nl)+env_vals.PcEnv(nl)-env_vals.Pc(nl))/(env_vals.Pc(nl)-PnEnvAvg); %use to scale the central pressure deficit in GAHM
 PscaleEnv(i) = 1;
end

end
