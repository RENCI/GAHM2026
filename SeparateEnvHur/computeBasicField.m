function basic = computeBasicField(psl, u, v, track, CONFIG, i, filterRadiusDegrees)
%computeBasicField Compute low-pass environmental pressure and wind fields.
    half = CONFIG.filterHalfWidth;
    rows = track.lat_idx(i)-half : track.lat_idx(i)+half;
    cols = track.lon_idx(i)-half : track.lon_idx(i)+half;
    if rows(1) < 1 || rows(end) > size(psl, 1) || cols(1) < 1 || cols(end) > size(psl, 2)
        error("SeparateEnvHur:FilterDomainOutOfBounds", ...
            "The configured filter domain extends beyond the source grid.");
    end

    FILTER_ORDER = 5;
    sampleRate = 1/CONFIG.gridSpacingDegrees;
    halfPowerWavelength = filterRadiusDegrees*CONFIG.filter_hp_multiplier;
    lowpassFilter = designfilt('lowpassiir', ...
                    'FilterOrder', FILTER_ORDER, ...
                    'HalfPowerFrequency', 1/halfPowerWavelength, ...
                    'DesignMethod', 'butter', ...
                    'SampleRate', sampleRate);

    ave_slp = mean(psl(rows, cols), 'all');
    ave_u = mean(u(rows, cols), 'all');
    ave_v = mean(v(rows, cols), 'all');

    basic.slp = applyButterworthFilter2D(psl-ave_slp, lowpassFilter, rows, cols)+ave_slp;
    basic.u = applyButterworthFilter2D(u-ave_u, lowpassFilter, rows, cols)+ave_u;
    basic.v = applyButterworthFilter2D(v-ave_v, lowpassFilter, rows, cols)+ave_v;
end
