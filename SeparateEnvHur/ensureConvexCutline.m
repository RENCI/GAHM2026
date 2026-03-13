function cutlineIdx = ensureConvexCutline(cutlineIdx, Xq, Yq)
    [lon_newv, lat_newv] = extractCutlineCoords(cutlineIdx, Xq, Yq);
    bearing_flag = computeBearingFlag(lon_newv, lat_newv);

    while abs(bearing_flag) < 24
        cutlineIdx = applyCircularSmooth(cutlineIdx);
        [lon_newv, lat_newv] = extractCutlineCoords(cutlineIdx, Xq, Yq);
        bearing_flag = computeBearingFlag(lon_newv, lat_newv);
    end
end
