classdef GAHM2026Plotter < handle
% GAHM2026Plotter  Unified plotting and diagnostics class for GAHM2026.
%
%   Accepts output from run_GAHM2026 (Result struct) or from the
%   SeparateEnvHur pipeline (.mat file or pre-loaded struct).
%
% CONSTRUCTORS
%   obj = GAHM2026Plotter(Result)
%   obj = GAHM2026Plotter(Result, opts)
%   obj = GAHM2026Plotter.fromSepEnvHur(sepfile_or_struct)
%   obj = GAHM2026Plotter.fromSepEnvHur(sepfile_or_struct, opts)
%
% PLOTTING METHODS
%   contourMap(plotType, figNum, time, plotdata)
%       Contour map (pcolor) of wind speed or pressure at one timestep.
%       plotType: 'velcon','precon','prequiv','mvelcon','mprecon'
%
%   addQuiver(time, plotdata)
%       Overlay velocity vectors on the current axes.
%
%   radialProfile(plotType, fieldType, figNum, time, theta_inc)
%       Radial profiles of wind or pressure at one timestep in subplots.
%       plotType: 'velrad' or 'prerad'
%       fieldType: string or cell array of strings from:
%         'envhur','vor_bt','vor_at','env','envvor_bt','envhur_final','trackdata'
%
%   timeSeriesPlot(fields, figNum)
%       Time-series of storm parameters (Vmax, Pc, Rmax, etc.).
%
%   differenceMap(fieldA, fieldB, variable, figNum, time)
%       Difference map between two gridded field sets.
%
%   scatterCompare(X, Y, figNum, titleStr, xlabelStr, ylabelStr, legendLabels)
%       1:1 scatter plot with optional metrics annotation.
%
%   animate(plotType, figNum, plotdata, filename)
%       GIF/MP4 animation over all timesteps.
%
%   exportFigure(fig, filename)
%       Save figure to PNG or PDF.
%
% DIAGNOSTICS
%   metrics = computeMetrics(X, Y, varName)
%       Compute bias, RMSE, MAE, correlation, scatter index.
%
% UTILITY METHODS
%   setOpts(group, field, value) - override a single option
%   resetOpts()                  - restore all defaults
%   syncDatetime(A, B)           - match two struct arrays by .datetime
%
% OPTIONS (see plot_defaults.m)
%   opts.domain, opts.wind, opts.pres, opts.quiver, opts.coast,
%   opts.track, opts.radial, opts.mask, opts.anim, opts.export,
%   opts.time, opts.scatter, opts.timeseries, opts.diffmap
%
% EXAMPLE (Result struct)
%   R   = run_GAHM2026('config_GAHM2026_default');
%   obj = GAHM2026Plotter(R);
%   fig = obj.contourMap('mvelcon', 1, 5);
%   obj.radialProfile('velrad', {'envhur','env','trackdata'}, 1, 3);
%   obj.timeSeriesPlot({'Vmax','Pc','Rmax'}, 10);
%
% EXAMPLE (SeparateEnvHur)
%   obj = GAHM2026Plotter.fromSepEnvHur('separated.mat');
%   obj.contourMap('mvelcon', 1, 5);
%   obj.differenceMap(obj.EnvData, obj.HurData, 'speed', 2, 5);
%
%                Rick Luettich / UNC/IMS/CNHR/EMES
%                Brian Blanton / UNC/RENCI

    properties (SetAccess = private)
        Result      % normalized data struct
        Opts        % options struct from plot_defaults
        Source      % 'gahm' or 'sepenvhur'
    end

    properties (Dependent, SetAccess = private)
        PlotData    % default gridded TC fields (Reggrid_TC_out)
        DataGrid    % grid coordinates (Reggrid_out)
        Trackdata   % track data
        RadialGrid  % radial grid data (empty for sepenvhur source)
        EnvData     % environmental fields (Reggrid_Env_out)
        HurData     % hurricane-only fields (Reggrid_Hur_out, sepenvhur only)
        HasRadialGrid % true if radial grid data is available
    end

    methods

        function obj = GAHM2026Plotter(Result, opts, source)
        % Constructor.
        %   GAHM2026Plotter(Result)
        %   GAHM2026Plotter(Result, opts)
        %   GAHM2026Plotter(Result, opts, source)  — internal use by fromSepEnvHur

            obj.Result = Result;

            if nargin >= 3 && ~isempty(source)
                obj.Source = source;
            else
                obj.Source = 'gahm';
            end

            if nargin >= 2 && isstruct(opts)
                obj.Opts = opts;
            else
                obj.Opts = plot_defaults();
            end
        end

        %% Dependent-property getters

        function val = get.PlotData(obj)
            val = obj.Result.Reggrid_TC_out;
        end

        function val = get.DataGrid(obj)
            val = obj.Result.Reggrid_out;
        end

        function val = get.Trackdata(obj)
            val = obj.Result.Trackdata;
        end

        function val = get.RadialGrid(obj)
            if isfield(obj.Result, 'VPrad')
                val = obj.Result.VPrad;
            else
                val = [];
            end
        end

        function val = get.EnvData(obj)
            if isfield(obj.Result, 'Reggrid_Env_out')
                val = obj.Result.Reggrid_Env_out;
            else
                val = [];
            end
        end

        function val = get.HurData(obj)
            if isfield(obj.Result, 'Reggrid_Hur_out')
                val = obj.Result.Reggrid_Hur_out;
            else
                val = [];
            end
        end

        function val = get.HasRadialGrid(obj)
            val = isfield(obj.Result, 'VPrad') && ~isempty(obj.Result.VPrad);
        end

        %% Option helpers

        function setOpts(obj, group, field, value)
        % setOpts  Override a single option.
        %   obj.setOpts('wind', 'clims', [0 100])
            obj.Opts.(group).(field) = value;
        end

        function resetOpts(obj)
        % resetOpts  Restore all options to defaults.
            obj.Opts = plot_defaults();
        end

        %% Plotting methods (in separate files)

        fig = contourMap(obj, plotType, figNum, time, plotdata)
        addQuiver(obj, time, plotdata)
        radialProfile(obj, plotType, fieldType, figNum, time, theta_inc)
        fig = scatterCompare(obj, X, Y, figNum, titleStr, xlabelStr, ylabelStr, legendLabels)
        [idxA, idxB] = syncDatetime(obj, A, B)
        animate(obj, plotType, figNum, plotdata, filename)
        exportFigure(obj, fig, filename)

        % New methods
        fig = timeSeriesPlot(obj, fields, figNum)
        fig = differenceMap(obj, fieldA, fieldB, variable, figNum, time)
        metrics = computeMetrics(obj, X, Y, varName)

    end

    methods (Static)
        obj = fromSepEnvHur(sepfile, opts)
    end

    methods (Access = private)

        tidx = resolveTime(obj, time)
        tidx = resolveRadialTime(obj, time)
        [minX, maxX, minY, maxY] = getDomain(obj, datagrid, tidx)
        plotTrack(obj, Track, tidx, ntimes)
        plotMaskContours(obj, datagrid, tidx)
        captureGifFrame(obj, fig, tidx, istart, filename)
        vw = openMp4(obj, filename)

    end

end
