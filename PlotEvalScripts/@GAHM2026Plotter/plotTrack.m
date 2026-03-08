function plotTrack(obj, Track, tidx, ntimes)
% plotTrack  Overlay storm track line on the current axes.

    opts = obj.Opts;

    if opts.track.progressive
        track = [Track(1:tidx).Lon; Track(1:tidx).Lat];
    else
        track = [Track(1:ntimes).Lon; Track(1:ntimes).Lat];
    end

    plot(track(1,:), track(2,:), '-', 'Color', opts.track.color, ...
        'LineWidth', opts.track.linewidth);

end
