function plotMaskContours(obj, datagrid, tidx)
% plotMaskContours  Overlay inner and outer mask boundary contours.

    % Normalize field names for backward compatibility
    if isfield(datagrid, 'Mask1') && ~isfield(datagrid, 'MaskInner')
        [datagrid.MaskInner] = datagrid.Mask1;
        [datagrid.MaskOuter] = datagrid.Mask2;
    end

    opts = obj.Opts;
    clevs=[1 1]*.99;
    [C,H]=contour(datagrid(tidx).Lon, datagrid(tidx).Lat, datagrid(tidx).MaskInner, clevs);
    delete(H)
    while ~isempty(C)
        n=C(2,1);
        line(C(1,2:n+1),C(2,2:n+1),color=opts.mask.color,LineWidth=opts.mask.linewidth);
        C(:,1:n+1)=[];
    end
    [C,H]=contour(datagrid(tidx).Lon, datagrid(tidx).Lat, datagrid(tidx).MaskOuter, clevs);
    delete(H)
    while ~isempty(C)
        n=C(2,1);
        line(C(1,2:n+1),C(2,2:n+1),color=opts.mask.color,LineWidth=opts.mask.linewidth);
        C(:,1:n+1)=[];
    end
end
