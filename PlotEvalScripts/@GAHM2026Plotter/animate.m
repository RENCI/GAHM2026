function animate(obj, ptype, fign, plotdata, filename)
% animate  Generate GIF and/or MP4 animation of contour maps over all timesteps.
%
%   obj.animate(ptype, fign)
%   obj.animate(ptype, fign, plotdata)
%   obj.animate(ptype, fign, plotdata, filename)
%
%   Loops over all timesteps, calling contourMap for each frame, and
%   captures to GIF and/or MP4 according to opts.anim settings.
%
%   ptype    - 'velcon', 'precon', 'prequiv', 'mvelcon', or 'mprecon'
%   fign    - figure number (reused each frame)
%   plotdata - (optional) gridded field struct array; defaults to
%              Result.Reggrid_TC_out
%   filename - (optional) base filename without extension; defaults to
%              'GAHM_V' for velocity types, 'GAHM_P' for pressure types
%
%   Uses opts.anim.gif, opts.anim.mp4, opts.anim.frameRate to control
%   which outputs are produced and their timing.

    if nargin < 4 || isempty(plotdata), plotdata = obj.PlotData; end

    isVel = strcmp(ptype,'velcon') || strcmp(ptype,'mvelcon');
    isPQ  = strcmp(ptype,'prequiv');
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
    itot = length(plotdata);

    gifFile = fullfile(opts.export.dir,string(filename)+".gif");
    mp4File = fullfile(opts.export.dir,string(filename)+".mp4");

    vw = [];
    if opts.anim.mp4
        vw = openMp4(obj, mp4File);
    end

    for ip = 1:itot
        fig = contourMap(obj, ptype, fign, ip, plotdata);
        drawnow

        if opts.anim.gif
            captureGifFrame(obj, fig, ip, 1, gifFile);
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
