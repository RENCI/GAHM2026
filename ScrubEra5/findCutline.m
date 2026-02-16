function [count, in, distance] = findCutline( ...
        hr_u, hr_v, Xq, Yq, cx, cy, real_lon, real_lat, ...
        lonn, latt, wei, jing, wind_threshold, cfg)
    
    half = cfg.grid_half_size;
    num_radial = cfg.num_radial_points;
    max_search = num_radial / 10 * 6;
    
    start_dist = 2 * hypot(cx - real_lon, cy - real_lat);
    start_idx = max(100, round(start_dist / 10 * num_radial));
    
    count = zeros(24, 1);
    for j = 1:24
        angle_idx = j * 15;
        count(j) = start_idx;
        
        while count(j) < max_search
            count(j) = count(j) + 1;
            tan_wind = -hr_u(angle_idx, count(j)) * sin(angle_idx * pi/180) + ...
                        hr_v(angle_idx, count(j)) * cos(angle_idx * pi/180);
            if tan_wind < wind_threshold
                break
            end
        end
    end
    
    count = smoothCutline(count);
    count = ensureConvexCutline(count, Xq, Yq);
    
    [lon_newv, lat_newv] = extractCutlineCoords(count, Xq, Yq);
    lon_newv = lon_newv + cx;
    lat_newv = lat_newv + cy;
    lon_newv = [lon_newv, lon_newv(1)];
    lat_newv = [lat_newv, lat_newv(1)];
    
    [domain_lon, domain_lat] = meshgrid( ...
        lonn(jing-half : jing+half), ...
        latt(wei-half : wei+half));
    
    in = inpolygon(domain_lon(:), domain_lat(:), lon_newv', lat_newv');
    
    count_deg = count * 10 / cfg.num_radial_points;
    distance = computeDistanceKm(count_deg, real_lat);
end
