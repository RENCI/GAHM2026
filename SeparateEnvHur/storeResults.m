function OUTPUT = storeResults(OUTPUT, i, era5, track, CONFIG, ...
        basic, psl, u, v, ...
        isInsideOuter, isInsideInner, distance_outer, distance_inner)

    half = round((CONFIG.output_grid_length/2)/CONFIG.dlonlat);
    rows = track.lat_idx(i)-half : track.lat_idx(i)+half;
    cols = track.lon_idx(i)-half : track.lon_idx(i)+half;
    grid_size = length(rows);

    OUTPUT.lon(i,:,:) = era5.lon_grid(rows, cols);
    OUTPUT.lat(i,:,:) = era5.lat_grid(rows, cols);
    OUTPUT.slp(i,:,:) = basic.slp(rows, cols);
    OUTPUT.u(i,:,:) = basic.u(rows, cols);
    OUTPUT.v(i,:,:) = basic.v(rows, cols);

    OUTPUT.dis_slp(i,:,:) = psl(rows, cols) - basic.slp(rows, cols);
    OUTPUT.dis_u(i,:,:) = u(rows, cols) - basic.u(rows, cols);
    OUTPUT.dis_v(i,:,:) = v(rows, cols) - basic.v(rows, cols);

    OUTPUT.mask_outer(i,:,:) = reshape(isInsideOuter, [grid_size, grid_size]);
    OUTPUT.mask_inner(i,:,:) = reshape(isInsideInner, [grid_size, grid_size]);
    OUTPUT.distance_outer(i,:) = distance_outer;
    OUTPUT.distance_inner(i,:) = distance_inner;
end
