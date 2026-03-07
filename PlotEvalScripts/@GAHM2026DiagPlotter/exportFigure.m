function exportFigure(obj, fig, filename)
% exportFigure  Save a figure to disk using opts.export settings.
%
%   obj.exportFigure(fig, filename)
%   obj.exportFigure(fig)
%
%   fig      - figure handle (e.g. from contourMap) or figure number
%   filename - (optional) base name without extension; defaults to
%              sprintf('GAHM2026_fig%d', fig.Number)
%
%   Behaviour is controlled by opts.export:
%     .dir    — output directory (created if it does not exist)
%     .format — 'png', 'pdf', or 'none'
%     .dpi    — resolution (PNG only)
%
%   Does nothing if opts.export.format is 'none'.

    opts = obj.Opts;

    if strcmp(opts.export.format, 'none')
        return
    end

    % Accept a figure number as well as a handle
    if isnumeric(fig)
        fig = figure(fig);
    end

    if nargin < 3 || isempty(filename)
        filename = sprintf('GAHM2026_fig%d', fig.Number);
    end

    outdir = opts.export.dir;
    if ~exist(outdir, 'dir')
        mkdir(outdir);
    end

    filepath = fullfile(outdir, filename);

    switch lower(opts.export.format)
        case 'png'
            exportgraphics(fig, [filepath '.png'], ...
                'Resolution', opts.export.dpi);
            fprintf('Saved: %s.png\n', filepath);
        case 'pdf'
            exportgraphics(fig, [filepath '.pdf'], ...
                'ContentType', 'vector');
            fprintf('Saved: %s.pdf\n', filepath);
        otherwise
            warning('GAHM2026DiagPlotter:badFormat', ...
                'Unknown export format ''%s''. Use ''png'', ''pdf'', or ''none''.', ...
                opts.export.format);
    end

end