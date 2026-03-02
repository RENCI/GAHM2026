function [cx, cy] = findPressureCenter(psl, lon, lat, LatIdx, LonIdx)
    search_range = 6;
    rows = LatIdx-search_range : LatIdx+search_range;
    cols = LonIdx-search_range : LonIdx+search_range;
    
    tem = psl(rows, cols);
    lowest = min(tem, [], "all");
    ind = find(tem == lowest, 1);
    
    temlon = lon(rows, cols);
    temlat = lat(rows, cols);
    
    cx = temlon(ind);
    cy = temlat(ind);
end
