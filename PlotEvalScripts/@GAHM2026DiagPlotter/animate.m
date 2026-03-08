function animate(obj, plotType, figNum, plotdata, filename)
% animate  Generate GIF and/or MP4 animation of contour maps over all timesteps.
%
%   obj.animate(plotType, figNum)
%   obj.animate(plotType, figNum, plotdata)
%   obj.animate(plotType, figNum, plotdata, filename)
%
%   Loops over all timesteps, calling contourMap for each frame, and
%   captures to GIF and/or MP4 according to opts.anim settings.
%
%   plotType    - 'velcon', 'precon', 'prequiv', 'mvelcon', or 'mprecon'
%   figNum    - figure number (reused each frame)
%   plotdata - (optional) gridded field struct array; defaults to
%              Result.Reggrid_TC_out
%   filename - (optional) base filename without extension; defaults to
%              'GAHM_V' for velocity types, 'GAHM_P' for pressure types
%
%   Uses opts.anim.gif, opts.anim.mp4, opts.anim.frameRate to control
%   which outputs are produced and their timing.

    if nargin < 4 || isempty(plotdata), plotdata = obj.PlotData; end

    isVel = strcmp(plotType,'velcon') || strcmp(plotType,'mvelcon');
    isPQ  = strcmp(plotType,'prequiv');
    if nargin < 5 || isempty(filename)
        if isVel
            filename = 'GAHM_V';
        elseif isPQ
            filename = 'GAHM_PQ';
        else
            filename = 'GAHM_P';
        end
    end

    opts = obj.Opts;
    ntimes = length(plotdata);

    gifFile = fullfile(opts.export.dir,string(filename)+".gif");
    mp4File = fullfile(opts.export.dir,string(filename)+".mp4");

    vw = [];
    if opts.anim.mp4
        vw = openMp4(obj, mp4File);
    end

    for tidx = 1:ntimes
        fig = contourMap(obj, plotType, figNum, tidx, plotdata);
        drawnow

        if opts.anim.gif
            captureGifFrame(obj, fig, tidx, 1, gifFile);
        end

        if opts.anim.mp4
            writeVideo(vw, getframe(fig));
        end
    end

    if opts.anim.mp4 && ~isempty(vw)
        close(vw);
    end

    if opts.anim.gif
        fprintf('GIF saved: %s\n', gifFile);
    end
    if opts.anim.mp4
        fprintf('MP4 saved: %s\n', mp4File);
    end

end
