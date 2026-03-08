%.........................................................................
%
%  Plot contour output from GAHM2026.m
%
%  Can also plot output from the environmental & hurricane field separation
%  step as found in the .mat file by running the code:
%        prep_separated_fields_4_conplot_GAHM2026.m
%  to create the needed inputs for this contour plotting script
%  %
%  ptype options:
%       velcon  - velocity contour plot with vectors
%       precon  - pressure contour plot
%       mvelcon - velocity contour plot with mask lines
%       mprecon - pressure contour plot with mask lines
%
%                 1/29/2026   - Rick Luettich
%                 2/7/2026    - modernized (opts pattern, built-in helpers)

function []=conplot_GAHM2026(plotdata,datagrid,Trackdata,ptype,fign,opts)

if nargin < 6
    opts = plot_defaults();
end

MS2KT = GAHM_physical_constants().ms2kt;

con_Vplot = strcmp(ptype,'velcon') || strcmp(ptype,'mvelcon');
con_Pplot = strcmp(ptype,'precon') || strcmp(ptype,'mprecon');
opts.mask.show = strcmp(ptype,'mvelcon') || strcmp(ptype,'mprecon');

itot = length(plotdata);

%% velocity contour plots with vectors

if con_Vplot
    istart = 1;
    for ip = istart:itot
        if strcmp(opts.domain.mode, 'moving')
            minX = min(datagrid(ip).Lon(:));
            maxX = max(datagrid(ip).Lon(:));
            minY = min(datagrid(ip).Lat(:));
            maxY = max(datagrid(ip).Lat(:));
        else
            minX = opts.domain.fixedLimits(1);
            maxX = opts.domain.fixedLimits(2);
            minY = opts.domain.fixedLimits(3);
            maxY = opts.domain.fixedLimits(4);
        end
        fign = fign + 1;
        fig = figure(fign);
        Speed = hypot(plotdata(ip).VelU, plotdata(ip).VelV);
        hs = pcolor(datagrid(ip).Lon, datagrid(ip).Lat, MS2KT*Speed);
        hold on
        shading interp
        colormap(gca, sky);
        colorbar
        clim(opts.wind.clims)
        alpha(opts.wind.alpha);

        plot_quiver_scaled(datagrid(ip).Lon, datagrid(ip).Lat, ...
            plotdata(ip).VelU, plotdata(ip).VelV, opts);

        if opts.mask.show
            contour(datagrid(ip).Lon, datagrid(ip).Lat, datagrid(ip).Mask1, 1, ...
                opts.mask.color, 'LineWidth', opts.mask.linewidth)
            contour(datagrid(ip).Lon, datagrid(ip).Lat, datagrid(ip).Mask2, 1, ...
                opts.mask.color, 'LineWidth', opts.mask.linewidth)
        end

        if opts.track.progressive
            track = [Trackdata(1:ip).Lon; Trackdata(1:ip).Lat];
        else
            track = [Trackdata(1:itot).Lon; Trackdata(1:itot).Lat];
        end
        plot(track(1,:), track(2,:), '-', 'Color', opts.track.color, ...
            'LineWidth', opts.track.linewidth);

        title(['Wind Speed (kts) 10 min @ 10 m  ' ...
            datestr(datetime(datagrid(ip).datetime),'mmm dd yyyy HH:MM') ' UTC'])
        axis('equal')
        axis([minX maxX minY maxY]);
        plot_coastline(opts);

        if opts.anim.gif
            frame = getframe(fig);
            im = frame2im(frame);
            [A, maps] = rgb2ind(im, 256);
            if ip == istart
                imwrite(A, maps, 'GAHM_V.gif', 'gif', 'LoopCount', Inf, ...
                    'DelayTime', 1/opts.anim.frameRate);
            else
                imwrite(A, maps, 'GAHM_V.gif', 'gif', 'WriteMode', 'append', ...
                    'DelayTime', 1/opts.anim.frameRate);
            end
        end

        if opts.anim.mp4
            frame = getframe(fig);
            if ip == istart
                dV = VideoWriter('GAHM_V.mp4', 'MPEG-4');
                dV.FrameRate = opts.anim.frameRate;
                dV.Quality = 100;
                open(dV);
            end
            writeVideo(dV, frame);
        end
    end
end

%% pressure contour plot

if con_Pplot
    for ip = 1:itot
        if strcmp(opts.domain.mode, 'moving')
            minX = min(datagrid(ip).Lon(:));
            maxX = max(datagrid(ip).Lon(:));
            minY = min(datagrid(ip).Lat(:));
            maxY = max(datagrid(ip).Lat(:));
        else
            minX = opts.domain.fixedLimits(1);
            maxX = opts.domain.fixedLimits(2);
            minY = opts.domain.fixedLimits(3);
            maxY = opts.domain.fixedLimits(4);
        end
        fign = fign + 1;
        fig = figure(fign);
        hs = pcolor(datagrid(ip).Lon, datagrid(ip).Lat, plotdata(ip).Press);
        hold on
        shading interp
        colormap(gca, sky);
        colorbar
        clim(opts.pres.clims)
        alpha(opts.pres.alpha);

        if opts.mask.show
            contour(datagrid(ip).Lon, datagrid(ip).Lat, datagrid(ip).Mask1, 1, ...
                opts.mask.color, 'LineWidth', opts.mask.linewidth)
            contour(datagrid(ip).Lon, datagrid(ip).Lat, datagrid(ip).Mask2, 1, ...
                opts.mask.color, 'LineWidth', opts.mask.linewidth)
        end

        if opts.track.progressive
            track = [Trackdata(1:ip).Lon; Trackdata(1:ip).Lat];
        else
            track = [Trackdata(1:itot).Lon; Trackdata(1:itot).Lat];
        end
        plot(track(1,:), track(2,:), '-', 'Color', opts.track.color, ...
            'LineWidth', opts.track.linewidth);

        title(['Atm Pressure (mb)  ' ...
            datestr(datetime(datagrid(ip).datetime),'mmm dd yyyy HH:MM') ' UTC'])
        axis('equal')
        axis([minX maxX minY maxY]);
        plot_coastline(opts);

        if opts.anim.gif
            frame = getframe(fig);
            im = frame2im(frame);
            [A, maps] = rgb2ind(im, 256);
            if ip == 1
                imwrite(A, maps, 'GAHM_P.gif', 'gif', 'LoopCount', Inf, ...
                    'DelayTime', 1/opts.anim.frameRate);
            else
                imwrite(A, maps, 'GAHM_P.gif', 'gif', 'WriteMode', 'append', ...
                    'DelayTime', 1/opts.anim.frameRate);
            end
        end

        if opts.anim.mp4
            frame = getframe(fig);
            if ip == 1
                dP = VideoWriter('GAHM_P.mp4', 'MPEG-4');
                dP.FrameRate = opts.anim.frameRate;
                dP.Quality = 100;
                open(dP);
            end
            writeVideo(dP, frame);
        end
    end
end

%% close MP4 animations if open

if con_Vplot && opts.anim.mp4
    close(dV)
end

if con_Pplot && opts.anim.mp4
    close(dP)
end
