function count = ensureConvexCutline(count, Xq, Yq)
    [lon_newv, lat_newv] = extractCutlineCoords(count, Xq, Yq);
    bearing_flag = computeBearingFlag(lon_newv, lat_newv);
    
    while abs(bearing_flag) < 24
        count = applyCircularSmooth(count);
        [lon_newv, lat_newv] = extractCutlineCoords(count, Xq, Yq);
        bearing_flag = computeBearingFlag(lon_newv, lat_newv);
    end
end
