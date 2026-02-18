function radialProfile(obj, ptype, fign, time, theta_inc)
% radialProfile  Radial profiles of wind speed or pressure at one timestep.
%
%   obj.radialProfile(ptype, fign)
%   obj.radialProfile(ptype, fign, time)
%   obj.radialProfile(ptype, fign, time, theta_inc)
%
%   ptype:
%     'velrad' - radial velocity profiles with isotach & Vmax markers
%     'prerad' - radial pressure profiles
%
%   fign      - starting figure number
%   time      - integer index, datetime, or [] (defaults to 1)
%   theta_inc - plot every Nth radial angle (default 2)
%
%   Produces subplot panels arranged according to opts.radial.layout.

    if nargin < 5 || isempty(theta_inc), theta_inc = 2; end
    if nargin < 4 || isempty(time), time = 1; end

    VPr   = obj.VPrad;
    Tdata = obj.Trackdata;
    opts  = obj.Opts;

    int = resolveRadialTime(obj, time);

    one2ten     = opts.radial.one2ten;
    SQuad_1_10  = opts.radial.isotachs;
    slotsPerFig = opts.radial.layout(1) * opts.radial.layout(2);

    rad_Vplot = strcmp(ptype,'velrad');
    rad_Pplot = strcmp(ptype,'prerad');

    hasEnv  = isfield(VPr, 'EnvVor');
    ntheta  = length(VPr.theta);
    nr      = length(VPr.r);

    nploti = fign + 1;

    %% radial velocity profiles

    if rad_Vplot
        for it = theta_inc:theta_inc:ntheta
            fignum = nploti + floor(((it-1)/theta_inc)/slotsPerFig);
            figure(fignum)
            splot = it/theta_inc - (fignum - nploti)*slotsPerFig;
            subplot(opts.radial.layout(1), opts.radial.layout(2), splot)

            if hasEnv
                S_envvor = 1.944*VPr.EnvVor(int).Speed(it,1:nr);
                S_env    = 1.944*VPr.Env(int).Speed(it,1:nr);
                plot(VPr.r, S_envvor, 'k', VPr.r, S_env, '--k')
            else
                S_vor = 1.944*VPr.VVor(int).Speed(it,1:nr);
                plot(VPr.r, S_vor, 'k')
            end
            hold on

            plot(Tdata(int).Rmax_t1, Tdata(int).Vmax_t1*1.944*one2ten, 'b*')
            if Tdata(int).Vmax_t2 ~= 0
                plot(Tdata(int).Rmax_t2, Tdata(int).Vmax_t2*1.944*one2ten, 'r*')
            end

            for ii = 1:length(SQuad_1_10)
                if Tdata(int).RQuad_t1(Tdata(int).RP1(it),ii) ~= 0
                    plot(Tdata(int).RQuad_t1(Tdata(int).RP1(it),ii), SQuad_1_10(ii)*one2ten, 'bo')
                end
                if Tdata(int).RQuad_t1(Tdata(int).RP2(it),ii) ~= 0
                    plot(Tdata(int).RQuad_t1(Tdata(int).RP2(it),ii), SQuad_1_10(ii)*one2ten, 'bx')
                end
                if Tdata(int).RQuad_t2(Tdata(int).RP1(it),ii) ~= 0
                    plot(Tdata(int).RQuad_t2(Tdata(int).RP1(it),ii), SQuad_1_10(ii)*one2ten, 'ro')
                end
                if Tdata(int).RQuad_t2(Tdata(int).RP2(it),ii) ~= 0
                    plot(Tdata(int).RQuad_t2(Tdata(int).RP2(it),ii), SQuad_1_10(ii)*one2ten, 'rx')
                end
            end

            text(2e5, 90, ['theta=' num2str(VPr.theta(it),'%.1f')])

            QRP1_t1 = ['RPQ' num2str(Tdata(int).RP1(it)) ' t1'];
            QRP2_t1 = ['RPQ' num2str(Tdata(int).RP2(it)) ' t1'];
            QRP1_t2 = ['RPQ' num2str(Tdata(int).RP1(it)) ' t2'];
            QRP2_t2 = ['RPQ' num2str(Tdata(int).RP2(it)) ' t2'];

            lastSlotOnFig = (splot == slotsPerFig);
            lastSlotTotal = (splot == floor(ntheta/theta_inc) - (fignum - nploti)*slotsPerFig);
            if lastSlotOnFig || lastSlotTotal
                if hasEnv
                    if Tdata(int).Vmax_t2 == 0
                        lgd = legend('EV Speed 10 10','E Speed 10 10','Vmax t1',QRP1_t1,QRP2_t1);
                    else
                        lgd = legend('EV Speed 10 10','E Speed 10 10','Vmax t1','Vmax t2',QRP1_t1,QRP2_t1,QRP1_t2,QRP2_t2);
                    end
                else
                    if Tdata(int).Vmax_t2 == 0
                        lgd = legend('Vortex Speed','Vmax t1',QRP1_t1,QRP2_t1);
                    else
                        lgd = legend('Vortex Speed','Vmax t1','Vmax t2',QRP1_t1,QRP2_t1,QRP1_t2,QRP2_t2);
                    end
                end
                lgd.Location = 'northeast';
            end
        end
    end

    %% radial pressure profiles

    if rad_Pplot
        for it = theta_inc:theta_inc:ntheta
            fignum = nploti + floor(((it-1)/theta_inc)/slotsPerFig);
            figure(fignum)
            splot = it/theta_inc - (fignum - nploti)*slotsPerFig;
            subplot(opts.radial.layout(1), opts.radial.layout(2), splot)

            if hasEnv
                P1 = VPr.EnvVor(int).Press(it,1:nr);
                P2 = VPr.Env(int).Press(it,1:nr);
                plot(VPr.r, P1, 'k', VPr.r, P2, '--k');
                lgd = legend('Total Pres','Env Pres');
            else
                P1 = VPr.VVor(int).Press(it,1:nr);
                plot(VPr.r, P1, 'k');
                lgd = legend('Vortex Pres');
            end
            ylim([940 1020]);
            hold on
            text(3e5, 1000, ['theta=' num2str(VPr.theta(it),'%.1f')])
            lgd.Location = 'southeast';
        end
    end

end
