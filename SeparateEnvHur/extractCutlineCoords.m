function [lon_v, lat_v] = extractCutlineCoords(cutlineIdx, Xq, Yq, CONFIG)
    n_angle = CONFIG.num_azimuthal_points;
    lon_v = zeros(1, n_angle);
    lat_v = zeros(1, n_angle);
    for j = 1:n_angle
        idx = round(cutlineIdx(j));
        lon_v(j) = Xq(j, idx);
        lat_v(j) = Yq(j, idx);
    end
end
