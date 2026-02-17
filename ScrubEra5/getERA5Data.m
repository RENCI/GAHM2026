function era5 = getERA5Data(cfg,time)
% getERA5Data - extract time chunk from ERA5 netCDF files
%TODO: spatial subsetting

    file_info = ncinfo(cfg.nc_file);

    % get time variable name, could be time or valid_time
    if ismember('time',{file_info.Variables.Name})
        tvarname='time';
    elseif ismember('valid_time',{file_info.Variables.Name})
        tvarname='valid_time';
    else
        error('Time variable in netcdf file not recognized.')
    end
    
    era5.lon  = double(ncread(cfg.nc_file, 'longitude'));
    era5.lat  = double(ncread(cfg.nc_file, 'latitude'));
    era5.time = ncread(cfg.nc_file, tvarname);

    tunits_str = ncreadatt(cfg.nc_file, tvarname, 'units');
    parts = strsplit(strtrim(tunits_str));

    if numel(parts) < 3 || ~strcmpi(parts{2}, 'since')
        error('Unrecognized time units format: "%s". Expected "<unit> since <reference_time>".', tunits_str);
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
        error('Unsupported time unit "%s" in units string "%s".', unit_name, tunits_str);
    end
    fac = known_units({unit_name});

    epoch_str = strjoin(parts(3:end), ' ');
    epoch_str = strrep(epoch_str, 'T', ' ');
    epoch_str = regexprep(epoch_str, '[Zz]$', '');
    epoch_str = regexprep(epoch_str, '\s*[+-]\d{1,2}(:\d{2})?$', '');

    try
        epochstart = datetime(epoch_str);
    catch
        error('Failed to parse reference time "%s" from units string "%s".', epoch_str, tunits_str);
    end

    era5.time = datetime(double(era5.time) * fac, 'ConvertFrom', 'epochtime', 'Epoch', epochstart);

    if cfg.debug, fprintf('[DEBUG:ScrubEra5] getERA5Data: time units="%s", epoch=%s, conversion factor=%.4g s\n', tunits_str, string(epochstart), fac); end

    idx=(era5.time>=time(1) & era5.time<=time(end));
    if isempty(find(idx,1))
        error('Times not found in ERA5 netCDF file.')
    end

    ifirst=find(idx,1,'first');
    icount=size(find(idx),1);

    era5.u10  = ncread(cfg.nc_file, 'u10', [1 1 ifirst], [Inf Inf icount]);
    era5.v10  = ncread(cfg.nc_file, 'v10', [1 1 ifirst], [Inf Inf icount]);
    era5.msl  = ncread(cfg.nc_file, 'msl', [1 1 ifirst], [Inf Inf icount]);
    
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
