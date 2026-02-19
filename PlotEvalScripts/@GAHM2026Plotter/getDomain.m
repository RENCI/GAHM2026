function [minX, maxX, minY, maxY] = getDomain(obj, datagrid, ip)
% getDomain  Compute axis limits for timestep ip.

    if strcmp(obj.Opts.domain.mode, 'moving')
        minX = min(datagrid(ip).Lon(:));
        maxX = max(datagrid(ip).Lon(:));
        minY = min(datagrid(ip).Lat(:));
        maxY = max(datagrid(ip).Lat(:));
    else
        lims = obj.Opts.domain.fixedLimits;
        if isempty(lims)
            % get min/max extents of entire datagrid
            temp=vertcat(obj.DataGrid.Lon);
            minX=min(temp(:));
            maxX=max(temp(:));
            temp=vertcat(obj.DataGrid.Lat);
            minY=min(temp(:));
            maxY=max(temp(:));
        else
            minX = lims(1);
            maxX = lims(2);
            minY = lims(3);
            maxY = lims(4);
        end
    end
end
