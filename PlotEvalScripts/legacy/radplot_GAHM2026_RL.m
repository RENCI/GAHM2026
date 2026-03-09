%.........................................................................
%
%  Plots radial profiles for all times in GAHM2026.m output
%
%  Inputs:
%    VPrad      - radial grid data struct from GAHM2026.m containing:
%                   .r, .theta  - radial grid coordinates
%                   .EnvHur_final(i) - final output including blended gridded fields if used
%                   .VVor_bt(i)    - GAHM vortex fields before taper applied 
%                   .VVor_at(i)    - GAHM vortex fields after taper applied 
%                   .EnvVor_bt(i)  - combined env+vortex fields before taper applied
%                                    should most closely match Vmax and istotach valeus
%                   .Env(i)     - environmental fields (if available)
%                   the above 6 fields include .Speed, .Press, .VelU, .VelV
%    Trackdata  - track data with Rmax, Vmax, quadrant info
%    theta_inc  - plot every Nth radial angle (e.g., 2 = every other)
%    ptype      - 'velrad' for velocity or 'prerad' for pressure
%    ftype {}   - cell array of STRINGS with type of plot to make (can include multiple values)
%               - "envhur" - hurricane (blended) + environmental fields - final output
%               - "vor_bt" - GAHM vortex fields before taper is applied
%               - "vor_at" - GAHM vortex fields after taper is applied
%               - "env"    - Environmental field 
%               - "envvor_bt" - GAHM vortex fields + environmental fields - should match Vmax and isotachs
%               - "trackdata" - include Vmax and isotach values from trackfile
%    fign       - starting figure number
%    tieminds   - indicators of times to plot (e.g., 2 = time 2; 2:4 = times 2-4)
%    opts       - (optional) options struct from plot_defaults()
%
%                 11/7/2024   - Rick Luettich
%                 2/8/2026    - modernized (VPrad struct, opts pattern)
%                 3/2/2026    - RL bug fixes, added ftype input
%                 3/4/2026    - RL additional ftypes, multiple output per
%                               plot, specify timeindicies to plot

%e.g., call radplot_GAHM2026(Florence.VPrad,Florence.Trackdata,1,'velrad',{"envhur","env","trackdata"},1,2:4,opts_hur)

function []=radplot_GAHM2026(VPrad,Trackdata,theta_inc,ptype,ftype,fign,timeinds,opts)

if nargin < 8
    opts = plot_defaults();
end

one2ten = opts.radial.one2ten;
SQuad_1_10 = opts.radial.isotachs;
slotsPerFig = opts.radial.layout(1) * opts.radial.layout(2);

c = GAHM_physical_constants(); MS2KT = c.ms2kt; NM2M = c.nm2m;

Vplot = strcmp(ptype,'velrad');
Pplot = strcmp(ptype,'prerad');

hasVor_bt = isfield(VPrad, 'VVor_bt');
hasVor_at = isfield(VPrad, 'VVor_at');
hasEnvHur = isfield(VPrad, 'EnvHur_final');
hasEnv = isfield(VPrad, 'Env');
hasEnvVor_bt = isfield(VPrad, 'EnvVor_bt');

rad_EnvHur=false;
rad_Vor_bt=false;
rad_Vor_at=false;
rad_Env=false;
rad_EnvVor_bt=false;
rad_track=false;

for i=1:length(ftype)
    if ftype{i}=="envhur"
        if hasEnvHur
            rad_EnvHur=true;
        end
    end
    if ftype{i}=="vor_bt"
        if hasVor_bt
            rad_Vor_bt = true;
        end
    end
    if ftype{i}=="vor_at"
        if hasVor_at
            rad_Vor_at=true;
        end
    end
    if ftype{i}=="env" 
        if hasEnv
            rad_Env=true;
        end
    end
    if ftype{i}=="envvor_bt"
        if hasEnvVor_bt
            rad_EnvVor_bt=true;
        end
    end
    if ftype{i}=="trackdata"
        rad_track=true;
    end
end

ntheta = length(VPrad.theta);
nr = length(VPrad.r);
if length(timeinds) == 1
    tind1=timeinds;
    tind2=timeinds;
elseif length(timeinds) >1
    tind1=timeinds(1);
    tind2=timeinds(length(timeinds));
end

if rad_EnvHur
    itot = length(VPrad.EnvHur_final);
elseif rad_Vor_bt
    itot = length(VPrad.VVor_bt);
elseif rad_Vor_at
    itot = length(VPrad.VVor_at);
elseif rad_Env
    itot = length(VPrad.Env);
elseif rad_EnvVor_bt
    itot = length(VPrad.EnvVor_bt);    
end

fign=fign-1;

%% radial velocity plots

if Vplot
    for ind = tind1:tind2
        int=ind-tind1+1;
        nploti = fign + 1;
        for it = theta_inc:theta_inc:ntheta
            fign = nploti + floor(((it-1)/theta_inc)/slotsPerFig);
            figure(fign)
            splot = it/theta_inc - (fign-nploti)*slotsPerFig;
            subplot(opts.radial.layout(1), opts.radial.layout(2), splot)
            legind=0;
            if rad_EnvHur
                ST_plot = MS2KT*VPrad.EnvHur_final(int).Speed(it,1:nr);
                plot(VPrad.r, ST_plot')              
                hold on               
                legind=legind+1;
                legtext{legind}='E+H Speed 10 10';
            end
            if rad_Vor_bt
                ST_plot = MS2KT*VPrad.VVor_bt(int).Speed(it,1:nr);
                plot(VPrad.r, ST_plot')
                hold on
                legind=legind+1;
                legtext{legind}='Vor_b_t Speed 10 10';                
            end
            if rad_Vor_at
                ST_plot = MS2KT*VPrad.VVor_at(int).Speed(it,1:nr);
                plot(VPrad.r, ST_plot')
                hold on
                legind=legind+1;
                legtext{legind}='Vor_a_t Speed 10 10';                
            end  
            if rad_EnvVor_bt
                ST_plot = MS2KT*VPrad.EnvVor_bt(int).Speed(it,1:nr);
                plot(VPrad.r, ST_plot')
                hold on          
                legind=legind+1;
                legtext{legind}='E+V_b_t Speed 10 10';                
            end            
            if rad_Env
                ST_plot = MS2KT*VPrad.Env(int).Speed(it,1:nr);
                plot(VPrad.r, ST_plot', '--k')
                hold on         
                legind=legind+1;
                legtext{legind}='Env Speed 10 10';                
            end
            if rad_track
                plot(Trackdata(int).Rmax_t1*NM2M, Trackdata(int).Vmax_t1*one2ten, 'b*')
                legind=legind+1;
                legtext{legind}='Vmax t1';
                if Trackdata(int).Vmax_t2 ~= 0
                    plot(Trackdata(int).Rmax_t2*NM2M, Trackdata(int).Vmax_t2*one2ten, 'r*')
                    legind=legind+1;
                    legtext{legind}='Vmax t2';                    
                end
                for ii = 1:length(SQuad_1_10)
                    if Trackdata(int).RQuad_t1(Trackdata(int).RP1(it),ii) ~= 0
                        plot(Trackdata(int).RQuad_t1(Trackdata(int).RP1(it),ii), SQuad_1_10(ii)*one2ten, 'bo')
                        if ii==1
                            legind=legind+1;
                            legtext{legind}=['RPQ' num2str(Trackdata(int).RP1(it)) ' t1'];                        
                        end
                    end
                    if Trackdata(int).RQuad_t1(Trackdata(int).RP2(it),ii) ~= 0
                        plot(Trackdata(int).RQuad_t1(Trackdata(int).RP2(it),ii), SQuad_1_10(ii)*one2ten, 'bx')
                        if ii==1
                            legind=legind+1;
                            legtext{legind}=['RPQ' num2str(Trackdata(int).RP2(it)) ' t1'];     
                        end
                    end
                    if Trackdata(int).RQuad_t2(Trackdata(int).RP1(it),ii) ~= 0
                        plot(Trackdata(int).RQuad_t2(Trackdata(int).RP1(it),ii), SQuad_1_10(ii)*one2ten, 'ro')
                        if ii==1
                            legind=legind+1;
                            legtext{legind}=['RPQ' num2str(Trackdata(int).RP1(it)) ' t2'];
                        end
                    end
                    if Trackdata(int).RQuad_t2(Trackdata(int).RP2(it),ii) ~= 0
                        plot(Trackdata(int).RQuad_t2(Trackdata(int).RP2(it),ii), SQuad_1_10(ii)*one2ten, 'rx')
                        if ii==1
                            legind=legind+1;
                            legtext{legind}=['RPQ' num2str(Trackdata(int).RP2(it)) ' t2'];   
                        end
                    end
                end
            end

            ax=gca;
            xloc=ax.XLim(1)+0.4*(ax.XLim(2)-ax.XLim(1));
            yloc=ax.YLim(1)+0.75*(ax.YLim(2)-ax.YLim(1));

            text(xloc, yloc, ['theta=' num2str(VPrad.theta(it),'%.1f')])

            if splot == slotsPerFig || splot == floor(ntheta/theta_inc)-(fign-nploti)*slotsPerFig
                lgd = legend(legtext);                  
                title(lgd,string(Trackdata(ind).datetime))
                lgd.Location = 'northeast';
            end
        end
    end
end

%% radial pressure plots

if Pplot
    for ind = tind1:tind2
        int=ind-tind1+1;
        nploti = fign + 1;
        for it = theta_inc:theta_inc:ntheta
            fign = nploti + floor(((it-1)/theta_inc)/slotsPerFig);
            figure(fign)
            splot = it/theta_inc - (fign-nploti)*slotsPerFig;
            subplot(opts.radial.layout(1), opts.radial.layout(2), splot)
            legind=0;
            if rad_EnvHur
                P_plot = VPrad.EnvHur_final(int).Press(it,1:nr);
                hp=plot(VPrad.r, P_plot');              
                hold on               
                legind=legind+1;
                legtext{legind}='E+H Pressure';
            end
            if rad_Vor_bt
                P_plot = VPrad.VVor_bt(int).Press(it,1:nr);
                hp=plot(VPrad.r, P_plot');
                hold on
                legind=legind+1;
                legtext{legind}='Vor_b_t Pressure';                
            end
            if rad_Vor_at
                P_plot = VPrad.VVor_at(int).Press(it,1:nr);
                hp=plot(VPrad.r, P_plot');
                hold on
                legind=legind+1;
                legtext{legind}='Vor_a_t Pressure';                
            end  
            if rad_EnvVor_bt
                P_plot = VPrad.EnvVor_bt(int).Press(it,1:nr);
                hp=plot(VPrad.r, P_plot');
                hold on          
                legind=legind+1;
                legtext{legind}='E+V_b_t Pressure';                
            end            
            if rad_Env
                P_plot = VPrad.Env(int).Press(it,1:nr);
                hp=plot(VPrad.r, P_plot', '--k');
                hold on         
                legind=legind+1;
                legtext{legind}='Env Pressure';                
            end

            ax=gca;
            xloc=ax.XLim(1)+0.4*(ax.XLim(2)-ax.XLim(1));
            yloc=ax.YLim(1)+0.4*(ax.YLim(2)-ax.YLim(1));
            text(xloc, yloc, ['theta=' num2str(VPrad.theta(it),'%.1f')])            

            if splot == slotsPerFig || splot == floor(ntheta/theta_inc)-(fign-nploti)*slotsPerFig
                lgd = legend(legtext);                  
                title(lgd,string(Trackdata(ind).datetime))
                lgd.Location = 'southeast';
            end
        end
    end
end
