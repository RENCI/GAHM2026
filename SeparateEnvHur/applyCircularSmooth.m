function cutlineIdx = applyCircularSmooth(cutlineIdx, CONFIG)
    n_angle = CONFIG.num_azimuthal_points;
    n_pts = CONFIG.num_points_smoother;
    % cutlineIdx is a column vector; triple it so the moving mean wraps
    tripled = [cutlineIdx; cutlineIdx; cutlineIdx];
    tripled = movmean(tripled, n_pts);
    cutlineIdx = tripled(n_angle+1 : 2*n_angle);
end
