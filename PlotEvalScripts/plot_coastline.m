function plot_coastline(opts)
% Overlay coastline on the current axes using MATLAB built-in data.
% Replaces external plotcoast dependency.
%
% Inputs:
%   opts - options struct from plot_defaults (uses opts.coast fields)
%
%                Rick Luettich / RENCI 2026

if ~opts.coast.show
    return
end

C = load('coastlines');
plot(C.coastlon, C.coastlat, '-', ...
    'Color', opts.coast.color, ...
    'LineWidth', opts.coast.linewidth);

end
