function plot_quiver_scaled(lon, lat, u, v, opts)
% Overlay quiver arrows on the current axes.
% Replaces external vecplot dependency.
%
% Inputs:
%   lon, lat  - 2D coordinate grids
%   u, v      - 2D velocity component grids (m/s)
%   opts      - options struct from plot_defaults (uses opts.quiver fields)
%
%                Rick Luettich / RENCI 2026

stride = opts.quiver.stride;
scl    = opts.quiver.scale;
clr    = opts.quiver.color;

% subsample
lon_s = lon(1:stride:end, 1:stride:end);
lat_s = lat(1:stride:end, 1:stride:end);
u_s   = u(1:stride:end, 1:stride:end);
v_s   = v(1:stride:end, 1:stride:end);

quiver(lon_s, lat_s, u_s, v_s, scl, 'Color', clr, 'LineWidth', 0.5);

end
