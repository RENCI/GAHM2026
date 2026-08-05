function validateSeparateEnvHurData(era5)
%validateSeparateEnvHurData Validate ERA5 field dimensions before allocation.
    expectedSize = [numel(era5.lon), numel(era5.lat), numel(era5.time)];
    fieldNames = ["u10", "v10", "msl"];
    for fieldName = fieldNames
        actualSize = [size(era5.(fieldName), 1), size(era5.(fieldName), 2), ...
            size(era5.(fieldName), 3)];
        if ~isequal(actualSize, expectedSize)
            error("SeparateEnvHur:DimensionMismatch", ...
                "%s dimensions must match longitude, latitude, and time dimensions.", fieldName);
        end
    end
end
