function [lon_v, lat_v] = extractCutlineCoords(cutlineIdx, Xq, Yq)
%extractCutlineCoords Extract one cutline coordinate from each polar row.
    [numAzimuthPoints, numRadialPoints] = size(Xq);
    if ~isequal(size(Xq), size(Yq)) || numel(cutlineIdx) ~= numAzimuthPoints
        error("SeparateEnvHur:PolarDimensionMismatch", ...
            "Polar grids and the cutline must have matching azimuth dimensions.");
    end
    lon_v = zeros(1, numAzimuthPoints);
    lat_v = zeros(1, numAzimuthPoints);
    for j = 1:numAzimuthPoints
        idx = min(max(round(cutlineIdx(j)), 1), numRadialPoints);
        lon_v(j) = Xq(j, idx);
        lat_v(j) = Yq(j, idx);
    end
end
