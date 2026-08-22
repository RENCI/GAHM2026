function [cutlineIdx, isInsideOuter, distance] = findCutline( ...
        hr_u, hr_v, Xq, Yq, era5, track, CONFIG, i, wind_threshold)

    half = round((CONFIG.output_grid_length/2)/CONFIG.dlonlat);
    num_radial = CONFIG.num_radial_points;
    max_search = CONFIG.output_grid_length/2;
    radial_inc = CONFIG.radial_inc;
    n_angle = CONFIG.num_azimuthal_points;
    angle_inc = 360/n_angle;

    centerLon = era5.vortex.lon(i);
    centerLat = era5.vortex.lat(i);

    % Attempt to jump past the rising limb of the wind field (i.e., the RMW)
    % and only search the falling limb.  If start_idx = 100 and
    % radial_inc = 0.01 deg, this skips at least the inner 1 deg (~100 km).
    start_dist = 2 * hypot(centerLon - track.lon(i), centerLat - track.lat(i));
    min_idx = 1/radial_inc;  % skip at least the inner 1 deg
    start_idx = max(min_idx, round(start_dist/max_search * num_radial));

    cutlineIdx = zeros(n_angle, 1);
    for j = 1:n_angle
        cutlineIdx(j) = start_idx;
        angle = j*angle_inc;

        while cutlineIdx(j) < num_radial
            cutlineIdx(j) = cutlineIdx(j) + 1;
            tan_wind = -hr_u(j, cutlineIdx(j)) * sind(angle) + ...
                        hr_v(j, cutlineIdx(j)) * cosd(angle);
            if tan_wind < wind_threshold
                break
            end
        end
    end

    cutlineIdx = smoothCutline(cutlineIdx, CONFIG);
    cutlineIdx = ensureConvexCutline(cutlineIdx, Xq, Yq, CONFIG);

    [lon_newv, lat_newv] = extractCutlineCoords(cutlineIdx, Xq, Yq, CONFIG);
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

    count_deg = max_search * (cutlineIdx / CONFIG.num_radial_points);
    distance = computeDistanceKm(count_deg, track.lat(i), CONFIG);
end
