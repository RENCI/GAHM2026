function distance = computeDistanceKm(count_deg, ref_lat, CONFIG)
    KM_PER_DEG_LAT = 110.54;
    KM_PER_DEG_LON = 111.32;
    n_angle = CONFIG.num_azimuthal_points;
    angle_inc = 360/n_angle;

    distance = zeros(1, n_angle);
    for j = 1:n_angle
        theta = angle_inc * j;
        dx = count_deg(j) * cosd(theta) * KM_PER_DEG_LON * cosd(ref_lat);
        dy = count_deg(j) * sind(theta) * KM_PER_DEG_LAT;
        distance(j) = hypot(dx, dy);
    end
end
