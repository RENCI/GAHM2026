function addQuiver(obj, time, plotdata)
% addQuiver  Overlay subsampled velocity vectors on the current axes.
%
%   obj.addQuiver(time)
%   obj.addQuiver(time, plotdata)
%
%   time can be:
%     integer index   — e.g. 5
%     datetime        — matched to nearest datagrid datetime
%     []              — defaults to timestep 1
%
%   plotdata - (optional) gridded field struct array; defaults to
%             Result.Reggrid_TC_out
%
%   Uses opts.quiver.stride, .scale, .color to control appearance.
%   Adds to the current axes — call after contourMap or on any figure.

    if nargin < 3, plotdata = obj.PlotData; end
    if nargin < 2 || isempty(time), time = 1; end

    ip = resolveTime(obj, time);

    datagrid = obj.DataGrid;
    opts     = obj.Opts;
    stride   = opts.quiver.stride;
    scl      = opts.quiver.scale;
    clr      = opts.quiver.color;

    lon = datagrid(ip).Lon;
    lat = datagrid(ip).Lat;
    u   = plotdata(ip).VelU;
    v   = plotdata(ip).VelV;

    lon_s = lon(1:stride:end, 1:stride:end);
    lat_s = lat(1:stride:end, 1:stride:end);
    u_s   = u(1:stride:end, 1:stride:end);
    v_s   = v(1:stride:end, 1:stride:end);

    hold on
    quiver(lon_s, lat_s, u_s, v_s, scl, 'Color', clr, 'LineWidth', 0.5);

end
