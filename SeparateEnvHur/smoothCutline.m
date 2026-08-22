function cutlineIdx = smoothCutline(cutlineIdx, CONFIG)
% NOTE (v1.5 behavior, ported verbatim): this loop has no iteration cap.
% See "Known v1.5 defects" in DECISIONS.md.
    var_last = 0;
    var_now = var(cutlineIdx);
    var_lim = CONFIG.isotach_smooth_variance;

    while abs(var_now - var_last) > var_lim
        cutlineIdx = applyCircularSmooth(cutlineIdx, CONFIG);
        var_last = var_now;
        var_now = var(cutlineIdx);
    end
end
