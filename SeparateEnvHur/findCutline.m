function [cutlineIdx, isInsideOuter, distance] = findCutline( ...
        hr_u, hr_v, Xq, Yq, era5, track, CONFIG, i, wind_threshold)

    half = CONFIG.grid_half_size;
    num_radial = CONFIG.num_radial_points;
    max_search = round(num_radial / CONFIG.max_radius_deg * 6);

    centerLon = era5.vortex.lon(i);
    centerLat = era5.vortex.lat(i);
    start_dist = 2 * hypot(centerLon - track.lon(i), centerLat - track.lat(i));
    MIN_START_DEG = 1;
    min_start_idx = round(MIN_START_DEG / CONFIG.max_radius_deg * num_radial);
    start_idx = max(min_start_idx, round(start_dist / CONFIG.max_radius_deg * num_radial));

    cutlineIdx = zeros(24, 1);
    for j = 1:24
        angle_idx = j * 15;
        cutlineIdx(j) = start_idx;

        while cutlineIdx(j) < max_search
            cutlineIdx(j) = cutlineIdx(j) + 1;
            tan_wind = -hr_u(angle_idx, cutlineIdx(j)) * sin(angle_idx * pi/180) + ...
                        hr_v(angle_idx, cutlineIdx(j)) * cos(angle_idx * pi/180);
            if isnan(tan_wind) || tan_wind < wind_threshold
                break
            end
        end
    end
    cutlineIdx = min(cutlineIdx, num_radial);

    cutlineIdx = smoothCutline(cutlineIdx);
    cutlineIdx = ensureConvexCutline(cutlineIdx, Xq, Yq);

    [lon_newv, lat_newv] = extractCutlineCoords(cutlineIdx, Xq, Yq);
    % move back to vortex center
    lon_newv = lon_newv + centerLon;
    lat_newv = lat_newv + centerLat;
    % close polygon
    lon_newv = [lon_newv, lon_newv(1)];
    lat_newv = [lat_newv, lat_newv(1)];

    [domain_lon, domain_lat] = meshgrid( ...
        era5.lon(track.lon_idx(i)-half : track.lon_idx(i)+half), ...
        era5.lat(track.lat_idx(i)-half : track.lat_idx(i)+half));

    isInsideOuter = inpolygon(domain_lon(:), domain_lat(:), lon_newv', lat_newv');

    count_deg = cutlineIdx * CONFIG.max_radius_deg / CONFIG.num_radial_points;
    distance = computeDistanceKm(count_deg, track.lat(i));
end
