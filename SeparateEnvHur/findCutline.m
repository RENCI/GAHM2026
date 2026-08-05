function [cutlineIdx, isInsideOuter, distance] = findCutline( ...
        hr_u, hr_v, Xq, Yq, era5, track, CONFIG, i, wind_threshold)
%findCutline Find a bounded radial wind-threshold cutline.

    half = CONFIG.outputHalfWidth;
    [numAzimuthPoints, numRadialPoints] = size(hr_u);
    if ~isequal(size(hr_u), size(hr_v), size(Xq), size(Yq)) || ...
            numAzimuthPoints ~= CONFIG.numAzimuthPoints
        error("SeparateEnvHur:PolarDimensionMismatch", ...
            "Wind and coordinate polar arrays must have matching configured dimensions.");
    end
    rows = track.lat_idx(i)-half:track.lat_idx(i)+half;
    cols = track.lon_idx(i)-half:track.lon_idx(i)+half;
    if rows(1) < 1 || rows(end) > numel(era5.lat) || ...
            cols(1) < 1 || cols(end) > numel(era5.lon)
        error("SeparateEnvHur:OutputDomainOutOfBounds", ...
            "The configured output domain extends beyond the source grid.");
    end
    maxSearchIndex = numRadialPoints;

    centerLon = era5.vortex.lon(i);
    centerLat = era5.vortex.lat(i);
    start_dist = 2 * hypot(centerLon - track.lon(i), centerLat - track.lat(i));
    MIN_START_DEG = 1;
    minStartIndex = round(MIN_START_DEG/CONFIG.radialIncrementDegrees) + 1;
    startIndex = max(minStartIndex, ...
        round(start_dist/CONFIG.radialIncrementDegrees) + 1);
    startIndex = min(max(startIndex, 1), maxSearchIndex);

    cutlineIdx = zeros(numAzimuthPoints, 1);
    angleIncrement = 360/numAzimuthPoints;
    for j = 1:numAzimuthPoints
        angle = (j-1)*angleIncrement;
        cutlineIdx(j) = startIndex;

        while cutlineIdx(j) <= maxSearchIndex
            tan_wind = -hr_u(j, cutlineIdx(j))*sind(angle) + ...
                        hr_v(j, cutlineIdx(j))*cosd(angle);
            if isnan(tan_wind) || tan_wind < wind_threshold
                break
            end
            if cutlineIdx(j) == maxSearchIndex
                break
            end
            cutlineIdx(j) = cutlineIdx(j) + 1;
        end
    end

    cutlineIdx = smoothCutline(cutlineIdx, CONFIG.isotach_smooth_variance, ...
        numAzimuthPoints, CONFIG.num_points_smoother);
    cutlineIdx = ensureConvexCutline(cutlineIdx, Xq, Yq, ...
        numAzimuthPoints, CONFIG.num_points_smoother);

    [lon_newv, lat_newv] = extractCutlineCoords(cutlineIdx, Xq, Yq);
    % move back to vortex center
    lon_newv = lon_newv + centerLon;
    lat_newv = lat_newv + centerLat;
    % close polygon
    lon_newv = [lon_newv, lon_newv(1)];
    lat_newv = [lat_newv, lat_newv(1)];

    [domain_lon, domain_lat] = meshgrid(era5.lon(cols), era5.lat(rows));

    isInsideOuter = inpolygon(domain_lon(:), domain_lat(:), lon_newv', lat_newv');

    count_deg = (cutlineIdx-1)*CONFIG.radialIncrementDegrees;
    distance = computeDistanceKm(count_deg, track.lat(i));
end
