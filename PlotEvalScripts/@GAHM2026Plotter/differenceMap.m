function fig = differenceMap(obj, fieldA, fieldB, variable, figNum, time)
% differenceMap  Difference map between two gridded field sets.
%
%   fig = obj.differenceMap(fieldA, fieldB, variable)
%   fig = obj.differenceMap(fieldA, fieldB, variable, figNum)
%   fig = obj.differenceMap(fieldA, fieldB, variable, figNum, time)
%
%   Plots the element-wise difference (A minus B) of two gridded field
%   struct arrays on a diverging colormap.
%
%   fieldA, fieldB — gridded field struct arrays (same format as
%       Reggrid_TC_out); each element has .Press, .VelU, .VelV.
%
%   variable — 'speed' or 'press'
%       'speed': diff = hypot(A.VelU,A.VelV) - hypot(B.VelU,B.VelV)
%                converted to knots (* MS2KT)
%       'press': diff = A.Press - B.Press
%
%   figNum — figure number (default 1; [] = use current figure)
%
%   time — integer index, datetime, or [] (default 1)
%       integer  — index into the struct arrays
%       datetime — matched to nearest datagrid(tidx).datetime
%       []       — defaults to timestep 1
%
%   Relevant options (set via obj.setOpts):
%       opts.diffmap.colormap  — colormap name (default 'rdbu')
%       opts.diffmap.clims     — fixed [lo hi] color limits; [] = auto-symmetric
%
%   Returns the figure handle.

    if nargin < 6 || isempty(time),   time = 1;  end
    if nargin < 5 || isempty(figNum), figNum = 1; end

    MS2KT = gahmPhysicalConstants().ms2kt;
    opts = obj.Opts;
    datagrid = obj.DataGrid;
    Track = obj.Trackdata;
    ntimes = length(fieldA);

    % --- diffmap option defaults ---
    if ~isfield(opts, 'diffmap'), opts.diffmap = struct(); end
    if ~isfield(opts.diffmap, 'colormap'), opts.diffmap.colormap = 'rdbu'; end
    if ~isfield(opts.diffmap, 'clims'), opts.diffmap.clims = []; end

    tidx = resolveTime(obj, time);
    ThisTime = datagrid(tidx).datetime;
    ThisTime.Format = 'yyyy-MM-dd HH:mm';

    % --- compute difference field ---
    switch lower(variable)
        case 'speed'
            diff_field = (hypot(fieldA(tidx).VelU, fieldA(tidx).VelV) ...
                        - hypot(fieldB(tidx).VelU, fieldB(tidx).VelV)) * MS2KT;
            titleStr = ['Speed Difference (kts) A-B  ' char(string(ThisTime)) ' UTC'];
        case 'press'
            diff_field = fieldA(tidx).Press - fieldB(tidx).Press;
            titleStr = ['Pressure Difference (mb) A-B  ' char(string(ThisTime)) ' UTC'];
        otherwise
            error("GAHM2026Plotter:differenceMap", ...
                  "variable must be 'speed' or 'press', got '%s'", variable);
    end

    [minX, maxX, minY, maxY] = getDomain(obj, datagrid, tidx);

    % --- figure ---
    if isempty(figNum)
        fig = figure(gcf);
    else
        fig = figure(figNum);
    end
    clf(fig);
    hold on

    % --- pcolor ---
    pcolor(datagrid(tidx).Lon, datagrid(tidx).Lat, diff_field);
    shading interp
    colormap(gca, opts.diffmap.colormap);
    colorbar

    % --- symmetric color limits ---
    if ~isempty(opts.diffmap.clims)
        clim(opts.diffmap.clims);
    else
        maxabs = max(abs(diff_field(:)));
        if maxabs > 0
            clim([-maxabs maxabs]);
        end
    end

    % --- overlays ---
    plotTrack(obj, Track, tidx, ntimes);

    if opts.mask.show
        plotMaskContours(obj, datagrid, tidx);
    end

    plotCoastline(opts);

    title(titleStr)
    axis('equal')
    axis([minX maxX minY maxY]);
    gm

end
