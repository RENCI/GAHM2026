function GAHM_VPrad = gahmVPradial(r,theta,GAHM_constants,GAHM)
% gahmVPradial  Compute velocity and pressure along a radial line using GAHM2026.
%
%     v1 coded by Rick Luettich 8/6/2024
%     v2 changed to pressure deficite 6/20/2025
%     v3 eliminated extraneous output from gahmVP.m 7/6/2025
%
% Inputs:
%       r - arrary of radial distances (m) from storm center to compute V,P
%           the first value should be 0
%       theta - angle (deg) ccw from East of radial line to compute V,P
%
%      GAHM - data structure containing GAHM parameter values
%            Note: q = quadrant # q=1:4 => NE, SE, SW, NW
%                  iso = isotach # iso=1:3 => SQuad_1_10=[34, 50, 64]/1.944
%                  iso+1 = 4 is reserved for the case when non of the
%                  isotachs have values. In this case default values are
%                  used in this position. The default values are derived
%                  from averaging Rmax from the quadrants with valid
%                  isotachs. If there are no valid isotachs in any
%                  quadrant, the input Rmax (e.g., from the best track file
%                  is used).
%            GAHM.Pback - background pressure in mb
%            GAHM.CP - central pressure in mb
%            GAHM.Eye(2) = LonEW, LatNS (deg)
%            GAHM.RQuad(q,iso) - radial distance (m) to isotachs
%            GAHM.SMax_10_10 - max speed (m/s) (from input file)
%            GAHM.SQuad_10_10(iso) - isotach speeds (m/s)
%            GAHM.SVorMax_10_10_theta - angle ccw from E where SVorMax_10_10 occurs
%            GAHM.SVorMax_10_10 (m/s) - maximum vortex wind speed
%            GAHM.VEnvStar_10_10 - Env vel near eye 10 min avg @ 10m
%            GAHM.Rmax(q,iso+1) - Rmax value computed by GAHM for each q,iso
%                               the final place = NaN or a defalut value if
%                               all of the iso values = NaN.
%            GAHM.RmaxQ(q) - Rmax value for strongest isotach in quadrant
%            GAHM.Ro(q,iso+1) - Rossby # for each q,iso
%            GAHM.A(q,iso+1) - original Holland A for each quadrant,isotach
%            GAHM.B(q,iso+1) - original Holland B for each quadrant,isotach
%            GAHM.Bg(q,iso+1) - GAHM Holland B for each quadrant,isotach
%            GAHM.phi(q,iso+1) - GAHM phi for quadrant,isotach
%
% Outputs:
%       GAHM_VPrad.Press - Pressure deficite (mb) array along radial line
%                               specified by theta
%       GAHM_VPrad.VVor_10_10 - vortex velocity (m/s) array along radial line
%                               specified by theta (speed interpolation)
%       GAHM_VPrad.VVor_10_10_RP - vortex velocity (m/s) along two quadrant
%                              radials used to interpolate to radial line
%                              specified by theta
%       GAHM_VPrad.Press_RP -  pressure deficite (mb) along two quadrant
%                              radials used to interpolate to radial line
%                              specified by theta
%       GAHM.RP - quadrant numbers of the two quadrant radials used to
%                             interpolate to radial line specified by theta
%
%--------------------------------------------------------------------------

    arguments
        r (1,:) double
        theta (1,1) double
        GAHM_constants (1,1) struct
        GAHM (1,1) struct
    end

%% identify which standard radials (NE, SE, SW, NW) the specified radial line
%  is between RP(1:2) and determine the associated interpolating factors IF(1:2)

[RP, IF] = thetaToQuadrantPair(theta);

%% for each r value, compute the values along RP1 & RP2 and interpolate
% to radial @ specified theta

GAHM_VPrad.VVor_10_10(1,:) = [0 0];   % initial r value assumed = 0
GAHM_VPrad.Press_RP(1,1) = GAHM.CP-GAHM.Pback;  %default pressure deficit
GAHM_VPrad.Press_RP(1,2) = GAHM.CP-GAHM.Pback;  %default pressure deficit
GAHM_VPrad.Press(1) = GAHM.CP-GAHM.Pback;
ndr = length(r);
Press_RP(1:ndr) = 0;
VVor_10_10_RP(1:ndr,1:2) = 0;
for ir=2:ndr
    for iRP=1:2 %For both RPs, determine which isotach(s) and weighting to use for r
       q = RP(iRP);

% Case 1 three isotachs (34, 50, 64 kts) available
        if ~isnan(GAHM.RQuad(q,3)) && ~isnan(GAHM.RQuad(q,2)) && ~isnan(GAHM.RQuad(q,1))
            if r(ir) <= GAHM.RQuad(q,3)
                [Press_RP(iRP),VVor_10_10_RP(iRP,:)] = ...
                                 gahmVP(r(ir),q,3,GAHM_constants,GAHM);
            elseif r(ir) <= GAHM.RQuad(q,2)
                [Press3,VVor3] = gahmVP(r(ir),q,3,GAHM_constants,GAHM);
                [Press2,VVor2] = gahmVP(r(ir),q,2,GAHM_constants,GAHM);
                R23_3 = (GAHM.RQuad(q,2)-r(ir))/(GAHM.RQuad(q,2)-GAHM.RQuad(q,3));
                R23_2 = (r(ir)-GAHM.RQuad(q,3))/(GAHM.RQuad(q,2)-GAHM.RQuad(q,3));
                Press_RP(iRP) = Press3*R23_3+Press2*R23_2;
                VVor_10_10_RP(iRP,:) = VVor3*R23_3+VVor2*R23_2;
            elseif r(ir) <= GAHM.RQuad(q,1)
                [Press2,VVor2] = gahmVP(r(ir),q,2,GAHM_constants,GAHM);
                [Press1,VVor1] = gahmVP(r(ir),q,1,GAHM_constants,GAHM);
                R12_2 = (GAHM.RQuad(q,1)-r(ir))/(GAHM.RQuad(q,1)-GAHM.RQuad(q,2));
                R12_1 = (r(ir)-GAHM.RQuad(q,2))/(GAHM.RQuad(q,1)-GAHM.RQuad(q,2));
                Press_RP(iRP) = Press2*R12_2+Press1*R12_1;
                VVor_10_10_RP(iRP,:) = VVor2*R12_2+VVor1*R12_1;
            else
                [Press_RP(iRP),VVor_10_10_RP(iRP,:)] = gahmVP(r(ir),q,1,GAHM_constants,GAHM);
            end

% Case 2 two isotachs (34, 50 kts) available
        elseif ~isnan(GAHM.RQuad(q,2)) && ~isnan(GAHM.RQuad(q,1))
            if r(ir) <= GAHM.RQuad(q,2)
                [Press_RP(iRP),VVor_10_10_RP(iRP,:)] = gahmVP(r(ir),q,2,GAHM_constants,GAHM);
            elseif r(ir) <= GAHM.RQuad(q,1)
                [Press2,VVor2] = gahmVP(r(ir),q,2,GAHM_constants,GAHM);
                [Press1,VVor1] = gahmVP(r(ir),q,1,GAHM_constants,GAHM);
                R12_2 = (GAHM.RQuad(q,1)-r(ir))/(GAHM.RQuad(q,1)-GAHM.RQuad(q,2));
                R12_1 = (r(ir)-GAHM.RQuad(q,2))/(GAHM.RQuad(q,1)-GAHM.RQuad(q,2));
                Press_RP(iRP) = Press2*R12_2+Press1*R12_1;
                VVor_10_10_RP(iRP,:) = VVor2*R12_2+VVor1*R12_1;
            else
                [Press_RP(iRP),VVor_10_10_RP(iRP,:)] = gahmVP(r(ir),q,1,GAHM_constants,GAHM);
            end

% Case 3 one isotach (34 kts) available
        elseif ~isnan(GAHM.RQuad(q,1))
            [Press_RP(iRP),VVor_10_10_RP(iRP,:)] = gahmVP(r(ir),q,1,GAHM_constants,GAHM);

% Case 4 no isotachs are available, use default values
        else
            [Press_RP(iRP),VVor_10_10_RP(iRP,:)] = gahmVP(r(ir),q,4,GAHM_constants,GAHM);
        end

    GAHM_VPrad.VVor_10_10_RP(ir,iRP,:) = VVor_10_10_RP(iRP,:);
    GAHM_VPrad.Press_RP(ir,iRP) = Press_RP(iRP);
    end

% interpolate value at specified r from the two Radial Profiles

    GAHM_VPrad.RP = RP;

    VVor_10_10(:) = VVor_10_10_RP(1,:)*IF(1)+VVor_10_10_RP(2,:)*IF(2);
    VSpeed_10_10 = norm(VVor_10_10_RP(1,:))*IF(1)+norm(VVor_10_10_RP(2,:))*IF(2);
    if norm(VVor_10_10) == 0
        VVuv_10_10 = [0 0];
    else
        VVuv_10_10(:) = VVor_10_10(:)/norm(VVor_10_10(:));
    end
    GAHM_VPrad.VVor_10_10(ir,:) = VSpeed_10_10*VVuv_10_10(:);
    GAHM_VPrad.Press(ir,1) = Press_RP(1)*IF(1)+Press_RP(2)*IF(2);

end

end

