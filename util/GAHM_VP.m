%--------------------------------------------------------------------------
%
%  Script to compute GAHM velocity and pressure deficit at a specified 
%  radial distance from the eye (r), for a specified quadrant (q) and
%  isotach (iso)
%
%    GAHM equations from R Luettich 5/2025 & Jia Gao 2018 dissertation
%
%    version 1 coded by Rick Luettich 8/15/2024
%    version 2 output changed to pressure deficit RL 6/20/2025
%    version 3 eliminated unused output RL 7/6/2026
%
% Units used in calculations:
%      velocity - m/s unless otherwise specified 10 min @ 10 m height
%      distance - m unless otherwise specified
%      pressure - mb (N/m^2 / 100) 
%
% Inputs:
%       r - distance (m) from the eye to compute V,P
%       q - quadrant number to compute for (1-4 = NE, SE, SW, NW)
%       iso - isotach number to use (1-3 = 34, 50, 64 kts)
%       GAHM - data structure containing GAHM parameter values computed by
%               the GAHM_Params.m script.  See the header of that script
%               for details.
%
% Outputs:
%    Press - atmospheric pressure deficite (P(r)-Pn) (mb)
%    VVorRadProf_10_10 - vortex velocity (m/s) including turning angle, 
%                                                 10 min avg, 10 m height
%
% Constants & Assumptions:
%       BLF - multiplication factor to reduce winds from the top of the
%            boundary layer to 10 m height (ADCIRC 0.9, others 0.8?)
%       f - Coriolis parameter = 2 omega sin(latitude) units 1/s
%       omega - rotation speed of earth rad/s (0.00007272)
%       turnangle - turning angle (ccw in N hemisphere) for the vortex wind
%                   velocity moving from the top of the bl to 10m
%                   if r < Rmax
%                       turnangle=10*r/Rmax;
%                   elseif r < 1.2*Rmax
%                       turnangle=10+75*(r/Rmax-1);
%                   else     (r>= 1.2*Rmax)
%                       turnangle=25;
%                   end  
%       
%
function [Press,VVorRadProf_10_10] = GAHM_VP(r,q,iso,GAHM_constants,GAHM)


%% Specify constants

LatNS=GAHM.Eye(2);
BLF = GAHM_constants.BLF;
omega = 0.00007272;    % rad / s
f=2*omega*sind(LatNS);

% Compute unit vectors & rotation matricies

VVorQuaduv_tbl = quadrantUnitVectors(LatNS);

SVorMax_10_10=GAHM.SVorMax_10_10;
SVorMax_10_tbl=SVorMax_10_10/BLF;
Bg=GAHM.Bg(q,iso);
Rmax=GAHM.Rmax(q,iso);   
RmaxQ=GAHM.RmaxQ(q);   % Rmax for highest isotach that isn't NaN
RmorBg=(Rmax/r)^Bg;
Ro=GAHM.Ro(q,iso);
phi=GAHM.phi(q,iso);
SVorGRadProf_10_tbl=sqrt(SVorMax_10_tbl^2*(1+1/Ro)*exp(phi*(1-RmorBg))*RmorBg+(r*f/2)^2)-r*f/2;
SVorRadProf_10_10=SVorGRadProf_10_tbl*BLF;
turnangle = turnAngleDeg(r, RmaxQ);
turnmat=[cosd(-turnangle) -sind(-turnangle); sind(-turnangle) cosd(-turnangle)];
VVorQuaduv_10=VVorQuaduv_tbl(q,:)*turnmat;
VVorRadProf_10_10=SVorRadProf_10_10*VVorQuaduv_10;
    
% Compute the pressure deficit
    
    Press=(GAHM.Pback-GAHM.CP)*(exp(-phi*RmorBg)-1);

%end


