function distance = computeDistanceKm(count_deg, ref_lat)
    KM_PER_DEG_LAT = 110.54;
    KM_PER_DEG_LON = 111.32;
    distance = zeros(1, 24);
    for j = 1:24
        theta = 15 * j;
        dx = count_deg(j) * cosd(theta) * KM_PER_DEG_LON * cosd(ref_lat);
        dy = count_deg(j) * sind(theta) * KM_PER_DEG_LAT;
        distance(j) = hypot(dx, dy);
    end
end
