function gm
% turns grid major / minor grid lines
echo off
ax=gca;
ax.Layer='top';
ax.GridLineStyle='-';
ax.MinorGridLineStyle=':';
ax.GridAlpha=.5;
ax.MinorGridAlpha=.5;
grid on
grid minor
