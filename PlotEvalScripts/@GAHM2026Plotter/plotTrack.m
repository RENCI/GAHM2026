function plotTrack(obj, Tdata, ip, itot)
% plotTrack  Overlay storm track line on the current axes.

    opts = obj.Opts;

    if opts.track.progressive
        track = [Tdata(1:ip).Lon; Tdata(1:ip).Lat];
    else
        track = [Tdata(1:itot).Lon; Tdata(1:itot).Lat];
    end

    plot(track(1,:), track(2,:), '-', 'Color', opts.track.color, ...
        'LineWidth', opts.track.linewidth);

end
