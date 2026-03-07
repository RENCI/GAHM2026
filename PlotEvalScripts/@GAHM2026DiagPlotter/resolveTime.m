function ip = resolveTime(obj, time)
% resolveTime  Convert a time argument to a timestep index.
%
%   ip = resolveTime(obj, 5)                 — integer index, returned as-is
%   ip = resolveTime(obj, datetime(2024,...)) — matched to nearest datagrid datetime

    datagrid = obj.DataGrid;
    itot = length(datagrid);

    if isnumeric(time) && isscalar(time)
        ip = round(time);
        if ip < 1 || ip > itot
            error('GAHM2026DiagPlotter:badIndex', ...
                'Time index %d is out of range [1, %d].', ip, itot);
        end
        return
    end

    if isdatetime(time)
        dtvec = datetime([datagrid.datetime]);
        [~, ip] = min(abs(dtvec - time));
        return
    end

    error('GAHM2026DiagPlotter:badTime', ...
        'time must be an integer index or a datetime value.');

end