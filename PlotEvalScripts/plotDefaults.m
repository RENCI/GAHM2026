function opts = plotDefaults()
% Returns default options struct for GAHM2026 plotting functions.
%
%                Rick Luettich / UNC/IMS/CNHR/EMES
%                Brian Blanton / RENCI

%% Domain
opts.domain.mode = "fixed";       % "moving" or "fixed"
opts.domain.padDeg = 2;            % extra padding in degrees (for moving mode)
% [minLon maxLon minLat maxLat] for fixed mode
% if mode is fixed, set the limits explicitly here, or leave empty to use the
% lon,lat limits for the entire analysis

%opts.domain.fixedLimits = [-85 -60 20 45];
% or
opts.domain.fixedLimits = [];

%% Wind velocity contour plots
opts.wind.clims = [0 80];          % color limits (kts)
opts.wind.alpha = 0.8;             % transparency
opts.wind.colormap = "burd";        % colormap name

%% Pressure contour plots
opts.pres.clims = [980 1020];      % color limits (mb)
opts.pres.alpha = 0.8;             % transparency
opts.pres.colormap = "rdbu";        % colormap name

%% Quiver (vector arrows)
opts.quiver.stride = 10;           % plot every Nth vector
opts.quiver.scale = 2;             % quiver scale factor
opts.quiver.color = 'k';           % arrow color

%% Coastline
opts.coast.show = true;            % overlay coastline
opts.coast.color = 'k';
opts.coast.linewidth = 2;

%% Animation
opts.anim.gif = true;
opts.anim.mp4 = true;
opts.anim.frameRate = 2;           % frames per second

%% Export
opts.export.dir = "output";        % directory for output files
opts.export.format = "png";        % "png", "pdf", or "none"
opts.export.dpi = 150;

%% Track line
opts.track.color = 'k';
opts.track.linewidth = 2;
opts.track.progressive = true;     % show track up to current time (vs full track)

%% Radial plots
opts.radial.isotachs = [34 50 64]; % knots
opts.radial.one2ten = 0.89;        % 1-min to 10-min conversion
opts.radial.layout = [6 4];        % subplot layout [rows cols]

%% Masks
opts.mask.show = false;            % overlay mask contours
opts.mask.color = 'm';
opts.mask.linewidth = 2;

%% Difference map
opts.diffmap.colormap = "rdbu";    % diverging colormap
opts.diffmap.clims = [];           % [] = auto-symmetric

%% Scatter plots
opts.scatter.showMetrics = false;  % annotate bias/RMSE/R^2 on scatter plots
opts.scatter.csvFile = "";         % CSV file for metrics export ("" = none)

%% Time-series plots
opts.timeseries.linewidth = 1.5;
opts.timeseries.marker = 'o';
opts.timeseries.markersize = 4;

%% Time
opts.time.format = "dd MMM yyyy HH:mm";

end
