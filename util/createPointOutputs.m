function [pointsTc, pointsEnvironment, pointsIntermediate] = createPointOutputs( ...
        coordinates, tcFields, environmentFields, intermediateFields)
% createPointOutputs Convert regular-grid result structures to point results.
    arguments
        coordinates (1,:) struct
        tcFields (1,:) struct
        environmentFields (1,:) struct
        intermediateFields
    end

    timeCount = numel(coordinates);
    pointTemplate = struct("datetime", NaT, "Lon", [], "Lat", [], ...
        "U10", [], "V10", [], "Press", []);
    pointsTc = repmat(pointTemplate, 1, timeCount);
    pointsEnvironment = repmat(pointTemplate, 1, timeCount);
    pointsIntermediate = repmat(pointTemplate, 1, timeCount);

    for timeIndex = 1:timeCount
        pointsTc(timeIndex) = createPointResult(coordinates(timeIndex), tcFields(timeIndex));
        pointsEnvironment(timeIndex) = createPointResult( ...
            coordinates(timeIndex), environmentFields(timeIndex));
        if isnumeric(intermediateFields(timeIndex)) && intermediateFields(timeIndex) == 0
            zeroFields = struct("VelU", zeros(size(coordinates(timeIndex).Lon)), ...
                "VelV", zeros(size(coordinates(timeIndex).Lon)), ...
                "Press", zeros(size(coordinates(timeIndex).Lon)));
            pointsIntermediate(timeIndex) = createPointResult(coordinates(timeIndex), zeroFields);
        else
            pointsIntermediate(timeIndex) = createPointResult( ...
                coordinates(timeIndex), intermediateFields(timeIndex));
        end
    end
end

function pointResult = createPointResult(coordinates, regularFields)
    pointResult = struct("datetime", coordinates.datetime, ...
        "Lon", coordinates.Lon, "Lat", coordinates.Lat, ...
        "U10", regularFields.VelU, "V10", regularFields.VelV, ...
        "Press", regularFields.Press);
end
