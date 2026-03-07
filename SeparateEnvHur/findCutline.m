function [count, in, distance] = findCutline( ...
        hr_u, hr_v, Xq, Yq, era5, track, CONFIG, i, wind_threshold)
    
    half = CONFIG.grid_half_size;
    num_radial = CONFIG.num_radial_points;
    max_search = num_radial / 10 * 6;
    
    cx = era5.vortex.lon(i);
    cy = era5.vortex.lat(i);
    start_dist = 2 * hypot(cx - track.lon(i), cy - track.lat(i));
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
    % move back to vortex center
    lon_newv = lon_newv + cx;
    lat_newv = lat_newv + cy;
    % close polygon
    lon_newv = [lon_newv, lon_newv(1)];
    lat_newv = [lat_newv, lat_newv(1)];
    
    [domain_lon, domain_lat] = meshgrid( ...
        era5.lon(track.lon_idx(i)-half : track.lon_idx(i)+half), ...
        era5.lat(track.lat_idx(i)-half : track.lat_idx(i)+half));
    
    in = inpolygon(domain_lon(:), domain_lat(:), lon_newv', lat_newv');
    
    count_deg = count * 10 / CONFIG.num_radial_points;
    distance = computeDistanceKm(count_deg, track.lat(i));
end
