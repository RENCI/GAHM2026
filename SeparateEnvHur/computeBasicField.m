function basic = computeBasicField(psl, u, v, track, CONFIG, i, meanFilterRadiusDeg)
% The filter domain and sample rate are derived from the physical grid
% spacing (CONFIG.dlonlat) rather than being fixed numbers of grid cells,
% so the filter behaves consistently for any input grid resolution.
    half = round((CONFIG.filter_grid_length/2)/CONFIG.dlonlat);
    rows = track.lat_idx(i)-half : track.lat_idx(i)+half;
    cols = track.lon_idx(i)-half : track.lon_idx(i)+half;

    FILTER_ORDER = 5;
    half_power_wl = CONFIG.filter_hp_multiplier * meanFilterRadiusDeg;
    lowpassFilter = designfilt('lowpassiir', ...
                    'FilterOrder', FILTER_ORDER, ...
                    'HalfPowerFrequency', 1/half_power_wl, ...
                    'DesignMethod', 'butter', ...
                    'SampleRate', 1/CONFIG.dlonlat);

    ave_slp = mean(psl(rows, cols), 'all');
    ave_u = mean(u(rows, cols), 'all');
    ave_v = mean(v(rows, cols), 'all');

    basic.slp = applyButterworthFilter2D(psl-ave_slp, lowpassFilter, rows, cols)+ave_slp;
    basic.u = applyButterworthFilter2D(u-ave_u, lowpassFilter, rows, cols)+ave_u;
    basic.v = applyButterworthFilter2D(v-ave_v, lowpassFilter, rows, cols)+ave_v;
end
