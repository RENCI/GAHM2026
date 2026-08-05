function cutlineIdx = smoothCutline( ...
        cutlineIdx, varianceTolerance, numAzimuthPoints, smoothingWidth)
%smoothCutline Smooth until variance stabilizes or the iteration limit is reached.
    MAX_ITER = 200;
    var_last = 0;
    var_now = var(cutlineIdx);

    iter = 0;
    while abs(var_now - var_last) > varianceTolerance && iter < MAX_ITER
        cutlineIdx = applyCircularSmooth(cutlineIdx, numAzimuthPoints, smoothingWidth);
        var_last = var_now;
        var_now = var(cutlineIdx);
        iter = iter + 1;
    end
end
