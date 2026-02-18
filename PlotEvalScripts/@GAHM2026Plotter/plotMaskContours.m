function plotMaskContours(obj, datagrid, ip)
% plotMaskContours  Overlay inner and outer mask boundary contours.

    opts = obj.Opts;

    contour(datagrid(ip).Lon, datagrid(ip).Lat, datagrid(ip).Mask1, 1, ...
        opts.mask.color, 'LineWidth', opts.mask.linewidth)
    contour(datagrid(ip).Lon, datagrid(ip).Lat, datagrid(ip).Mask2, 1, ...
        opts.mask.color, 'LineWidth', opts.mask.linewidth)

end
