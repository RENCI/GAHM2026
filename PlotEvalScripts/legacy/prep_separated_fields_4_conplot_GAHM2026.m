%
%  Function to prepare data in the intermediate .mat file written when 
%  gridded fields are separated into environmental and hurricane fields 
%  so that they can be plotted using conplot_GAHM2026.m
%
%                Rick Luettich 2/25/2026
%                Brian Blanton 3/ 7/2026
%                           RL 9/1/2026
%
% Load the data from the .mat file
%   S = prep_separated_fields_4_conplot_GAHM2026(sepfile);
% or:
%   data = load(sepfile);
%   data = data.env_vals;
%   S = prep_separated_fields_4_conplot_GAHM2026(data)
%   S = 
%     struct with fields:
% 
%            datagrid: [1×NT struct]
%        plotdata_env: [1×NT struct]
%        plotdata_hur: [1×NT struct]
%     plotdata_envhur: [1×NT struct]
%           Trackdata: [1×NT struct]
%            opts_env: [1×1 struct]
%            opts_hur: [1×1 struct]
%         opts_envhur: [1×1 struct]
%
function S = prep_separated_fields_4_conplot_GAHM2026(sepfile)

    %% set general plot options
    %
    if isfile(sepfile)
        D=load(sepfile,'env_vals');
        D=D.env_vals;
    else
        D=sepfile;
    end
    
    opts.domain.mode = 'moving';       % 'moving' or 'fixed'
    opts.domain.padDeg = 2;            % extra padding in degrees (for moving mode)
    % if mode is fixed, set the limits explicitly here, or leave empty to use the 
    % lon,lat limits for the entire analysis  
    %opts.domain.fixedLimits = [-85 -60 20 45]; % [minLon maxLon minLat maxLat]
    % or                                             
    opts.domain.fixedLimits = [];  
    
    % Coastline
    opts.coast.show = true;            % overlay coastline
    opts.coast.color = 'k';
    opts.coast.linewidth = 2;
    
    % Animation
    opts.anim.gif = false;
    opts.anim.mp4 = false;
    opts.anim.frameRate = 2;           % frames per second
    
    % Export
    opts.export.dir = 'output';        % directory for output files
    opts.export.format = 'png';        % 'png', 'pdf', or 'none'
    opts.export.dpi = 150;
    
    % Track line
    opts.track.color = 'k';
    opts.track.linewidth = 2;
    opts.track.progressive = true;     % show track up to current time (vs full track)
    
    % Radial plots
    opts.radial.isotachs = [34 50 64]; % knots
    opts.radial.one2ten = 0.89;        % 1-min to 10-min conversion
    opts.radial.layout = [4 4];        % subplot layout [rows cols]
    
    % Masks
    opts.mask.show = true;            % overlay mask contours
    opts.mask.color = 'm';
    opts.mask.linewidth = 2;
    
    % Time
    opts.time.format='dd MMM yyyy HH:mm';
    
    % Wind velocity contour plots
    opts.wind.alpha = 1;               % transparency
    opts.wind.colormap = 'burd';       % colormap name
    
    % Pressure contour plots  
    opts.pres.alpha = 1;               % transparency
    opts.pres.colormap = 'rdbu';        % colormap name
    
    % Quiver (vector arrows)
    opts.quiver.stride = 3;           % plot every Nth vector
    opts.quiver.color = 'k';           % arrow color
    
    opts_env=opts;
    opts_hur=opts;
    opts_envhur=opts;
    
    %% set options that vary between different output types
    
    % Wind velocity contour plots
    opts_env.wind.clims = [0 16];
    opts_hur.wind.clims = [0 50];          % color limits (kts)
    opts_envhur.wind.clims=[0 50];
    
    % Pressure contour plots  
    opts_env.pres.clims = [980 1020];      % color limits (mb)
    opts_hur.pres.clims = [-50 50];
    opts_envhur.pres.clims = [980 1020];
    
    % Quiver (vector arrows)
    opts_env.quiver.scale = 1;             % quiver scale factor
    opts_hur.quiver.scale = 1;
    opts_envhur.quiver.scale = 1;
    
    
    %% load individual datastructures
    S.datagrid = struct('datetime',[],'Lon',[],'Lat',[],'Mask1',[],'Mask2',[]);
    S.plotdata_env=struct('Press',[],'VelU',[],'VelV',[]);
    S.plotdata_hur=struct('Press',[],'VelU',[],'VelV',[]);
    S.plotdata_envhur=struct('Press',[],'VelU',[],'VelV',[]);
    S.Trackdata=struct('Lon',[],'Lat',[]);
    
    for i=1:length(D.Time)
        S.datagrid(i).datetime=squeeze(D.Time(i));
        S.datagrid(i).Lon=squeeze(D.Lo(i,:,:));
        S.datagrid(i).Lat=squeeze(D.La(i,:,:));
        S.datagrid(i).Mask1=squeeze(D.Vortex_mask_inner(i,:,:));
        S.datagrid(i).Mask2=squeeze(D.Vortex_mask_outer(i,:,:));
        S.plotdata_env(i).Press=squeeze(D.env_msl(i,:,:));    
        S.plotdata_env(i).VelU=squeeze(D.env_u10(i,:,:));
        S.plotdata_env(i).VelV=squeeze(D.env_v10(i,:,:));
        S.plotdata_hur(i).Press=squeeze(D.hur_msl(i,:,:));    
        S.plotdata_hur(i).VelU=squeeze(D.hur_u10(i,:,:));
        S.plotdata_hur(i).VelV=squeeze(D.hur_v10(i,:,:));
        S.plotdata_envhur(i).Press=S.plotdata_env(i).Press+S.plotdata_hur(i).Press;    
        S.plotdata_envhur(i).VelU=S.plotdata_env(i).VelU+S.plotdata_hur(i).VelU;
        S.plotdata_envhur(i).VelV=S.plotdata_env(i).VelV+S.plotdata_hur(i).VelV;    
        S.Trackdata(i).Lon=D.BestTrack_lon(i);
        S.Trackdata(i).Lat=D.BestTrack_lat(i);
    end
    
    S.opts_env=opts_env;
    S.opts_hur=opts_hur;
    S.opts_envhur=opts_envhur;

end

