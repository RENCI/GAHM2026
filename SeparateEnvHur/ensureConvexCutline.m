function cutlineIdx = ensureConvexCutline(cutlineIdx, Xq, Yq, CONFIG)
    n_angle = CONFIG.num_azimuthal_points;
    [lon_newv, lat_newv] = extractCutlineCoords(cutlineIdx, Xq, Yq, CONFIG);
    bearing_flag = computeBearingFlag(lon_newv, lat_newv);

    ntrys = 1;
    limit = 500;

    while abs(bearing_flag) < n_angle
        if ntrys > limit
            logMsg(-1, "WARNING", "Unable to find convex cut line after %d tries", limit);
            break
        end
        cutlineIdx = applyCircularSmooth(cutlineIdx, CONFIG);
        [lon_newv, lat_newv] = extractCutlineCoords(cutlineIdx, Xq, Yq, CONFIG);
        bearing_flag = computeBearingFlag(lon_newv, lat_newv);
        ntrys = ntrys + 1;
    end
end
