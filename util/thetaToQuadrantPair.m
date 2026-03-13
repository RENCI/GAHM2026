function [RP, IF] = thetaToQuadrantPair(theta)
% Determine which two standard quadrant radials a given angle falls between
% and compute interpolation factors.
%
% theta is in degrees CCW from East.
% Standard radials: NE=1, SE=2, SW=3, NW=4
%
% Inputs:
%       theta - angle in degrees CCW from East
%
% Outputs:
%       RP(1:2) - pair of quadrant indices bracketing theta
%       IF(1:2) - interpolation factors for each quadrant in RP

if theta > 315
    theta = theta - 360;
end
if -45 < theta && theta <= 45
    IF(2) = (45-theta)/90;
    RP(1) = 1;
    RP(2) = 2;
elseif 225 < theta && theta <= 315
    IF(2) = (315-theta)/90;
    RP(1) = 2;
    RP(2) = 3;
elseif 135 < theta && theta <= 225
    IF(2) = (225-theta)/90;
    RP(1) = 3;
    RP(2) = 4;
elseif 45 < theta && theta <= 135
    IF(2) = (135-theta)/90;
    RP(1) = 4;
    RP(2) = 1;
end
IF(1) = 1 - IF(2);

end
