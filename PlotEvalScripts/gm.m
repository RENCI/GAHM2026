function gm
% turns grid major / minor grid lines
echo off
ax = gca;
ax.Layer = 'top';
ax.GridLineStyle = '-';
ax.MinorGridLineStyle = ':';
ax.GridAlpha = 0.5;
ax.MinorGridAlpha = 0.5;
grid on
grid minor

end
