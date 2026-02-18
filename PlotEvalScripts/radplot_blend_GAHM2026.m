%.........................................................................
%
%  Plot radial profiles from GAHM2026.m output
%
%  Inputs:
%    VPrad      - radial grid data struct from GAHM2026.m containing:
%                   .r, .theta  - radial grid coordinates
%                   .VVor(i)    - vortex fields (.Speed, .Press, .VelU, .VelV)
%                   .Env(i)     - environmental fields (if available)
%                   .EnvVor(i)  - combined env+vortex fields (if available)
%    Trackdata  - track data with Rmax, Vmax, quadrant info
%    theta_inc  - plot every Nth radial angle (e.g., 2 = every other)
%    ptype      - 'velrad' for velocity or 'prerad' for pressure
%    fign       - starting figure number
%    opts       - (optional) options struct from plot_defaults()
%
%                 11/7/2024   - Rick Luettich
%                 2/8/2026    - modernized (VPrad struct, opts pattern)

function []=radplot_blend_GAHM2026(VPrad,Trackdata,theta_inc,ptype,fign,opts)

if nargin < 6
    opts = plot_defaults();
end

one2ten = opts.radial.one2ten;
SQuad_1_10 = opts.radial.isotachs;
slotsPerFig = opts.radial.layout(1) * opts.radial.layout(2);

rad_Vplot = strcmp(ptype,'velrad');
rad_Pplot = strcmp(ptype,'prerad');

hasEnv = isfield(VPrad, 'EnvVor');

itot = length(VPrad.VVor);
ntheta = length(VPrad.theta);
nr = length(VPrad.r);

%% radial velocity plots

if rad_Vplot
    for int = 1:itot
        nploti = fign + 1;
        for it = theta_inc:theta_inc:ntheta
            fign = nploti + floor(((it-1)/theta_inc)/slotsPerFig);
            figure(fign)
            splot = it/theta_inc - (fign-nploti)*slotsPerFig;
            subplot(opts.radial.layout(1), opts.radial.layout(2), splot)

            if hasEnv
                S_envvor(:) = 1.944*VPrad.EnvVor(int).Speed(it,1:nr);
                S_env(:) = 1.944*VPrad.Env(int).Speed(it,1:nr);
                plot(VPrad.r, S_envvor', 'k', VPrad.r, S_env, '--k')
            else
                S_vor(:) = 1.944*VPrad.VVor(int).Speed(it,1:nr);
                plot(VPrad.r, S_vor', 'k')
            end
            hold on
            plot(Trackdata(int).Rmax_t1, Trackdata(int).Vmax_t1*1.944*one2ten, 'b*')
            if Trackdata(int).Vmax_t2 ~= 0
                plot(Trackdata(int).Rmax_t2, Trackdata(int).Vmax_t2*1.944*one2ten, 'r*')
            end
            for ii = 1:length(SQuad_1_10)
                if Trackdata(int).RQuad_t1(Trackdata(int).RP1(it),ii) ~= 0
                    plot(Trackdata(int).RQuad_t1(Trackdata(int).RP1(it),ii), SQuad_1_10(ii)*one2ten, 'bo')
                end
                if Trackdata(int).RQuad_t1(Trackdata(int).RP2(it),ii) ~= 0
                    plot(Trackdata(int).RQuad_t1(Trackdata(int).RP2(it),ii), SQuad_1_10(ii)*one2ten, 'bx')
                end
                if Trackdata(int).RQuad_t2(Trackdata(int).RP1(it),ii) ~= 0
                    plot(Trackdata(int).RQuad_t2(Trackdata(int).RP1(it),ii), SQuad_1_10(ii)*one2ten, 'ro')
                end
                if Trackdata(int).RQuad_t2(Trackdata(int).RP2(it),ii) ~= 0
                    plot(Trackdata(int).RQuad_t2(Trackdata(int).RP2(it),ii), SQuad_1_10(ii)*one2ten, 'rx')
                end
            end
            text(2e5, 90, ['theta=' num2str(VPrad.theta(it),'%.1f')])
            QRP1_t1 = ['RPQ' num2str(Trackdata(int).RP1(it)) ' t1'];
            QRP2_t1 = ['RPQ' num2str(Trackdata(int).RP2(it)) ' t1'];
            QRP1_t2 = ['RPQ' num2str(Trackdata(int).RP1(it)) ' t2'];
            QRP2_t2 = ['RPQ' num2str(Trackdata(int).RP2(it)) ' t2'];

            if splot == slotsPerFig || splot == floor(ntheta/theta_inc)-(fign-nploti)*slotsPerFig
                if hasEnv
                    if Trackdata(int).Vmax_t2 == 0
                        lgd = legend('EV Speed 10 10','E Speed 10 10','Vmax t1',QRP1_t1,QRP2_t1);
                    else
                        lgd = legend('EV Speed 10 10','E Speed 10 10','Vmax t1','Vmax t2',QRP1_t1,QRP2_t1,QRP1_t2,QRP2_t2);
                    end
                else
                    if Trackdata(int).Vmax_t2 == 0
                        lgd = legend('Vortex Speed','Vmax t1',QRP1_t1,QRP2_t1);
                    else
                        lgd = legend('Vortex Speed','Vmax t1','Vmax t2',QRP1_t1,QRP2_t1,QRP1_t2,QRP2_t2);
                    end
                end
                lgd.Location = 'northeast';
            end
        end
    end
end

%% radial pressure plots

if rad_Pplot
    for int = 1:itot
        nploti = fign + 1;
        for it = theta_inc:theta_inc:ntheta
            fign = nploti + floor(((it-1)/theta_inc)/slotsPerFig);
            figure(fign)
            splot = it/theta_inc - (fign-nploti)*slotsPerFig;
            subplot(opts.radial.layout(1), opts.radial.layout(2), splot)
            if hasEnv
                P1 = VPrad.EnvVor(int).Press(it,1:nr);
                P2 = VPrad.Env(int).Press(it,1:nr);
                hp = plot(VPrad.r, P1, 'k', VPrad.r, P2, '--k');
                lgd = legend('Total Pres','Env Pres');
            else
                P1 = VPrad.VVor(int).Press(it,1:nr);
                hp = plot(VPrad.r, P1, 'k');
                lgd = legend('Vortex Pres');
            end
            ylim([940 1020]);
            hold on
            text(3e5, 1000, ['theta=' num2str(VPrad.theta(it),'%.1f')])
            lgd.Location = 'southeast';
        end
    end
end
