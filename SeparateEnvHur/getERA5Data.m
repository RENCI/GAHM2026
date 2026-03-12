function era5 = getERA5Data(CONFIG,time)
% getERA5Data - extract time chunk from ERA5 netCDF files
%TODO: spatial subsetting

    bg_file = strrep(CONFIG.background_file, '<year>', num2str(CONFIG.storm_year));
    if startsWith(bg_file, 'http')
        check_url([bg_file '.html']);
    elseif ~exist(bg_file, 'file')
        logMsg(-1, 'ERROR', 'ERA5 file not found: %s', bg_file);
    end

    file_info = ncinfo(bg_file);

    % get time variable name, could be time or valid_time
    if ismember('time',{file_info.Variables.Name})
        tvarname='time';
    elseif ismember('valid_time',{file_info.Variables.Name})
        tvarname='valid_time';
    else
        logMsg(-1, 'ERROR', 'Time variable in netcdf file not recognized.');
    end
    
    era5.lon  = double(ncread(bg_file, 'longitude'));
    era5.lat  = double(ncread(bg_file, 'latitude'));
    era5.time = ncread(bg_file, tvarname);

    % Detect longitude convention from the ERA5 grid
    if min(era5.lon) < 0
        era5.lon_convention = '-180_180';
    else
        era5.lon_convention = '0_360';
    end
    logMsg(-1, 'INFO', 'ERA5 longitude convention detected: %s (range %.1f to %.1f)', ...
        era5.lon_convention, min(era5.lon), max(era5.lon));

    tunits_str = ncreadatt(bg_file, tvarname, 'units');
    parts = strsplit(strtrim(tunits_str));

    if numel(parts) < 3 || ~strcmpi(parts{2}, 'since')
        logMsg(-1, 'ERROR', sprintf('Unrecognized time units format: "%s". Expected "<unit> since <reference_time>".', tunits_str));
    end

    unit_name = lower(parts{1});
    known_units = dictionary( ...
        {'milliseconds','millisecond','ms'}, [0.001 0.001 0.001], ...
        {'seconds','second','sec','s'},      [1 1 1 1], ...
        {'minutes','minute','min'},          [60 60 60], ...
        {'hours','hour','hr','h'},           [3600 3600 3600 3600], ...
        {'days','day','d'},                  [86400 86400 86400] ...
    );
    if ~isKey(known_units, {unit_name})
        logMsg(-1, 'ERROR', sprintf('Unsupported time unit "%s" in units string "%s".', unit_name, tunits_str));
    end
    fac = known_units({unit_name});

    epoch_str = strjoin(parts(3:end), ' ');
    epoch_str = strrep(epoch_str, 'T', ' ');
    epoch_str = regexprep(epoch_str, '[Zz]$', '');
    if contains(epoch_str, ':')
        epoch_str = regexprep(epoch_str, '\s*[+-]\d{1,2}(:\d{2})?$', '');
    end

    try
        epochstart = datetime(epoch_str);
    catch
        logMsg(-1, 'ERROR', sprintf('Failed to parse reference time "%s" from units string "%s".', epoch_str, tunits_str));
    end

    era5.time = datetime(double(era5.time) * fac, 'ConvertFrom', 'epochtime', 'Epoch', epochstart);

    if CONFIG.debug, logMsg(-1, 'DEBUG', 'time units="%s", epoch=%s, conversion factor=%.4g s', tunits_str, string(epochstart), fac); end

    idx=(era5.time>=time(1) & era5.time<=time(end));
    if isempty(find(idx,1))
        logMsg(-1, 'ERROR', 'Track times not found in ERA5 netCDF file.');
    end

    ifirst=find(idx,1,'first');
    icount=nnz(idx);

    era5.u10  = ncread(bg_file, 'u10', [1 1 ifirst], [Inf Inf icount]);
    era5.v10  = ncread(bg_file, 'v10', [1 1 ifirst], [Inf Inf icount]);
    era5.msl  = ncread(bg_file, 'msl', [1 1 ifirst], [Inf Inf icount]);
    
    % TODO: check if empty overlap
    % for f = fields(era5)'
    %     s=sprintf()
    % end
    % era5.msl=era5.msl(:,:,idx);
    % era5.u10=era5.u10(:,:,idx);
    % era5.v10=era5.v10(:,:,idx);
    % era5.time = era5.time(idx);

    [era5.lon_grid, era5.lat_grid] = meshgrid(era5.lon, era5.lat);
    era5.time=era5.time(idx);
    
end
