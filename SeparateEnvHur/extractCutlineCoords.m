function [lon_v, lat_v] = extractCutlineCoords(cutlineIdx, Xq, Yq)
    lon_v = zeros(1, 24);
    lat_v = zeros(1, 24);
    for j = 1:24
        idx = round(cutlineIdx(j));
        lon_v(j) = Xq(j*15, idx);
        lat_v(j) = Yq(j*15, idx);
    end
end
