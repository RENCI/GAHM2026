function tests = testMergeFeatures
% testMergeFeatures Test features introduced while merging external code.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    toolsDirectory = fileparts(mfilename("fullpath"));
    projectDirectory = fileparts(toolsDirectory);
    testCase.TestData.OriginalPath = path;
    addpath(fullfile(projectDirectory, "util"));
end

function teardownOnce(testCase)
    path(testCase.TestData.OriginalPath);
end

function testNorthWindUsesFirstDirection(testCase)
    wafPoints = createWafPoint(-75, 35, [1, 2, 3, 4]);
    vortexPoints = struct("VelU", 0, "VelV", -10);

    actual = applyWAFfromPoints(wafPoints, vortexPoints, -75, 35);

    verifyEqual(testCase, actual.VelU, 0, "AbsTol", 1.0e-12);
    verifyEqual(testCase, actual.VelV, -10, "AbsTol", 1.0e-12);
end

function testEastWindUsesSecondDirection(testCase)
    wafPoints = createWafPoint(-75, 35, [1, 2, 3, 4]);
    vortexPoints = struct("VelU", -10, "VelV", 0);

    actual = applyWAFfromPoints(wafPoints, vortexPoints, -75, 35);

    verifyEqual(testCase, actual.VelU, -20, "AbsTol", 1.0e-12);
    verifyEqual(testCase, actual.VelV, 0, "AbsTol", 1.0e-12);
end

function testDirectionalInterpolation(testCase)
    wafPoints = createWafPoint(-75, 35, [1, 2, 3, 4]);
    speed = 10;
    direction = 45;
    vortexPoints = createWind(speed, direction);

    actual = applyWAFfromPoints(wafPoints, vortexPoints, -75, 35);

    verifyEqual(testCase, actual.VelU, 1.5*vortexPoints.VelU, "AbsTol", 1.0e-12);
    verifyEqual(testCase, actual.VelV, 1.5*vortexPoints.VelV, "AbsTol", 1.0e-12);
end

function testPeriodicInterpolationWrapsFrom359To1Degrees(testCase)
    wafPoints = createWafPoint(-75, 35, [1, 2, 3, 4]);
    vortexPoints = createWind([10, 10], [359, 1]);
    expectedFactors = [1 + 3/90, 1 + 1/90];

    actual = applyWAFfromPoints(wafPoints, vortexPoints, [-75, -75], [35, 35]);

    verifyEqual(testCase, actual.VelU, expectedFactors.*vortexPoints.VelU, "AbsTol", 1.0e-12);
    verifyEqual(testCase, actual.VelV, expectedFactors.*vortexPoints.VelV, "AbsTol", 1.0e-12);
    verifyLessThan(testCase, abs(expectedFactors(1) - expectedFactors(2)), 0.03);
end

function testCoordinatesAreMatchedAsPairs(testCase)
    wafPoints(1) = createWafPoint(-75, 35, [1, 1, 1, 1]);
    wafPoints(2) = createWafPoint(-74, 36, [2, 2, 2, 2]);
    vortexPoints = struct("VelU", 0, "VelV", -10);

    function callHelper()
        applyWAFfromPoints(wafPoints, vortexPoints, -75, 36);
    end

    verifyError(testCase, @callHelper, "applyWAFfromPoints:MissingCoordinateMatch");
end

function testDuplicateCoordinatesRaiseError(testCase)
    wafPoints(1) = createWafPoint(-75, 35, [1, 1, 1, 1]);
    wafPoints(2) = createWafPoint(-75, 35, [2, 2, 2, 2]);
    vortexPoints = struct("VelU", 0, "VelV", -10);

    function callHelper()
        applyWAFfromPoints(wafPoints, vortexPoints, -75, 35);
    end

    verifyError(testCase, @callHelper, "applyWAFfromPoints:DuplicateCoordinateMatch");
end

function testShapeAndStructureFieldsArePreserved(testCase)
    wafPoints(1) = createWafPoint(-75, 35, [2, 2, 2, 2]);
    wafPoints(2) = createWafPoint(-74, 35, [3, 3, 3, 3]);
    vortexPoints = struct("VelU", [3; 4], "VelV", [4; 3], "Speed", [5; 5], ...
        "Pressure", [990; 991], "StormName", "Synthetic");

    actual = applyWAFfromPoints(wafPoints, vortexPoints, [-75; -74], [35; 35]);

    verifySize(testCase, actual.VelU, [2, 1]);
    verifyEqual(testCase, actual.VelU, [6; 12]);
    verifyEqual(testCase, actual.VelV, [8; 9]);
    verifyEqual(testCase, actual.Speed, [10; 15]);
    verifyEqual(testCase, actual.Pressure, vortexPoints.Pressure);
    verifyEqual(testCase, actual.StormName, vortexPoints.StormName);
end

function testSpeedRemainsAbsentWhenAbsent(testCase)
    wafPoints = createWafPoint(-75, 35, [1, 1, 1, 1]);
    vortexPoints = struct("VelU", 0, "VelV", -10);

    actual = applyWAFfromPoints(wafPoints, vortexPoints, -75, 35);

    verifyFalse(testCase, isfield(actual, "Speed"));
end

function testEmptyWafPointsRaiseError(testCase)
    verifyError(testCase, @() callWithWaf(struct([])), ...
        "applyWAFfromPoints:EmptyWafPoints");
end

function testUnequalDirectionCountsRaiseError(testCase)
    wafPoints(1) = createWafPoint(-75, 35, [1, 2, 3, 4]);
    wafPoints(2) = createWafPoint(-74, 35, [1, 2]);

    verifyError(testCase, @() callWithWaf(wafPoints), ...
        "applyWAFfromPoints:InvalidWafPoint");
end

function testMalformedWafValuesRaiseError(testCase)
    malformedValues = {[], ones(2), "invalid", [1, Inf], [1, 2i]};
    for valueIndex = 1:numel(malformedValues)
        wafPoints = createWafPoint(-75, 35, malformedValues{valueIndex});
        verifyError(testCase, @() callWithWaf(wafPoints), ...
            "applyWAFfromPoints:InvalidWafPoint");
    end
end

function testInvalidCoordinatesRaiseError(testCase)
    invalidCoordinates = {"-75", 1i, Inf, [-75, -74]};
    for coordinateIndex = 1:numel(invalidCoordinates)
        wafPoints = createWafPoint(invalidCoordinates{coordinateIndex}, 35, [1, 2, 3, 4]);
        verifyError(testCase, @() callWithWaf(wafPoints), ...
            "applyWAFfromPoints:InvalidWafPoint");

        wafPoints = createWafPoint(-75, invalidCoordinates{coordinateIndex}, [1, 2, 3, 4]);
        verifyError(testCase, @() callWithWaf(wafPoints), ...
            "applyWAFfromPoints:InvalidWafPoint");
    end
end

function testCoordinateVelocityCountMismatchRaisesError(testCase)
    wafPoints = createWafPoint(-75, 35, [1, 2, 3, 4]);
    vortexPoints = struct("VelU", [0, 0], "VelV", [10, 10]);

    verifyError(testCase, ...
        @() applyWAFfromPoints(wafPoints, vortexPoints, -75, 35), ...
        "applyWAFfromPoints:SizeMismatch");
end

function testCoordinateVelocityShapeMismatchRaisesError(testCase)
    wafPoints = createWafPoint(-75, 35, [1, 2, 3, 4]);
    vortexPoints = struct("VelU", [0; 0], "VelV", [10; 10]);

    verifyError(testCase, ...
        @() applyWAFfromPoints(wafPoints, vortexPoints, [-75, -75], [35, 35]), ...
        "applyWAFfromPoints:ShapeMismatch");
end

function testMissingVelocityFieldsRaiseError(testCase)
    wafPoints = createWafPoint(-75, 35, [1, 2, 3, 4]);
    verifyError(testCase, @() applyWAFfromPoints(wafPoints, struct("VelV", -10), -75, 35), ...
        "applyWAFfromPoints:MissingVelocityField");
    verifyError(testCase, @() applyWAFfromPoints(wafPoints, struct("VelU", 0), -75, 35), ...
        "applyWAFfromPoints:MissingVelocityField");
end

function wafPoint = createWafPoint(longitude, latitude, waf)
    wafPoint = struct("lon", longitude, "lat", latitude, "WAF", waf);
end

function vortexPoints = createWind(speed, direction)
    vortexPoints = struct("VelU", -speed.*sind(direction), "VelV", -speed.*cosd(direction));
end

function callWithWaf(wafPoints)
    applyWAFfromPoints(wafPoints, struct("VelU", 0, "VelV", -10), -75, 35);
end
