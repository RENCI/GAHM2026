function flag = computeBearingFlag(lon_v, lat_v)
    n = length(lon_v);
    vec_lon = [diff(lon_v), lon_v(1) - lon_v(n)];
    vec_lat = [diff(lat_v), lat_v(1) - lat_v(n)];

    cross_prod = zeros(1, n);
    for j = 1:n
        next_j = mod(j, n) + 1;
        cross_prod(j) = vec_lon(j) * vec_lat(next_j) - vec_lon(next_j) * vec_lat(j);
    end

    flag = sum(sign(cross_prod));
end
