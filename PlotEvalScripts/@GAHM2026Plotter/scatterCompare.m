function fig = scatterCompare(obj, X, Y, fign, titleStr, xlabelStr, ylabelStr, legendLabels)
% scatterCompare  1:1 scatter comparison plot.
%
%   fig = obj.scatterCompare(X, Y, fign, titleStr, xlabelStr, ylabelStr)
%   fig = obj.scatterCompare(X, Y, fign, titleStr, xlabelStr, ylabelStr, legendLabels)
%
%   Two modes based on the shape of X and Y:
%
%   By-quadrant:  X and Y are N×4 matrices (one column per quadrant).
%     Columns are plotted as NE=black, SE=blue, SW=green, NW=red with
%     default legend labels {'NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant'}.
%
%   By-series:  X and Y are N×K matrices with K series (K ~= 4 or
%     legendLabels explicitly provided).
%     Each column is plotted in a distinct color.
%
%   A 1:1 reference line is always drawn.
%
%   Inputs:
%     X, Y         - data matrices (same size); zeros are treated as NaN
%     fign        - figure number
%     titleStr     - figure title string
%     xlabelStr    - x-axis label
%     ylabelStr    - y-axis label
%     legendLabels - (optional) cell array of legend strings, one per column

    quadColors = {'K.','B.','G.','R.'};
    quadNames  = {'NE Quadrant','SE Quadrant','SW Quadrant','NW Quadrant'};
    seriesColors = {'b.','g.','r.','c.','m.','k.'};

    ncols = size(X, 2);

    % NaN out zeros
    X(X == 0) = NaN;
    Y(Y == 0) = NaN;

    % Decide mode
    if ncols == 4 && (nargin < 8 || isempty(legendLabels))
        colors = quadColors;
        labels = quadNames;
    else
        if nargin < 8 || isempty(legendLabels)
            labels = arrayfun(@(k) sprintf('Series %d', k), 1:ncols, 'UniformOutput', false);
        else
            labels = legendLabels;
        end
        colors = seriesColors;
    end

    fig = figure(fign);
    clf(fig);
    hold on

    for k = 1:ncols
        cidx = mod(k-1, numel(colors)) + 1;
        plot(X(:,k), Y(:,k), colors{cidx});
    end

    % 1:1 line
    lim = max([max(X(:)), max(Y(:))]);
    if isnan(lim) || lim == 0, lim = 1; end
    plot([0 lim], [0 lim], 'k--');

    labels{end+1} = '1:1';
    legend(labels{:}, 'Location', 'southeast');

    title(titleStr)
    xlabel(xlabelStr)
    ylabel(ylabelStr)
    axis([0 lim 0 lim])
    hold off

end
