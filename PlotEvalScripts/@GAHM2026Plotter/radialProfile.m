function radialProfile(obj, plotType, fieldType, figNum, time, theta_inc)
% radialProfile  Radial profiles of wind speed or pressure at one timestep.
%  To use this, must first issue command: 
%      obj = GAHM2026Plotter(R);
%  where R is the datastructure from
%      R=run_GAHM2026(<config>);
%
%   obj.radialProfile(plotType, fieldType)
%   obj.radialProfile(plotType, fieldType, figNum)
%   obj.radialProfile(plotType, fieldType, figNum, time)
%   obj.radialProfile(plotType, fieldType, figNum, time, theta_inc)
%
%   Required parameters:
%
%   plotType:
%     'velrad' - radial velocity profiles with isotach & Vmax markers
%     'prerad' - radial pressure profiles
%   fieldType:
%     'envhur' - env + vortex combined fields
%     'hur'    - vortex fields only
%     'env'    - environmental fields only
%
%   Optional parameters:
%
%   figNum    - starting figure number (defaults to 1; [] = auto)
%   time      - integer index, datetime, or [] (defaults to 1)
%   theta_inc - plot every Nth radial angle (default 2)
%
%   Produces subplot panels arranged according to opts.radial.layout.
%
%     Fixed Vmax to kts, Rmax to m, starting fig number  2/24/2026
%     added fieldType & made all plot types functional    3/2/2026
%
%-------------------------------------------------------------------

    if nargin < 6 || isempty(theta_inc), theta_inc = 2; end
    if nargin < 5 || isempty(time), time = 1; end
    if nargin < 4 || isempty(figNum), figNum = 1; end
    if nargin < 3 || isempty(fieldType), fieldType = 'envhur'; end

    c = GAHM_physical_constants(); MS2KT = c.ms2kt; NM2M = c.nm2m;

    Vrad  = obj.VPrad;
    Track = obj.Trackdata;
    opts  = obj.Opts;

    tidx = resolveRadialTime(obj, time);

    min1to10    = opts.radial.one2ten;
    isotach_kts = opts.radial.isotachs;

    isVelRadial  = strcmp(plotType,'velrad');
    isPresRadial = strcmp(plotType,'prerad');

    hasVor    = isfield(Vrad, 'VVor_bt');
    hasEnv    = isfield(Vrad, 'Env');
    hasEnvVor = isfield(Vrad, 'EnvVor_bt');

    showEnvHur = strcmp(fieldType,'envhur') && hasEnvVor;
    showVor    = strcmp(fieldType,'hur')    && hasVor;
    showEnv    = strcmp(fieldType,'env')    && hasEnv;

    ntheta  = length(Vrad.theta);
    nr      = length(Vrad.r);

    slotsPerFig = min(length(theta_inc:theta_inc:ntheta),...
        opts.radial.layout(1) * opts.radial.layout(2));
    tileGrid.rows=slotsPerFig/opts.radial.layout(2);
    tileGrid.cols=opts.radial.layout(2);

    if isempty(figNum)
        f=figure;
        nploti=f.Number;
    else
        nploti = figNum;
    end

    tl=tiledlayout(tileGrid.rows,tileGrid.cols);
    tl.Padding='compact';
    tl.TileSpacing='compact';

    %% radial velocity profiles
    ax=[];
    tileIdx=0;
    if isVelRadial
        for itheta = theta_inc:theta_inc:ntheta
            tileIdx=tileIdx+1;
            
            ax(tileIdx)=nexttile;
            x=Vrad.r/1000;

            if showEnvHur
                y = MS2KT*Vrad.EnvVor_bt(tidx).Speed(itheta,1:nr);
                if hasEnv
                     y = [y;MS2KT*Vrad.Env(tidx).Speed(itheta,1:nr)];
                end
            elseif showVor
                y = MS2KT*Vrad.VVor_bt(tidx).Speed(itheta,1:nr);
            elseif showEnv
                y = MS2KT*Vrad.Env(tidx).Speed(itheta,1:nr);
            end
            hp=plot(x, y,linewidth=2);
            hold on
            plot(Track(tidx).Rmax_t1*NM2M/1000, Track(tidx).Vmax_t1*min1to10, 'b*')
            if Track(tidx).Vmax_t2 ~= 0
                plot(Track(tidx).Rmax_t2*NM2M/1000, Track(tidx).Vmax_t2*min1to10, 'r*')
            end

            for ii = 1:length(isotach_kts)
                if Track(tidx).RQuad_t1(Track(tidx).RP1(itheta),ii) ~= 0
                    plot(Track(tidx).RQuad_t1(Track(tidx).RP1(itheta),ii)/1000, isotach_kts(ii)*min1to10, 'bo')
                end
                if Track(tidx).RQuad_t1(Track(tidx).RP2(itheta),ii) ~= 0
                    plot(Track(tidx).RQuad_t1(Track(tidx).RP2(itheta),ii)/1000, isotach_kts(ii)*min1to10, 'bx')
                end
                if Track(tidx).RQuad_t2(Track(tidx).RP1(itheta),ii) ~= 0
                    plot(Track(tidx).RQuad_t2(Track(tidx).RP1(itheta),ii)/1000, isotach_kts(ii)*min1to10, 'ro')
                end
                if Track(tidx).RQuad_t2(Track(tidx).RP2(itheta),ii) ~= 0
                    plot(Track(tidx).RQuad_t2(Track(tidx).RP2(itheta),ii)/1000, isotach_kts(ii)*min1to10, 'rx')
                end
            end

            yloc = min(hp(1).YData(:)) + 0.95*(max(hp(1).YData(:)) - min(hp(1).YData(:)));
            text(4e5/1000, yloc, ['theta=' num2str(Vrad.theta(itheta),'%.1f')])

            QRP1_t1 = ['RPQ' num2str(Track(tidx).RP1(itheta)) ' t1'];
            QRP2_t1 = ['RPQ' num2str(Track(tidx).RP2(itheta)) ' t1'];
            QRP1_t2 = ['RPQ' num2str(Track(tidx).RP1(itheta)) ' t2'];
            QRP2_t2 = ['RPQ' num2str(Track(tidx).RP2(itheta)) ' t2'];

            [col,row] = ind2sub([tileGrid.cols tileGrid.rows],tileIdx);
            if col==tileGrid.cols && row==tileGrid.rows
                if showEnvHur
                    if Track(tidx).Vmax_t2 == 0
                        lgds = {'EV Speed 10 10','E Speed 10 10','Vmax t1',QRP1_t1,QRP2_t1};
                    else
                        lgds = {'EV Speed 10 10','E Speed 10 10','Vmax t1','Vmax t2',QRP1_t1,QRP2_t1,QRP1_t2,QRP2_t2};
                    end
                elseif showVor
                    if Track(tidx).Vmax_t2 == 0
                        lgds = {'Vortex Speed','Vmax t1',QRP1_t1,QRP2_t1};
                    else
                        lgds = {'Vortex Speed','Vmax t1','Vmax t2',QRP1_t1,QRP2_t1,QRP1_t2,QRP2_t2};
                    end
                elseif showEnv
                    if Track(tidx).Vmax_t2 == 0
                        lgds = {'Env Speed','Vmax t1',QRP1_t1,QRP2_t1};
                    else
                        lgds = {'Env Speed','Vmax t1','Vmax t2',QRP1_t1,QRP2_t1,QRP1_t2,QRP2_t2};
                    end
                end
                lgd=legend(lgds);
            end            

            if row<tileGrid.rows 
                set(gca,'XTickLabel',[])
            else
                xlabel('km')
            end
            if col>1
                 set(gca,'YTickLabel',[])
            else
                ylabel({'Speed','[m/s]'})     
            end
            gm
        end
    end

    %% radial pressure profiles
    if isPresRadial
        for itheta = theta_inc:theta_inc:ntheta
            tileIdx=tileIdx+1;
            ax(tileIdx)=nexttile;
            x=Vrad.r/1000;
            if showEnvHur
                y = Vrad.EnvVor_bt(tidx).Press(itheta,1:nr);
                if hasEnv
                    y = [y;Vrad.Env(tidx).Press(itheta,1:nr)];
                end
                lgds = {'Total Pres','Env Pres'};
            elseif showVor
                y = Vrad.VVor_bt(tidx).Press(itheta,1:nr);
                lgds = {'Vortex Pres'};
            elseif showEnv
                y = Vrad.Env(tidx).Press(itheta,1:nr);
                lgds = {'Env Pres'};
            end
            hp = plot(x, y',linewidth=2);
            yloc = min(hp(1).YData(:)) + 0.05*(max(hp(1).YData(:)) - min(hp(1).YData(:)));
            text(3e5/1000, yloc, ['theta=' num2str(Vrad.theta(itheta),'%.1f')])
            [col,row] = ind2sub([tileGrid.cols tileGrid.rows],tileIdx);
            if row<tileGrid.rows 
                set(gca,'XTickLabel',[])
            else
                xlabel('km')
            end
            if col>1
                 set(gca,'YTickLabel',[])
            else
                 ylabel({'Pres','[mb]'})
            end
            if col==tileGrid.cols && row==tileGrid.rows
                lgd=legend(lgds);
                lgd.Location = 'southeast';
            end
            gm
        end
    end

    linkaxes(ax)

end
