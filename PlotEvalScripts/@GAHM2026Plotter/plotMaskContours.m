function plotMaskContours(obj, datagrid, tidx)
% plotMaskContours  Overlay inner and outer mask boundary contours.

    opts = obj.Opts;
    clevs=[1 1]*.99;
    [C,H]=contour(datagrid(tidx).Lon, datagrid(tidx).Lat, datagrid(tidx).Mask1, clevs);
    delete(H)
    while ~isempty(C)
        n=C(2,1);
        line(C(1,2:n+1),C(2,2:n+1),color=opts.mask.color,LineWidth=opts.mask.linewidth);
        C(:,1:n+1)=[];
    end
    [C,H]=contour(datagrid(tidx).Lon, datagrid(tidx).Lat, datagrid(tidx).Mask2, clevs);
    delete(H)
    while ~isempty(C)
        n=C(2,1);
        line(C(1,2:n+1),C(2,2:n+1),color=opts.mask.color,LineWidth=opts.mask.linewidth);
        C(:,1:n+1)=[];
    end
end
