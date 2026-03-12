function basic = computeBasicField(psl, u, v, track, CONFIG, i, meanInnerRadiusDeg)
    half = CONFIG.filter_domain_size;
    rows = track.lat_idx(i)-half : track.lat_idx(i)+half;
    cols = track.lon_idx(i)-half : track.lon_idx(i)+half;
    
    FILTER_RADIUS_SCALE = 0.04;
    FILTER_ORDER = 5;
    SAMPLE_RATE = 4;
    half_power_wl = meanInnerRadiusDeg / FILTER_RADIUS_SCALE;
    lowpassFilter = designfilt('lowpassiir', ...
                    'FilterOrder', FILTER_ORDER, ...
                    'HalfPowerFrequency', 1/half_power_wl, ...
                    'DesignMethod', 'butter', ...
                    'SampleRate', SAMPLE_RATE);
    
    ave_slp = mean(psl(rows, cols), 'all');
    ave_u = mean(u(rows, cols), 'all');
    ave_v = mean(v(rows, cols), 'all');
    
    basic.slp = applyButterworthFilter2D(psl-ave_slp, lowpassFilter, rows, cols)+ave_slp;
    basic.u = applyButterworthFilter2D(u-ave_u, lowpassFilter, rows, cols)+ave_u;
    basic.v = applyButterworthFilter2D(v-ave_v, lowpassFilter, rows, cols)+ave_v;
end
