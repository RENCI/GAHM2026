function plotMaskContours(obj, datagrid, ip)
% plotMaskContours  Overlay inner and outer mask boundary contours.

    opts = obj.Opts;
    clevs=[1 1]*.99;
    [C,H]=contour(datagrid(ip).Lon, datagrid(ip).Lat, datagrid(ip).Mask1, clevs);
    delete(H)
    line(C(1,2:end),C(2,2:end),color=opts.mask.color,LineWidth=opts.mask.linewidth)

    [C,H]=contour(datagrid(ip).Lon, datagrid(ip).Lat, datagrid(ip).Mask2, clevs);
    delete(H)
    line(C(1,2:end),C(2,2:end),color=opts.mask.color,LineWidth=opts.mask.linewidth)

end
