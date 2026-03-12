function env_vals = SeparateEnvHur(config_input, ATCF_data_in)
%SeparateEnvHur  Extract environmental fields from ERA5 data for a tropical cyclone.
%   env_vals = SeparateEnvHur(config_file) runs the vortex removal using the
%   configuration specified in config_file (a .m file that defines CONFIG).
%
%   env_vals = SeparateEnvHur(config_input, ATCF_data_in) uses pre-loaded track
%   data instead of reading the track file.
%
%   config_input can be:
%     - a string/char path to a .m file that defines a CONFIG struct
%       (original SeparateEnvHur config) or a sepenvhur struct (unified config)
%     - a struct with all required SeparateEnvHur fields (passed directly)

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

logMsg(-1, 'INFO', 'Configuration loaded: storm=%s, year=%d', CONFIG.storm_name, CONFIG.storm_year);

%% Load and preprocess track data (shared reader with GAHM2026)
if nargin >= 2 && ~isempty(ATCF_data_in)
    ATCF_data = ATCF_data_in;
    logMsg(-1, 'INFO', 'Using pre-loaded track data (%d entries)', length(ATCF_data));
else
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Loading track data from %s ...', CONFIG.track_file); end
    track_storm.track_file  = CONFIG.track_file;
    track_storm.designation = CONFIG.storm_designation;
    track_storm.year        = num2str(CONFIG.storm_year);
    track_storm.name        = CONFIG.storm_name;
    ATCF_data = read_IBTrACS(track_storm);
    if isempty(ATCF_data)
        logMsg(-1, 'ERROR', 'Storm info combination of %s,%s not found in track file.',track_storm.designation,track_storm.year);
    end
end

% Trim to storm_start / storm_end
all_times = [ATCF_data.datetime];
keep = true(size(all_times));
if ~isnat(CONFIG.storm_start), keep = keep & all_times >= CONFIG.storm_start; end
if ~isnat(CONFIG.storm_end),   keep = keep & all_times <= CONFIG.storm_end;   end
ATCF_data = ATCF_data(keep);
if isempty(ATCF_data)
    logMsg(-1, 'ERROR', 'No track info remaining after storm_start and storm_end filtering. Check storm_info in config file.');
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
logMsg(-1, 'INFO', 'Track loaded: %d hourly times from %s to %s', length(track.time), string(track.start_time), string(track.end_time));

% Load ERA5 data (detects longitude convention)
logMsg(-1, 'INFO', 'Loading ERA5 data from %s ...', replace(CONFIG.background_file,'<year>',string(CONFIG.storm_year)));
era5 = getERA5Data(CONFIG,track.time);
logMsg(-1, 'INFO', 'ERA5 data loaded: grid=%dx%d, %d time steps', length(era5.lon), length(era5.lat), length(era5.time));
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
if strcmp(era5.lon_convention, '0_360')
    track.lon(track.lon < 0) = track.lon(track.lon < 0) + 360;
end

% Compute grid indices from the actual ERA5 coordinate vectors
track.lon_idx = interp1(era5.lon, 1:length(era5.lon), track.lon, 'nearest', 'extrap');
track.lat_idx = interp1(era5.lat, 1:length(era5.lat), track.lat, 'nearest', 'extrap');
track.search_range = CONFIG.search_range;


%% Initialize output arrays
OUTPUT = initializeOutputArrays(length(track.time), CONFIG);
era5.vortex.lon = zeros(1, length(track.time));
era5.vortex.lat = zeros(1, length(track.time));
if CONFIG.debug
    grid_size = 2 * CONFIG.output_half_size + 1;
    logMsg(-1, 'DEBUG', 'Output arrays initialized: %d times, %dx%d grid', length(track.time), grid_size, grid_size);
end

%% Main processing loop
if CONFIG.debug, logMsg(-1, 'DEBUG', 'Beginning main processing loop over %d time steps', length(track.time)); end

PA2MB = 0.01;
for i = 1:length(track.time)
    
    logMsg(-1, 'INFO', 'Analyzing %s',string(track.time(i)))
    if CONFIG.debug, tic; end

    % extract at time level i
    slp = squeeze(era5.msl(:,:,i))' * PA2MB;
    u10 = squeeze(era5.u10(:,:,i))';
    v10 = squeeze(era5.v10(:,:,i))';
    windSpeed = hypot(u10, v10);
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Step %d/%d: field extraction done (SLP range=%.1f-%.1f mb, max wind=%.1f m/s)', i, length(track.time), min(slp(:)), max(slp(:)), max(windSpeed(:))); end

    [era5.vortex.lon(i), era5.vortex.lat(i)] = findPressureCenter(era5, track, i);
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Pressure center found at (%.4f, %.4f), track position (%.4f, %.4f)', era5.vortex.lon(i), era5.vortex.lat(i), track.lon(i), track.lat(i)); end
    
    [Xq, Yq, hr_u, hr_v] = convertToPolarCoords(era5, track, CONFIG, i);
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Polar coordinate interpolation done (grid size=%dx%d)', size(Xq,1), size(Xq,2)); end
    
    [cutlineIdx_inner, isInsideInner, distance_inner] = findCutline(hr_u, hr_v, Xq, Yq, ...
                                                           era5, track, CONFIG, i, ...
                                                           CONFIG.wind_threshold_inner);
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Inner cutline found: mean radius=%.1f km, points inside=%d', mean(distance_inner), sum(isInsideInner)); end
    
    [~, isInsideOuter, distance_outer] = findCutline(hr_u, hr_v, Xq, Yq, ...
                                           era5, track, CONFIG, i, ...
                                           CONFIG.wind_threshold_outer);
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Outer cutline found: mean radius=%.1f km, points inside=%d', mean(distance_outer), sum(isInsideOuter)); end
    
    meanInnerRadiusDeg = mean(cutlineIdx_inner, "all") * CONFIG.max_radius_deg / CONFIG.num_radial_points;
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Mean inner vortex radius=%.4f deg', meanInnerRadiusDeg); end
    
    basic = computeBasicField(slp, u10, v10, ...
                              track, CONFIG, i, meanInnerRadiusDeg);
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Basic field computed (mean inner radius=%.4f deg)', meanInnerRadiusDeg); end
    
    OUTPUT = storeResults(OUTPUT, i, era5, track, CONFIG, ...
                          basic, slp, u10, v10, ...
                          isInsideOuter, isInsideInner, distance_outer, distance_inner);
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Results stored for step %d (elapsed=%.2f s)', i, toc); end

end

%% Save output
env_vals = createOutputStruct(OUTPUT, track, era5);
outfile = string(CONFIG.storm_name)+"_"+string(CONFIG.storm_designation)+"_"+string(CONFIG.storm_year)+".mat";
if isfield(CONFIG, 'output_dir')
    if ~exist(CONFIG.output_dir, 'dir'), mkdir(CONFIG.output_dir); end
    outfile = fullfile(CONFIG.output_dir, outfile);
end
if CONFIG.debug, logMsg(-1, 'DEBUG', 'Saving output to %s', outfile); end
save(outfile, "env_vals")
logMsg(-1, 'INFO', 'Done.');
