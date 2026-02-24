function env_vals = ScrubEra5(config_input, ATCF_data_in)
%SCRUBERA5  Extract environmental fields from ERA5 data for a tropical cyclone.
%   env_vals = ScrubEra5(config_file) runs the vortex removal using the
%   configuration specified in config_file (a .m file that defines CONFIG).
%
%   env_vals = ScrubEra5(config_input, ATCF_data_in) uses pre-loaded track
%   data instead of reading the track file.
%
%   config_input can be:
%     - a string/char path to a .m file that defines a CONFIG struct
%       (original ScrubEra5 config) or a scrub_info struct (unified config)
%     - a struct with all required ScrubEra5 fields (passed directly)

%% Configuration
if isstruct(config_input)
    CONFIG = config_input;
else
    run(config_input);
    % Support unified config: if scrub_info exists (but CONFIG does not),
    % use scrub_info as CONFIG
    if ~exist('CONFIG','var') && exist('scrub_info','var')
        CONFIG = scrub_info;
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
raw_time   = [ATCF_data.datetime];
raw_lon    = [ATCF_data.lon] + 360;   % shift to 0-360 for ERA5
raw_lat    = [ATCF_data.lat];
start_time = raw_time(1);
end_time   = raw_time(end);
time       = start_time:hours(1):end_time;
real_lon   = interp1(raw_time, raw_lon, time);
real_lat   = interp1(raw_time, raw_lat, time);
num_times  = length(time);
logMsg(-1, 'INFO', 'Track loaded: %d hourly times from %s to %s', num_times, string(start_time), string(end_time));

% lon_idx, lat_idx are the indices into the ERA5 grid for the track positions.
% TODO: Note that this ("*4") depends on the resolution of .25 deg, which
% should be fixed with round(1/CONFIG.resolution) or just calc from the
% era5 grid
lon_idx = round(real_lon * 4);
lat_idx = round((90 - real_lat) * 4);

logMsg(-1, 'INFO', 'Loading ERA5 data from %s ...', ...
    replace(CONFIG.background_file,'<year>',string(CONFIG.storm_year)));
era5 = getERA5Data(CONFIG,time);
logMsg(-1, 'INFO', 'ERA5 data loaded: grid=%dx%d, %d time steps', ...
    length(era5.lon), length(era5.lat), length(era5.time)); 

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

%% Initialize output arrays
OUTPUT = initializeOutputArrays(num_times, CONFIG);
era5_lon = zeros(1, num_times);
era5_lat = zeros(1, num_times);
if CONFIG.debug
    grid_size = 2 * CONFIG.output_half_size + 1;
    logMsg(-1, 'DEBUG', 'Output arrays initialized: %d times, %dx%d grid', num_times, grid_size, grid_size);
end

%% Main processing loop
if CONFIG.debug, logMsg(-1, 'DEBUG', 'Beginning main processing loop over %d time steps', num_times); end

for i = 1:num_times
    
    logMsg(-1, 'INFO', 'Analyzing %s',string(time(i)))
    if CONFIG.debug, tic; end

    % extract at time level i
    ThisMsl = squeeze(era5.msl(:,:,i))' / 100;  % convert from Pa to mb
    ThisU = squeeze(era5.u10(:,:,i))';
    ThisV = squeeze(era5.v10(:,:,i))';
    ThisWind = abs(ThisU+1i*ThisV);
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Step %d/%d: field extraction done (SLP range=%.1f-%.1f mb, max wind=%.1f m/s)', i, num_times, min(ThisMsl(:)), max(ThisMsl(:)), max(ThisWind(:))); end

    [era5_lon(i), era5_lat(i)] = findPressureCenter(ThisMsl, era5.lon_grid, ...
        era5.lat_grid, lat_idx(i), lon_idx(i));
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Pressure center found at (%.4f, %.4f), track position (%.4f, %.4f)', era5_lon(i), era5_lat(i), real_lon(i), real_lat(i)); end
    
    [Xq, Yq, hr_u, hr_v] = convertToPolarCoords(era5.lon_grid, era5.lat_grid, ...
        ThisU, ThisV, ThisMsl, ThisWind, ...
        lat_idx(i), lon_idx(i), era5_lon(i), era5_lat(i), CONFIG);
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Polar coordinate interpolation done (grid size=%dx%d)', size(Xq,1), size(Xq,2)); end
    
    [count_inner, in_inner, distance_inner] = findCutline(hr_u, hr_v, Xq, Yq, ...
        era5_lon(i), era5_lat(i), real_lon(i), real_lat(i), era5.lon, era5.lat, ...
        lat_idx(i), lon_idx(i), CONFIG.wind_threshold_inner, CONFIG);
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Inner cutline found: mean radius=%.1f km, points inside=%d', mean(distance_inner), sum(in_inner)); end
    
    [~, in, distance_outer] = findCutline(hr_u, hr_v, Xq, Yq, ...
        era5_lon(i), era5_lat(i), real_lon(i), real_lat(i), era5.lon, era5.lat, ...
        lat_idx(i), lon_idx(i), CONFIG.wind_threshold_outer, CONFIG);
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Outer cutline found: mean radius=%.1f km, points inside=%d', mean(distance_outer), sum(in)); end
    
    tem_ave_r = mean(count_inner, "all") * 10 / 1000;
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Mean inner vortex radius=%.4f deg', tem_ave_r); end
    
    [basic_slp, basic_u, basic_v] = computeBasicField(ThisMsl, ThisU, ThisV, ...
        lat_idx(i), lon_idx(i), tem_ave_r, CONFIG);
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Basic field computed (filter half-power wavelength=%.2f)', tem_ave_r / 0.04); end
    
    OUTPUT = storeResults(OUTPUT, i, era5.lon_grid, era5.lat_grid, basic_slp, ...
        basic_u, basic_v, ThisMsl, ThisU, ThisV, in, in_inner,  ...
        distance_outer, distance_inner, lat_idx(i), lon_idx(i), CONFIG);
    if CONFIG.debug, logMsg(-1, 'DEBUG', 'Results stored for step %d (elapsed=%.2f s)', i, toc); end

end

%% Save output
% TODO: fix longitude shift in createOutputStruct
env_vals = createOutputStruct(OUTPUT, time, real_lon, real_lat, era5_lon, era5_lat);
outfile = string(CONFIG.storm_name)+"_"+string(CONFIG.storm_designation)+"_"+string(CONFIG.storm_year)+".mat";
if isfield(CONFIG, 'output_dir')
    if ~exist(CONFIG.output_dir, 'dir'), mkdir(CONFIG.output_dir); end
    outfile = fullfile(CONFIG.output_dir, outfile);
end
if CONFIG.debug, logMsg(-1, 'DEBUG', 'Saving output to %s', outfile); end
save(outfile, "env_vals")
logMsg(-1, 'INFO', 'Done.');
