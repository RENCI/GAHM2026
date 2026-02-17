function env_vals = ScrubEra5(config_input)
%SCRUBERA5  Extract environmental fields from ERA5 data for a tropical cyclone.
%   env_vals = ScrubEra5(config_file) runs the vortex removal using the
%   configuration specified in config_file (a .m file that defines CONFIG).
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

if CONFIG.debug, fprintf('[DEBUG:ScrubEra5] Configuration loaded: storm=%s, year=%d\n', CONFIG.storm_name, CONFIG.storm_year); end

%% Load and preprocess data
if CONFIG.debug, fprintf('[DEBUG:ScrubEra5] Loading track data from %s ...\n', CONFIG.track_file); end
[time, real_lon, real_lat, start_time, end_time] = loadTrackData(CONFIG);
num_times = length(time);
if CONFIG.debug, fprintf('[DEBUG:ScrubEra5] Track loaded: %d hourly times from %s to %s\n', num_times, string(start_time), string(end_time)); end

% lon_idx, lat_idx are the indices into the ERA5 grid for the track positions.  
% TODO: Note that this ("*4") depends on the resolution of .25 deg, which 
% should be fixed with round(1/CONFIG.resolution) or just calc from the
% era5 grid
lon_idx = round(real_lon * 4);
lat_idx = round((90 - real_lat) * 4);

% TODO: Replace loadERA5Data with something that gets any time period for a 
% specific storm, and preferably not the entire global grid
if CONFIG.debug, fprintf('[DEBUG:ScrubEra5] Loading ERA5 data from %s ...\n', CONFIG.nc_file); end
era5 = getERA5Data(CONFIG,time);
if CONFIG.debug, fprintf('[DEBUG:ScrubEra5] ERA5 data loaded: grid=%dx%d, %d time steps\n', length(era5.lon), length(era5.lat), length(era5.time)); end

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
    fprintf('[DEBUG:ScrubEra5] Output arrays initialized: %d times, %dx%d grid\n', num_times, grid_size, grid_size);
end

%% Main processing loop
if CONFIG.debug, fprintf('[DEBUG:ScrubEra5] Beginning main processing loop over %d time steps\n', num_times); end

for i = 1:num_times
    
    fprintf('[INFO:ScrubEra5] Analyzing %s\n',string(time(i)))
    if CONFIG.debug, tic; end

    % extract at time level i
    ThisMsl = squeeze(era5.msl(:,:,i))' / 100;  % convert from Pa to mb
    ThisU = squeeze(era5.u10(:,:,i))';
    ThisV = squeeze(era5.v10(:,:,i))';
    ThisWind = abs(ThisU+1i*ThisV);
    if CONFIG.debug, fprintf('[DEBUG:ScrubEra5]   Step %d/%d: field extraction done (SLP range=%.1f-%.1f mb, max wind=%.1f m/s)\n', i, num_times, min(ThisMsl(:)), max(ThisMsl(:)), max(ThisWind(:))); end

    [era5_lon(i), era5_lat(i)] = findPressureCenter(ThisMsl, era5.lon_grid, ...
        era5.lat_grid, lat_idx(i), lon_idx(i));
    if CONFIG.debug, fprintf('[DEBUG:ScrubEra5]   Pressure center found at (%.4f, %.4f), track position (%.4f, %.4f)\n', era5_lon(i), era5_lat(i), real_lon(i), real_lat(i)); end
    
    [Xq, Yq, hr_u, hr_v] = convertToPolarCoords(era5.lon_grid, era5.lat_grid, ...
        ThisU, ThisV, ThisMsl, ThisWind, ...
        lat_idx(i), lon_idx(i), era5_lon(i), era5_lat(i), CONFIG);
    if CONFIG.debug, fprintf('[DEBUG:ScrubEra5]   Polar coordinate interpolation done (grid size=%dx%d)\n', size(Xq,1), size(Xq,2)); end
    
    [count_34, in_34, distance_34] = findCutline(hr_u, hr_v, Xq, Yq, ...
        era5_lon(i), era5_lat(i), real_lon(i), real_lat(i), era5.lon, era5.lat, ...
        lat_idx(i), lon_idx(i), CONFIG.wind_threshold_34, CONFIG);
    if CONFIG.debug, fprintf('[DEBUG:ScrubEra5]   34-kt cutline found: mean radius=%.1f km, points inside=%d\n', mean(distance_34), sum(in_34)); end
    
    [count, in, distance] = findCutline(hr_u, hr_v, Xq, Yq, ...
        era5_lon(i), era5_lat(i), real_lon(i), real_lat(i), era5.lon, era5.lat, ...
        lat_idx(i), lon_idx(i), CONFIG.wind_threshold_10, CONFIG);
    if CONFIG.debug, fprintf('[DEBUG:ScrubEra5]   10-m/s cutline found: mean radius=%.1f km, points inside=%d\n', mean(distance), sum(in)); end
    
    tem_ave_r = mean(count_34, "all") * 10 / 1000;
    if CONFIG.debug, fprintf('[DEBUG:ScrubEra5]   Mean 34-kt vortex radius=%.4f deg\n', tem_ave_r); end
    
    [basic_slp, basic_u, basic_v] = computeBasicField(ThisMsl, ThisU, ThisV, ...
        lat_idx(i), lon_idx(i), tem_ave_r, CONFIG);
    if CONFIG.debug, fprintf('[DEBUG:ScrubEra5]   Basic field computed (filter half-power wavelength=%.2f)\n', tem_ave_r / 0.04); end
    
    OUTPUT = storeResults(OUTPUT, i, era5.lon_grid, era5.lat_grid, basic_slp, ...
        basic_u, basic_v, ThisMsl, ThisU, ThisV, in, in_34,  ...
        distance, distance_34, lat_idx(i), lon_idx(i), CONFIG);
    if CONFIG.debug, fprintf('[DEBUG:ScrubEra5]   Results stored for step %d (elapsed=%.2f s)\n', i, toc); end

end

%% Save output
% TODO: fix longitude shift 
env_vals = createOutputStruct(OUTPUT, time, real_lon, real_lat, era5_lon, era5_lat);
outfile = string(CONFIG.storm_name)+"_"+string(CONFIG.storm_year)+".mat";
if isfield(CONFIG, 'output_dir')
    if ~exist(CONFIG.output_dir, 'dir'), mkdir(CONFIG.output_dir); end
    outfile = fullfile(CONFIG.output_dir, outfile);
end
if CONFIG.debug, fprintf('[DEBUG:ScrubEra5] Saving output to %s\n', outfile); end
save(outfile, "env_vals")
if CONFIG.debug, fprintf('[DEBUG:ScrubEra5] Done.\n'); end

