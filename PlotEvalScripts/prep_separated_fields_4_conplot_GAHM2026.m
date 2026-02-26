%
%  Script to prepare data in the .mat file written when gridded fields are
%  separated into environmental and hurricane fields so that they can be
%  plotted using conplot_GAHM2026.m
%
%                Rick Luettich 2/25/2026
%
% Load the data from the .mat file
% data = load('separated.mat');
%

function [datagrid,plotdata_env,plotdata_hur,plotdata_envhur,Trackdata, ...
    opts_env,opts_hur,opts_envhur] = ...
    prep_separated_fields_4_conplot_GAHM2026(sepfile)

%% set general plot options
%
opts.domain.mode = 'moving';       % 'moving' or 'fixed'
opts.domain.padDeg = 2;            % extra padding in degrees (for moving mode)
% if mode is fixed, set the limits explicitly here, or leave empty to use the 
% lon,lat limits for the entire analysis  
%opts.domain.fixedLimits = [-85 -60 20 45]; % [minLon maxLon minLat maxLat]
% or                                             
opts.domain.fixedLimits = [];  % not sure that this works

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

for i=1:length(sepfile.Time)
    datagrid(i).datetime=squeeze(sepfile.Time(i));
    datagrid(i).Lon=squeeze(sepfile.Lo(i,:,:));
    datagrid(i).Lat=squeeze(sepfile.La(i,:,:));
    datagrid(i).Mask1=squeeze(sepfile.Vortex_mask34(i,:,:));
    datagrid(i).Mask2=squeeze(sepfile.Vortex_mask(i,:,:));
    plotdata_env(i).Press=squeeze(sepfile.env_msl(i,:,:));    
    plotdata_env(i).VelU=squeeze(sepfile.env_u10(i,:,:));
    plotdata_env(i).VelV=squeeze(sepfile.env_v10(i,:,:));
    plotdata_hur(i).Press=squeeze(sepfile.hur_msl(i,:,:));    
    plotdata_hur(i).VelU=squeeze(sepfile.hur_u10(i,:,:));
    plotdata_hur(i).VelV=squeeze(sepfile.hur_v10(i,:,:));
    plotdata_envhur(i).Press=plotdata_env(i).Press+plotdata_hur(i).Press;    
    plotdata_envhur(i).VelU=plotdata_env(i).VelU+plotdata_hur(i).VelU;
    plotdata_envhur(i).VelV=plotdata_env(i).VelV+plotdata_hur(i).VelV;    
    Trackdata(i).Lon=sepfile.BestTrack_lon(i);
    Trackdata(i).Lat=sepfile.BestTrack_lat(i);
end

end

