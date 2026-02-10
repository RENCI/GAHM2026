% Script to compute a hyperbolic tangent taper function with the properties
%
%    taper = 1 r<=r1
%    taper = 0.5*(1 + tanh(a*(1-2*r))/tanh(a))
%    taper = 0 r>r2
%    
%    r1 and r2 are assumed to vary for each theta.
%
%    Input variables
%         array of r values
%         array of theta values
%         Speed_VPrad - speed from GAHM
%         Maskrad(1:2) - radial interpolation of mask values for inner,outer masks
%
%
%    blend_constants data structure
%         blend_constants.ntheta - number of radial lines to blend along
%                               (e.g., 24 = ever 15 deg)
%         blend_constants.nr -  number of points along each radial line to
%                               compute GAHM speed & pressure values
%         blend_constants.delr - distance (meters) between points along
%                               each radial line (radial length = nr*delr)
%         blend_constants.taper_flag = true or false - apply a taper
%                               function to GAHM speed and pressure values
%         blend_constants.taper_mindelr2r1  % minimum value for (r2-r1)/r2
%                               If violated r1 is reduced.
%         blend_constants.taper_a - taper coefficient in hyperbolic tan
%                               function (e.g., 2). 
%                        a = 1 nearly linear taper (middle of tanh range). 
%                        a > 1 uses more of tanh range and is more s-shaped. 
%
%                         Rick Luettich 6/19/2025
%                         Rick Luettich 1/28/2926
%
% 

function taper=radial_taper2(r,theta,datetime,Maskrad,blend_constants,fid)        

mindelr2r1=blend_constants.taper_mindelr2r1;
a=blend_constants.taper_a;
nr = length(r);
nt = length(theta);
Maskrad=squeeze(Maskrad);
taper(1:nt,1:nr)=0;   % preallocate for efficiency

for i=1:nt       % compute the radial taper function for each theta value

    radnum2=find(1-Maskrad(i,1:nr,2) > 0, 1, 'last');    
    r2=r(radnum2);
    
    if isempty(r2)
        r2=r(nr);
        fprintf ('%s %s %s %.0f %s %.0f\n',['Failed to find outer radius in function', ...
                ' radial_taper at'],datetime,'for theta = ',theta(i), ...
                ' r2 set = ',r2)        
        fprintf (fid,'%s %s %s %.0f %s %.0f\n',['Failed to find outer radius in function', ...
                ' radial_taper at'],datetime,' for theta = ',theta(i), ...
                ' r2 set = ',r2);    
    end

    radnum1=find(1-Maskrad(i,1:nr,1) > 0, 1, 'last');    
    r1=r(radnum1);
 
    if isempty(r1)
        radnum1=round((1-mindelr2r1)*radnum2);
        r1=r(radnum1);
        fprintf ('%s %s %s %.0f %s %.0f\n',['Failed to find inner radius in function', ...
            ' radial_taper at'],datetime,'for theta = ',theta(i), ...
            ' r1 set = (1-mindelr2r1)*r2 = ',r1')  
        fprintf (fid,'%s %s %s %.0f %s %.0f\n',['Failed to find inner radius in function', ...
            ' radial_taper at'],datetime,'for theta = ',theta(i), ...
            ' r1 set = (1-mindelr2r1)*r2 = ',r1);  
    elseif (r2-r1)/r2 < mindelr2r1
        radnum1=round((1-mindelr2r1)*radnum2);
        r1=r(radnum1);  
        fprintf ('%s %.2f %s %s %s %.0f %s %.0f\n','(r2-r1)/r2 < ',mindelr2r1, ...
            ' at', datetime,' for theta = ',theta(i), ...
            ' r1 set = (1-mindelr2r1)*r2 = ',r1')        
        fprintf (fid,'%s %.2f %s %s %s %.0f %s %.0f\n','(r2-r1)/r2 < ',mindelr2r1, ...
            ' at', datetime,' for theta = ',theta(i), ...
            ' r1 set = (1-mindelr2r1)*r2 = = ',r1'); 
    end

% compute taper using r1 & r2

    for ir=1:nr
        if r(ir) < r1 
            taper(i,ir)=1;
        elseif r(ir) >= r1 && r(ir) <= r2
            taper(i,ir)=0.5*(1 + tanh(a*(1-2*(r(ir)-r1)/(r2-r1)))/tanh(a));
        else
            taper(i,ir)=0;
        end
    end
end       
