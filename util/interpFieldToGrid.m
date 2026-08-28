function out = interpFieldToGrid(fieldStruct, longrid, latgrid)
% Interpolate a VelU/VelV/Press field struct onto a regular lon/lat grid.
%
% Input:
%       fieldStruct - struct with fields: .lon, .lat, .VelU, .VelV, .Press
%       longrid     - target longitude grid (meshgrid output)
%       latgrid     - target latitude grid (meshgrid output)
%
% Output:
%       out - struct with fields: .VelU, .VelV, .Press on target grid

%warnState = warning('off', 'MATLAB:griddedInterpolant:MeshgridFormatDetect');
warnState = warning('off', 'MATLAB:griddedInterpolant:MeshgridEval2DWarnId');
cleanupWarn = onCleanup(@() warning(warnState));

FU = griddedInterpolant(fieldStruct.lon', fieldStruct.lat', fieldStruct.VelU');
out.VelU = FU(longrid, latgrid);

FV = griddedInterpolant(fieldStruct.lon', fieldStruct.lat', fieldStruct.VelV');
out.VelV = FV(longrid, latgrid);

FP = griddedInterpolant(fieldStruct.lon', fieldStruct.lat', fieldStruct.Press');
out.Press = FP(longrid, latgrid);

end
