%
%    Script to perform consistency checks on the inputs to GAHM2026 and set
%    GAHM flag values based on these checks. The flags are used in
%    calculating GAHM2026 parameter values / radial profiles.
%
%        GAHM2026 equations adapted from Jia Gao 2018 PhD dissertation
%                      R. Luettich 2024-25
%
%              coded by Rick Luettich 7/11/2025
%
%     GAHM variables are either singular (i.e., a single value applies for 
%     a given time step) or as a matrix with (q,i) indicies,
%     where q is the quadrant (NE,SE,SW,NW = 1:4) and i is the isotach
%     (34, 50, 64 kt = 1:3).  A 4th isotach is uses for default values.
%
%     If all of the consistency checks are passed, GAHM.flag_B=1, 
%     GAHM.flag(q,i)=1 (or 5), GAHM.flag(q,4)=NaN.
%
%   The consistency checks are:
%
%     1. Check whether Holland 1980 B value falls within specified limits
%        If Bmin <= B <= Bmax GAHM.flag_B=1
%        if B < Bmin, B is reset = Bmin and GAHM.flag_B=0
%        if B > Bmax, B is reset = Bmax and GAHM.flag_B=2
%        B is input via the GAHM datastructure
%        Bmin, Bmax are input via the GAHM_constants datastructure
%     2. Check if any isotach (34kt, 50kt, 64kt) distances are present in  
%        any quadrant in the track file for the current time.
%        If not, GAHM.flag(1:4,1:4) = 0. Rmw in all quadrants = Rmw read in
%        from the track file. Bg, A, phi computed from GAHM2026.
%     3. SVorMax_10_tbl >= SVorMax_10_tblmin - this ensures that the vortex
%        maximum speed (input maximum speed minus the environmental speed),
%        moved to the top of the boundary layer, is strong enough (>20 kts?)
%        to use GAHM to compute Rmw. If this condition is not met, 
%        GAHM.flag(1:4,1:3)=2, GAHM.flag(1:4,4)=0, Rmw in all quadrants = 
%        Rmw read in from track file. Bg, A, phi computed from GAHM2026.
%     4. Check if an isotach distance is present in the track file for a 
%        specific quadrant, isotach pair. If not, GAHM.flag(q,i)=0;
%     5. SVorQuad_10_tbl > SVorQuad_10_tblmin - this ensures that the 
%        vortex isotach speeds in each quadrant (input isotach velocity 
%        minus the environmental velocity), moved to the top of the 
%        boundary layer, is strong enough (>5 kts?) to use GAHM to compute 
%        Rmw. This is checked for each quadrant, isotach pair. If this 
%        condition is not met, then GAHM_flag(q,i)=3. Rmw is copied from 
%        surrounding isotachs (e.g., next higher isotach in quadrant) and 
%        Bg, A, phi computed from GAHM2026. 
%     6. SVorMax_10_10 >= SVorQuad_10_10(q,i) - this ensures that the 
%        voretex isotach speeds in each quadrant are < or = the vortex 
%        maximum speeded.  This is checked for each quadrant, isotach pair 
%        assuming 10 and 25 deg ccw turning angles from the tbl to 10m. If 
%        this condition is not met for both turning angles, 
%        GAHM_flag(q,i)=4. In this case assume Rmw = RQuad, 
%        SVorQuad_10_10(q,i)=SVorMax_10_10. Bg, A phi are computed using 
%        GAHM2026. If the condition is not met for only one of the turning 
%        angles, GAHM_flag(q,i)=5. Estimate an intermediate turning angle 
%        and use to determine Rmw, Bg, A, phi using GAHM2026.
%  
% Input & Output variables:
%   Passed in via the GAHM_constants and GAHM data structures
%
%   GAHM_constants - data structure with constants needed by GAHM
%       GAHM_constants.Vmax_multiplier
%       GAHM_constants.one2tenF - convert from 1 min to 10 min wind speed 
%                                                       (ADCIRC/ASWIP=0.89)
%       GAHM_constants.BLF  - boundary layer factor (ADCIRC/ASWIP=0.9)
%       GAHM_constants.Bmin - lower limit on B
%       GAHM_constants.Bmax - upper limit on B
%       GAHM_constants.SVorMax_10_tblmin - (kts)
%       GAHM_constants.SVorQuad_10_tblmin - (kts)
%       GAHM_constants.rhoa - density of air (kg/m^3) (ADCIRC/ASWIP=1.204)
%       GAHM_constants.pback - (mb) default environmental pressure if not 
%                               read in from track file
%       GAHM_constants.version  (3 or 4)
%       GAHM_constants.Bg0M - multiplies B to give initial condition for
%                              iterative solver in GAHM2026v4 & GAHM2026v3
%                              (recom: 1.05)
%       GAHM_constants.c0 - initial condition for c (0<c<1) for iterative
%                              solver in GAHM2026va (recom: 0), ignored
%                              for GAHM2023v3.
%
%   See documentation/GAHM_struct.md for full GAHM data structure definition.
%
% Constants & Assumptions:
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
% Select Variables Definitions:
%      SMax_1_10 - maximum wind speed (m/s) 1 min sustained, 10 m height
%                  from besttrack file after units conversion
%                  note, SMax_1_10 is aligned with the environmental
%                  velocity VEnvStar_10_10
%       SMax_10_tbl - SMax_10_10 @ top of the boundary layer
%       SVorMax_10_10 = SMax_10_10 - SEnvStar_10_10 
%       SVorMax_10_10_theta - angle ccw from E where SVorMax_10_10 occurs
%       SVorMax_10_tbl - vortex component of SMax_10_tbl
%       SQuad_1_10(3) - 1 min sustained speed (m/s) of 3 isotachs @ 10m
%                            height (34, 50, 64 kts converted to m/s). 
%       SQuad_10_10(3) - 10 min avg SQuad_1_10
%       SQuad_10_tbl(3) - SQuad_10_10(3) @ top of the boundary layer
%       SVorQuad_10_tbl(3) - vortex component of SQuad_10_tbl(3)
%       VVorQuaduv_tbl(4,3) - SVorQuad_10_tbl(3) unit vectors in the 4 
%                            quadrants  
%       deltaP_NpMsq - central pressure deficite in N/m^2 = 100*milibars
%       VEnv_10_10 -  Environmental background velocity 10 min avg @ 10m
%                     Total wind velocity = Environmental velocity + vortex 
%                     velocity.
%       SEnv_10_10 -  speed of VEnv_10_10
%       VEnvStar_10_10 - average environmental background velocity near eye
%                      (within r=Rmax_in).
%       SEnvStar_10_10 - speed of VEnvStar_10_10
%       VEnvStaruv_10_10 - unit vector of VEnvStar_10_10
%       VEnvQuad_10_10 - Environmental background velocity at the 3 isotach
%                  locations in the 4 quadrants.
%       RQuad(4,3) -radial distance (m) in the 4 quadrants ordered NE, SE,
%                   SW, NW for the 3 isotach values ordered 34, 50, 64 kt          
%       B - Holland (1980) B = SVorMax_10_tbl^2*rhoa*exp(1)/deltaP_NpMsq
%

function GAHM_out = GAHM2026_consistency(GAHM_constants,GAHM_in,fid)   

% Extract inputs

BLF=GAHM_constants.BLF;
one2tenF=GAHM_constants.one2tenF;
SVorMax_10_tblmin=GAHM_constants.SVorMax_10_tblmin/1.944;   %convert to m/s
SVorQuad_10_tblmin=GAHM_constants.SVorQuad_10_tblmin/1.944; %convert to m/s
Bmin=GAHM_constants.Bmin;
Bmax=GAHM_constants.Bmax;

GAHM_datetime=GAHM_in.datetime;
LatNS=GAHM_in.Eye(2);
B=GAHM_in.B;
Rmax_in=GAHM_in.Rmax_in;
RQuad=GAHM_in.RQuad;
Gcase=GAHM_in.Gcase;
SQuad_10_10=GAHM_in.SQuad_10_10;  % 34,50,64 kt converted to 10 min & m/s
SVorMax_10_10=GAHM_in.SVorMax_10_10;
SVorMax_10_tbl=SVorMax_10_10/BLF;
VEnvStar_10_10=GAHM_in.VEnvStar_10_10;  % avg environmental velocity near eye
VEnvQuad_10_10=GAHM_in.VEnvQuad_10_10;

GAHM_out=GAHM_in;

% Compute unit vectors & rotation matricies

VVorQuaduv_tbl = quadrantUnitVectors(LatNS);
ra25=25*LatNS/abs(LatNS);                                     % S hemisphere
ra10=10*LatNS/abs(LatNS);
rotation_matrix_ccw25d=[cosd(-ra25) -sind(-ra25); sind(-ra25) cosd(-ra25)];  % rotate 25deg ccw N hemi
rotation_matrix_ccw10d=[cosd(-ra10) -sind(-ra10); sind(-ra10) cosd(-ra10)];  % rotate 10deg ccw N hemi

%% Check 1: that the Holland (1980) B is within bounds

GAHM_out.flag_B=1;

if B<Bmin
    fprintf (' %s %s %s %.3f %s %.3f\n', ...
        'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
        'initial B =',B,'reset = Bmin =',Bmin);  
    fprintf (fid,' %s %s %s %.3f %s %.3f\n', ...
        'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
        'initial B =',B,'reset = Bmin =',Bmin);      
    B=Bmin;
    GAHM_out.B=B;
    GAHM_out.flag_B=0;
elseif B>Bmax
    fprintf (' %s %s %s %.3f %s %.3f\n', ...
        'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
        'initial B =',B,'reset = Bmax =',Bmax);
    fprintf (fid,' %s %s %s %.3f %s %.3f\n', ...
        'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
        'initial B =',B,'reset = Bmax =',Bmax);      
    B=Bmax;
    GAHM_out.B=B;
    GAHM_out.flag_B=2;
end

%% Check GAHM vortex consistency

GAHM_out.flag(1:4,1:4)=NaN;
GAHM_out.turnangle(1:4,1:4)=25;    %default value

% check 2. All distances to isotachs in the track file = 0, NaN or missing

if all(RQuad(:)==0) || all(isnan(RQuad(:))) || all(ismissing(RQuad(:))) 
    GAHM_out.flag(1:4,1:4)=0;
    fprintf(' %s %s %s %s\n', ...
        'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
        'No valid isotachs were found in any quadrant', ...
        'Alternative Rmw required, e.g., = Rmw read in from track file');    
    fprintf(fid,' %s %s %s %s\n', ...
        'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
        'No valid isotachs were found in any quadrant', ...
        'Alternative Rmw required, e.g., = Rmw read in from track file'); 
    return
end

% check 3. SVorMax_10_tbl >= SVorMax_10_tblmin

if SVorMax_10_tbl < SVorMax_10_tblmin
    GAHM_out.flag(1:4,1:3)=2;
    GAHM_out.flag(1:4,4)=0;
    fprintf(' %s %s %s %.1f %s %.1f %s\n', ...
        'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
        'Maximum Vortex Speed @ tbl =',SVorMax_10_tbl*0.51444, ...
        '(kt) < mimimum allowable value =',SVorMax_10_tblmin*0.51444, ...
        '(kt) Alternative Rmw required, e.g., = Rmw read in from track file');
    fprintf(fid,' %s %s %s %.1f %s %.1f %s\n', ...
        'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
        'Maximum Vortex Speed @ tbl =',SVorMax_10_tbl*0.51444, ...
        '(kt) < mimimum allowable value =',SVorMax_10_tblmin*0.51444, ...
        '(kt) Alternative Rmw required, e.g., = Rmw read in from track file');
    return
end

for i=1:3      % loop through the 3 isotachs
    for q=1:4  % loop through the 4 quadrants

% check 4. if no radial distance to specified quadrant, isotach

        if RQuad(q,i) == 0  || isnan(RQuad(q,i)) || ismissing(RQuad(q,i))   
            GAHM_out.flag(q,i)=0;              
            continue
        end

% check 5. SVorQuad_10_10 >= SVorQuad_10_10min for specified quadrant, isotach

        VVorQuaduv_10_10(1:2)=VVorQuaduv_tbl(q,1:2)*rotation_matrix_ccw25d; %Quadrant vortex unit vector rotated to 10 m assuming r>1.2*Rmw         
        VVorQuad_10_10min(1:2)=VVorQuaduv_10_10(1:2)*SVorQuad_10_tblmin*BLF;
        if Gcase == 1
            VEnvQuad_10_10_check=VEnvStar_10_10*(SVorQuad_10_tblmin/SVorMax_10_tbl);
        else
            VEnvQuad_10_10_check=squeeze(squeeze(VEnvQuad_10_10(q,i,1:2)))';
        end
        SQuad_10_10min=vecnorm(VVorQuad_10_10min+VEnvQuad_10_10_check);
        if SQuad_10_10(i) < SQuad_10_10min
            GAHM_out.flag(q,i) = 3;   
            fprintf(' %s %s %s %s %i %s %i %s\n', ...
                'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
                'Vortex Isotach Speed @ tbl < minimum allowable value', ...
                'isotach=',i,'quadrant=',q,'flag(q,i)=3'); 
            fprintf(fid,' %s %s %s %s %i %s %i %s\n', ...
                'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
                'Vortex Isotach Speed @ tbl < minimum allowable value', ...
                'isotach=',i,'quadrant=',q, 'flag(q,i)=3'); 
            continue
        end

% check 6: SVorQuad_10_10 <= SVorMax_10_10 for both a 10 deg and 25 deg turning angle for each quadrant, isotach               
        if Gcase == 1
            VEnvQuad_10_10_check=VEnvStar_10_10;
        else
            VEnvQuad_10_10_check=squeeze(squeeze(VEnvQuad_10_10(q,i,1:2)))';
        end
        VVorQuaduv_10_10(1:2)=VVorQuaduv_tbl(q,1:2)*rotation_matrix_ccw10d; %Quadrant vortex unit vector rotated to 10 deg limiting case
        VVorQuad_10_10max(1:2)=VVorQuaduv_10_10(1:2)*SVorMax_10_10;         
        SQuad_10_10max_10deg=vecnorm(VVorQuad_10_10max+VEnvQuad_10_10_check);
        VVorQuaduv_10_10(1:2)=VVorQuaduv_tbl(q,1:2)*rotation_matrix_ccw25d; %Quadrant vortex unit vector rotated to 25 deg limiting case
        VVorQuad_10_10max(1:2)=VVorQuaduv_10_10(1:2)*SVorMax_10_10;         
        SQuad_10_10max_25deg=vecnorm(VVorQuad_10_10max+VEnvQuad_10_10_check);
        if SQuad_10_10(i) > SQuad_10_10max_10deg && SQuad_10_10(i) > SQuad_10_10max_25deg
            fprintf (' %s %s %s %s %i %s %i %s\n', ...
                'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
                'Vortex Isotach Speed @ 10 & 25 deg turn angles > Maximum Vortex Speed', ...
                'isotach=',i,'quadrant=',q,'flag=4'); 
            fprintf (fid,' %s %s %s %s %i %s %i %s\n', ...
                'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
                'Vortex Isotach Speed @ 10 & 25 deg turn angles > Maximum Vortex Speed', ...
                'isotach=',i,'quadrant=',q,'flag=4, Vor Iso Spd = Max Vor Spd'); 
            GAHM_out.flag(q,i)=4;
        elseif SQuad_10_10(i) > SQuad_10_10max_25deg
            delturnangle=15*(SQuad_10_10max_10deg-SQuad_10_10(i))/(SQuad_10_10max_10deg-SQuad_10_10max_25deg);
            GAHM_out.turnangle(q,i)=10+delturnangle/2;  %estimate of an intermediate turning angle
            fprintf (' %s %s %s %s %i %s %i %s %.1f %s\n', ...
                'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
                'Vortex Isotach Speed @ 25 deg turn angles > Maximum Vortex Speed', ...
                'isotach=',i,'quadrant=',q,'flag=5, new turning angle=', ...
                GAHM_out.turnangle(q,i),'deg'); 
            fprintf (fid,' %s %s %s %s %i %s %i %s %.1f %s\n', ...
                'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
                'Vortex Isotach Speed @ 25 deg turn angles > Maximum Vortex Speed', ...
                'isotach=',i,'quadrant=',q,'flag=5, new turning angle=', ...
                GAHM_out.turnangle(q,i),'deg'); 
            GAHM_out.flag(q,i)=5;            
        elseif SQuad_10_10(i) > SQuad_10_10max_10deg
            delturnangle=15*(SQuad_10_10max_25deg-SQuad_10_10(i))/(SQuad_10_10max_25deg-SQuad_10_10max_10deg);
            GAHM_out.turnangle(q,i)=25-delturnangle/2;  %estimate of an intermediate turning angle
            fprintf (' %s %s %s %s %i %s %i %s %.1f %s\n', ...
                'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
                'Vortex Isotach Speed @ 10 deg turn angles > Maximum Vortex Speed', ...
                'isotach=',i,'quadrant=',q,'flag=5, new turning angle=', ...
                GAHM_out.turnangle(q,i),'deg'); 
            fprintf (fid,' %s %s %s %s %i %s %i %s %.1f %s\n', ...
                'WARNING: Function GAHM2026_consistency: @ time =',GAHM_datetime, ...
                'Vortex Isotach Speed @ 10 deg turn angles > Maximum Vortex Speed', ...
                'isotach=',i,'quadrant=',q,'flag=5, new turning angle=', ...
                GAHM_out.turnangle(q,i),'deg'); 
            GAHM_out.flag(q,i)=5;            
        end        
        if GAHM_out.flag(q,i)==4 ||  GAHM_out.flag(q,i)==5
            continue
        end
       
% If made it to here, passed all vortex consistency checks

        GAHM_out.flag(q,i) = 1;
    end    % end of quadrant loop

end    % end of isotach loop



