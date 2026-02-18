function animate(obj, ptype, nplot, plotdata, filename)
% animate  Generate GIF and/or MP4 animation of contour maps over all timesteps.
%
%   obj.animate(ptype, nplot)
%   obj.animate(ptype, nplot, plotdata)
%   obj.animate(ptype, nplot, plotdata, filename)
%
%   Loops over all timesteps, calling contourMap for each frame, and
%   captures to GIF and/or MP4 according to opts.anim settings.
%
%   ptype    - 'velcon', 'precon', 'mvelcon', or 'mprecon'
%   nplot    - figure number (reused each frame)
%   plotdata - (optional) gridded field struct array; defaults to
%              Result.Reggrid_TC_out
%   filename - (optional) base filename without extension; defaults to
%              'GAHM_V' for velocity types, 'GAHM_P' for pressure types
%
%   Uses opts.anim.gif, opts.anim.mp4, opts.anim.frameRate to control
%   which outputs are produced and their timing.

    if nargin < 4 || isempty(plotdata), plotdata = obj.PlotData; end

    isVel = strcmp(ptype,'velcon') || strcmp(ptype,'mvelcon');
    if nargin < 5 || isempty(filename)
        if isVel
            filename = 'GAHM_V';
        else
            filename = 'GAHM_P';
        end
    end

    opts = obj.Opts;
    itot = length(plotdata);

    gifFile = [filename '.gif'];
    mp4File = [filename '.mp4'];

    vw = [];
    if opts.anim.mp4
        vw = openMp4(obj, mp4File);
    end

    for ip = 1:itot
        fig = contourMap(obj, ptype, nplot, ip, plotdata);
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
