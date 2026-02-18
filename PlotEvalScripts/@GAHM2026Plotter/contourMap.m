function fig = contourMap(obj, ptype, nplot, time, plotdata)
% contourMap  Contour plot of a gridded wind or pressure field at one time.
%
%   fig = obj.contourMap(ptype, nplot)            — plots first timestep
%   fig = obj.contourMap(ptype, nplot, time)      — plots specified time
%   fig = obj.contourMap(ptype, nplot, time, plotdata)
%
%   time can be:
%     integer index   — e.g. 5  (5th timestep)
%     datetime        — matched to nearest datagrid(ip).datetime
%     []              — defaults to timestep 1
%
%   ptype options:
%     'velcon'  - wind speed contours with velocity vectors
%     'precon'  - pressure contours
%     'mvelcon' - wind speed contours with mask boundary lines
%     'mprecon' - pressure contours with mask boundary lines
%
%   nplot    - figure number
%   plotdata - (optional) gridded field struct array to plot instead of
%              the default Result.Reggrid_TC_out
%
%   Returns the figure handle.

    if nargin < 5, plotdata = obj.PlotData; end
    if nargin < 4 || isempty(time), time = 1; end

    opts     = obj.Opts;
    datagrid = obj.DataGrid;
    Tdata    = obj.Trackdata;
    itot     = length(plotdata);

    ip = resolveTime(obj, time);

    con_Vplot = strcmp(ptype,'velcon') || strcmp(ptype,'mvelcon');
    con_Pplot = strcmp(ptype,'precon') || strcmp(ptype,'mprecon');
    showMask  = strcmp(ptype,'mvelcon') || strcmp(ptype,'mprecon');

    [minX, maxX, minY, maxY] = getDomain(obj, datagrid, ip);

    fig = figure(nplot);
    clf(fig);
    hold on

    %% velocity contour

    if con_Vplot
        Speed = hypot(plotdata(ip).VelU, plotdata(ip).VelV);
        pcolor(datagrid(ip).Lon, datagrid(ip).Lat, 1.944*Speed);
        shading interp
        colormap(gca, sky);
        colorbar
        clim(opts.wind.clims)
        alpha(opts.wind.alpha);

        addQuiver(obj, ip, plotdata);

        titleStr = ['Wind Speed (kts) 10 min @ 10 m  ' ...
            datestr(datetime(datagrid(ip).datetime),'mmm dd yyyy HH:MM') ' UTC'];
    end

    %% pressure contour

    if con_Pplot
        pcolor(datagrid(ip).Lon, datagrid(ip).Lat, plotdata(ip).Press);
        shading interp
        colormap(gca, sky);
        colorbar
        clim(opts.pres.clims)
        alpha(opts.pres.alpha);

        titleStr = ['Atm Pressure (mb)  ' ...
            datestr(datetime(datagrid(ip).datetime),'mmm dd yyyy HH:MM') ' UTC'];
    end

    %% overlays common to both

    if showMask
        plotMaskContours(obj, datagrid, ip);
    end

    plotTrack(obj, Tdata, ip, itot);

    title(titleStr)
    axis('equal')
    axis([minX maxX minY maxY]);
    plot_coastline(opts);

end
