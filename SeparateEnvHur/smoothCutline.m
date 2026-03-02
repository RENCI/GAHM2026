function count = smoothCutline(count)
    var_last = 0;
    var_now = var(count);
    
    while abs(var_now - var_last) > 2000
        count = applyCircularSmooth(count);
        var_last = var_now;
        var_now = var(count);
    end
end
