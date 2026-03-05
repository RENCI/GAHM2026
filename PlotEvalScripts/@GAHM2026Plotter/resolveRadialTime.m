function ip = resolveRadialTime(obj, time)
% resolveRadialTime  Convert a time argument to a VPrad timestep index.
%
%   ip = resolveRadialTime(obj, 5)                 — integer index
%   ip = resolveRadialTime(obj, datetime(2024,...)) — matched via Trackdata

    itot = length(obj.VPrad.VVor_bt);

    if isnumeric(time) && isscalar(time)
        ip = round(time);
        if ip < 1 || ip > itot
            error('GAHM2026Plotter:badIndex', ...
                'Radial time index %d is out of range [1, %d].', ip, itot);
        end
        return
    end

    if isdatetime(time)
        Tdata = obj.Trackdata;
        dtvec = datetime([Tdata(1:itot).datetime]);
        [~, ip] = min(abs(dtvec - time));
        return
    end

    error('GAHM2026Plotter:badTime', ...
        'time must be an integer index or a datetime value.');

end
