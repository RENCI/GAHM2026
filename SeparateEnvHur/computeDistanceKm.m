function distance = computeDistanceKm(count_deg, ref_lat)
%computeDistanceKm Convert polar radii in degrees to distances in kilometers.
    KM_PER_DEG_LAT = 110.54;
    KM_PER_DEG_LON = 111.32;
    numAzimuthPoints = numel(count_deg);
    angleIncrement = 360/numAzimuthPoints;
    count_deg = count_deg(:)';
    distance = zeros(1, numAzimuthPoints);
    for j = 1:numAzimuthPoints
        theta = (j-1)*angleIncrement;
        dx = count_deg(j) * cosd(theta) * KM_PER_DEG_LON * cosd(ref_lat);
        dy = count_deg(j) * sind(theta) * KM_PER_DEG_LAT;
        distance(j) = hypot(dx, dy);
    end
end
