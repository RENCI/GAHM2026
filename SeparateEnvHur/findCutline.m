function [cutline, isInsideOuter, distance] = findCutline( hr_u, hr_v, ...
                  Xq, Yq, era5, track, CONFIG, i, wind_threshold, Meanonly)

    half = round((CONFIG.output_grid_length/2)/CONFIG.dlonlat);
    num_radial = CONFIG.num_radial_points;
    max_search = CONFIG.output_grid_length/2;
    radial_inc = CONFIG.radial_inc;
    n_angle = CONFIG.num_azimuthal_points;
    angle_inc = 360/n_angle;
    isInsideOuter = 0;
    distance = zeros(n_angle,1);

    centerLon = era5.vortex.lon(i);
    centerLat = era5.vortex.lat(i);

    cutlineIdx1 = zeros(n_angle, 1);
    cutline.Idx = zeros(n_angle, 1);
    tan_wind_max_Idx = zeros(n_angle,1);
    cutline.found = 0;
    for j = 1:n_angle
        angle = j*angle_inc;
        tan_wind = -hr_u(j,:) * sind(angle) + hr_v(j,:) * cosd(angle);
        [tan_wind_max, tan_wind_max_Idx(j)]=max(tan_wind);
        cutlineIdx1(j) = 0;
        if tan_wind_max > wind_threshold
            if any(tan_wind(tan_wind_max_Idx(j):num_radial) < wind_threshold)                
                cutline.found = cutline.found + 1;
                cutlineIdx1(j) = tan_wind_max_Idx(j) - 1 + ...
                    find(tan_wind(tan_wind_max_Idx(j):num_radial) ...
                        < wind_threshold, 1, 'first');
            end
        end
    end

    if cutline.found == 0
        cutline.IdxMean = 1.5*mean(tan_wind_max_Idx);
    else
        cutline.IdxMean = mean(cutlineIdx1(cutlineIdx1~=0));
    end

    if ~Meanonly
        cutlineIdx1(cutlineIdx1==0) = cutline.IdxMean;
        cutlineIdx2 = smoothCutline(cutlineIdx1, CONFIG);
        cutline.Idx = ensureConvexCutline(cutlineIdx2, Xq, Yq, CONFIG);

        [lon_newv, lat_newv] = extractCutlineCoords(cutline.Idx, Xq, Yq, CONFIG);
        % move back to vortex center
        lon_newv = lon_newv + centerLon;
        lat_newv = lat_newv + centerLat;
        % close polygon
        lon_newv = [lon_newv, lon_newv(1)];
        lat_newv = [lat_newv, lat_newv(1)];

        [domain_lon, domain_lat] = meshgrid( ...
            era5.lon(track.lon_idx(i)-half : track.lon_idx(i)+half), ...
            era5.lat(track.lat_idx(i)-half : track.lat_idx(i)+half));

        isInsideOuter = inpolygon(domain_lon(:), domain_lat(:), ...
            lon_newv', lat_newv');

        count_deg = max_search * (cutline.Idx / num_radial);
        distance = computeDistanceKm(count_deg, track.lat(i), CONFIG);
    end
end
