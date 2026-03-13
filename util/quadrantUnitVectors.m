function VVorQuaduv_tbl = quadrantUnitVectors(LatNS)
% Compute unit vectors for vortex rotation in each quadrant.
% Sign convention accounts for hemisphere (CCW in NH, CW in SH).
%
% Input:
%       LatNS - latitude (positive = Northern Hemisphere)
%
% Output:
%       VVorQuaduv_tbl(4,2) - unit vectors [u,v] for quadrants NE,SE,SW,NW

hemiSign = sign(LatNS);
if hemiSign == 0
    hemiSign = 1;
end
VVorQuaduv_tbl(1,:) = [-1,1]/norm([-1,1])*hemiSign;
VVorQuaduv_tbl(2,:) = [1,1]/norm([1,1])*hemiSign;
VVorQuaduv_tbl(3,:) = [1,-1]/norm([1,-1])*hemiSign;
VVorQuaduv_tbl(4,:) = [-1,-1]/norm([-1,-1])*hemiSign;

end
