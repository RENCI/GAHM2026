function ta = turnAngleDeg(r, RmaxQ)
% Compute the piecewise turning angle as a function of radial distance,
% based on the following formula
%
%  r < Rmax             turn angle = 10*(r/Rmax)
%  Rmax <= r <1.2*Rmax  turn angle = 10 + 75*(r/Rmax - 1)
%  r => 1.2*Rmax        turn angle = 25
%
%  where the turning angle is deg
%
% Inputs:
%       r     - radial distance from the eye (m)
%       RmaxQ - radius of maximum wind for the quadrant (m)
%
% Output:
%       ta - turning angle (degrees)

if r < RmaxQ
    ta = 10*r/RmaxQ;
elseif r < 1.2*RmaxQ
    ta = 10 + 75*(r/RmaxQ-1);
else
    ta = 25;
end

end
