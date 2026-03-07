classdef GAHM2026Plotter < handle
% GAHM2026Plotter  Plotting and evaluation class for GAHM2026 output.
%
%   obj = GAHM2026Plotter(Result)
%   obj = GAHM2026Plotter(Result, opts)
%
%   Result is the struct returned by run_GAHM2026, containing:
%     .Reggrid_out, .Reggrid_TC_out, .Reggrid_Env_out,
%     .Reggrid_VVor_invtapHur_out, .Trackdata, .GAHM_out, .VPrad,
%     .storm_info, .env_info
%     and optionally .Points_TC_out, .Points_Env_out (for point output)
%
% PLOTTING METHODS
%   contourMap(ptype, fign, time, plotdata)
%       Contour map (pcolor) of wind speed or pressure at one timestep.
%       ptype: 'velcon','precon','prequiv','mvelcon','mprecon'
%       time:  integer index, datetime, or [] (default 1)
%
%   addQuiver(time, plotdata)
%       Overlay velocity vectors on the current axes at one timestep.
%
%   radialProfile(ptype, fign, time, theta_inc)
%       Radial profiles of wind or pressure at one timestep in subplots.
%       ptype: 'velrad' or 'prerad'
%
%   scatterCompare(X, Y, fign, titleStr, xlabelStr, ylabelStr, legendLabels)
%       1:1 scatter plot.  N×4 → by-quadrant; N×K → by-series.
%
%   animate(ptype, fign, plotdata, filename)
%       GIF/MP4 animation over all timesteps via contourMap.
%
%   exportFigure(fig, filename)
%       Save a figure to PNG or PDF using opts.export settings.
%
% UTILITY METHODS
%   setOpts(group, field, value) — override a single option
%   resetOpts()                  — restore all defaults
%   syncDatetime(A, B)           — match two struct arrays by .datetime
%
% OPTIONS (see plot_defaults.m)
%   opts.domain   — .mode, .padDeg, .fixedLimits
%   opts.wind     — .clims, .alpha, .colormap
%   opts.pres     — .clims, .alpha, .colormap
%   opts.quiver   — .stride, .scale, .color
%   opts.coast    — .show, .color, .linewidth
%   opts.track    — .color, .linewidth, .progressive
%   opts.radial   — .isotachs, .one2ten, .layout
%   opts.mask     — .show, .color, .linewidth
%   opts.anim     — .gif, .mp4, .frameRate
%   opts.export   — .dir, .format, .dpi
%   opts.time     — .format
%
% EXAMPLE
%   R   = run_GAHM2026('config_GAHM2026_default');
%   obj = GAHM2026Plotter(R);
%
%   % single-frame contour map at timestep 5
%   fig = obj.contourMap('mvelcon', 1, 5);
%   obj.exportFigure(fig, 'Helene_wind_t5');
%
%   % animate all timesteps
%   obj.animate('mvelcon', 1);
%
%   % radial velocity profiles at timestep 3
%   obj.radialProfile('velrad', 20, 3);
%
%   % scatter comparison
%   obj.scatterCompare(X, Y, 1, 'Rmax 34kt', 'GAHM (nm)', 'ASWIP (nm)');
%
%                Rick Luettich / UNC/IMS/CNHR/EMES
%                Brian Blanton / UNC/RENCI

    properties (SetAccess = private)
        Result      % full Result struct from run_GAHM2026
        Opts        % options struct from plot_defaults
    end

    % Convenience dependent properties — avoid deep dot-indexing everywhere
    properties (Dependent, SetAccess = private)
        PlotData    % Result.Reggrid_TC_out  (default gridded TC fields)
        DataGrid    % Result.Reggrid_out
        Trackdata   % Result.Trackdata
        VPrad       % Result.VPrad
    end

    methods

        function obj = GAHM2026Plotter(Result, opts)
        % Constructor.
        %   GAHM2026Plotter(Result)
        %   GAHM2026Plotter(Result, opts)

            obj.Result = Result;

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

        function val = get.VPrad(obj)
            val = obj.Result.VPrad;
        end

        %% Option helpers

        function setOpts(obj, group, field, value)
        % setOpts  Override a single option.
        %   obj.setOpts('wind', 'clims', [0 100])
        %   obj.setOpts('anim', 'gif', false)

            obj.Opts.(group).(field) = value;
        end

        function resetOpts(obj)
        % resetOpts  Restore all options to defaults.

            obj.Opts = plot_defaults();
        end

        %% Plotting methods (in separate files)

        fig = contourMap(obj, ptype, fign, time, plotdata)
        addQuiver(obj, time, plotdata)
        radialProfile(obj, ptype, ftype, fign, time, theta_inc)
        fig = scatterCompare(obj, X, Y, fign, titleStr, xlabelStr, ylabelStr, legendLabels)
        [idxA, idxB] = syncDatetime(obj, A, B)
        animate(obj, ptype, fign, plotdata, filename)
        exportFigure(obj, fig, filename)

    end

    methods (Access = private)

        ip = resolveTime(obj, time)
        ip = resolveRadialTime(obj, time)
        [minX, maxX, minY, maxY] = getDomain(obj, datagrid, ip)
        plotTrack(obj, Tdata, ip, itot)
        plotMaskContours(obj, datagrid, ip)
        captureGifFrame(obj, fig, ip, istart, filename)
        vw = openMp4(obj, filename)

    end

end
