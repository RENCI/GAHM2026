function tests = testMergeFeatures
% testMergeFeatures Test features introduced while merging external code.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    toolsDirectory = fileparts(mfilename("fullpath"));
    projectDirectory = fileparts(toolsDirectory);
    testCase.TestData.ProjectDirectory = projectDirectory;
    testCase.TestData.OriginalPath = path;
    addpath(fullfile(projectDirectory, "util"));
    addpath(fullfile(projectDirectory, "SeparateEnvHur"));
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

function testPointWafMatLoading(testCase)
    fileName = string(tempname) + ".mat";
    cleanupFile = onCleanup(@() deleteIfPresent(fileName));
    WAF_points = createWafPoint(-75, 35, [1, 2, 3, 4]);
    save(fileName, "WAF_points");

    [actual, metadata] = loadWAFData("points", fileName);

    verifyEqual(testCase, actual, WAF_points);
    verifyEmpty(testCase, metadata);
end

function testPointWafMatLoadingRequiresNamedVariable(testCase)
    fileName = string(tempname) + ".mat";
    cleanupFile = onCleanup(@() deleteIfPresent(fileName));
    unrelated = 1;
    save(fileName, "unrelated");

    verifyError(testCase, @() loadWAFData("points", fileName), ...
        "GAHM2026:MissingWafPoints");
end

function testGridWafGeoTiffLoading(testCase)
    fileName = string(tempname) + ".tif";
    cleanupFile = onCleanup(@() deleteIfPresent(fileName));
    expectedRaster = uint16([1, 2; 3, 4]);
    latitudeLimits = [34, 36];
    longitudeLimits = [-76, -74];
    reference = georefcells(latitudeLimits, longitudeLimits, size(expectedRaster), ...
        ColumnsStartFrom="north");
    geotiffwrite(fileName, expectedRaster, reference, CoordRefSysCode=4326);

    [actualRaster, actualReference] = loadWAFData("grid", fileName);

    verifyEqual(testCase, actualRaster, expectedRaster);
    verifyEqual(testCase, actualReference.RasterSize, size(expectedRaster));
    verifyEqual(testCase, actualReference.LatitudeLimits, latitudeLimits, ...
        AbsTol=1.0e-12);
    verifyEqual(testCase, actualReference.LongitudeLimits, longitudeLimits, ...
        AbsTol=1.0e-12);
end

function testPointWafDispatchPreservesPressureAndMetadata(testCase)
    wafPoints = createWafPoint(-75, 35, [1, 2, 3, 4]);
    vortex = struct("VelU", -10, "VelV", 0, "Speed", 10, ...
        "Press", 975, "StormName", "Synthetic");

    actual = applyWAFforOutput("points", wafPoints, [], vortex, -75, 35);

    verifyEqual(testCase, actual.VelU, -20, "AbsTol", 1.0e-12);
    verifyEqual(testCase, actual.VelV, 0, "AbsTol", 1.0e-12);
    verifyEqual(testCase, actual.Speed, 20, "AbsTol", 1.0e-12);
    verifyEqual(testCase, actual.Press, 975);
    verifyEqual(testCase, actual.StormName, "Synthetic");
end

function testGridWafDispatchPreservesPressure(testCase)
    raster = 2*ones(2, 2, 4);
    metadata = struct("LongitudeLimits", [-76, -74], "LatitudeLimits", [34, 36]);
    vortex = struct("VelU", -10, "VelV", 0, "Press", 980, "Tag", 17);

    actual = applyWAFforOutput("grid", raster, metadata, vortex, -75, 35);

    verifyEqual(testCase, actual.VelU, -20, "AbsTol", 1.0e-12);
    verifyEqual(testCase, actual.VelV, 0, "AbsTol", 1.0e-12);
    verifyEqual(testCase, actual.Press, 980);
    verifyEqual(testCase, actual.Tag, 17);
end

function testWafHelpersRejectInvalidOutputTypes(testCase)
    verifyError(testCase, @() loadWAFData("invalid", "unused"), ...
        "GAHM2026:InvalidOutputType");
    verifyError(testCase, ...
        @() applyWAFforOutput("invalid", [], [], struct(), [], []), ...
        "GAHM2026:InvalidOutputType");
end

function testPointPackagingCopiesAllFieldsValuesAndShapes(testCase)
    coordinates = createCoordinates();
    tc = createRegularField(1);
    environment = createRegularField(10);
    intermediate = createRegularField(100);

    [pointsTc, pointsEnvironment, pointsIntermediate] = ...
        createPointOutputs(coordinates, tc, environment, intermediate);

    verifyPointResult(testCase, pointsTc, coordinates, tc);
    verifyPointResult(testCase, pointsEnvironment, coordinates, environment);
    verifyPointResult(testCase, pointsIntermediate, coordinates, intermediate);
end

function testPointPackagingCreatesShapedZerosForTypeOneAndTwoIntermediate(testCase)
    coordinates = repmat(createCoordinates(), 1, 2);
    coordinates(2).datetime = coordinates(1).datetime + hours(1);
    tc = repmat(createRegularField(1), 1, 2);
    environment = repmat(createRegularField(10), 1, 2);

    [~, ~, intermediate] = createPointOutputs(coordinates, tc, environment, 0);

    verifySize(testCase, intermediate, [1, 2]);
    for timeIndex = 1:2
        verifyEqual(testCase, intermediate(timeIndex).datetime, coordinates(timeIndex).datetime);
        verifyEqual(testCase, intermediate(timeIndex).Lon, coordinates(timeIndex).Lon);
        verifyEqual(testCase, intermediate(timeIndex).Lat, coordinates(timeIndex).Lat);
        verifySize(testCase, intermediate(timeIndex).U10, size(coordinates(timeIndex).Lon));
        verifyEqual(testCase, intermediate(timeIndex).U10, zeros(size(coordinates(timeIndex).Lon)));
        verifyEqual(testCase, intermediate(timeIndex).V10, zeros(size(coordinates(timeIndex).Lon)));
        verifyEqual(testCase, intermediate(timeIndex).Press, zeros(size(coordinates(timeIndex).Lon)));
    end
end

function testPointPackagingAcceptsMultiTimeZeroIntermediate(testCase)
    coordinates = repmat(createCoordinates(), 1, 2);
    coordinates(2).datetime = coordinates(1).datetime + hours(1);
    tc = repmat(createRegularField(1), 1, 2);
    environment = repmat(createRegularField(10), 1, 2);
    upstreamIntermediate = zeros(1, numel(coordinates));

    [~, ~, intermediate] = createPointOutputs( ...
        coordinates, tc, environment, upstreamIntermediate);

    for timeIndex = 1:numel(coordinates)
        verifyEqual(testCase, intermediate(timeIndex).U10, ...
            zeros(size(coordinates(timeIndex).Lon)));
        verifyEqual(testCase, intermediate(timeIndex).V10, ...
            zeros(size(coordinates(timeIndex).Lon)));
        verifyEqual(testCase, intermediate(timeIndex).Press, ...
            zeros(size(coordinates(timeIndex).Lon)));
    end
end

function testGridDiagnosticGuardOnlyStructuralBecauseFullFixtureIsDisproportionate(testCase)
    % A complete GAHM radial diagnostic fixture requires track and environmental datasets.
    source = join(readlines(fullfile(testCase.TestData.ProjectDirectory, "GAHM2026.m")), newline);

    verifySubstring(testCase, source, "if output.type == ""grid""" + newline + ...
        "        FU = griddedInterpolant");
end

function testCallerRetainsGenericAssignmentsStructuralDueToNoPracticalRunSeam(testCase)
    source = join(readlines(fullfile(testCase.TestData.ProjectDirectory, "run_GAHM2026.m")), newline);
    genericFields = ["Reggrid_out", "Reggrid_TC_out", "Reggrid_Env_out", ...
        "Reggrid_VVor_invtapHur_out"];

    for fieldName = genericFields
        verifySubstring(testCase, source, "Result." + fieldName);
    end
end

function testZeroQuadrantRadiiAreNormalizedAtIngestion(testCase)
    constants = struct("BLF", 0.9, "one2tenF", 0.89, "rhoa", 1.204, ...
        "pback_def", 1013, "Vmax_multiplier", 1);
    env = struct("type", 1);
    track = struct("datetime", datetime(2026, 8, 5), "lat", 30, "lon", -75, ...
        "Pmin", 950, "Vmax", 80, "Pouter", 1010, "numiso", 3, "RMW", 20, ...
        "R34", [0, 10, 20, 30], "R50", [40, 0, 50, 60], ...
        "R64", [70, 80, 0, 90]);

    actual = gahm2026Prep(constants, env, track, [], [], 1, 1, -1);

    verifyTrue(testCase, all(isnan(actual.RQuad([1, 6, 11]))));
    verifyEqual(testCase, actual.RQuad([2, 3, 4, 5, 7, 8, 9, 10, 12]), ...
        [10, 20, 30, 40, 50, 60, 70, 80, 90]*1852);
end

function testEitherOuterMaskSchemaProducesSameMask(testCase)
    expectedMask = [1, NaN; 1, 0];
    legacyFile = createEnvironmentalFile("Vortex_mask", expectedMask);
    outerFile = createEnvironmentalFile("Vortex_mask_outer", expectedMask);
    cleanupFiles = onCleanup(@() deleteFiles([legacyFile, outerFile]));
    sampleTime = datetime(2026, 8, 5);

    [~, ~, legacyMasks] = readEnvAndHurrFields2(struct("file_name", legacyFile), ...
        sampleTime, sampleTime);
    [~, ~, outerMasks] = readEnvAndHurrFields2(struct("file_name", outerFile), ...
        sampleTime, sampleTime);

    verifyEqual(testCase, outerMasks.mask2, legacyMasks.mask2);
    verifyEqual(testCase, outerMasks.mask2, [1, 0; 1, 0]);
end

function testPreferredOuterMaskWinsWhenBothSchemasArePresent(testCase)
    preferredMask = [1, 0; 1, 0];
    legacyMask = [0, 1; 0, 1];
    fileName = createEnvironmentalFile("Vortex_mask_outer", preferredMask, legacyMask);
    cleanupFile = onCleanup(@() deleteIfPresent(fileName));
    sampleTime = datetime(2026, 8, 5);

    [~, ~, masks] = readEnvAndHurrFields2(struct("file_name", fileName), ...
        sampleTime, sampleTime);

    verifyEqual(testCase, masks.mask2, preferredMask);
end

function testMissingOuterMaskIdentifiesAcceptedNames(testCase)
    fileName = createEnvironmentalFile("", []);
    cleanupFile = onCleanup(@() deleteIfPresent(fileName));
    sampleTime = datetime(2026, 8, 5);

    try
        readEnvAndHurrFields2(struct("file_name", fileName), sampleTime, sampleTime);
        verifyFail(testCase, "Expected a missing outer-mask error.");
    catch exception
        verifyEqual(testCase, exception.identifier, ...
            'readEnvAndHurrFields2:MissingOuterMaskField');
        verifySubstring(testCase, exception.message, ...
            "contain Vortex_mask_outer or Vortex_mask.");
    end
end

function testPhysicalGridConfigurationDerivesCellCounts(testCase)
    config = createPhysicalGridConfig();

    actual = deriveSeparateEnvHurConfig(config, 0:0.25:40, 0:0.25:40);

    verifyEqual(testCase, actual.gridSpacingDegrees, 0.25);
    verifyEqual(testCase, actual.outputGridSize, 81);
    verifyEqual(testCase, actual.filterHalfWidth, 60);
    verifyEqual(testCase, actual.outputHalfWidth, 40);
    verifyEqual(testCase, actual.searchRange, 6);
    verifyEqual(testCase, actual.numAzimuthPoints, 24);
    verifyEqual(testCase, actual.numRadialPoints, 800);
    verifyEqual(testCase, actual.radialIncrementDegrees, 10/799);
    verifyEqual(testCase, ...
        (actual.numRadialPoints-1)*actual.radialIncrementDegrees, 10);
end

function testPhysicalGridConfigurationRejectsNonSquareSpacing(testCase)
    config = createPhysicalGridConfig();

    verifyError(testCase, ...
        @() deriveSeparateEnvHurConfig(config, 0:0.25:40, 0:0.2501:40), ...
        "SeparateEnvHur:NonSquareGridSpacing");
end

function testPhysicalGridConfigurationAcceptsRoundoffInSpacing(testCase)
    config = createPhysicalGridConfig();

    actual = deriveSeparateEnvHurConfig(config, 0:0.25:40, 0:(0.25 + eps(0.25)):40);

    verifyEqual(testCase, actual.gridSpacingDegrees, 0.25, AbsTol=1.0e-12);
end

function testPhysicalGridConfigurationRejectsFractionalCells(testCase)
    config = createPhysicalGridConfig();
    config.output_grid_length = 20.1;

    verifyError(testCase, ...
        @() deriveSeparateEnvHurConfig(config, 0:0.25:40, 0:0.25:40), ...
        "SeparateEnvHur:NonIntegerCellCount");
end

function testPhysicalGridConfigurationRejectsUndersizedArrays(testCase)
    config = createPhysicalGridConfig();

    verifyError(testCase, ...
        @() deriveSeparateEnvHurConfig(config, 0:0.25:20, 0:0.25:20), ...
        "SeparateEnvHur:GridTooSmall");
end

function testLegacyConfigurationPreservesIndependentFields(testCase)
    config = createLegacyGridConfig();

    actual = deriveSeparateEnvHurConfig(config, 0:0.25:40, 0:0.25:40);

    verifyEqual(testCase, actual.filter_domain_size, 60);
    verifyEqual(testCase, actual.grid_half_size, 35);
    verifyEqual(testCase, actual.output_half_size, 40);
    verifyEqual(testCase, actual.search_range, 6);
    verifyEqual(testCase, actual.max_radius_deg, 12);
    verifyEqual(testCase, ...
        (actual.numRadialPoints-1)*actual.radialIncrementDegrees, 12);
    verifyEqual(testCase, actual.filter_isotach, actual.wind_threshold_inner);
    verifyEqual(testCase, actual.filter_hp_multiplier, 25);
end

function testLegacyConfigurationUsesLargestHalfWidthForGridSize(testCase)
    fieldNames = ["grid_half_size", "output_half_size"];
    for fieldName = fieldNames
        config = createLegacyGridConfig();
        config.(fieldName) = 61;

        verifyError(testCase, ...
            @() deriveSeparateEnvHurConfig(config, 0:0.25:30, 0:0.25:30), ...
            "SeparateEnvHur:GridTooSmall");
    end
end

function testConfigurationRejectsMixedModes(testCase)
    config = createPhysicalGridConfig();
    config.search_range = 6;

    verifyError(testCase, @() deriveSeparateEnvHurConfig(config, 0:0.25:40, 0:0.25:40), ...
        "SeparateEnvHur:MixedConfigurationModes");
end

function testConfigurationRejectsPartialPhysicalMode(testCase)
    config = rmfield(createPhysicalGridConfig(), "search_radius");

    verifyError(testCase, @() deriveSeparateEnvHurConfig(config, 0:0.25:40, 0:0.25:40), ...
        "SeparateEnvHur:PartialConfigurationMode");
end

function testConfigurationRejectsNonuniformCoordinates(testCase)
    config = createPhysicalGridConfig();
    longitude = [0:0.25:20, 20.3:0.25:40];

    verifyError(testCase, @() deriveSeparateEnvHurConfig(config, longitude, 0:0.25:40), ...
        "SeparateEnvHur:NonuniformCoordinates");
end

function testConfigurationRejectsInvalidCoordinatesAndCounts(testCase)
    config = createPhysicalGridConfig();
    verifyError(testCase, @() deriveSeparateEnvHurConfig(config, [0, NaN], [0, 0.25]), ...
        "SeparateEnvHur:InvalidCoordinates");

    config.num_radial_points = 2.5;
    verifyError(testCase, @() deriveSeparateEnvHurConfig(config, 0:0.25:40, 0:0.25:40), ...
        "SeparateEnvHur:InvalidPointCount");

    config.num_radial_points = 1;
    verifyError(testCase, @() deriveSeparateEnvHurConfig(config, 0:0.25:40, 0:0.25:40), ...
        "SeparateEnvHur:InvalidRadialPointCount");
end

function testConfigurationRejectsNonpositivePhysicalLength(testCase)
    config = createPhysicalGridConfig();
    config.search_radius = 0;

    verifyError(testCase, @() deriveSeparateEnvHurConfig(config, 0:0.25:40, 0:0.25:40), ...
        "SeparateEnvHur:InvalidPhysicalLength");
end

function testEra5DimensionsMustMatchCoordinatesAndTime(testCase)
    era5 = struct("lon", 1:4, "lat", 1:3, "time", 1:2, ...
        "u10", zeros(4, 3, 2), "v10", zeros(4, 3, 2), "msl", zeros(4, 3, 1));

    verifyError(testCase, @() validateSeparateEnvHurData(era5), ...
        "SeparateEnvHur:DimensionMismatch");
end

function testComputeBasicFieldDerivesFilterFromNormalizedConfig(testCase)
    field = reshape(sin(1:6561), 81, 81);
    track = struct("lat_idx", 41, "lon_idx", 41);
    config = struct("filterHalfWidth", 20, "gridSpacingDegrees", 0.5, ...
        "filter_hp_multiplier", 5);
    filterRadius = 2;
    wavelength = filterRadius*config.filter_hp_multiplier;
    filter = designfilt("lowpassiir", FilterOrder=5, HalfPowerFrequency=1/wavelength, ...
        DesignMethod="butter", SampleRate=1/config.gridSpacingDegrees);
    rows = 21:61;
    average = mean(field(rows, rows), "all");
    expected = applyButterworthFilter2D(field-average, filter, rows, rows) + average;

    actual = computeBasicField(field, field, field, track, config, 1, filterRadius);

    verifyEqual(testCase, actual.slp, expected, AbsTol=1.0e-12);
end

function testPolarGeometryHasEndpointSafeAzimuthRows(testCase)
    for azimuthCount = [24, 360]
        [era5, track, config] = createSyntheticPolarInputs(azimuthCount);

        [Xq, Yq] = convertToPolarCoords(era5, track, config, 1);
        angles = mod(atan2d(Yq(:, end), Xq(:, end)), 360);

        verifySize(testCase, Xq, [azimuthCount, config.numRadialPoints]);
        verifyEqual(testCase, angles, (0:azimuthCount-1)'*360/azimuthCount, ...
            AbsTol=1.0e-10);
        verifyEqual(testCase, numel(unique(round(angles, 10))), azimuthCount);
    end
end

function testCutlineExtractionUsesCorrespondingPolarRow(testCase)
    for azimuthCount = [24, 360]
        radialCount = 8;
        Xq = repmat((1:azimuthCount)', 1, radialCount);
        Yq = repmat(1:radialCount, azimuthCount, 1);
        cutlineIndex = mod((1:azimuthCount)'-1, radialCount) + 1;

        [longitude, latitude] = extractCutlineCoords(cutlineIndex, Xq, Yq);

        verifyEqual(testCase, longitude, 1:azimuthCount);
        verifyEqual(testCase, latitude, cutlineIndex');
    end
end

function testCircularSmoothUsesRequestedWidthAndMiddleCopy(testCase)
    values = (1:24)';
    expectedTripled = movmean([values; values; values], 5);

    actual = applyCircularSmooth(values, 24, 5);

    verifyEqual(testCase, actual, expectedTripled(25:48));
end

function testOutputArraysUseConfiguredGeometryAndLogicalMasks(testCase)
    for azimuthCount = [24, 360]
        config = struct("outputGridSize", 9, "numAzimuthPoints", azimuthCount);

        output = initializeOutputArrays(2, config);

        verifySize(testCase, output.mask, [2, 9, 9]);
        verifyTrue(testCase, islogical(output.mask));
        verifyTrue(testCase, islogical(output.mask_inner));
        verifySize(testCase, output.distance_outer, [2, azimuthCount]);
        verifySize(testCase, output.distance_inner, [2, azimuthCount]);
    end
end

function testDistanceUsesActualAzimuthVectorLengthAndReturnsRow(testCase)
    radiusDegrees = ones(360, 1);

    actual = computeDistanceKm(radiusDegrees, 60);

    verifySize(testCase, actual, [1, 360]);
    verifyEqual(testCase, actual(1), 111.32*cosd(60), AbsTol=1.0e-10);
    verifyEqual(testCase, actual(91), 110.54, AbsTol=1.0e-10);
end

function testNaNWindTerminatesEachRadialSearch(testCase)
    [era5, track, config] = createSyntheticPolarInputs(24);
    config.numRadialPoints = 10;
    config.radialIncrementDegrees = 1;
    config.outputHalfWidth = 2;
    config.isotach_smooth_variance = Inf;
    config.num_points_smoother = 3;
    angles = (0:23)'*15;
    radii = 0:9;
    [Xq, Yq] = pol2cart(deg2rad(angles), ones(24, 1)*radii);
    hrU = -20*sind(angles)*ones(1, 10);
    hrV = 20*cosd(angles)*ones(1, 10);
    hrU(:, 4) = NaN;
    hrV(:, 4) = NaN;

    cutlineIndex = findCutline(hrU, hrV, Xq, Yq, era5, track, config, 1, 10);

    verifyEqual(testCase, cutlineIndex, 4*ones(24, 1));
end

function testFindCutlineExaminesConvertedStartIndexAndUsesZeroBasedRadius(testCase)
    [era5, track, config] = createSyntheticPolarInputs(24);
    config.numRadialPoints = 4;
    config.radialIncrementDegrees = 1;
    config.outputHalfWidth = 2;
    config.isotach_smooth_variance = Inf;
    config.num_points_smoother = 3;
    angles = (0:23)'*15;
    radii = 0:3;
    [Xq, Yq] = pol2cart(deg2rad(angles), ones(24, 1)*radii);
    hrU = zeros(24, 4);
    hrV = zeros(24, 4);

    [cutlineIndex, ~, distance] = findCutline( ...
        hrU, hrV, Xq, Yq, era5, track, config, 1, 10);

    verifyEqual(testCase, cutlineIndex, 2*ones(24, 1));
    verifySize(testCase, distance, [1, 24]);
    verifyEqual(testCase, distance(1), 111.32, AbsTol=1.0e-10);
end

function testOutputDomainNearGridEdgeRaisesClearError(testCase)
    [era5, track, config] = createSyntheticPolarInputs(24);
    track.lat_idx = 1;
    config.outputHalfWidth = 2;
    config.numRadialPoints = 10;
    config.radialIncrementDegrees = 1;
    config.isotach_smooth_variance = Inf;
    config.num_points_smoother = 3;
    [Xq, Yq] = meshgrid(0:9, 1:24);
    wind = zeros(24, 10);

    verifyError(testCase, ...
        @() findCutline(wind, wind, Xq, Yq, era5, track, config, 1, 10), ...
        "SeparateEnvHur:OutputDomainOutOfBounds");
end

function testSmoothingAndConvexityRespectIterationBounds(testCase)
    alternating = repmat([1; 100], 12, 1);
    [smoothed, smoothIterations] = smoothCutline(alternating, -1, 24, 1);
    verifyEqual(testCase, smoothed, alternating);
    verifyEqual(testCase, smoothIterations, 200);

    Xq = zeros(24, 100);
    Yq = zeros(24, 100);
    [convexResult, convexIterations] = ensureConvexCutline( ...
        alternating, Xq, Yq, 24, 1);
    verifyEqual(testCase, convexResult, alternating);
    verifyEqual(testCase, convexIterations, 200);
end

function testLegacyConfigurationRunsFindCutlineWithoutSmoothingFields(testCase)
    legacyConfig = createLegacyGridConfig();
    legacyConfig.num_radial_points = 4;
    actual = deriveSeparateEnvHurConfig(legacyConfig, -40:0.5:40, -40:0.5:40);
    [era5, track] = createSyntheticPolarInputs(24);
    actual.outputHalfWidth = 2;
    angles = (0:23)'*15;
    radii = (0:actual.numRadialPoints-1)*actual.radialIncrementDegrees;
    [Xq, Yq] = pol2cart(deg2rad(angles), ones(24, 1)*radii);
    hrU = -20*sind(angles)*ones(1, actual.numRadialPoints);
    hrV = 20*cosd(angles)*ones(1, actual.numRadialPoints);

    [~, ~, distance] = findCutline( ...
        hrU, hrV, Xq, Yq, era5, track, actual, 1, 10);

    verifyEqual(testCase, actual.num_points_smoother, 3);
    verifyEqual(testCase, actual.isotach_smooth_variance, 2000);
    verifySize(testCase, distance, [1, 24]);
end

function testDefaultConfigDerivesSeparateEnvHurPointCounts(testCase)
    projectDirectory = testCase.TestData.ProjectDirectory;
    run(fullfile(projectDirectory, "config", "config_GAHM2026_default.m"));

    verifyEqual(testCase, sepenvhur.num_azimuth_points, GAHM_compute_info.ntheta);
    verifyEqual(testCase, sepenvhur.num_radial_points, GAHM_compute_info.nr);
end

function wafPoint = createWafPoint(longitude, latitude, waf)
    wafPoint = struct("lon", longitude, "lat", latitude, "WAF", waf);
end

function config = createPhysicalGridConfig()
    config = struct("filter_grid_length", 30, "output_grid_length", 20, ...
        "search_radius", 1.5, "num_azimuth_points", 24, ...
        "num_radial_points", 800);
end

function config = createLegacyGridConfig()
    config = struct("filter_domain_size", 60, "grid_half_size", 35, ...
        "output_half_size", 40, "search_range", 6, "max_radius_deg", 12, ...
        "num_azimuth_points", 24, "num_radial_points", 800, ...
        "wind_threshold_inner", 17.5);
end

function [era5, track, config] = createSyntheticPolarInputs(azimuthCount)
    coordinates = -10:0.5:10;
    [longitudeGrid, latitudeGrid] = meshgrid(coordinates, coordinates);
    era5 = struct("lon", coordinates, "lat", coordinates, ...
        "lon_grid", longitudeGrid, "lat_grid", latitudeGrid, ...
        "u10", zeros(41, 41, 1), "v10", zeros(41, 41, 1), ...
        "vortex", struct("lon", 0, "lat", 0));
    track = struct("lon_idx", 21, "lat_idx", 21, "lon", 0, "lat", 0);
    config = struct("outputHalfWidth", 20, "outputGridSize", 41, ...
        "numAzimuthPoints", azimuthCount, "numRadialPoints", 21, ...
        "radialIncrementDegrees", 0.5, "gridSpacingDegrees", 0.5);
end

function vortexPoints = createWind(speed, direction)
    vortexPoints = struct("VelU", -speed.*sind(direction), "VelV", -speed.*cosd(direction));
end

function callWithWaf(wafPoints)
    applyWAFfromPoints(wafPoints, struct("VelU", 0, "VelV", -10), -75, 35);
end

function coordinates = createCoordinates()
    coordinates = struct("datetime", datetime(2026, 8, 5, 12, 0, 0), ...
        "Lon", [-75; -74], "Lat", [35; 36]);
end

function field = createRegularField(offset)
    field = struct("VelU", offset + [1; 2], "VelV", offset + [3; 4], ...
        "Press", offset + [5; 6]);
end

function verifyPointResult(testCase, actual, coordinates, expectedField)
    verifyEqual(testCase, fieldnames(actual), ...
        {'datetime'; 'Lon'; 'Lat'; 'U10'; 'V10'; 'Press'});
    verifyEqual(testCase, actual.datetime, coordinates.datetime);
    verifyEqual(testCase, actual.Lon, coordinates.Lon);
    verifyEqual(testCase, actual.Lat, coordinates.Lat);
    verifyEqual(testCase, actual.U10, expectedField.VelU);
    verifyEqual(testCase, actual.V10, expectedField.VelV);
    verifyEqual(testCase, actual.Press, expectedField.Press);
    verifySize(testCase, actual.U10, size(coordinates.Lon));
end

function deleteIfPresent(fileName)
    if isfile(fileName)
        delete(fileName);
    end
end

function fileName = createEnvironmentalFile(outerMaskName, outerMask, legacyMask)
    sampleTime = datetime(2026, 8, 5);
    env_vals = struct("Time", sampleTime, "Lo", reshape([-76, -75; -76, -75], 1, 2, 2), ...
        "La", reshape([29, 29; 30, 30], 1, 2, 2), ...
        "env_u10", zeros(1, 2, 2), "env_v10", zeros(1, 2, 2), ...
        "env_msl", 1000*ones(1, 2, 2), "hur_u10", zeros(1, 2, 2), ...
        "hur_v10", zeros(1, 2, 2), "hur_msl", 990*ones(1, 2, 2), ...
        "Vortex_mask_inner", ones(1, 2, 2));
    if strlength(outerMaskName) > 0
        env_vals.(outerMaskName) = reshape(outerMask, 1, 2, 2);
    end
    if nargin == 3
        env_vals.Vortex_mask = reshape(legacyMask, 1, 2, 2);
    end
    fileName = string(tempname) + ".mat";
    save(fileName, "env_vals");
end

function deleteFiles(fileNames)
    for fileName = fileNames
        deleteIfPresent(fileName);
    end
end
