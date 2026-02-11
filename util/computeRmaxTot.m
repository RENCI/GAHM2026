% Compute an interpolated Rmax from quadrant Rmax values using the 
% environmental wind direction to determine the interpolation angle.
%
% Inputs:
%       RmaxQ(4) - Rmax values for each quadrant (NE,SE,SW,NW)
%       Venv(2)  - environmental wind vector [u,v]
%
% Outputs:
%       Rmax  - interpolated Rmax value
%       theta - angle CCW from East to the radial line to Rmax (degrees)

function [Rmax, theta] = computeRmaxTot(RmaxQ, Venv)

theta=atan2d(Venv(2),Venv(1))-90;
if theta < 0
    theta= theta+360;   
end
if theta  > 360
    theta=theta-360;
end 
[RP, IF] = thetaToQuadrantPair(theta);
Rmax=IF(1)*RmaxQ(RP(1))+IF(2)*RmaxQ(RP(2));
