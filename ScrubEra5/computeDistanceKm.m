function distance = computeDistanceKm(count_deg, ref_lat)
    distance = zeros(1, 24);
    for j = 1:24
        theta = 15 * j;
        dx = count_deg(j) * cosd(theta) * 110.54;
        dy = count_deg(j) * sind(theta) * 111.32 * cosd(ref_lat);
        distance(j) = hypot(dx, dy);
    end
end
