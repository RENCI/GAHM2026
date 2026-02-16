function [cx, cy] = findPressureCenter(psl, lon, lat, wei, jing)
    search_range = 6;
    rows = wei-search_range : wei+search_range;
    cols = jing-search_range : jing+search_range;
    
    tem = psl(rows, cols);
    lowest = min(tem, [], "all");
    ind = find(tem == lowest, 1);
    
    temlon = lon(rows, cols);
    temlat = lat(rows, cols);
    
    cx = temlon(ind);
    cy = temlat(ind);
end
