function cutlineIdx = ensureConvexCutline( ...
        cutlineIdx, Xq, Yq, numAzimuthPoints, smoothingWidth)
%ensureConvexCutline Smooth a cutline toward convexity with bounded work.
    MAX_ITER = 200;
    [lon_newv, lat_newv] = extractCutlineCoords(cutlineIdx, Xq, Yq);
    bearing_flag = computeBearingFlag(lon_newv, lat_newv);

    iteration = 0;
    while abs(bearing_flag) < numAzimuthPoints && iteration < MAX_ITER
        cutlineIdx = applyCircularSmooth(cutlineIdx, numAzimuthPoints, smoothingWidth);
        [lon_newv, lat_newv] = extractCutlineCoords(cutlineIdx, Xq, Yq);
        bearing_flag = computeBearingFlag(lon_newv, lat_newv);
        iteration = iteration + 1;
    end
end
