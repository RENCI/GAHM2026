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

function testDirectionalSeamIsContinuous(testCase)
    wafPoints = createWafPoint(-75, 35, [1, 2, 3, 4]);
    vortexPoints = createWind([10, 10], [359, 1]);
    expectedFactors = [1 + 3/90, 1 + 1/90];

    actual = applyWAFfromPoints(wafPoints, vortexPoints, [-75, -75], [35, 35]);

    verifyEqual(testCase, actual.VelU, expectedFactors.*vortexPoints.VelU, "AbsTol", 1.0e-12);
    verifyEqual(testCase, actual.VelV, expectedFactors.*vortexPoints.VelV, "AbsTol", 1.0e-12);
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

function wafPoint = createWafPoint(longitude, latitude, waf)
    wafPoint = struct("lon", longitude, "lat", latitude, "WAF", waf);
end

function vortexPoints = createWind(speed, direction)
    vortexPoints = struct("VelU", -speed.*sind(direction), "VelV", -speed.*cosd(direction));
end
