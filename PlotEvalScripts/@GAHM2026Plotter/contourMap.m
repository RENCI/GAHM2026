function fig = contourMap(obj, plotType, figNum, time, plotdata)
% contourMap  Contour plot of a gridded wind or pressure field at one time.
%
%  To use this, must first issue command:
%      obj = GAHM2026Plotter(R);
%  where R is the datastructure from
%      R=run_GAHM2026( );
%
%   fig = obs.contourMap(plotType)                  - defaults to figure #1
%   fig = obj.contourMap(plotType, figNum)            - plots first timestep
%   fig = obj.contourMap(plotType, figNum, time)      - plots specified time
%   fig = obj.contourMap(plotType, figNum, time, plotdata)
%
%   time can be:
%     integer index   — e.g. 5  (5th timestep)
%     datetime        — matched to nearest datagrid(tidx).datetime
%     []              — defaults to timestep 1
%
%   plotType options:
%     'velcon'  - wind speed contours with velocity vectors
%     'precon'  - pressure contours
%     'prequiv' - pressure contours with velocity vectors
%     'mvelcon' - wind speed contours with mask boundary lines
%     'mprecon' - pressure contours with mask boundary lines
%
%   figNum     - figure number
%   plotdata - (optional) gridded field struct array to plot instead of
%              the default Result.Reggrid_TC_out
%
%   Returns the figure handle.

    if nargin < 5, plotdata = obj.PlotData; end
    if nargin < 4 || isempty(time), time = 1; end
    if nargin < 3 || isempty(figNum), figNum = 1; end

    MS2KT = gahmPhysicalConstants().ms2kt;
    opts = obj.Opts;
    datagrid = obj.DataGrid;
    Track = obj.Trackdata;
    ntimes = length(plotdata);

    tidx = resolveTime(obj, time);
    ThisTime = datagrid(tidx).datetime;
    ThisTime.Format = 'yyyy-MM-dd HH:mm';

    isWindPlot = plotType == "velcon" || plotType == "mvelcon";
    isPresPlot = plotType == "precon" || plotType == "mprecon" || plotType == "prequiv";
    showMask = plotType == "mvelcon" || plotType == "mprecon";
    showQuiv = plotType == "velcon" || plotType == "prequiv";

    [minX, maxX, minY, maxY] = getDomain(obj, datagrid, tidx);

    if isempty(figNum)
        fig = figure(gcf);
    else
        fig = figure(figNum);
    end
    clf(fig);
    hold on

    %% velocity contour

    if isWindPlot
        Speed = hypot(plotdata(tidx).VelU, plotdata(tidx).VelV);
        pcolor(datagrid(tidx).Lon, datagrid(tidx).Lat, MS2KT*Speed);
        shading interp
        colormap(gca, opts.wind.colormap);
        colorbar
        clim(opts.wind.clims)
        alpha(opts.wind.alpha);

        addQuiver(obj, tidx, plotdata);

        titleStr = ['Wind Speed (kts) 10 min @ 10 m  ' char(string(ThisTime)) ' UTC'];
    end

    %% pressure contour

    if isPresPlot
        pcolor(datagrid(tidx).Lon, datagrid(tidx).Lat, plotdata(tidx).Press);
        shading interp
        colormap(gca, opts.pres.colormap);
        colorbar
        clim(opts.pres.clims)
        alpha(opts.pres.alpha);

        if showQuiv
            addQuiver(obj, tidx, plotdata);
        end

        titleStr = ['Atm Pressure (mb)  ' char(string(ThisTime)) ' UTC'];
    end

    %% overlays common to both

    if showMask
        plotMaskContours(obj, datagrid, tidx);
    end

    plotTrack(obj, Track, tidx, ntimes);

    title(titleStr)
    axis('equal')
    gm
    axis([minX maxX minY maxY]);
    plotCoastline(opts);

end
