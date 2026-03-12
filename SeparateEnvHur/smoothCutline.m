function cutlineIdx = smoothCutline(cutlineIdx)
    VARIANCE_TOL = 2000;
    MAX_ITER = 200;
    var_last = 0;
    var_now = var(cutlineIdx);
    
    iter = 0;
    while abs(var_now - var_last) > VARIANCE_TOL && iter < MAX_ITER
        cutlineIdx = applyCircularSmooth(cutlineIdx);
        var_last = var_now;
        var_now = var(cutlineIdx);
        iter = iter + 1;
    end
end
