function [env_vals, CONFIG] = SeparateEnvHur(config_input, ATCF_data_in)
%SeparateEnvHur  Extract environmental fields from ERA5 data for a tropical cyclone.
%   env_vals = SeparateEnvHur(config_file) runs the vortex removal using the
%   configuration specified in config_file (a .m file that defines CONFIG).
%
%   env_vals = SeparateEnvHur(config_input, ATCF_data_in) uses pre-loaded track
%   data instead of reading the track file.
%
%   [env_vals, CONFIG] = SeparateEnvHur(...) also returns the configuration
%   augmented with values derived from the gridded input file, notably the
%   grid increment CONFIG.dlonlat and the derived CONFIG.grid_size.
%
%   config_input can be:
%     - a string/char path to a .m file that defines a CONFIG struct
%       (original SeparateEnvHur config) or a sepenvhur struct (unified config)
%     - a struct with all required SeparateEnvHur fields (passed directly)
%
%                        J. Chen 2025-26
%                        B. Blanton 1/2026 - 2/2026 initial integration into GAHM2026
%                        R. Luettich 5/2/2026 - further integration into GAHM2026
%                        R. Luettich 8/18/2026 - centered on track eye location,
%                                                not ERA5 min pressure

    arguments
        config_input
        ATCF_data_in (1,:) struct = struct.empty
    end

% Use a 24-hour, unambiguous default datetime format.  run_GAHM2026 sets this
% too, but SeparateEnvHur can be run standalone, and under a lower-case "hh"
% format (a 12-hour clock with no AM/PM designator) 18:00 is reported as
% "06:00:00" and a date with no time component as "12:00:00", which makes the
% ERA5 epoch and timestep messages confusing to read.
datetimeFormat = 'yyyy-MMM-dd HH:mm:ss';
datetime.setDefaultFormats('default',datetimeFormat);
datetime.setDefaultFormats('defaultdate',datetimeFormat);

%% Configuration
if isstruct(config_input)
    CONFIG = config_input;
else
    run(config_input);
    % Support unified config: if sepenvhur exists (but CONFIG does not),
    % use sepenvhur as CONFIG
    if ~exist('CONFIG','var') && exist('sepenvhur','var')
        CONFIG = sepenvhur;
    end
end

logMsg(-1, "INFO", "Configuration loaded: storm=%s, year=%d", CONFIG.storm_name, CONFIG.storm_year);

%% Load and preprocess track data (shared reader with GAHM2026)
if ~isempty(ATCF_data_in)
    ATCF_data = ATCF_data_in;
    logMsg(-1, "INFO", "Using pre-loaded track data (%d entries)", length(ATCF_data));
else
    if CONFIG.debug, logMsg(-1, "DEBUG", "Loading track data from %s ...", CONFIG.track_file); end
    track_storm.track_file  = CONFIG.track_file;
    track_storm.designation = CONFIG.storm_designation;
    track_storm.year        = num2str(CONFIG.storm_year);
    track_storm.name        = CONFIG.storm_name;
    ATCF_data = readIBTrACS(track_storm);
    if isempty(ATCF_data)
        logMsg(-1, "ERROR", "Storm info combination of %s,%s not found in track file.", track_storm.designation, track_storm.year);
    end
end

% Trim to storm_start / storm_end
all_times = [ATCF_data.datetime];
keep = true(size(all_times));
if ~isnat(CONFIG.storm_start), keep = keep & all_times >= CONFIG.storm_start; end
if ~isnat(CONFIG.storm_end),   keep = keep & all_times <= CONFIG.storm_end;   end
ATCF_data = ATCF_data(keep);
if isempty(ATCF_data)
    logMsg(-1, "ERROR", "No track info remaining after storm_start and storm_end filtering. Check storm_info in config file.");
end

% Generate hourly time vector and interpolate positions
track.raw_time   = [ATCF_data.datetime];
track.raw_lon    = [ATCF_data.lon];   % track lons (typically -180 to 180)
track.raw_lat    = [ATCF_data.lat];
track.start_time = track.raw_time(1);
track.end_time   = track.raw_time(end);
track.time       = track.start_time:hours(1):track.end_time;
track.lon = interp1(track.raw_time, track.raw_lon, track.time);
track.lat = interp1(track.raw_time, track.raw_lat, track.time);
logMsg(-1, "INFO", "Track loaded: %d hourly times from %s to %s", length(track.time), string(track.start_time), string(track.end_time));

% Load ERA5 data (detects longitude convention)
logMsg(-1, "INFO", "Loading ERA5 data from %s ...", replace(CONFIG.background_file,'<year>',string(CONFIG.storm_year)));
era5 = getERA5Data(CONFIG,track.time);
logMsg(-1, "INFO", "ERA5 data loaded: grid=%dx%d, %d time steps", length(era5.lon), length(era5.lat), length(era5.time));
% era5 =
%   struct with fields:
%
%         time: [312×1 datetime]
%          lat: [721×1 double]
%          lon: [1440×1 double]
%          msl: [1440×721×312 double]
%          u10: [1440×721×312 double]
%          v10: [1440×721×312 double]
%     lon_grid: [721×1440 double]
%     lat_grid: [721×1440 double]

% Shift track longitudes to match the ERA5 longitude convention
if era5.lon_convention == "0_360"
    track.lon(track.lon < 0) = track.lon(track.lon < 0) + 360;
end

% Compute the grid increment (deg) from the gridded input file.  All
% downstream cell counts are derived from this rather than being configured
% as fixed numbers of grid cells.
dlon = abs(era5.lon(2)-era5.lon(1));
dlat = abs(era5.lat(2)-era5.lat(1));
logMsg(-1, "INFO", "gridded data lon,lat increments: %g, %g", dlon, dlat);
if dlon == dlat
    CONFIG.dlonlat = dlon;
else
    logMsg(-1, "ERROR", "gridded data longitude and latitude increments are not equal.");
end
CONFIG.grid_size = CONFIG.output_grid_length/CONFIG.dlonlat + 1;

% Compute grid indices from the actual ERA5 coordinate vectors
track.lon_idx = interp1(era5.lon, 1:length(era5.lon), track.lon, 'nearest', 'extrap');
track.lat_idx = interp1(era5.lat, 1:length(era5.lat), track.lat, 'nearest', 'extrap');

% Search box (grid cells) used by findPressureCenter.  The extraction is
% centered on the track eye as of v1.5, so this only affects the diagnostic
% report of where the gridded pressure minimum sits.
track.search_range = round(CONFIG.search_radius/CONFIG.dlonlat);


%% Initialize output arrays
OUTPUT = initializeOutputArrays(length(track.time), CONFIG);
if CONFIG.debug
    logMsg(-1, "DEBUG", "Output arrays initialized: %d times, %dx%d grid", ...
           length(track.time), CONFIG.grid_size, CONFIG.grid_size);
end

%% Main processing loop
if CONFIG.debug, logMsg(-1, "DEBUG", "Beginning main processing loop over %d time steps", length(track.time)); end

% Center the extraction on the track eye location rather than on the
% location of minimum pressure in the gridded input data.
era5.vortex.lon = track.lon;
era5.vortex.lat = track.lat;

PA2MB = 0.01;
for i = 1:length(track.time)

    logMsg(-1, "INFO", "Analyzing %s", string(track.time(i)))
    if CONFIG.debug, tic; end

    % extract at time level i
    slp = squeeze(era5.msl(:,:,i))' * PA2MB;
    u10 = squeeze(era5.u10(:,:,i))';
    v10 = squeeze(era5.v10(:,:,i))';
    windSpeed = hypot(u10, v10);
    if CONFIG.debug, logMsg(-1, "DEBUG", "Step %d/%d: field extraction done (SLP range=%.1f-%.1f mb, max wind=%.1f m/s)", i, length(track.time), min(slp(:)), max(slp(:)), max(windSpeed(:))); end

    % Not used in the calculation; retained as a diagnostic comparison
    % against the track eye location that the extraction is centered on.
    [era5_minpre_lon, era5_minpre_lat] = findPressureCenter(era5, track, i);
    if CONFIG.debug, logMsg(-1, "DEBUG", "Pressure center found at (%.4f, %.4f), track position (%.4f, %.4f)", era5_minpre_lon, era5_minpre_lat, track.lon(i), track.lat(i)); end

    % determine the cutline for setting the filter half-power length scale

    [Xq, Yq, hr_u, hr_v] = convertToPolarCoords(era5, track, CONFIG, i);
    if CONFIG.debug, logMsg(-1, "DEBUG", "Polar coordinate interpolation for filter isotach done (grid size=%dx%d)", size(Xq,1), size(Xq,2)); end

    Meanonly=true;
    [cutlineFilt,~,~] = findCutline(hr_u, hr_v, Xq, Yq, ...
                  era5, track, CONFIG, i, CONFIG.filter_isotach, Meanonly);

    max_radius_deg = CONFIG.output_grid_length/2;  % length of each radial line (deg)
    meanFilterRadiusDeg = max_radius_deg * (cutlineFilt.IdxMean / CONFIG.num_radial_points);
    if CONFIG.debug
        logMsg(-1, "DEBUG", "Filter isotach found on %i radials: Mean filter isotach radius=%.4f deg", ...
                cutlineFilt.found, meanFilterRadiusDeg);
    end

    % compute the filtered fields

    basic = computeBasicField(slp, u10, v10, track, CONFIG, i, meanFilterRadiusDeg);
    if CONFIG.debug, logMsg(-1, "DEBUG", "Basic field computed (filter half-power wavelength=%.2f deg)", CONFIG.filter_hp_multiplier*meanFilterRadiusDeg); end

    % determine the cutlines for the inner and outer blending isotachs

    Meanonly=false;
    [cutlineIn, isInsideInner, distance_inner] = findCutline(hr_u, hr_v, Xq, Yq, ...
            era5, track, CONFIG, i, CONFIG.wind_threshold_inner, Meanonly);
    if CONFIG.debug
        logMsg(-1, "DEBUG", "Inner cutline isotach found on %i radials, mean radius=%.1f km, points inside=%d", ...
                cutlineIn.found, mean(distance_inner), sum(isInsideInner));
    end

    Meanonly=false;
    [cutlineOut, isInsideOuter, distance_outer] = findCutline(hr_u, hr_v, Xq, Yq, ...
            era5, track, CONFIG, i, CONFIG.wind_threshold_outer, Meanonly);
    if CONFIG.debug
        logMsg(-1, "DEBUG", "Outer cutline isotach found on %i radials, mean radius=%.1f km, points inside=%d", ...
                cutlineOut.found, mean(distance_outer), sum(isInsideOuter));
    end

    OUTPUT = storeResults(OUTPUT, i, era5, track, CONFIG, ...
                          basic, slp, u10, v10, ...
                          isInsideOuter, isInsideInner, distance_outer, distance_inner);
    if CONFIG.debug, logMsg(-1, "DEBUG", "Results stored for step %d (elapsed=%.2f s)", i, toc); end

end

%% Save output
env_vals = createOutputStruct(OUTPUT, track, era5);

% NOTE (v1.5 behavior, ported verbatim): output_dir is created but is not
% joined to output_file_name, so the created directory may not be the one
% written to.  See "Known v1.5 defects" in DECISIONS.md.
outfile = CONFIG.output_file_name;
if isfield(CONFIG, 'output_dir')
    if ~exist(CONFIG.output_dir, 'dir'), mkdir(CONFIG.output_dir); end
end
if CONFIG.debug, logMsg(-1, "DEBUG", "Saving output to %s", outfile); end
save(outfile, "env_vals")
logMsg(-1, "INFO", "Done.");
end
