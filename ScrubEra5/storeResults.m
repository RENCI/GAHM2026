function OUTPUT = storeResults(OUTPUT, i, lon, lat, basic_slp, basic_u, basic_v, ...
        psl, u, v, in, in_inner, distance_outer, distance_inner, LatIdx, LonIdx, CONFIG)
    
    half = CONFIG.output_half_size;
    rows = LatIdx-half : LatIdx+half;
    cols = LonIdx-half : LonIdx+half;
    grid_size = length(rows);
    
    OUTPUT.lon(i,:,:) = lon(rows, cols);
    OUTPUT.lat(i,:,:) = lat(rows, cols);
    OUTPUT.slp(i,:,:) = basic_slp(rows, cols);
    OUTPUT.u(i,:,:) = basic_u(rows, cols);
    OUTPUT.v(i,:,:) = basic_v(rows, cols);
    
    OUTPUT.dis_slp(i,:,:) = psl(rows, cols) - basic_slp(rows, cols);
    OUTPUT.dis_u(i,:,:) = u(rows, cols) - basic_u(rows, cols);
    OUTPUT.dis_v(i,:,:) = v(rows, cols) - basic_v(rows, cols);
    
    OUTPUT.mask(i,:,:) = reshape(in, [grid_size, grid_size]);
    OUTPUT.mask_inner(i,:,:) = reshape(in_inner, [grid_size, grid_size]);
    OUTPUT.distance_outer(i,:) = distance_outer;
    OUTPUT.distance_inner(i,:) = distance_inner;
end
