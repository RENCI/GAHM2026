function radialProfile(obj, plotType, fieldType, figNum, time, theta_inc)
% radialProfile  Radial profiles of wind speed or pressure at one timestep.
%  Merges the original GAHM2026Plotter.radialProfile with the expanded
%  multi-overlay capability of radplot_GAHM2026_RL.  Multiple field types
%  can be overlaid on the same subplot panels by passing fieldType as a cell
%  array of strings.
%
%  To use this, must first issue command:
%      obj = GAHM2026DiagPlotter(R);
%  where R is the datastructure from
%      R = run_GAHM2026(<config>);
%
%   obj.radialProfile(plotType, fieldType)
%   obj.radialProfile(plotType, fieldType, figNum)
%   obj.radialProfile(plotType, fieldType, figNum, time)
%   obj.radialProfile(plotType, fieldType, figNum, time, theta_inc)
%
%   Required parameters:
%
%   plotType:
%     'velrad' - radial velocity profiles (knots) with optional isotach
%                and Vmax markers when 'trackdata' is included
%     'prerad' - radial pressure profiles (mb)
%
%   fieldType:
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
%   figNum    - starting figure number (default 1; [] = auto via figure)
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
%     added fieldType & made all plot types functional    3/2/2026
%     merged multi-overlay from radplot_GAHM2026_RL      3/7/2026
%
%-------------------------------------------------------------------

    if nargin < 6 || isempty(theta_inc), theta_inc = 2; end
    if nargin < 5 || isempty(time), time = 1; end
    if nargin < 4 || isempty(figNum), figNum = 1; end
    if nargin < 3 || isempty(fieldType), fieldType = 'envhur'; end

    assert(obj.HasRadialGrid, 'GAHM2026DiagPlotter:noRadialGrid', ...
        'Radial grid data (RadialGrid) is not available in this Result struct.')

    if ischar(fieldType) || isstring(fieldType)
        fieldType = {char(fieldType)};
    end

    phys  = GAHM_physical_constants();
    MS2KT = phys.ms2kt;
    NM2M  = phys.nm2m;

    Vrad  = obj.RadialGrid;
    Track = obj.Trackdata;
    opts  = obj.Opts;

    tidx = resolveRadialTime(obj, time);

    min1to10    = opts.radial.one2ten;
    isotach_kts = opts.radial.isotachs;

    isVelRadial = strcmp(plotType,'velrad');
    isPresRadial = strcmp(plotType,'prerad');

    hasEnvHur_final = isfield(Vrad, 'EnvHur_final');
    hasVor_bt       = isfield(Vrad, 'VVor_bt');
    hasVor_at       = isfield(Vrad, 'VVor_at');
    hasEnv          = isfield(Vrad, 'Env');
    hasEnvVor_bt    = isfield(Vrad, 'EnvVor_bt');

    showEnvHurFinal = false;
    showVorBt       = false;
    showVorAt       = false;
    showEnv         = false;
    showEnvVorBt    = false;
    showEnvHur      = false;
    showTrack       = false;

    for i = 1:length(fieldType)
        switch fieldType{i}
            case 'envhur_final', if hasEnvHur_final, showEnvHurFinal = true; end
            case 'vor_bt',       if hasVor_bt,       showVorBt       = true; end
            case 'vor_at',       if hasVor_at,       showVorAt       = true; end
            case 'env',          if hasEnv,           showEnv         = true; end
            case 'envvor_bt',    if hasEnvVor_bt,     showEnvVorBt    = true; end
            case 'envhur',       if hasEnvVor_bt,     showEnvHur      = true; end
            case 'trackdata',    showTrack = true;
        end
    end

    ntheta = length(Vrad.theta);
    nr     = length(Vrad.r);

    slotsPerFig = min(length(theta_inc:theta_inc:ntheta), ...
        opts.radial.layout(1) * opts.radial.layout(2));
    tileGrid.rows = slotsPerFig / opts.radial.layout(2);
    tileGrid.cols = opts.radial.layout(2);

    if isempty(figNum)
        f = figure;
        figNum = f.Number;
    else
        figure(figNum);
    end

    tl = tiledlayout(tileGrid.rows, tileGrid.cols);
    tl.Padding     = 'compact';
    tl.TileSpacing = 'compact';

    ax      = [];
    tileIdx = 0;
    x       = Vrad.r / 1000;

    %% radial velocity profiles
    if isVelRadial
        for itheta = theta_inc:theta_inc:ntheta
            tileIdx = tileIdx + 1;
            ax(tileIdx) = nexttile; %#ok<AGROW>
            hold on

            nleg      = 0;
            legLabels = {};

            if showEnvHurFinal
                plot(x, MS2KT*Vrad.EnvHur_final(tidx).Speed(itheta,1:nr), linewidth=2);
                nleg = nleg + 1;
                legLabels{nleg} = 'E+H Final';
            end
            if showVorBt
                plot(x, MS2KT*Vrad.VVor_bt(tidx).Speed(itheta,1:nr), linewidth=2);
                nleg = nleg + 1;
                legLabels{nleg} = 'Vor b/t';
            end
            if showVorAt
                plot(x, MS2KT*Vrad.VVor_at(tidx).Speed(itheta,1:nr), linewidth=2);
                nleg = nleg + 1;
                legLabels{nleg} = 'Vor a/t';
            end
            if showEnvVorBt
                plot(x, MS2KT*Vrad.EnvVor_bt(tidx).Speed(itheta,1:nr), linewidth=2);
                nleg = nleg + 1;
                legLabels{nleg} = 'E+V b/t';
            end
            if showEnvHur
                plot(x, MS2KT*Vrad.EnvVor_bt(tidx).Speed(itheta,1:nr), linewidth=2);
                nleg = nleg + 1;
                legLabels{nleg} = 'E+H';
            end
            if showEnv
                plot(x, MS2KT*Vrad.Env(tidx).Speed(itheta,1:nr), '--k', linewidth=2);
                nleg = nleg + 1;
                legLabels{nleg} = 'Env';
            end

            if showTrack
                plot(Track(tidx).Rmax_t1*NM2M/1000, Track(tidx).Vmax_t1*min1to10, 'b*')
                nleg = nleg + 1;
                legLabels{nleg} = 'Vmax t1';
                if Track(tidx).Vmax_t2 ~= 0
                    plot(Track(tidx).Rmax_t2*NM2M/1000, Track(tidx).Vmax_t2*min1to10, 'r*')
                    nleg = nleg + 1;
                    legLabels{nleg} = 'Vmax t2';
                end
                for ii = 1:length(isotach_kts)
                    if Track(tidx).RQuad_t1(Track(tidx).RP1(itheta),ii) ~= 0
                        plot(Track(tidx).RQuad_t1(Track(tidx).RP1(itheta),ii)/1000, isotach_kts(ii)*min1to10, 'bo')
                        if ii == 1
                            nleg = nleg + 1;
                            legLabels{nleg} = ['RPQ' num2str(Track(tidx).RP1(itheta)) ' t1'];
                        end
                    end
                    if Track(tidx).RQuad_t1(Track(tidx).RP2(itheta),ii) ~= 0
                        plot(Track(tidx).RQuad_t1(Track(tidx).RP2(itheta),ii)/1000, isotach_kts(ii)*min1to10, 'bx')
                        if ii == 1
                            nleg = nleg + 1;
                            legLabels{nleg} = ['RPQ' num2str(Track(tidx).RP2(itheta)) ' t1'];
                        end
                    end
                    if Track(tidx).RQuad_t2(Track(tidx).RP1(itheta),ii) ~= 0
                        plot(Track(tidx).RQuad_t2(Track(tidx).RP1(itheta),ii)/1000, isotach_kts(ii)*min1to10, 'ro')
                        if ii == 1
                            nleg = nleg + 1;
                            legLabels{nleg} = ['RPQ' num2str(Track(tidx).RP1(itheta)) ' t2'];
                        end
                    end
                    if Track(tidx).RQuad_t2(Track(tidx).RP2(itheta),ii) ~= 0
                        plot(Track(tidx).RQuad_t2(Track(tidx).RP2(itheta),ii)/1000, isotach_kts(ii)*min1to10, 'rx')
                        if ii == 1
                            nleg = nleg + 1;
                            legLabels{nleg} = ['RPQ' num2str(Track(tidx).RP2(itheta)) ' t2'];
                        end
                    end
                end
            end

            yloc = min(ylim) + 0.95*(max(ylim) - min(ylim));
            text(4e5/1000, yloc, ['theta=' num2str(Vrad.theta(itheta),'%.1f')])

            [col,row] = ind2sub([tileGrid.cols tileGrid.rows], tileIdx);
            if col == tileGrid.cols && row == tileGrid.rows
                lgd = legend(legLabels);
                lgd.Location = 'northeast';
            end
            if row < tileGrid.rows
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
    if isPresRadial
        for itheta = theta_inc:theta_inc:ntheta
            tileIdx = tileIdx + 1;
            ax(tileIdx) = nexttile; %#ok<AGROW>
            hold on

            nleg      = 0;
            legLabels = {};

            if showEnvHurFinal
                plot(x, Vrad.EnvHur_final(tidx).Press(itheta,1:nr), linewidth=2);
                nleg = nleg + 1;
                legLabels{nleg} = 'E+H Final';
            end
            if showVorBt
                plot(x, Vrad.VVor_bt(tidx).Press(itheta,1:nr), linewidth=2);
                nleg = nleg + 1;
                legLabels{nleg} = 'Vor b/t';
            end
            if showVorAt
                plot(x, Vrad.VVor_at(tidx).Press(itheta,1:nr), linewidth=2);
                nleg = nleg + 1;
                legLabels{nleg} = 'Vor a/t';
            end
            if showEnvVorBt
                plot(x, Vrad.EnvVor_bt(tidx).Press(itheta,1:nr), linewidth=2);
                nleg = nleg + 1;
                legLabels{nleg} = 'E+V b/t';
            end
            if showEnvHur
                plot(x, Vrad.EnvVor_bt(tidx).Press(itheta,1:nr), linewidth=2);
                nleg = nleg + 1;
                legLabels{nleg} = 'E+H';
            end
            if showEnv
                plot(x, Vrad.Env(tidx).Press(itheta,1:nr), '--k', linewidth=2);
                nleg = nleg + 1;
                legLabels{nleg} = 'Env';
            end

            yloc = min(ylim) + 0.05*(max(ylim) - min(ylim));
            text(3e5/1000, yloc, ['theta=' num2str(Vrad.theta(itheta),'%.1f')])

            [col,row] = ind2sub([tileGrid.cols tileGrid.rows], tileIdx);
            if col == tileGrid.cols && row == tileGrid.rows
                lgd = legend(legLabels);
                lgd.Location = 'southeast';
            end
            if row < tileGrid.rows
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
