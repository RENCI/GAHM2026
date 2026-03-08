function tidx = resolveTime(obj, time)
% resolveTime  Convert a time argument to a timestep index.
%
%   tidx = resolveTime(obj, 5)                 — integer index, returned as-is
%   tidx = resolveTime(obj, datetime(2024,...)) — matched to nearest datagrid datetime

    datagrid = obj.DataGrid;
    ntimes = length(datagrid);

    if isnumeric(time) && isscalar(time)
        tidx = round(time);
        if tidx < 1 || tidx > ntimes
            error('GAHM2026Plotter:badIndex', ...
                'Time index %d is out of range [1, %d].', tidx, ntimes);
        end
        return
    end

    if isdatetime(time)
        dtvec = datetime([datagrid.datetime]);
        [~, tidx] = min(abs(dtvec - time));
        return
    end

    error('GAHM2026Plotter:badTime', ...
        'time must be an integer index or a datetime value.');

end
