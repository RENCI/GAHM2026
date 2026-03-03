function [cx, cy] = findPressureCenter(era5, track, i)
    search_range = track.search_range;
    rows = track.lat_idx(i)-search_range : track.lat_idx(i)+search_range;
    cols = track.lon_idx(i)-search_range : track.lon_idx(i)+search_range;
    
    psl = squeeze(era5.msl(:,:,i))' / 100;  % convert from Pa to mb
    tem = psl(rows, cols);
    lowest = min(tem, [], "all");
    ind = find(tem == lowest, 1);
    
    temlon = era5.lon_grid(rows, cols);
    temlat = era5.lat_grid(rows, cols);
    
    cx = temlon(ind);
    cy = temlat(ind);
end
