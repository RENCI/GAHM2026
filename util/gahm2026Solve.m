function GAHM_out = gahm2026Solve(GAHM_in,GAHM_constants,fid)
%--------------------------------------------------------------------------
%  Unified GAHM2026 parameter solver
%
%  Combines the shared logic from GAHM2026v3e.m and GAHM2026v4a.m into a
%  single entry point. Dispatches to version-specific solver backends:
%     version 3: custom two-phase iterative solver (no toolbox required)
%     version 4: fsolve-based solver (requires Optimization Toolbox)
%
%  See documentation/GAHM_struct.md for full GAHM data structure definition.
%
%  Input:
%     GAHM_in        - GAHM data structure from gahm2026Consistency
%     GAHM_constants - constants structure (must include .version = 3 or 4)
%     fid            - file ID for diagnostics output
%
%  Output:
%     GAHM_out       - GAHM data structure with computed parameters
%
%              Rick Luettich 2024-25, unified by refactoring 2/2026
%--------------------------------------------------------------------------

    %% determine solver version

    GAHM_version = GAHM_constants.version;

    %% unpack input and set up

    BLF = GAHM_constants.BLF;
    Bg0M = GAHM_constants.Bg0M;

    GAHM_datetime = GAHM_in.datetime;
    LatNS = GAHM_in.Eye(2);
    SQuad_10_10 = GAHM_in.SQuad_10_10;
    SVorMax_10_10 = GAHM_in.SVorMax_10_10;
    SVorMax_10_tbl = SVorMax_10_10/BLF;
    VEnvStar_10_10 = GAHM_in.VEnvStar_10_10;
    Rmax_in = GAHM_in.Rmax_in;
    RQuad = GAHM_in.RQuad;
    VEnvQuad_10_10 = GAHM_in.VEnvQuad_10_10;
    B = GAHM_in.B;
    Gcase = GAHM_in.Gcase;
    flag = GAHM_in.flag;
    numiso = GAHM_in.numiso;
    GAHM_out = GAHM_in;
    GAHM_out.flag_exit = 0;

    c = gahmPhysicalConstants();
    omega = c.omega;
    f = 2*omega*sind(LatNS); % 1/s

    VVorQuaduv_tbl = quadrantUnitVectors(LatNS);
    hemiSign = sign(LatNS);
    if hemiSign == 0, hemiSign = 1; end

    %% put NaNs in output variables.  Replace with valid values if available.

    GAHM_out.SVorQuad_10_10(1:4,1:4) = NaN;
    GAHM_out.Rmax(1:4,1:4) = NaN;
    GAHM_out.Ro(1:4,1:4) = NaN;
    GAHM_out.A(1:4,1:4) = NaN;
    GAHM_out.Bg(1:4,1:4) = NaN;
    GAHM_out.phi(1:4,1:4) = NaN;
    GAHM_out.RmaxQ(1:4) = NaN;
    GAHM_out.Rmic(1:4,1:4) = NaN;
    GAHM_out.Bgicmax(1:4,1:4) = NaN;

    %% main compute loops

    for q = 1:4 % loop through the 4 quadrants

        for i = 1:3 % loop through the isotachs

            Bgicmax = 1;

            if flag(q,i) == 1 || flag(q,i) == 5
                ra = GAHM_in.turnangle(q,i)*hemiSign;
                rotation_matrix_ccw = [cosd(-ra) -sind(-ra); sind(-ra) cosd(-ra)];
                VVorQuaduv_10 = VVorQuaduv_tbl(q,:)*rotation_matrix_ccw;
                if Gcase == 1
                    SVorQuad_10_10 = SQuad_10_10(i)/vecnorm(VVorQuaduv_10+VEnvStar_10_10/SVorMax_10_10);
                    GAHM_out.SVorQuad_10_10(q,i) = SVorQuad_10_10;
                    VEnvQuad_10_10(q,i,1:2) = VEnvStar_10_10(1:2)*SVorQuad_10_10/SVorMax_10_10;
                    GAHM_out.VEnvQuad_10_10(q,i,1:2) = VEnvQuad_10_10(q,i,1:2);
                elseif Gcase == 2
                    SEnvQuad_10_10 = vecnorm(VEnvQuad_10_10(q,i,:));
                    if SEnvQuad_10_10 == 0
                        VEnvQuaduv_10_10(1:2) = VEnvQuad_10_10(q,i,1:2);
                    else
                        VEnvQuaduv_10_10(1:2) = VEnvQuad_10_10(q,i,1:2)/SEnvQuad_10_10;
                    end
                    acoef = 1;
                    bcoef = 2*SEnvQuad_10_10*sum(VVorQuaduv_10.*VEnvQuaduv_10_10);
                    ccoef = SEnvQuad_10_10*SEnvQuad_10_10-SQuad_10_10(i)*SQuad_10_10(i);
                    SVorQuad_10_10 = (-bcoef+sqrt(bcoef*bcoef-4*acoef*ccoef))/(2*acoef);
                    GAHM_out.SVorQuad_10_10(q,i) = SVorQuad_10_10;
                    if ~isreal(SVorQuad_10_10)
                        logMsg(fid, "ERROR", "@ time = %s Imaginary solution for Vortex isotach speed, quadrant=%i isotach=%i", GAHM_datetime, q, i);
                    end
                    if SVorQuad_10_10 < 0
                        logMsg(fid, "ERROR", "@ time = %s Solution for Vortex isotach speed < 0, quadrant=%i isotach=%i", GAHM_datetime, q, i);
                    end
                end
                if SVorQuad_10_10 > SVorMax_10_10
                    logMsg(fid, "ERROR", "@ time = %s Solution for Vortex isotach speed > Maximum vortex speed, quadrant=%i isotach=%i", GAHM_datetime, q, i);
                end

                SVorQuad_10_tbl = SVorQuad_10_10/BLF;

                if GAHM_version == 3
                    [Rmax, Ro, Bg, phi, A_qi, Rmic, Bgicmax, flag_qi] = ...
                        solve_flag1or5_v3(GAHM_datetime, B, Bg0M, SVorMax_10_tbl, ...
                        SVorQuad_10_tbl, f, Rmax_in, RQuad(q,i), q, i, fid);
                    GAHM_out.Rmic(q,i) = Rmic;
                    GAHM_out.Bgicmax(q,i) = Bgicmax;
                elseif GAHM_version == 4
                    [Rmax, Ro, Bg, phi, A_qi, flag_qi] = ...
                        solve_flag1or5_v4(GAHM_datetime, B, Bg0M, GAHM_constants.c0, ...
                        SVorMax_10_tbl, SVorQuad_10_tbl, f, RQuad(q,i), q, i, fid);
                end
                if flag_qi == 9
                    flag(q,i) = 9;
                else
                    GAHM_out.Rmax(q,i) = Rmax;
                    GAHM_out.Ro(q,i) = Ro;
                    GAHM_out.A(q,i) = A_qi;
                    GAHM_out.Bg(q,i) = Bg;
                    GAHM_out.phi(q,i) = phi;
                end

            end % end of flag(q,i) == 1 or 5 cases

            if flag(q,i) == 4
                Rmax = RQuad(q,i);
                Ro = SVorMax_10_tbl/(Rmax*f);
                GAHM_out.SVorQuad_10_10(q,i) = SVorMax_10_10;
                GAHM_out.Rmax(q,i) = Rmax;
                GAHM_out.Ro(q,i) = Ro;
                Bg_in = Bg0M*B;
                [Bg, Bg_status] = compute_Bg(GAHM_version,GAHM_datetime,B,Ro,Bg_in,i,q,fid);
                if GAHM_version == 3
                    if Bg_status > Bgicmax
                        Bgicmax = Bg_status;
                    end
                    if Bg_status == 100
                        flag(q,i) = 9;
                    end
                    GAHM_out.Rmic(q,i) = 0;
                    GAHM_out.Bgicmax(q,i) = Bg_status;
                elseif GAHM_version == 4
                    if ~isreal(Bg) || Bg_status <= 0
                        Bg = NaN;
                        flag(q,i) = 9;
                    end
                end
                phi = 1 + 1/(Bg*(1+Ro));
                GAHM_out.A(q,i) = phi*Rmax^B;
                GAHM_out.Bg(q,i) = Bg;
                GAHM_out.phi(q,i) = phi;
            end % flag(q,i) == 4 case

            if Gcase == 1
                GAHM_out.VEnvQuad_10_10(q,i,1:2) = VEnvStar_10_10(1:2);
            end

        end % end of loop over 3 isotachs

        % select the Rmax value from the greatest available isotach as representing
        % the vortex Rmax in this quadrant

        if ~isnan(GAHM_out.Rmax(q,3))
            GAHM_out.RmaxQ(q) = GAHM_out.Rmax(q,3);
        elseif ~isnan(GAHM_out.Rmax(q,2))
            GAHM_out.RmaxQ(q) = GAHM_out.Rmax(q,2);
        elseif ~isnan(GAHM_out.Rmax(q,1))
            GAHM_out.RmaxQ(q) = GAHM_out.Rmax(q,1);
        end

    end % end of loop over 4 quadrants

    % Fill in RmaxQ values for the case that a particular quadrant RmaxQ = NaN.
    % In this case average the other values.  Note, eliminate the case where all
    % RmaxQ = NaN

    if sum(flag(1:4,4)) ~= 0
        RmaxQmean = 0;
        num = 0;
        for q = 1:4
            if ~isnan(GAHM_out.RmaxQ(q))
                RmaxQmean = RmaxQmean+GAHM_out.RmaxQ(q);
                num = num+1;
            end
        end
        Rmax = RmaxQmean/num;
        for q = 1:4
            if isnan(GAHM_out.RmaxQ(q))
                GAHM_out.RmaxQ(q) = Rmax;
            end
        end
    end

    % deal with cases where no good isotachs, i.e.,
    %     all isotach values are missing - flag(1:4,1:3) = 0
    %     SVorMax_10_tbl < SVorMax_10_tblmin - flag(1:4,1:3) = 2
    % In both cases the default flags(1:4,4)=0
    % Use Rmax=Rmax_in, compute Bg, A, phi and then populate RmaxQ(1:4) and
    % GAHM_out values.  Note, results are put into the iso=4 column if
    % flag(1:4,1:3)=0 (numiso=0) and isotach columns if flag(1:4,1:3)=2 (numiso>0).

    if sum(flag(1:4,4)) == 0
        Rmax = Rmax_in;
        Ro = SVorMax_10_tbl/(Rmax*f);
        GAHM_out.Rmax(1:4,4) = Rmax;
        GAHM_out.Ro(1:4,4) = Ro;
        GAHM_out.RmaxQ(1:4) = Rmax;
        Bg_in = Bg0M*B;
        [Bg, Bg_status] = compute_Bg(GAHM_version,GAHM_datetime,B,Ro,Bg_in,4,5,fid);
        if GAHM_version == 3
            if Bg_status == 100
                flag(1:4,4) = 9;
            end
            GAHM_out.Rmic(1:4,4) = 0;
            GAHM_out.Bgicmax(1:4,4) = Bg_status;
        elseif GAHM_version == 4
            if ~isreal(Bg) || Bg_status <= 0
                Bg = NaN;
                flag(1:4,4) = 9;
            end
        end
        phi = 1 + 1/(Bg*(1+Ro));
        GAHM_out.A(1:4,4) = phi*Rmax^B;
        GAHM_out.Bg(1:4,4) = Bg;
        GAHM_out.phi(1:4,4) = phi;
        for i = 1:numiso
            GAHM_out.Rmax(1:4,i) = Rmax;
            GAHM_out.Ro(1:4,i) = Ro;
            GAHM_out.A(1:4,i) = phi*Rmax^B;
            GAHM_out.Bg(1:4,i) = Bg;
            GAHM_out.phi(1:4,i) = phi;
        end
    else

        % finally check individual isotach - quadrant values for flag(q,i) = 0 or 3.
        % Fill in Rmax & other values from the corresponding quadrant either from
        % the next higher isotach or RmaxQ

        for i = 1:numiso
            for q = 1:4
                if flag(q,i) == 0 || flag(q,i) == 3
                    if i == 1 && ~isnan(GAHM_out.Rmax(q,i+1))
                        GAHM_out.Rmax(q,i) = GAHM_out.Rmax(q,i+1);
                        GAHM_out.Ro(q,i) = GAHM_out.Ro(q,i+1);
                        GAHM_out.Rmic(q,i) = GAHM_out.Rmic(q,i+1);
                        GAHM_out.Bgicmax(q,i) = GAHM_out.Bgicmax(q,i+1);
                        GAHM_out.A(q,i) = GAHM_out.A(q,i+1);
                        GAHM_out.Bg(q,i) = GAHM_out.Bg(q,i+1);
                        GAHM_out.phi(q,i) = GAHM_out.phi(q,i+1);
                    else
                        Rmax = GAHM_out.RmaxQ(q);
                        Ro = SVorMax_10_tbl/(Rmax*f);
                        Bg_in = Bg0M*B;
                        [Bg, Bg_status] = compute_Bg(GAHM_version,GAHM_datetime,B,Ro,Bg_in,4,q,fid);
                        if GAHM_version == 3
                            if Bg_status == 100
                                flag(q,i) = 9;
                            end
                            GAHM_out.Rmic(q,i) = 0;
                            GAHM_out.Bgicmax(q,i) = Bg_status;
                        elseif GAHM_version == 4
                            if ~isreal(Bg) || Bg_status <= 0
                                Bg = NaN;
                                flag(q,i) = 9;
                            end
                        end
                        phi = 1 + 1/(Bg*(1+Ro));
                        GAHM_out.Rmax(q,4) = Rmax;
                        GAHM_out.Ro(q,4) = Ro;
                        GAHM_out.A(q,4) = phi*Rmax^B;
                        GAHM_out.Bg(q,4) = Bg;
                        GAHM_out.phi(q,4) = phi;
                    end
                end
            end
        end
    end

    %  compute the distance to the actual maximum velocity and the angle to it

    [Rmax_tot, Rmax_tot_angle] = computeRmaxTot(GAHM_out.RmaxQ,VEnvStar_10_10);

    Ro = SVorMax_10_tbl/(Rmax_tot*f);
    [Bg_tot, Bg_status] = compute_Bg(GAHM_version,GAHM_datetime,B,Ro,Bg0M*B,4,9,fid);
    if GAHM_version == 4
        if ~isreal(Bg_tot) || Bg_status <= 0
            Bg_tot = NaN;
        end
    end
    GAHM_out.Rmax_tot = Rmax_tot;
    GAHM_out.Rmax_tot_angle = Rmax_tot_angle;
    GAHM_out.Bg_tot = Bg_tot;

    GAHM_out.flag = flag;

end % end of gahm2026Solve


%%=========================================================================
%  Version-specific solver for flag==1||5 cases
%%=========================================================================

%% v3: iterative solver for Rmax and Bg (no toolbox required)

function [Rmax, Ro, Bg, phi, A_qi, Rmic, Bgicmax, flag_qi] = ...
        solve_flag1or5_v3(GAHM_datetime, B, Bg0M, SVorMax_10_tbl, ...
        SVorQuad_10_tbl, f, Rmax_in, RQuad_qi, q, i, fid)

    flag_qi = 0;
    Bgicmax = 1;
    Factor = (SVorQuad_10_tbl/SVorMax_10_tbl)*(SVorQuad_10_tbl/f+RQuad_qi);
    Rmic = 0;
    Rmax_tol = 100;
    Bg_in = Bg0M*B;
    if ~isnan(Rmax_in)
        Rmax = Rmax_in;
    else
        Rmax = 40000;  % this might be abstracted into the config file
    end
    while abs(Rmax_tol) > 1
        Rmic = Rmic+1;
        if Rmic > 200
            logMsg(fid, "WARNING", "@ time %s Rmax failed to converge in 200 iterations, quadrant=%i isotach=%i final tol=%.2f", GAHM_datetime, q, i, Rmax_tol);
            flag_qi = 9;
            break
        end
        Ro = SVorMax_10_tbl/(Rmax*f);
        [Bg, Bgic] = compute_Bg_iterative(GAHM_datetime,B,Ro,Bg_in,i,q,fid);
        if Bgic > Bgicmax
            Bgicmax = Bgic;
        end
        if Bgic == 100
            flag_qi = 9;
        end
        phi = 1 + 1/(Bg*(1+Ro));
        Rmax2 = (Factor*RQuad_qi^Bg/((1+Ro)*exp(phi*(1-(Rmax/RQuad_qi)^Bg))))^(1/(Bg+1));
        Rmax_tol = Rmax2-Rmax;
        Rmax = Rmax2;
        Bg_in = Bg;
    end
    A_qi = phi*Rmax^B;
end


%% v4: fsolve-based solver for coupled Bg and c=Rmax/r (requires Optimization Toolbox)

function [Rmax, Ro, Bg, phi, A_qi, flag_qi] = ...
        solve_flag1or5_v4(GAHM_datetime, B, Bg0M, c0, SVorMax_10_tbl, ...
        SVorQuad_10_tbl, f, RQuad_qi, q, i, fid)

    flag_qi = 0;
    Rr = SVorMax_10_tbl/(RQuad_qi*f);
    VgOVmax = SVorQuad_10_tbl/SVorMax_10_tbl;
    x0 = [Bg0M*B,c0];
    fun = @(x)GAHM2026a(x,B,Rr,VgOVmax);
    options = optimoptions('fsolve','Display','off');
    [x,fsolve_fval,fsolve_exitflag,fsolve_output] = fsolve(fun,x0,options);
    if ~isreal(x)
        logMsg(fid, "WARNING", "@ time %s fsolve returned imaginary values for Bg, c, quadrant=%i isotach=%i. Try adjusting GAHM_constants.Bg0M or GAHM_constants.c0.", GAHM_datetime, q, i);
        flag_qi = 9;
        Rmax = NaN; Ro = NaN; Bg = NaN; phi = NaN; A_qi = NaN;
    elseif fsolve_exitflag <= 0
        logMsg(fid, "WARNING", "@ time %s fsolve did not converge solving Bg, c, quadrant=%i isotach=%i exitflag=%i. Try adjusting GAHM_constants.Bg0M or GAHM_constants.c0.", GAHM_datetime, q, i, fsolve_exitflag);
        flag_qi = 9;
        Rmax = NaN; Ro = NaN; Bg = NaN; phi = NaN; A_qi = NaN;
    else
        Bg = x(1);
        Rmax = RQuad_qi*x(2);
        Ro = Rr/x(2);
        phi = 1+1/(Bg*(1+Ro));
        A_qi = phi*Rmax^Bg;
    end
end


%%=========================================================================
%  Unified compute_Bg — dispatches to iterative or fsolve backend
%%=========================================================================

function [Bg, status] = compute_Bg(version, time, B, Ro, Bg_in, i, q, fid)

    if version == 3
        [Bg, status] = compute_Bg_iterative(time, B, Ro, Bg_in, i, q, fid);
    elseif version == 4
        [Bg, status] = compute_Bg_fsolve(time, B, Ro, Bg_in, i, q, fid);
    end
end


%%=========================================================================
%  compute_Bg backends
%%=========================================================================

%% Iterative backend (v3 logic, no toolbox required)
%  Returns: [Bg, Bgic] where Bgic = iteration count (100 = failure)

function [Bg, Bgic] = compute_Bg_iterative(time,B,Ro,Bg_in,i,q,fid)

    if Bg_in == 0 || isnan(Bg_in)
        Bgi = 1.1*B;
        if Bgi < 0.5
            Bgi = 0.5;
        end
    else
        Bgi = Bg_in;
    end
    Bgic = 0;
    Bg_tol = 1;
    while abs(Bg_tol) > 0.001
        Bgic = Bgic+1;
        if Bgic < 50
            if Bgic == 1
                Bg = Bgi;
            end
            Bg2 = B*((1+Ro)/Ro)*exp(1/(Bg*(1+Ro)))-1/(1+Ro);
        elseif Bgic < 100
            if Bgic == 50
                Bg = Bgi;
            end
            Bg2 = 1/((log(Bg+1/(1+Ro))-log(B*(1+Ro)/Ro))*(1+Ro));
        elseif Bgic == 100
            logMsg(fid, "WARNING", "@ time %s Bg failed to converge in 100 iterations, quadrant=%i isotach=%i B=%.4f Ro=%.2f Bg=%.4f final tol=%.4f", time, q, i, B, Ro, Bg, Bg_tol);
            break
        end
        if Bg2 < 0 || ~isreal(Bg2)
            Bg2 = 0.001;
        end
        Bg_tol = Bg2-Bg;
        Bg = Bg2;
    end
end


%% fsolve backend (v4 logic, requires Optimization Toolbox)
%  Returns: [Bg, fsolve_exitflag]

function [y,fsolve_exitflag] = compute_Bg_fsolve(time,B,Ro,Bg_in,i,q,fid)

    fun = @(y)GAHM2026b(y,B,Ro);
    options = optimoptions('fsolve','Display','off');
    y0 = Bg_in;
    [y,fsolve_fval,fsolve_exitflag,fsolve_output] = fsolve(fun,y0,options);

    if ~isreal(y)
        logMsg(fid, "WARNING", "@ time %s fsolve returned imaginary value for Bg, quadrant=%i isotach=%i B=%.4f Ro=%.2f Bg=%.2f. Try adjusting GAHM_constants.Bg0M", time, q, i, B, Ro, y);
    end

    if fsolve_exitflag <= 0
        logMsg(fid, "WARNING", "@ time %s fsolve did not converge for Bg, quadrant=%i isotach=%i B=%.4f Ro=%.2f Bg=%.2f exitflag=%i. Try adjusting GAHM_constants.Bg0M", time, q, i, B, Ro, y, fsolve_exitflag);
    end

end


%%=========================================================================
%  v4 equation functions (used by fsolve)
%%=========================================================================

%% Full GAHM2026 nondimensionalized equations (Luettich 2025)
%  Solves for x(1)=Bg, x(2)=c=Rmw/r simultaneously
%  Used in solve_flag1or5_v4

function F = GAHM2026a(x,B,Rr,VgOVmax)

    e1 = exp(1/(x(1)*(1+Rr/x(2))));
    e2 = exp((1 + 1/(x(1)*(1+Rr/x(2))))*(1-x(2)^x(1)));

    F(1) = x(1) - (B*e1*(1+x(2)/Rr) - 1/(1+Rr/x(2)));
    F(2) = VgOVmax - (sqrt((1+x(2)/Rr)*x(2)^x(1)*e2 + (1/(2*Rr))^2) - 1/(2*Rr));

end


%% Bg-only GAHM2026 equation (Luettich 2025)
%  Used by compute_Bg_fsolve when Rmax is specified

function F = GAHM2026b(y,B,Ro)

    e1 = exp(1/(y*(1+Ro)));

    F = y - (B*e1*(1+1/Ro) - 1/(1+Ro));

end
