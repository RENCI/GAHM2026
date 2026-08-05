function config = deriveSeparateEnvHurConfig(config, longitude, latitude)
%deriveSeparateEnvHurConfig Validate and normalize SeparateEnvHur configuration.
    gridSpacingDegrees = validateCoordinates(longitude, latitude);
    physicalFields = ["filter_grid_length", "output_grid_length", "search_radius"];
    legacyFields = ["filter_domain_size", "grid_half_size", "output_half_size", ...
        "search_range", "max_radius_deg"];
    physicalPresent = isfield(config, physicalFields);
    legacyPresent = isfield(config, legacyFields);

    if any(physicalPresent) && any(legacyPresent)
        error("SeparateEnvHur:MixedConfigurationModes", ...
            "Use either physical-length settings or legacy fixed-cell settings, not both.");
    elseif any(physicalPresent) && ~all(physicalPresent)
        error("SeparateEnvHur:PartialConfigurationMode", ...
            "Physical mode requires filter_grid_length, output_grid_length, and search_radius.");
    elseif any(legacyPresent) && ~all(legacyPresent)
        error("SeparateEnvHur:PartialConfigurationMode", ...
            "Legacy mode requires all five fixed-cell settings, including max_radius_deg.");
    elseif ~any(physicalPresent) && ~any(legacyPresent)
        error("SeparateEnvHur:PartialConfigurationMode", ...
            "Specify one complete SeparateEnvHur configuration mode.");
    end

    validatePointCount(config, "num_azimuth_points");
    validatePointCount(config, "num_radial_points");
    if config.num_radial_points < 2
        error("SeparateEnvHur:InvalidRadialPointCount", ...
            "num_radial_points must be an integer scalar of at least two.");
    end
    config.gridSpacingDegrees = gridSpacingDegrees;
    config.numAzimuthPoints = config.num_azimuth_points;
    config.numRadialPoints = config.num_radial_points;

    if all(physicalPresent)
        validatePhysicalLength(config, physicalFields);
        filterCells = validatedCellCount(config.filter_grid_length, gridSpacingDegrees, ...
            "filter_grid_length");
        outputCells = validatedCellCount(config.output_grid_length, gridSpacingDegrees, ...
            "output_grid_length");
        config.searchRange = validatedCellCount(config.search_radius, gridSpacingDegrees, ...
            "search_radius");
        if mod(filterCells, 2) ~= 0 || mod(outputCells, 2) ~= 0
            error("SeparateEnvHur:NonIntegerCellCount", ...
                "Filter and output lengths must each span an even number of grid cells.");
        end
        config.filterHalfWidth = filterCells/2;
        config.outputHalfWidth = outputCells/2;
        config.outputGridSize = outputCells + 1;
        config.radialIncrementDegrees = ...
            (config.output_grid_length/2)/(config.numRadialPoints-1);
        config.filter_domain_size = config.filterHalfWidth;
        config.grid_half_size = config.outputHalfWidth;
        config.output_half_size = config.outputHalfWidth;
        config.search_range = config.searchRange;
        config.max_radius_deg = config.output_grid_length/2;
    else
        validateLegacyValues(config, legacyFields);
        config.filterHalfWidth = config.filter_domain_size;
        config.outputHalfWidth = config.output_half_size;
        config.outputGridSize = 2*config.output_half_size + 1;
        config.searchRange = config.search_range;
        config.radialIncrementDegrees = config.max_radius_deg/(config.numRadialPoints-1);
        if ~isfield(config, "filter_isotach")
            config.filter_isotach = config.wind_threshold_inner;
        end
        if ~isfield(config, "filter_hp_multiplier")
            config.filter_hp_multiplier = 25;
        end
        if ~isfield(config, "num_points_smoother")
            config.num_points_smoother = 3;
        end
        if ~isfield(config, "isotach_smooth_variance")
            config.isotach_smooth_variance = 2000;
        end
    end

    requiredHalfWidth = max([config.filter_domain_size, config.grid_half_size, ...
        config.output_half_size]);
    requiredGridSize = 2*requiredHalfWidth + 1;
    if numel(longitude) < requiredGridSize || numel(latitude) < requiredGridSize
        error("SeparateEnvHur:GridTooSmall", ...
            "The loaded grid must accommodate the largest configured extraction half-width before allocation.");
    end
end

function spacing = validateCoordinates(longitude, latitude)
    if ~isnumeric(longitude) || ~isvector(longitude) || numel(longitude) < 2 || ...
            any(~isfinite(longitude)) || ~isnumeric(latitude) || ~isvector(latitude) || ...
            numel(latitude) < 2 || any(~isfinite(latitude))
        error("SeparateEnvHur:InvalidCoordinates", ...
            "Longitude and latitude must be finite numeric vectors with at least two entries.");
    end
    longitudeDiff = diff(longitude);
    latitudeDiff = diff(latitude);
    if ~(all(longitudeDiff > 0) || all(longitudeDiff < 0)) || ...
            ~(all(latitudeDiff > 0) || all(latitudeDiff < 0))
        error("SeparateEnvHur:NonmonotonicCoordinates", ...
            "Longitude and latitude must each be strictly monotonic.");
    end
    longitudeSpacing = abs(longitudeDiff(1));
    latitudeSpacing = abs(latitudeDiff(1));
    tolerance = 1.0e-10*max([longitudeSpacing, latitudeSpacing, 1]);
    if any(abs(abs(longitudeDiff) - longitudeSpacing) > tolerance) || ...
            any(abs(abs(latitudeDiff) - latitudeSpacing) > tolerance)
        error("SeparateEnvHur:NonuniformCoordinates", ...
            "All longitude and latitude increments must be uniform within numeric tolerance.");
    end
    if abs(longitudeSpacing - latitudeSpacing) > tolerance
        error("SeparateEnvHur:NonSquareGridSpacing", ...
            "Longitude and latitude grid increments must be equal within numeric tolerance.");
    end
    spacing = (longitudeSpacing + latitudeSpacing)/2;
end

function validatePointCount(config, fieldName)
    if ~isfield(config, fieldName) || ~isnumeric(config.(fieldName)) || ...
            ~isscalar(config.(fieldName)) || ~isfinite(config.(fieldName)) || ...
            config.(fieldName) <= 0 || config.(fieldName) ~= fix(config.(fieldName))
        error("SeparateEnvHur:InvalidPointCount", "%s must be a positive integer scalar.", fieldName);
    end
end

function validatePhysicalLength(config, fieldNames)
    for fieldName = fieldNames
        value = config.(fieldName);
        if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || value <= 0
            error("SeparateEnvHur:InvalidPhysicalLength", ...
                "%s must be a positive finite numeric scalar.", fieldName);
        end
    end
end

function validateLegacyValues(config, fieldNames)
    for fieldName = fieldNames
        value = config.(fieldName);
        if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || value <= 0 || ...
                (fieldName ~= "max_radius_deg" && value ~= fix(value))
            error("SeparateEnvHur:InvalidLegacySetting", ...
                "%s must be a positive finite scalar; cell counts must be integers.", fieldName);
        end
    end
end

function cellCount = validatedCellCount(lengthDegrees, spacingDegrees, fieldName)
    rawCellCount = lengthDegrees/spacingDegrees;
    cellCount = round(rawCellCount);
    countTolerance = 1.0e-10*max(abs(rawCellCount), 1);
    if abs(rawCellCount - cellCount) > countTolerance
        error("SeparateEnvHur:NonIntegerCellCount", ...
            "%s must map to an integer number of grid cells.", fieldName);
    end
end
