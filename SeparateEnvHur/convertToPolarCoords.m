function [Xq, Yq, hr_u, hr_v] = convertToPolarCoords(era5, track, CONFIG, i)

    half = round((CONFIG.output_grid_length/2)/CONFIG.dlonlat);
    max_radius_deg = CONFIG.output_grid_length/2;
    rows = track.lat_idx(i)-half : track.lat_idx(i)+half;
    cols = track.lon_idx(i)-half : track.lon_idx(i)+half;

    centerLon = era5.vortex.lon(i);
    centerLat = era5.vortex.lat(i);
    lon_dc = era5.lon_grid(rows, cols) - centerLon;
    lat_dc = era5.lat_grid(rows, cols) - centerLat;
    u_dc = squeeze(era5.u10(cols, rows, i))';
    v_dc = squeeze(era5.v10(cols, rows, i))';

    r = linspace(0, max_radius_deg, CONFIG.num_radial_points);
    th = linspace(0, 2*pi, CONFIG.num_azimuthal_points);
    [rho, theta] = meshgrid(r, th);
    [Xq, Yq] = pol2cart(theta, rho);

    hr_u = griddata(lon_dc, lat_dc, u_dc, Xq, Yq, 'linear');
    hr_v = griddata(lon_dc, lat_dc, v_dc, Xq, Yq, 'linear');
end
