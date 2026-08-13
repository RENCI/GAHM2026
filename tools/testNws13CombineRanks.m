function tests = testNws13CombineRanks
% testNws13CombineRanks Test grouped NWS13 NetCDF output behavior.
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

function testFilterSlicesFixedTimeDimension(testCase)
    temporaryDirectory = tempname();
    mkdir(temporaryDirectory);
    cleanupDirectory = onCleanup(@() rmdir(temporaryDirectory, "s"));
    inputFile = fullfile(temporaryDirectory, "input.nc");
    outputFile = fullfile(temporaryDirectory, "output.nc");

    createInputFile(inputFile);

    nests = {{inputFile, "Filtered", "Synthetic", "1970-01-01 00:30:00"}};
    nws13_combine_ranks(outputFile, inputFile, "Main", "Synthetic", "nests", nests);

    verifyEqual(testCase, ncread(outputFile, "/Filtered/time"), int32(60));
    verifyEqual(testCase, ncread(outputFile, "/Filtered/PSFC"), [1001; 1003]);

    outputInfo = ncinfo(outputFile);
    verifyEqual(testCase, getAttribute(outputInfo.Attributes, "group_order"), "Main Filtered");
    verifyEqual(testCase, getAttribute(outputInfo.Groups(1).Attributes, "rank"), "1");
    verifyEqual(testCase, getAttribute(outputInfo.Groups(2).Attributes, "rank"), "2");
end

function testOutputClosesAfterError(testCase)
    temporaryDirectory = tempname();
    mkdir(temporaryDirectory);
    cleanupDirectory = onCleanup(@() rmdir(temporaryDirectory, "s"));
    inputFile = fullfile(temporaryDirectory, "input.nc");
    outputFile = fullfile(temporaryDirectory, "output.nc");
    createInputFile(inputFile);

    duplicateGroup = {{inputFile, "Main", "Synthetic nest"}};
    caughtException = [];
    try
        nws13_combine_ranks(outputFile, inputFile, "Main", "Synthetic", ...
            "nests", duplicateGroup);
    catch caughtException
        % The duplicate group intentionally exercises output cleanup.
    end
    verifyNotEmpty(testCase, caughtException);

    nws13_combine_ranks(outputFile, inputFile, "Retry", "Synthetic");
    verifyEqual(testCase, ncread(outputFile, "/Retry/time"), int32([0; 60]));
end

function testUnlimitedTimeAndPascalOutput(testCase)
    temporaryDirectory = tempname();
    mkdir(temporaryDirectory);
    cleanupDirectory = onCleanup(@() rmdir(temporaryDirectory, "s"));
    inputFile = fullfile(temporaryDirectory, "input.nc");
    outputFile = fullfile(temporaryDirectory, "output.nc");
    createUnlimitedInputFile(inputFile);

    nests = {{inputFile, "Filtered", "Nest source", "1970-01-01 00:30:00"}};
    nws13_combine_ranks(outputFile, inputFile, "Main", "Main source", ...
        "nests", nests, "institution", "Test institution", "pressure_units", "Pa");

    filteredInfo = ncinfo(outputFile, "/Filtered");
    timeDimension = filteredInfo.Dimensions(strcmp({filteredInfo.Dimensions.Name}, "time"));
    pressureInfo = ncinfo(outputFile, "/Filtered/PSFC");
    verifyTrue(testCase, timeDimension.Unlimited);
    verifyEqual(testCase, timeDimension.Length, 1);
    verifyEqual(testCase, string({pressureInfo.Dimensions.Name}), ["x", "time"]);
    verifyEqual(testCase, ncread(outputFile, "/Filtered/PSFC"), [100100; 100300]);
    verifyEqual(testCase, getAttribute(pressureInfo.Attributes, "units"), "Pa");
    verifyEqual(testCase, getAttribute(filteredInfo.Attributes, "source"), "Nest source");
end

function createInputFile(inputFile)
    nccreate(inputFile, "time", Dimensions={"time", 2}, Datatype="int32");
    ncwrite(inputFile, "time", int32([0; 60]));
    ncwriteatt(inputFile, "time", "units", "minutes since 1970-01-01");
    nccreate(inputFile, "msl", Dimensions={"x", 2, "time", 2});
    ncwrite(inputFile, "msl", [100000, 100100; 100200, 100300]);
end

function createUnlimitedInputFile(inputFile)
    nccreate(inputFile, "time", Dimensions={"time", Inf}, Datatype="int32");
    ncwrite(inputFile, "time", int32([0; 60]));
    ncwriteatt(inputFile, "time", "units", "minutes since 1970-01-01");
    nccreate(inputFile, "msl", Dimensions={"x", 2, "time", Inf});
    ncwrite(inputFile, "msl", [100000, 100100; 100200, 100300]);
end

function value = getAttribute(attributes, attributeName)
    attribute = attributes(strcmp({attributes.Name}, attributeName));
    value = string(attribute.Value);
end
