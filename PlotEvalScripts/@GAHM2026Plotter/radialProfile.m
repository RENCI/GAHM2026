function radialProfile(obj, ptype, ftype, fign, time, theta_inc)
% radialProfile  Radial profiles of wind speed or pressure at one timestep.
%  To use this, must first issue command: 
%      obj = GAHM2026Plotter(R);
%  where R is the datastructure from
%      R=run_GAHM2026(<config>);
%
%   obj.radialProfile(ptype, ftype)
%   obj.radialProfile(ptype, ftype, fign)
%   obj.radialProfile(ptype, ftype, fign, time)
%   obj.radialProfile(ptype, ftype, fign, time, theta_inc)
%
%   Required parameters:
%
%   ptype:
%     'velrad' - radial velocity profiles with isotach & Vmax markers
%     'prerad' - radial pressure profiles
%   ftype:
%     'envhur' - env + vortex combined fields
%     'hur'    - vortex fields only
%     'env'    - environmental fields only
%
%   Optional parameters:
%
%   fign      - starting figure number (defaults to 1; [] = auto)
%   time      - integer index, datetime, or [] (defaults to 1)
%   theta_inc - plot every Nth radial angle (default 2)
%
%   Produces subplot panels arranged according to opts.radial.layout.
%
%     Fixed Vmax to kts, Rmax to m, starting fig number  2/24/2026
%     added ftype & made all plot types functional        3/2/2026
%
%-------------------------------------------------------------------

    if nargin < 6 || isempty(theta_inc), theta_inc = 2; end
    if nargin < 5 || isempty(time), time = 1; end
    if nargin < 4 || isempty(fign), fign = 1; end
    if nargin < 3 || isempty(ftype), ftype = 'envhur'; end

    VPr   = obj.VPrad;
    Tdata = obj.Trackdata;
    opts  = obj.Opts;

    int = resolveRadialTime(obj, time);

    one2ten     = opts.radial.one2ten;
    SQuad_1_10  = opts.radial.isotachs;
    slotsPerFig = opts.radial.layout(1) * opts.radial.layout(2);

    rad_Vplot = strcmp(ptype,'velrad');
    rad_Pplot = strcmp(ptype,'prerad');

    hasVor    = isfield(VPr, 'VVor_bt');
    hasEnv    = isfield(VPr, 'Env');
    hasEnvVor = isfield(VPr, 'EnvVor_bt');

    rad_EnvVor = strcmp(ftype,'envhur') && hasEnvVor;
    rad_Vor    = strcmp(ftype,'hur')    && hasVor;
    rad_Env    = strcmp(ftype,'env')    && hasEnv;

    ntheta  = length(VPr.theta);
    nr      = length(VPr.r);

    if isempty(fign)
        f=figure;
        nploti=f.Number;
    else
        nploti = fign;
    end

    %% radial velocity profiles
    ax=[];
    idx=0;
    if rad_Vplot
        for it = theta_inc:theta_inc:ntheta
            idx=idx+1;
            fignum = nploti + floor(((it-1)/theta_inc)/slotsPerFig);
            figure(fignum)
            splot = it/theta_inc - (fignum - nploti)*slotsPerFig;
            ax(idx)=subplot(numel(theta_inc:theta_inc:ntheta)/opts.radial.layout(2), opts.radial.layout(2), splot);

            if rad_EnvVor
                S_envvor = 1.944*VPr.EnvVor_bt(int).Speed(it,1:nr);
                plot(VPr.r, S_envvor, 'k')
                hold on
                if hasEnv
                    S_env = 1.944*VPr.Env(int).Speed(it,1:nr);
                    plot(VPr.r, S_env, '--r')
                end
            elseif rad_Vor
                S_vor = 1.944*VPr.VVor_bt(int).Speed(it,1:nr);
                plot(VPr.r, S_vor, 'k')
                hold on
            elseif rad_Env
                S_env = 1.944*VPr.Env(int).Speed(it,1:nr);
                plot(VPr.r, S_env, '--r')
                hold on
            end

            plot(Tdata(int).Rmax_t1*1852, Tdata(int).Vmax_t1*one2ten, 'b*')
            if Tdata(int).Vmax_t2 ~= 0
                plot(Tdata(int).Rmax_t2*1852, Tdata(int).Vmax_t2*one2ten, 'r*')
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
                if rad_EnvVor
                    if Tdata(int).Vmax_t2 == 0
                        lgd = legend('EV Speed 10 10','E Speed 10 10','Vmax t1',QRP1_t1,QRP2_t1);
                    else
                        lgd = legend('EV Speed 10 10','E Speed 10 10','Vmax t1','Vmax t2',QRP1_t1,QRP2_t1,QRP1_t2,QRP2_t2);
                    end
                elseif rad_Vor
                    if Tdata(int).Vmax_t2 == 0
                        lgd = legend('Vortex Speed','Vmax t1',QRP1_t1,QRP2_t1);
                    else
                        lgd = legend('Vortex Speed','Vmax t1','Vmax t2',QRP1_t1,QRP2_t1,QRP1_t2,QRP2_t2);
                    end
                elseif rad_Env
                    if Tdata(int).Vmax_t2 == 0
                        lgd = legend('Env Speed','Vmax t1',QRP1_t1,QRP2_t1);
                    else
                        lgd = legend('Env Speed','Vmax t1','Vmax t2',QRP1_t1,QRP2_t1,QRP1_t2,QRP2_t2);
                    end
                end
                lgd.Location = 'northeast';
            end
        end
    end

    %% radial pressure profiles

    if rad_Pplot
        for it = theta_inc:theta_inc:ntheta
            idx=idx+1;
            fignum = nploti + floor(((it-1)/theta_inc)/slotsPerFig);
            figure(fignum)
            splot = it/theta_inc - (fignum - nploti)*slotsPerFig;
            ax(idx)=subplot(opts.radial.layout(1), opts.radial.layout(2), splot);

            if rad_EnvVor
                P1 = VPr.EnvVor_bt(int).Press(it,1:nr);
                hp = plot(VPr.r, P1, 'k');
                hold on
                if hasEnv
                    P2 = VPr.Env(int).Press(it,1:nr);
                    plot(VPr.r, P2, '--r');
                end
                lgd = legend('Total Pres','Env Pres');
            elseif rad_Vor
                P1 = VPr.VVor_bt(int).Press(it,1:nr);
                hp = plot(VPr.r, P1, 'k');
                hold on
                lgd = legend('Vortex Pres');
            elseif rad_Env
                P1 = VPr.Env(int).Press(it,1:nr);
                hp = plot(VPr.r, P1, '--r');
                hold on
                lgd = legend('Env Pres');
            end

            yloc = min(hp.YData) + 0.85*(max(hp.YData) - min(hp.YData));
            text(3e5, yloc, ['theta=' num2str(VPr.theta(it),'%.1f')])
            lgd.Location = 'southeast';
        end
    end

    linkaxes(ax)

end
