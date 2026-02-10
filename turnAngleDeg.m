% Compute the piecewise turning angle as a function of radial distance.
%
% Inputs:
%       r     - radial distance from the eye (m)
%       RmaxQ - radius of maximum wind for the quadrant (m)
%
% Output:
%       ta - turning angle (degrees)

function ta = turnAngleDeg(r, RmaxQ)

if r < RmaxQ
    ta = 10*r/RmaxQ;
elseif r < 1.2*RmaxQ
    ta = 10+75*(r/RmaxQ-1);
else
    ta = 25;
end
