function [centerLon, centerLat] = findPressureCenter(era5, track, i)
    search_range = track.search_range;
    rows = track.lat_idx(i)-search_range : track.lat_idx(i)+search_range;
    cols = track.lon_idx(i)-search_range : track.lon_idx(i)+search_range;
    
    PA2MB = 0.01;
    psl = squeeze(era5.msl(:,:,i))' * PA2MB;
    localPsl = psl(rows, cols);
    lowest = min(localPsl, [], "all");
    ind = find(localPsl == lowest, 1);
    
    localLon = era5.lon_grid(rows, cols);
    localLat = era5.lat_grid(rows, cols);
    
    centerLon = localLon(ind);
    centerLat = localLat(ind);
end
