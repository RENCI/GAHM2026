function az = thetaToAzimuth(theta)
% Convert angle from CCW-from-East to bearing CW-from-North.
%
% Input:
%       theta - angle in degrees, counter-clockwise from East
%
% Output:
%       az - bearing in degrees, clockwise from North (0-360)

az = 90 - theta;
if az < 0
    az = az + 360;
end

end
