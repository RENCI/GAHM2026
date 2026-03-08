function [minX, maxX, minY, maxY] = getDomain(obj, datagrid, tidx)
% getDomain  Compute axis limits for timestep tidx.

    if strcmp(obj.Opts.domain.mode, 'moving')
        minX = min(datagrid(tidx).Lon(:));
        maxX = max(datagrid(tidx).Lon(:));
        minY = min(datagrid(tidx).Lat(:));
        maxY = max(datagrid(tidx).Lat(:));
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
