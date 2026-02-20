function [basic_slp, basic_u, basic_v] = computeBasicField(psl, u, v, LatIdx, LonIdx, tem_ave_r, CONFIG)
    half = CONFIG.filter_domain_size;
    rows = LatIdx-half : LatIdx+half;
    cols = LonIdx-half : LonIdx+half;
    
    half_power_wl = tem_ave_r / 0.04;
    d1 = designfilt('lowpassiir', ...
        'FilterOrder', 5, ...
        'HalfPowerFrequency', 1/half_power_wl, ...
        'DesignMethod', 'butter', ...
        'SampleRate', 4);
    
    ave_slp = mean(psl(rows, cols), 'all');
    ave_u = mean(u(rows, cols), 'all');
    ave_v = mean(v(rows, cols), 'all');
    
    basic_slp = applyButterworthFilter2D(psl - ave_slp, d1, rows, cols) + ave_slp;
    basic_u = applyButterworthFilter2D(u - ave_u, d1, rows, cols) + ave_u;
    basic_v = applyButterworthFilter2D(v - ave_v, d1, rows, cols) + ave_v;
end
