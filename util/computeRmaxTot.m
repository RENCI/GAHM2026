function [Rmax, theta] = computeRmaxTot(RmaxQ, Venv)
% Use quadrant Rmax values to compute an interpolated Rmax that lies along
% a radial line that is 90 deg to the right of a specified input vector
% (called Venv).  u,v are in the direction vector is point toward
%
% Inputs:
%       RmaxQ(4) - Rmax values for each quadrant (NE,SE,SW,NW)
%       Venv(2)  - input vector [u,v]
%
% Outputs:
%       Rmax  - interpolated Rmax value
%       theta - angle CCW from East to the radial line to Rmax (degrees)

theta = atan2d(Venv(2),Venv(1)) - 90;
if theta < 0
    theta = theta + 360;
end
if theta > 360
    theta = theta - 360;
end
[RP, IF] = thetaToQuadrantPair(theta);
Rmax = IF(1)*RmaxQ(RP(1)) + IF(2)*RmaxQ(RP(2));

end
