function fig = timeSeriesPlot(obj, fields, fign)
% timeSeriesPlot  Time-series plots of storm parameters vs time.
%
%   fig = obj.timeSeriesPlot()
%   fig = obj.timeSeriesPlot(fields)
%   fig = obj.timeSeriesPlot(fields, fign)
%
%   Plots one or more storm parameters from the track data as a function
%   of time using a tiled layout with one tile per parameter.
%
%   Inputs:
%     fields - cell array of parameter names to plot.  Allowed values:
%                'Vmax'   - maximum wind speed (converted to knots)
%                'Pc'     - central pressure (mb)
%                'Rmax'   - radius of maximum wind (nautical miles)
%                'Rmax34' - max isotach radius at 34 kt (nautical miles)
%                'Rmax50' - max isotach radius at 50 kt (nautical miles)
%                'Rmax64' - max isotach radius at 64 kt (nautical miles)
%              Default: {'Vmax','Pc','Rmax'}
%
%     fign   - figure number (integer).  Default is 1.
%              Pass [] for automatic figure numbering.
%
%   The x-axes of all tiles are linked so that zooming or panning one
%   tile updates the others.  Only the bottom tile shows x-axis tick
%   labels to avoid clutter.
%
%   Data source:
%     Trackdata is obtained from obj.Trackdata (struct array with one
%     entry per timestep).  Fields used:
%       .datetime   - MATLAB datetime for x-axis
%       .Vmax_t1    - max wind speed in m/s (converted to kts via MS2KT)
%       .MSLP or .Pc - central pressure in mb
%       .Rmax_t1    - radius of maximum wind in nautical miles
%       .RQuad_t1   - 4x3 matrix of isotach radii [34kt 50kt 64kt]
%                     (divided by NM2M to convert metres to nmi)
%
%   If a requested field is unavailable in the track data the
%   corresponding tile is skipped and a warning is issued.
%
%   Example:
%     R   = run_GAHM2026('config_GAHM2026_default');
%     obj = GAHM2026DiagPlotter(R);
%     fig = obj.timeSeriesPlot({'Vmax','Pc','Rmax','Rmax34'}, 10);
%
%   See also GAHM2026DiagPlotter, contourMap, radialProfile

    %% Defaults
    if nargin < 2 || isempty(fields), fields = {'Vmax','Pc','Rmax'}; end
    if nargin < 3 || isempty(fign),   fign = 1; end

    phys    = GAHM_physical_constants();
    MS2KT   = phys.ms2kt;
    NM2M    = phys.nm2m;

    Tdata   = obj.Trackdata;
    ntimes  = numel(Tdata);

    % Extract datetime vector
    dt = [Tdata.datetime];

    %% Build storm title prefix
    stormStr = '';
    if isfield(obj.Result, 'storm_info') && isfield(obj.Result.storm_info, 'storm_name')
        stormStr = [obj.Result.storm_info.storm_name ' — '];
    end

    %% Create figure
    if isempty(fign)
        fig = figure;
    else
        fig = figure(fign);
    end
    clf(fig);

    nfields = numel(fields);
    tl = tiledlayout(nfields, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, [stormStr 'Storm Parameters vs Time']);

    ax = gobjects(nfields, 1);
    nplotted = 0;

    for k = 1:nfields
        fname = fields{k};

        % Extract the appropriate data vector
        switch fname
            case 'Vmax'
                if ~isfield(Tdata, 'Vmax_t1')
                    warning('timeSeriesPlot:missingField', ...
                        'Vmax_t1 not found in Trackdata — skipping Vmax.');
                    continue
                end
                ydata  = [Tdata.Vmax_t1] * MS2KT;
                ylab   = 'Vmax [kts]';

            case 'Pc'
                if isfield(Tdata, 'MSLP')
                    ydata = [Tdata.MSLP];
                elseif isfield(Tdata, 'Pc')
                    ydata = [Tdata.Pc];
                else
                    warning('timeSeriesPlot:missingField', ...
                        'Neither MSLP nor Pc found in Trackdata — skipping Pc.');
                    continue
                end
                ylab = 'Pc [mb]';

            case 'Rmax'
                if ~isfield(Tdata, 'Rmax_t1')
                    warning('timeSeriesPlot:missingField', ...
                        'Rmax_t1 not found in Trackdata — skipping Rmax.');
                    continue
                end
                ydata = [Tdata.Rmax_t1];
                ylab  = 'Rmax [nm]';

            case 'Rmax34'
                if ~isfield(Tdata, 'RQuad_t1')
                    warning('timeSeriesPlot:missingField', ...
                        'RQuad_t1 not found in Trackdata — skipping Rmax34.');
                    continue
                end
                ydata = NaN(1, ntimes);
                for j = 1:ntimes
                    ydata(j) = max(Tdata(j).RQuad_t1(:, 1));
                end
                ydata = ydata / NM2M;
                ylab  = 'Rmax 34kt [nm]';

            case 'Rmax50'
                if ~isfield(Tdata, 'RQuad_t1')
                    warning('timeSeriesPlot:missingField', ...
                        'RQuad_t1 not found in Trackdata — skipping Rmax50.');
                    continue
                end
                ydata = NaN(1, ntimes);
                for j = 1:ntimes
                    ydata(j) = max(Tdata(j).RQuad_t1(:, 2));
                end
                ydata = ydata / NM2M;
                ylab  = 'Rmax 50kt [nm]';

            case 'Rmax64'
                if ~isfield(Tdata, 'RQuad_t1')
                    warning('timeSeriesPlot:missingField', ...
                        'RQuad_t1 not found in Trackdata — skipping Rmax64.');
                    continue
                end
                ydata = NaN(1, ntimes);
                for j = 1:ntimes
                    ydata(j) = max(Tdata(j).RQuad_t1(:, 3));
                end
                ydata = ydata / NM2M;
                ylab  = 'Rmax 64kt [nm]';

            otherwise
                warning('timeSeriesPlot:unknownField', ...
                    'Unknown field "%s" — skipping.', fname);
                continue
        end

        nplotted = nplotted + 1;
        ax(nplotted) = nexttile;
        tsopts = obj.Opts;
        if isfield(tsopts, 'timeseries')
            lw  = tsopts.timeseries.linewidth;
            mrk = tsopts.timeseries.marker;
            ms  = tsopts.timeseries.markersize;
        else
            lw = 1.5; mrk = 'o'; ms = 4;
        end
        plot(dt, ydata, [mrk '-'], 'LineWidth', lw, 'MarkerSize', ms);
        ylabel(ylab)
        gm
    end

    % Trim axes array to only the tiles actually created
    ax = ax(1:nplotted);

    if nplotted == 0
        warning('timeSeriesPlot:noData', 'No plottable fields found.');
        return
    end

    % Link x-axes and show tick labels only on the bottom tile
    linkaxes(ax, 'x');
    for k = 1:nplotted-1
        ax(k).XTickLabel = [];
    end

end
