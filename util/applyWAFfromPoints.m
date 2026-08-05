function vortexWaf = applyWAFfromPoints(wafPoints, vortexPoints, longitudePoints, latitudePoints)
% applyWAFfromPoints Apply directional wind adjustment factors at specified points.
%   vortexWaf = applyWAFfromPoints(wafPoints, vortexPoints, longitudePoints,
%   latitudePoints) matches each output coordinate pair to exactly one WAF
%   point and linearly interpolates its clockwise-from-north directional WAF.
    arguments
        wafPoints struct
        vortexPoints (1,1) struct
        longitudePoints {mustBeNumeric, mustBeReal, mustBeFinite}
        latitudePoints {mustBeNumeric, mustBeReal, mustBeFinite}
    end

    validateVortexSizes(vortexPoints, longitudePoints, latitudePoints);
    directionCount = validateWafPoints(wafPoints);

    coordinateTolerance = 1.0e-8; % Degrees, applied to both coordinates of a pair.
    pointCount = numel(longitudePoints);
    wafValues = zeros(size(longitudePoints));
    directions = linspace(0, 360, directionCount + 1);
    windDirections = mod(atan2d(vortexPoints.VelU, vortexPoints.VelV) + 180, 360);

    wafLongitudes = [wafPoints.lon];
    wafLatitudes = [wafPoints.lat];
    for pointIndex = 1:pointCount
        coordinateMatches = abs(wafLongitudes - longitudePoints(pointIndex)) <= coordinateTolerance & ...
            abs(wafLatitudes - latitudePoints(pointIndex)) <= coordinateTolerance;
        matchCount = nnz(coordinateMatches);
        if matchCount == 1
            wafVector = wafPoints(coordinateMatches).WAF;
            periodicWaf = [wafVector(:).', wafVector(1)];
            wafValues(pointIndex) = interp1(directions, periodicWaf, windDirections(pointIndex), "linear");
        elseif matchCount == 0
            error("applyWAFfromPoints:MissingCoordinateMatch", ...
                "No WAF point matches output point %d at longitude %.15g and latitude %.15g.", ...
                pointIndex, longitudePoints(pointIndex), latitudePoints(pointIndex));
        else
            error("applyWAFfromPoints:DuplicateCoordinateMatch", ...
                "Multiple WAF points match output point %d at longitude %.15g and latitude %.15g.", ...
                pointIndex, longitudePoints(pointIndex), latitudePoints(pointIndex));
        end
    end

    vortexWaf = vortexPoints;
    vortexWaf.VelU = wafValues.*vortexPoints.VelU;
    vortexWaf.VelV = wafValues.*vortexPoints.VelV;
    if isfield(vortexPoints, "Speed")
        vortexWaf.Speed = hypot(vortexWaf.VelU, vortexWaf.VelV);
    end
end

function validateVortexSizes(vortexPoints, longitudePoints, latitudePoints)
    requiredFields = ["VelU", "VelV"];
    if ~all(isfield(vortexPoints, requiredFields))
        error("applyWAFfromPoints:MissingVelocityField", ...
            "The vortex structure must contain VelU and VelV fields.");
    end

    elementCounts = [numel(longitudePoints), numel(latitudePoints), ...
        numel(vortexPoints.VelU), numel(vortexPoints.VelV)];
    if any(elementCounts ~= elementCounts(1))
        error("applyWAFfromPoints:SizeMismatch", ...
            "Longitude, latitude, VelU, and VelV must have equal element counts.");
    end

    if ~isequal(size(longitudePoints), size(latitudePoints), size(vortexPoints.VelU), size(vortexPoints.VelV))
        error("applyWAFfromPoints:ShapeMismatch", ...
            "Longitude, latitude, VelU, and VelV must have matching array shapes.");
    end
end

function directionCount = validateWafPoints(wafPoints)
    requiredFields = ["lon", "lat", "WAF"];
    if isempty(wafPoints)
        error("applyWAFfromPoints:EmptyWafPoints", "At least one WAF point is required.");
    end
    if ~all(isfield(wafPoints, requiredFields))
        error("applyWAFfromPoints:InvalidWafPoint", ...
            "Every WAF point must contain lon, lat, and WAF fields.");
    end

    directionCount = numel(wafPoints(1).WAF);
    for wafIndex = 1:numel(wafPoints)
        isScalarCoordinate = isscalar(wafPoints(wafIndex).lon) && isscalar(wafPoints(wafIndex).lat);
        hasValidWaf = isnumeric(wafPoints(wafIndex).WAF) && isreal(wafPoints(wafIndex).WAF) && ...
            all(isfinite(wafPoints(wafIndex).WAF), "all") && ...
            numel(wafPoints(wafIndex).WAF) == directionCount;
        if ~isScalarCoordinate || directionCount == 0 || ~hasValidWaf
            error("applyWAFfromPoints:InvalidWafPoint", ...
                "Every WAF point must have scalar coordinates and the same nonempty number of finite WAF values.");
        end
    end
end
