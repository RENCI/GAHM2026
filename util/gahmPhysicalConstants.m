function c = gahmPhysicalConstants()
% Return a struct of physical constants used in GAHM calculations.
%
% Output:
%       c - struct with fields: omega, earthRadiusM, nm2m, kt2ms, ms2kt

c.omega = 0.00007272;       % Earth rotation rate (rad/s)
c.earthRadiusM = 6371000;   % Earth radius (m)
c.nm2m = 1852;              % nautical miles to meters
c.kt2ms = 0.514444;         % knots to m/s
c.ms2kt = 1/0.514444;       % m/s to knots

end
