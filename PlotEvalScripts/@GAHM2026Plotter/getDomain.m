function [minX, maxX, minY, maxY] = getDomain(obj, datagrid, ip)
% getDomain  Compute axis limits for timestep ip.

    if strcmp(obj.Opts.domain.mode, 'moving')
        minX = min(datagrid(ip).Lon(:));
        maxX = max(datagrid(ip).Lon(:));
        minY = min(datagrid(ip).Lat(:));
        maxY = max(datagrid(ip).Lat(:));
    else
        lims = obj.Opts.domain.fixedLimits;
        minX = lims(1);
        maxX = lims(2);
        minY = lims(3);
        maxY = lims(4);
    end

end
