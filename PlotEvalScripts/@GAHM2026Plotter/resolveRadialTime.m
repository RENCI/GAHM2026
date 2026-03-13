function tidx = resolveRadialTime(obj, time)
% resolveRadialTime  Convert a time argument to a RadialGrid timestep index.
%
%   tidx = resolveRadialTime(obj, 5)                 — integer index
%   tidx = resolveRadialTime(obj, datetime(2024,...)) — matched via Trackdata

    ntimes = length(obj.RadialGrid.VVor_bt);

    if isnumeric(time) && isscalar(time)
        tidx = round(time);
        if tidx < 1 || tidx > ntimes
            error("GAHM2026Plotter:badIndex", ...
                "Radial time index %d is out of range [1, %d].", tidx, ntimes);
        end
        return
    end

    if isdatetime(time)
        Track = obj.Trackdata;
        dtvec = datetime([Track(1:ntimes).datetime]);
        [~, tidx] = min(abs(dtvec - time));
        return
    end

    error("GAHM2026Plotter:badTime", ...
        "time must be an integer index or a datetime value.");

end
