function radialProfile(obj, ptype, ftype, fign, time, theta_inc)
% radialProfile  Radial profiles of wind speed or pressure at one timestep.
%  Merges the original GAHM2026Plotter.radialProfile with the expanded
%  multi-overlay capability of radplot_GAHM2026_RL.  Multiple field types
%  can be overlaid on the same subplot panels by passing ftype as a cell
%  array of strings.
%
%  To use this, must first issue command:
%      obj = GAHM2026DiagPlotter(R);
%  where R is the datastructure from
%      R = run_GAHM2026(<config>);
%
%   obj.radialProfile(ptype, ftype)
%   obj.radialProfile(ptype, ftype, fign)
%   obj.radialProfile(ptype, ftype, fign, time)
%   obj.radialProfile(ptype, ftype, fign, time, theta_inc)
%
%   Required parameters:
%
%   ptype:
%     'velrad' - radial velocity profiles (knots) with optional isotach
%                and Vmax markers when 'trackdata' is included
%     'prerad' - radial pressure profiles (mb)
%
%   ftype:
%     A single string or a cell array of strings.  When a cell array is
%     given, all requested field types are overlaid on every subplot panel.
%     Supported values:
%       'envhur'       - Env + Vortex (before taper) — backward-compatible
%                        shorthand that plots EnvVor_bt data
%       'envhur_final' - final blended hurricane + environmental fields
%       'vor_bt'       - GAHM vortex fields before taper
%       'vor_at'       - GAHM vortex fields after taper
%       'envvor_bt'    - Env + Vortex (before taper)
%       'env'          - environmental fields only
%       'trackdata'    - overlay Vmax and isotach markers from the track
%                        file (velrad only; ignored for prerad)
%
%   Optional parameters:
%
%   fign      - starting figure number (default 1; [] = auto via figure)
%   time      - integer index, datetime, or [] (default 1)
%   theta_inc - plot every Nth radial angle (default 2)
%
%   Produces tiled subplot panels arranged according to opts.radial.layout.
%
%   Line styles:
%     'envhur_final' : solid, auto-color
%     'vor_bt'       : solid, auto-color
%     'vor_at'       : solid, auto-color
%     'envvor_bt'    : solid, auto-color
%     'envhur'       : solid, auto-color
%     'env'          : dashed black ('--k')
%
%   Legend labels:
%     'envhur_final' -> 'E+H Final'
%     'vor_bt'       -> 'Vor b/t'
%     'vor_at'       -> 'Vor a/t'
%     'envvor_bt'    -> 'E+V b/t'
%     'envhur'       -> 'E+H'
%     'env'          -> 'Env'
%
%     Fixed Vmax to kts, Rmax to m, starting fig number  2/24/2026
%     added ftype & made all plot types functional        3/2/2026
%     merged multi-overlay from radplot_GAHM2026_RL      3/7/2026
%
%-------------------------------------------------------------------

    if nargin < 6 || isempty(theta_inc), theta_inc = 2; end
    if nargin < 5 || isempty(time), time = 1; end
    if nargin < 4 || isempty(fign), fign = 1; end
    if nargin < 3 || isempty(ftype), ftype = 'envhur'; end

    assert(obj.HasVPrad, 'GAHM2026DiagPlotter:noVPrad', ...
        'Radial grid data (VPrad) is not available in this Result struct.')

    if ischar(ftype) || isstring(ftype)
        ftype = {char(ftype)};
    end

    phys  = GAHM_physical_constants();
    MS2KT = phys.ms2kt;
    NM2M  = phys.nm2m;

    VPr   = obj.VPrad;
    Tdata = obj.Trackdata;
    opts  = obj.Opts;

    int = resolveRadialTime(obj, time);

    one2ten    = opts.radial.one2ten;
    SQuad_1_10 = opts.radial.isotachs;

    rad_Vplot = strcmp(ptype,'velrad');
    rad_Pplot = strcmp(ptype,'prerad');

    hasEnvHur_final = isfield(VPr, 'EnvHur_final');
    hasVor_bt       = isfield(VPr, 'VVor_bt');
    hasVor_at       = isfield(VPr, 'VVor_at');
    hasEnv          = isfield(VPr, 'Env');
    hasEnvVor_bt    = isfield(VPr, 'EnvVor_bt');

    rad_EnvHur_final = false;
    rad_Vor_bt       = false;
    rad_Vor_at       = false;
    rad_Env          = false;
    rad_EnvVor_bt    = false;
    rad_EnvHur       = false;
    rad_track        = false;

    for i = 1:length(ftype)
        switch ftype{i}
            case 'envhur_final', if hasEnvHur_final, rad_EnvHur_final = true; end
            case 'vor_bt',       if hasVor_bt,       rad_Vor_bt       = true; end
            case 'vor_at',       if hasVor_at,       rad_Vor_at       = true; end
            case 'env',          if hasEnv,           rad_Env          = true; end
            case 'envvor_bt',    if hasEnvVor_bt,     rad_EnvVor_bt    = true; end
            case 'envhur',       if hasEnvVor_bt,     rad_EnvHur       = true; end
            case 'trackdata',    rad_track = true;
        end
    end

    ntheta = length(VPr.theta);
    nr     = length(VPr.r);

    slotsPerFig = min(length(theta_inc:theta_inc:ntheta), ...
        opts.radial.layout(1) * opts.radial.layout(2));
    np.rows = slotsPerFig / opts.radial.layout(2);
    np.cols = opts.radial.layout(2);

    if isempty(fign)
        f = figure;
        fign = f.Number;
    else
        figure(fign);
    end

    tl = tiledlayout(np.rows, np.cols);
    tl.Padding     = 'compact';
    tl.TileSpacing = 'compact';

    ax  = [];
    idx = 0;
    x   = VPr.r / 1000;

    %% radial velocity profiles
    if rad_Vplot
        for it = theta_inc:theta_inc:ntheta
            idx = idx + 1;
            ax(idx) = nexttile; %#ok<AGROW>
            hold on

            legind  = 0;
            legtext = {};

            if rad_EnvHur_final
                plot(x, MS2KT*VPr.EnvHur_final(int).Speed(it,1:nr), linewidth=2);
                legind = legind + 1;
                legtext{legind} = 'E+H Final';
            end
            if rad_Vor_bt
                plot(x, MS2KT*VPr.VVor_bt(int).Speed(it,1:nr), linewidth=2);
                legind = legind + 1;
                legtext{legind} = 'Vor b/t';
            end
            if rad_Vor_at
                plot(x, MS2KT*VPr.VVor_at(int).Speed(it,1:nr), linewidth=2);
                legind = legind + 1;
                legtext{legind} = 'Vor a/t';
            end
            if rad_EnvVor_bt
                plot(x, MS2KT*VPr.EnvVor_bt(int).Speed(it,1:nr), linewidth=2);
                legind = legind + 1;
                legtext{legind} = 'E+V b/t';
            end
            if rad_EnvHur
                plot(x, MS2KT*VPr.EnvVor_bt(int).Speed(it,1:nr), linewidth=2);
                legind = legind + 1;
                legtext{legind} = 'E+H';
            end
            if rad_Env
                plot(x, MS2KT*VPr.Env(int).Speed(it,1:nr), '--k', linewidth=2);
                legind = legind + 1;
                legtext{legind} = 'Env';
            end

            if rad_track
                plot(Tdata(int).Rmax_t1*NM2M/1000, Tdata(int).Vmax_t1*one2ten, 'b*')
                legind = legind + 1;
                legtext{legind} = 'Vmax t1';
                if Tdata(int).Vmax_t2 ~= 0
                    plot(Tdata(int).Rmax_t2*NM2M/1000, Tdata(int).Vmax_t2*one2ten, 'r*')
                    legind = legind + 1;
                    legtext{legind} = 'Vmax t2';
                end
                for ii = 1:length(SQuad_1_10)
                    if Tdata(int).RQuad_t1(Tdata(int).RP1(it),ii) ~= 0
                        plot(Tdata(int).RQuad_t1(Tdata(int).RP1(it),ii)/1000, SQuad_1_10(ii)*one2ten, 'bo')
                        if ii == 1
                            legind = legind + 1;
                            legtext{legind} = ['RPQ' num2str(Tdata(int).RP1(it)) ' t1'];
                        end
                    end
                    if Tdata(int).RQuad_t1(Tdata(int).RP2(it),ii) ~= 0
                        plot(Tdata(int).RQuad_t1(Tdata(int).RP2(it),ii)/1000, SQuad_1_10(ii)*one2ten, 'bx')
                        if ii == 1
                            legind = legind + 1;
                            legtext{legind} = ['RPQ' num2str(Tdata(int).RP2(it)) ' t1'];
                        end
                    end
                    if Tdata(int).RQuad_t2(Tdata(int).RP1(it),ii) ~= 0
                        plot(Tdata(int).RQuad_t2(Tdata(int).RP1(it),ii)/1000, SQuad_1_10(ii)*one2ten, 'ro')
                        if ii == 1
                            legind = legind + 1;
                            legtext{legind} = ['RPQ' num2str(Tdata(int).RP1(it)) ' t2'];
                        end
                    end
                    if Tdata(int).RQuad_t2(Tdata(int).RP2(it),ii) ~= 0
                        plot(Tdata(int).RQuad_t2(Tdata(int).RP2(it),ii)/1000, SQuad_1_10(ii)*one2ten, 'rx')
                        if ii == 1
                            legind = legind + 1;
                            legtext{legind} = ['RPQ' num2str(Tdata(int).RP2(it)) ' t2'];
                        end
                    end
                end
            end

            yloc = min(ylim) + 0.95*(max(ylim) - min(ylim));
            text(4e5/1000, yloc, ['theta=' num2str(VPr.theta(it),'%.1f')])

            [col,row] = ind2sub([np.cols np.rows], idx);
            if col == np.cols && row == np.rows
                lgd = legend(legtext);
                lgd.Location = 'northeast';
            end
            if row < np.rows
                set(gca,'XTickLabel',[])
            else
                xlabel('km')
            end
            if col > 1
                set(gca,'YTickLabel',[])
            else
                ylabel({'Speed','[kts]'})
            end
            gm
        end
    end

    %% radial pressure profiles
    if rad_Pplot
        for it = theta_inc:theta_inc:ntheta
            idx = idx + 1;
            ax(idx) = nexttile; %#ok<AGROW>
            hold on

            legind  = 0;
            legtext = {};

            if rad_EnvHur_final
                plot(x, VPr.EnvHur_final(int).Press(it,1:nr), linewidth=2);
                legind = legind + 1;
                legtext{legind} = 'E+H Final';
            end
            if rad_Vor_bt
                plot(x, VPr.VVor_bt(int).Press(it,1:nr), linewidth=2);
                legind = legind + 1;
                legtext{legind} = 'Vor b/t';
            end
            if rad_Vor_at
                plot(x, VPr.VVor_at(int).Press(it,1:nr), linewidth=2);
                legind = legind + 1;
                legtext{legind} = 'Vor a/t';
            end
            if rad_EnvVor_bt
                plot(x, VPr.EnvVor_bt(int).Press(it,1:nr), linewidth=2);
                legind = legind + 1;
                legtext{legind} = 'E+V b/t';
            end
            if rad_EnvHur
                plot(x, VPr.EnvVor_bt(int).Press(it,1:nr), linewidth=2);
                legind = legind + 1;
                legtext{legind} = 'E+H';
            end
            if rad_Env
                plot(x, VPr.Env(int).Press(it,1:nr), '--k', linewidth=2);
                legind = legind + 1;
                legtext{legind} = 'Env';
            end

            yloc = min(ylim) + 0.05*(max(ylim) - min(ylim));
            text(3e5/1000, yloc, ['theta=' num2str(VPr.theta(it),'%.1f')])

            [col,row] = ind2sub([np.cols np.rows], idx);
            if col == np.cols && row == np.rows
                lgd = legend(legtext);
                lgd.Location = 'southeast';
            end
            if row < np.rows
                set(gca,'XTickLabel',[])
            else
                xlabel('km')
            end
            if col > 1
                set(gca,'YTickLabel',[])
            else
                ylabel({'Pres','[mb]'})
            end
            gm
        end
    end

    linkaxes(ax)

end
