function Isoline = findIsotach(config_input)
%
% Find a specified isotach in gridded wind & pressure fields (e.g., ERA5) 
% around the eye of a tropical cyclone.
%
% Input: 
% Requires a GAHM2026 configuration file
%
% Returns a data structure containing:
% Isoline.time = times Isotach distances are evaluated
% Isoline.found = # of radial lines the specified isotach was found along
% Isoline.Idx = # of radial points along each radial line from the TC eye
%                                              to the specified isotach
% Isoline.distance = distances (km) along each radial lines from the TC eye
%                                              to the specified isotach 
% Isoline.IdxMean = mean of the non NaN values of Isoline.Idx
% Isoline.distMean = mean of the non NaN values of Isoline.distance
% 
% If the specified isotach is not found along a radial line, Isoline.Idx 
%                                               and Isoline.distance = NaN
% 
% The TC eye is identified as the grid location with the minimum pressure
% 
%
%
%                R. Luettich, B. Blanton 8/28/2026
%                                        8/31/2026
%
%
%  TODO - clean up the file output piece of this
%% -------------------------------------------------------------------------

    arguments
        config_input     
    end

% Use a 24-hour, unambiguous default datetime format.  Under a lower-case "hh"
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

%% Load and preprocess track data (shared reader with GAHM2026)
if CONFIG.debug, logMsg(-1, "DEBUG", "Loading track data from %s ...", CONFIG.track_file); end
track_storm.track_file  = CONFIG.track_file;
track_storm.designation = CONFIG.storm_designation;
track_storm.year        = num2str(CONFIG.storm_year);
track_storm.name        = CONFIG.storm_name;
ATCF_data = readIBTrACS(track_storm);
if isempty(ATCF_data)
    logMsg(-1, "ERROR", "Storm info combination of %s,%s not found in track file.", ...
                                track_storm.designation, track_storm.year);
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
logMsg(-1, "INFO", "Track loaded: %d hourly times from %s to %s", ...
    length(track.time), string(track.start_time), string(track.end_time));

% Load ERA5 data (detects longitude convention)
logMsg(-1, "INFO", "Loading ERA5 data from %s ...", replace(CONFIG.background_file, ...
                                     '<year>',string(CONFIG.storm_year)));
era5 = getERA5Data(CONFIG,track.time);
logMsg(-1, "INFO", "ERA5 data loaded: grid=%dx%d, %d time steps", ...
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

% Shift track longitudes to match the ERA5 longitude convention
if era5.lon_convention == "0_360"
    track.lon(track.lon < 0) = track.lon(track.lon < 0) + 360;
end

% Compute the grid increment (deg) from the gridded input file.  
dlon = abs(era5.lon(2)-era5.lon(1));
dlat = abs(era5.lat(2)-era5.lat(1));
logMsg(-1, "INFO", "gridded data lon,lat increments: %g, %g", dlon, dlat);
if dlon == dlat
    CONFIG.dlonlat = dlon;
else
    logMsg(-1, "ERROR", "gridded data longitude and latitude increments are not equal.");
end

% Compute grid indices from the actual ERA5 coordinate vectors
track.lon_idx = interp1(era5.lon, 1:length(era5.lon), track.lon, 'nearest', 'extrap');
track.lat_idx = interp1(era5.lat, 1:length(era5.lat), track.lat, 'nearest', 'extrap');

% Search box (grid cells) used by findPressureCenter.

track.search_range = round(CONFIG.search_radius/CONFIG.dlonlat);

%% Initialize output arrays
outputflag=false;
if outputflag
    OUTPUT = initializeOutputArrays(length(track.time), CONFIG);
    if CONFIG.debug
        logMsg(-1, "DEBUG", "Output array initialized: %d times, %d radial lines", ...
               length(track.time), CONFIG.num_azimuthal_points);
    end
end

%% Main processing loop
if CONFIG.debug, logMsg(-1, "DEBUG", "Beginning main processing loop over %d time steps", length(track.time)); end

Isotach=CONFIG.filter_isotach;

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

    [era5.vortex.lon(i), era5.vortex.lat(i)] = findPressureCenter(era5, track, i);
    if CONFIG.debug, logMsg(-1, "DEBUG", "Pressure center found at (%.4f, %.4f), track position (%.4f, %.4f)", era5.vortex.lon(i), era5.vortex.lat(i), track.lon(i), track.lat(i)); end
    
    % determine the distance to the specified isotach

    [Xq, Yq, hr_u, hr_v] = convertToPolarCoords(era5, track, CONFIG, i);
    if CONFIG.debug, logMsg(-1, "DEBUG", "Polar coordinate interpolation for filter isotach done (grid size=%dx%d)", size(Xq,1), size(Xq,2)); end

    Isoline(i) = findIsoDist(hr_u, hr_v, track, CONFIG, i, Isotach);

    if CONFIG.debug
        logMsg(-1, "DEBUG", "isotach found on %.0f radials: Mean isotach radius=%.4f km", ...
                Isoline(i).found, Isoline(i).distMean);
    end

    if outputflag
        OUTPUT = storeResults(OUTPUT, i, era5, track, CONFIG, NaN, NaN, NaN, ...
                                      NaN, NaN, NaN, NaN, Isoline.distance);
        if CONFIG.debug, logMsg(-1, "DEBUG", "Results stored for step %d (elapsed=%.2f s)", i, toc); end
    end

end

%% Save output - output functions need to be revised to work with this code!!!

if outputflag
    env_vals = createOutputStruct(Isoline);
    outfile = CONFIG.output_file_name;
    if isfield(CONFIG, 'output_dir')
        if ~exist(CONFIG.output_dir, 'dir'), mkdir(CONFIG.output_dir); end
    end
    if CONFIG.debug, logMsg(-1, "DEBUG", "Saving output to %s", outfile); end
    save(outfile, "isoline_distances")
    logMsg(-1, "INFO", "Done.");
end

end

%% find the isoline

function Isoline = findIsoDist( hr_u, hr_v, track, CONFIG, i, wind_threshold)

    num_radial = CONFIG.num_radial_points;
    max_search = CONFIG.output_grid_length/2;
    n_angle = CONFIG.num_azimuthal_points;

    IsolineIdx1 = zeros(1, n_angle);
    Isoline.time=track.time(i);    
    Isoline.found = 0;

    for j = 1:n_angle
        windspeed = hypot(hr_u(j,:),hr_v(j,:));
        [wind_max, wind_max_Idx]=max(windspeed);
        IsolineIdx1(j) = NaN;
        if wind_max > wind_threshold
            if any(windspeed(wind_max_Idx:num_radial) < wind_threshold)                
                Isoline.found = Isoline.found + 1;
                IsolineIdx1(j) = wind_max_Idx - 1 + ...
                    find(windspeed(wind_max_Idx:num_radial) ...
                        < wind_threshold, 1, 'first');
            end
        end
    end
    
    Isoline.Idx=IsolineIdx1;
    Isoline_deg = max_search * (IsolineIdx1 / num_radial);
    Isoline.distance = computeDistanceKm(Isoline_deg, track.lat(i), CONFIG);

    if Isoline.found == 0
        Isoline.IdxMean = NaN;
        Isoline.distMean = NaN;
    else
        Isoline.IdxMean = mean(IsolineIdx1(~isnan(IsolineIdx1)));
        Isoline.distMean = mean(Isoline.distance(~isnan(IsolineIdx1)));
    end

end


%% functions to generate an output file - need to be checked / fixed before
%  being used!!!

function OUTPUT = initializeOutputArrays(numTimes, CONFIG)

    output_radials = CONFIG.num_azimuthal_points;
    OUTPUT = struct('Isotach_distance', zeros(numTimes, output_radials));

end


function OUTPUT = storeIsoResults(OUTPUT, i, distance)

    OUTPUT.Isolinedistance(i,:) = distance;
end

function storm = createIsoOutputStruct(OUTPUT, track, era5)

    storm = struct( ...
        'Time', track.time, ...
        'Isotach_distance', OUTPUT.isolinedistance);

    varnames = ["era5"];
    varunits = ["km"];
    storm.units = dictionary(varnames, varunits);
end

