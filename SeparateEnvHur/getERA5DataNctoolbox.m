function era5 = getERA5DataNctoolbox(CONFIG, time)
% getERA5DataNctoolbox Extract an ERA5 time chunk with nctoolbox.

    assert(exist('ncgeodataset', 'class') == 8, ...
        "nctoolbox is not initialized. Run setup_nctoolbox before calling getERA5DataNctoolbox.");

    backgroundFile = string(strrep(CONFIG.background_file, "<year>", num2str(CONFIG.storm_year)));
    if startsWith(backgroundFile, "http")
        checkUrl(backgroundFile + ".html");
    else
        assert(exist(backgroundFile, "file") ~= 0, "ERA5 file not found: %s", backgroundFile);
    end

    era5Dataset = ncgeodataset(char(backgroundFile));

    % Get time variable name, which may be time or valid_time.
    variableNames = string(era5Dataset.variables);
    if ismember("time", variableNames)
        timeVariableName = "time";
    elseif ismember("valid_time", variableNames)
        timeVariableName = "valid_time";
    else
        logMsg(-1, "ERROR", "Time variable in netCDF file not recognized.");
    end

    era5.lon = double(era5Dataset.data('longitude'));
    era5.lat = double(era5Dataset.data('latitude'));
    era5.time = era5Dataset.data(char(timeVariableName));

    % Detect longitude convention from the ERA5 grid.
    if min(era5.lon) < 0
        era5.lon_convention = "-180_180";
    else
        era5.lon_convention = "0_360";
    end
    logMsg(-1, "INFO", "ERA5 longitude convention detected: %s (range %.1f to %.1f)", ...
        era5.lon_convention, min(era5.lon), max(era5.lon));

    timeUnits = era5Dataset.attribute(char(timeVariableName), 'units');
    parts = strsplit(strtrim(timeUnits));

    if numel(parts) < 3 || ~strcmpi(parts{2}, "since")
        logMsg(-1, "ERROR", ...
            sprintf("Unrecognized time units format: ""%s"". Expected ""<unit> since <reference_time>"".", ...
            timeUnits));
    end

    unitName = lower(parts{1});
    knownUnits = dictionary( ...
        {'milliseconds', 'millisecond', 'ms'}, [0.001 0.001 0.001], ...
        {'seconds', 'second', 'sec', 's'}, [1 1 1 1], ...
        {'minutes', 'minute', 'min'}, [60 60 60], ...
        {'hours', 'hour', 'hr', 'h'}, [3600 3600 3600 3600], ...
        {'days', 'day', 'd'}, [86400 86400 86400] ...
    );
    if ~isKey(knownUnits, {unitName})
        logMsg(-1, "ERROR", ...
            sprintf("Unsupported time unit ""%s"" in units string ""%s"".", unitName, timeUnits));
    end
    conversionFactor = knownUnits({unitName});

    epochString = strjoin(parts(3:end), " ");
    epochString = strrep(epochString, "T", " ");
    epochString = regexprep(epochString, "[Zz]$", "");
    if contains(epochString, ":")
        epochString = regexprep(epochString, "\s*[+-]\d{1,2}(:\d{2})?$", "");
    end

    try
        epochStart = datetime(epochString);
    catch
        logMsg(-1, "ERROR", ...
            sprintf("Failed to parse reference time ""%s"" from units string ""%s"".", ...
            epochString, timeUnits));
    end

    era5.time = datetime(double(era5.time)*conversionFactor, ...
        "ConvertFrom", "epochtime", "Epoch", epochStart);

    if CONFIG.debug
        logMsg(-1, "DEBUG", "time units=""%s"", epoch=%s, conversion factor=%.4g s", ...
            timeUnits, string(epochStart), conversionFactor);
    end

    selectedTimes = (era5.time >= time(1) & era5.time <= time(end));
    if isempty(find(selectedTimes, 1))
        logMsg(-1, "ERROR", "Track times not found in ERA5 netCDF file.");
    end

    firstTimeIndex = find(selectedTimes, 1, "first");
    timeCount = nnz(selectedTimes);

    % nctoolbox indexes in NetCDF dimension order. Reverse the returned
    % dimensions to retain ncread's longitude-by-latitude-by-time layout.
    era5.u10 = readFieldInChunks(era5Dataset, 'u10', firstTimeIndex, timeCount);
    era5.v10 = readFieldInChunks(era5Dataset, 'v10', firstTimeIndex, timeCount);
    era5.msl = readFieldInChunks(era5Dataset, 'msl', firstTimeIndex, timeCount);

    [era5.lon_grid, era5.lat_grid] = meshgrid(era5.lon, era5.lat);
    era5.time = era5.time(selectedTimes);
end

function fieldData = readFieldInChunks(dataset, variableName, firstTimeIndex, timeCount)
% readFieldInChunks Read a field without making an oversized OPeNDAP request.

    maximumElementsPerRead = 1e8;
    fieldSize = dataset.size(variableName);
    spatialElementCount = prod(fieldSize(2:end));
    timeChunkSize = max(1, floor(maximumElementsPerRead/spatialElementCount));
    firstChunkCount = min(timeChunkSize, timeCount);

    sourceStart = [firstTimeIndex 1 1];
    sourceEnd = fieldSize;
    sourceEnd(1) = firstTimeIndex + firstChunkCount - 1;
    firstChunk = double(permute(dataset.data(variableName, sourceStart, sourceEnd), [3 2 1]));

    fieldData = zeros(fieldSize(3), fieldSize(2), timeCount, "like", firstChunk);
    fieldData(:, :, 1:firstChunkCount) = firstChunk;

    for outputStart = (firstChunkCount + 1):timeChunkSize:timeCount
        chunkCount = min(timeChunkSize, timeCount - outputStart + 1);
        sourceStart(1) = firstTimeIndex + outputStart - 1;
        sourceEnd(1) = sourceStart(1) + chunkCount - 1;
        outputEnd = outputStart + chunkCount - 1;
        fieldData(:, :, outputStart:outputEnd) = ...
            double(permute(dataset.data(variableName, sourceStart, sourceEnd), [3 2 1]));
    end
end
