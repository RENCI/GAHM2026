function [Xq, Yq, hr_u, hr_v] = convertToPolarCoords( ...
          lon, lat, u, v, LonIdx, LatIdx, cx, cy, CONFIG)
    % lon
    % lat
    % u
    % v
    % LonIdx
    % LatIdx
    % cx
    % cy

    half = CONFIG.grid_half_size;
    rows = LatIdx-half : LatIdx+half;
    cols = LonIdx-half : LonIdx+half;
    
    lon_dc = lon(rows, cols) - cx;
    lat_dc = lat(rows, cols) - cy;
    u_dc = u(rows, cols);
    v_dc = v(rows, cols);
    
    r = linspace(0, CONFIG.max_radius_deg, CONFIG.num_radial_points);
    th = linspace(0, 2*pi, CONFIG.num_azimuth_points);
    [rho, theta] = meshgrid(r, th);
    [Xq, Yq] = pol2cart(theta, rho);
    
    hr_u = griddata(lon_dc, lat_dc, u_dc, Xq, Yq, 'linear');
    hr_v = griddata(lon_dc, lat_dc, v_dc, Xq, Yq, 'linear');
end
