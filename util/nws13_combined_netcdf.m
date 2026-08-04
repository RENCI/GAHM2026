function nws13_combined_netcdf(era5_file, gahm_file, output_file, varargin)
% CREATE_COMBINED_NETCDF Creates a combined NetCDF file with ERA5 and GAHM2024 data in separate groups
%
% Syntax:
%   create_combined_netcdf(era5_file, gahm_file, output_file)
%   create_combined_netcdf(era5_file, gahm_file, output_file, 'Name', Value, ...)
%
% Inputs:
%   era5_file   - String, path to ERA5 NetCDF file
%   gahm_file   - String, path to GAHM2024 .mat file
%   output_file - String, path for output NetCDF file
%
% Optional Name-Value Pairs:
%   'Title'           - String, dataset title (default: auto-generated)
%   'Institution'     - String, institution name (default: 'RENCI')
%   'MainGroupName'   - String, name for ERA5 group (default: 'Main')
%   'GAHMGroupName'   - String, name for GAHM2024 group (default: 'Florence2018')
%   'ERA5VarNames'    - Struct with ERA5 variable names (default: standard names)
%   'GAHMVarNames'    - Struct with GAHM2024 variable names (default: standard names)
%
% Example:
%   create_combined_netcdf('era5_data.nc', 'gahm_data.mat', 'combined_output.nc');
%
%   create_combined_netcdf('era5_data.nc', 'gahm_data.mat', 'output.nc', ...
%                         'Title', 'Hurricane Data Analysis', ...
%                         'Institution', 'My University', ...
%                         'MainGroupName', 'ERA5_Data', ...
%                         'GAHMGroupName', 'Hurricane_Model');

    % Parse input arguments
    p = inputParser;
    addRequired(p, 'era5_file', @ischar);
    addRequired(p, 'gahm_file', @ischar);
    addRequired(p, 'output_file', @ischar);
    addParameter(p, 'Title', '', @ischar);
    addParameter(p, 'Institution', 'RENCI', @ischar);
    addParameter(p, 'MainGroupName', 'Main', @ischar);
    addParameter(p, 'GAHMGroupName', 'Florence2018', @ischar);
    addParameter(p, 'ERA5VarNames', struct(), @isstruct);
    addParameter(p, 'GAHMVarNames', struct(), @isstruct);
    
    parse(p, era5_file, gahm_file, output_file, varargin{:});
    
    % Extract parsed values
    title_str = p.Results.Title;
    institution = p.Results.Institution;
    main_group_name = p.Results.MainGroupName;
    gahm_group_name = p.Results.GAHMGroupName;
    era5_vars = p.Results.ERA5VarNames;
    gahm_vars = p.Results.GAHMVarNames;
    
    % Set default variable names if not provided
    if isempty(fieldnames(era5_vars))
        era5_vars = struct('lon', 'longitude', 'lat', 'latitude', 'time', 'valid_time', ...
                          'u10', 'u10', 'v10', 'v10', 'msl', 'msl');
    end
    
    if isempty(fieldnames(gahm_vars))
        gahm_vars = struct('fields_var', 'EVReggrid_out_times_1to3', ...
                          'grid_var', 'Reggrid_out_times_1to3');
    end
    
    % Generate default title if not provided
    if isempty(title_str)
        [~, era5_name, ~] = fileparts(era5_file);
        [~, gahm_name, ~] = fileparts(gahm_file);
        title_str = sprintf('Combined Dataset - %s and %s', era5_name, gahm_name);
    end
    
    try
        %% === Load ERA5 Data ===
        fprintf('Loading ERA5 data from: %s\n', era5_file);
        
        lon = ncread(era5_file, era5_vars.lon);
        lat = ncread(era5_file, era5_vars.lat);
        time = ncread(era5_file, era5_vars.time); % seconds since 1970-01-01
        time_era5 = int32(time / 60); % convert to minutes
        [LonGrid, LatGrid] = meshgrid(lon, lat);
        U_era5 = ncread(era5_file, era5_vars.u10);
        V_era5 = ncread(era5_file, era5_vars.v10);
        P_era5 = (ncread(era5_file, era5_vars.msl))/100;
        
        %% === Load GAHM Data ===
        fprintf('Loading GAHM data from: %s\n', gahm_file);
        
        data = load(gahm_file);
        
        % Dynamically find the fields variable
        field_names = fieldnames(data);
        fields_var_name = '';
        grid_var_name = '';
        
        for i = 1:length(field_names)
            if contains(field_names{i}, 'fields') || contains(field_names{i}, 'field')
                fields_var_name = field_names{i};
            elseif contains(field_names{i}, 'grid')
                grid_var_name = field_names{i};
            end
        end
        
        % Use specified names if available, otherwise use found names
        if isfield(gahm_vars, 'fields_var') && isfield(data, gahm_vars.fields_var)
            fields_data = data.(gahm_vars.fields_var);
        elseif ~isempty(fields_var_name)
            fields_data = data.(fields_var_name);
        else
            error('Could not find fields variable in GAHM file');
        end
        
        if isfield(gahm_vars, 'grid_var') && isfield(data, gahm_vars.grid_var)
            grid_data = data.(gahm_vars.grid_var);
        elseif ~isempty(grid_var_name)
            grid_data = data.(grid_var_name);
        else
            error('Could not find grid variable in GAHM file');
        end
        
        % Process GAHM data
        numele = length(fields_data);
        U_gahm = zeros(size(fields_data(1).VelU,1), size(fields_data(1).VelU,2), numele);
        V_gahm = U_gahm;
        P_gahm = U_gahm;
        Lon_gahm = U_gahm;
        Lat_gahm = U_gahm;
        T = NaT(1, numele);
        
        for i = 1:numele
            U_gahm(:,:,i) = fields_data(i).VelU;
            V_gahm(:,:,i) = fields_data(i).VelV;
            P_gahm(:,:,i) = fields_data(i).Press;
            Lon_gahm(:,:,i) = grid_data(i).Lon;
            Lat_gahm(:,:,i) = grid_data(i).Lat;
            T(i) = grid_data(i).datetime;
        end
        time_gahm = int32(convertTo(T, 'posixtime') / 60);
        
        %% === Create Combined NetCDF with Groups ===
        fprintf('Creating combined NetCDF file: %s\n', output_file);
        
        % Create global header file and groups using low-level functions
        ncid = netcdf.create(output_file, 'NETCDF4');
        
        % Add global attributes
        netcdf.putAtt(ncid, netcdf.getConstant('NC_GLOBAL'), 'title', title_str);
        netcdf.putAtt(ncid, netcdf.getConstant('NC_GLOBAL'), 'group_order', [main_group_name ' ' gahm_group_name]);
        netcdf.putAtt(ncid, netcdf.getConstant('NC_GLOBAL'), 'institution', institution);
        netcdf.putAtt(ncid, netcdf.getConstant('NC_GLOBAL'), 'source', 'ERA5 Reanalysis and GAHM2024 Vortex Model');
        netcdf.putAtt(ncid, netcdf.getConstant('NC_GLOBAL'), 'Rank 1 Source', 'ERA5');
        netcdf.putAtt(ncid, netcdf.getConstant('NC_GLOBAL'), 'history', ['Created on ' datestr(now)]);
        
        % Create groups
        main_grp_id = netcdf.defGrp(ncid, main_group_name);
        gahm_grp_id = netcdf.defGrp(ncid, gahm_group_name);
        
        % Add group attributes
        netcdf.putAtt(main_grp_id, netcdf.getConstant('NC_GLOBAL'), 'description', 'ERA5 Reanalysis Data');
        netcdf.putAtt(main_grp_id, netcdf.getConstant('NC_GLOBAL'), 'data_source', 'ECMWF ERA5 Reanalysis');
        netcdf.putAtt(gahm_grp_id, netcdf.getConstant('NC_GLOBAL'), 'description', 'GAHM2024 Vortex Model Data');
        netcdf.putAtt(gahm_grp_id, netcdf.getConstant('NC_GLOBAL'), 'data_source', 'Generalized Asymmetric Holland Model');
        
        netcdf.close(ncid);
        
        %% === Write ERA5 Group ===
        write_era5_group(output_file, main_group_name, time_era5, lon, lat, LonGrid, LatGrid, U_era5, V_era5, P_era5);
        
        %% === Write GAHM Group ===
        write_gahm_group(output_file, gahm_group_name, time_gahm, Lon_gahm, Lat_gahm, U_gahm, V_gahm, P_gahm);
        
        fprintf('NetCDF file created successfully: %s\n', output_file);
        
    catch ME
        fprintf('Error creating NetCDF file: %s\n', ME.message);
        rethrow(ME);
    end
end

function write_era5_group(output_file, group_name, time_era5, lon, lat, LonGrid, LatGrid, U_era5, V_era5, P_era5)
    % Write ERA5 data to the specified group
    
    ncid = netcdf.open(output_file, 'WRITE');
    main_grp_id = netcdf.inqNcid(ncid, group_name);
    
    % Define dimensions
    time_dim_id = netcdf.defDim(main_grp_id, 'time', length(time_era5));
    xi_dim_id = netcdf.defDim(main_grp_id, 'xi', length(lon));
    yi_dim_id = netcdf.defDim(main_grp_id, 'yi', length(lat));
    
    % Define coordinate variables
    time_var_id = netcdf.defVar(main_grp_id, 'time', 'NC_INT', time_dim_id);
    lon_var_id = netcdf.defVar(main_grp_id, 'lon', 'NC_DOUBLE', [xi_dim_id, yi_dim_id]);
    lat_var_id = netcdf.defVar(main_grp_id, 'lat', 'NC_DOUBLE', [xi_dim_id, yi_dim_id]);
    
    % Define data variables
    u10_var_id = netcdf.defVar(main_grp_id, 'U10', 'NC_DOUBLE', [xi_dim_id, yi_dim_id, time_dim_id]);
    v10_var_id = netcdf.defVar(main_grp_id, 'V10', 'NC_DOUBLE', [xi_dim_id, yi_dim_id, time_dim_id]);
    psfc_var_id = netcdf.defVar(main_grp_id, 'PSFC', 'NC_DOUBLE', [xi_dim_id, yi_dim_id, time_dim_id]);
    
    % Add variable attributes
    add_era5_attributes(main_grp_id, time_var_id, lon_var_id, lat_var_id, u10_var_id, v10_var_id, psfc_var_id);
    
    % End define mode
    netcdf.endDef(main_grp_id);
    
    % Write data
    netcdf.putVar(main_grp_id, time_var_id, time_era5);
    netcdf.putVar(main_grp_id, lon_var_id, LonGrid);
    netcdf.putVar(main_grp_id, lat_var_id, LatGrid);
    netcdf.putVar(main_grp_id, u10_var_id, U_era5);
    netcdf.putVar(main_grp_id, v10_var_id, V_era5);
    netcdf.putVar(main_grp_id, psfc_var_id, P_era5);
    
    netcdf.close(ncid);
end

function write_gahm_group(output_file, group_name, time_gahm, Lon_gahm, Lat_gahm, U_gahm, V_gahm, P_gahm)
    % Write GAHM data to the specified group
    
    ncid = netcdf.open(output_file, 'WRITE');
    gahm_grp_id = netcdf.inqNcid(ncid, group_name);
    
    % Define dimensions for GAHM group
    time_dim_id = netcdf.defDim(gahm_grp_id, 'time', length(time_gahm));
    xi_dim_id = netcdf.defDim(gahm_grp_id, 'xi', size(Lon_gahm,1));
    yi_dim_id = netcdf.defDim(gahm_grp_id, 'yi', size(Lon_gahm,2));
    
    % Define coordinate variables
    time_var_id = netcdf.defVar(gahm_grp_id, 'time', 'NC_INT', time_dim_id);
    lon_var_id = netcdf.defVar(gahm_grp_id, 'lon', 'NC_DOUBLE', [xi_dim_id, yi_dim_id, time_dim_id]);
    lat_var_id = netcdf.defVar(gahm_grp_id, 'lat', 'NC_DOUBLE', [xi_dim_id, yi_dim_id, time_dim_id]);
    
    % Define data variables
    u10_var_id = netcdf.defVar(gahm_grp_id, 'U10', 'NC_DOUBLE', [xi_dim_id, yi_dim_id, time_dim_id]);
    v10_var_id = netcdf.defVar(gahm_grp_id, 'V10', 'NC_DOUBLE', [xi_dim_id, yi_dim_id, time_dim_id]);
    psfc_var_id = netcdf.defVar(gahm_grp_id, 'PSFC', 'NC_DOUBLE', [xi_dim_id, yi_dim_id, time_dim_id]);
    
    % Add variable attributes
    add_gahm_attributes(gahm_grp_id, time_var_id, lon_var_id, lat_var_id, u10_var_id, v10_var_id, psfc_var_id);
    
    % End define mode
    netcdf.endDef(gahm_grp_id);
    
    % Write data
    netcdf.putVar(gahm_grp_id, time_var_id, time_gahm);
    netcdf.putVar(gahm_grp_id, lon_var_id, Lon_gahm);
    netcdf.putVar(gahm_grp_id, lat_var_id, Lat_gahm);
    netcdf.putVar(gahm_grp_id, u10_var_id, U_gahm);
    netcdf.putVar(gahm_grp_id, v10_var_id, V_gahm);
    netcdf.putVar(gahm_grp_id, psfc_var_id, P_gahm);
    
    netcdf.close(ncid);
end

function add_era5_attributes(grp_id, time_var_id, lon_var_id, lat_var_id, u10_var_id, v10_var_id, psfc_var_id)
    % Add attributes for ERA5 variables
    
    % Time attributes
    netcdf.putAtt(grp_id, time_var_id, 'standard_name', 'time');
    netcdf.putAtt(grp_id, time_var_id, 'long_name', 'Time');
    netcdf.putAtt(grp_id, time_var_id, 'units', 'minutes since 1970-01-01 00:00:00');
    netcdf.putAtt(grp_id, time_var_id, 'calendar', 'gregorian');
    netcdf.putAtt(grp_id, time_var_id, 'axis', 'T');
    
    % Longitude attributes
    netcdf.putAtt(grp_id, lon_var_id, 'standard_name', 'longitude');
    netcdf.putAtt(grp_id, lon_var_id, 'long_name', 'Longitude');
    netcdf.putAtt(grp_id, lon_var_id, 'units', 'degrees_east');
    netcdf.putAtt(grp_id, lon_var_id, 'axis', 'X');
    netcdf.putAtt(grp_id, lon_var_id, 'valid_min', -180.0);
    netcdf.putAtt(grp_id, lon_var_id, 'valid_max', 180.0);
    
    % Latitude attributes
    netcdf.putAtt(grp_id, lat_var_id, 'standard_name', 'latitude');
    netcdf.putAtt(grp_id, lat_var_id, 'long_name', 'Latitude');
    netcdf.putAtt(grp_id, lat_var_id, 'units', 'degrees_north');
    netcdf.putAtt(grp_id, lat_var_id, 'axis', 'Y');
    netcdf.putAtt(grp_id, lat_var_id, 'valid_min', -90.0);
    netcdf.putAtt(grp_id, lat_var_id, 'valid_max', 90.0);
    
    % U10 Wind Component attributes
    netcdf.putAtt(grp_id, u10_var_id, 'standard_name', 'eastward_wind');
    netcdf.putAtt(grp_id, u10_var_id, 'long_name', '10 metre U wind component');
    netcdf.putAtt(grp_id, u10_var_id, 'units', 'm s-1');
    netcdf.putAtt(grp_id, u10_var_id, 'coordinates', 'lon lat time');
    netcdf.putAtt(grp_id, u10_var_id, '_FillValue', -9999.0);
    netcdf.putAtt(grp_id, u10_var_id, 'source', 'ERA5 Reanalysis');
    
    % V10 Wind Component attributes
    netcdf.putAtt(grp_id, v10_var_id, 'standard_name', 'northward_wind');
    netcdf.putAtt(grp_id, v10_var_id, 'long_name', '10 metre V wind component');
    netcdf.putAtt(grp_id, v10_var_id, 'units', 'm s-1');
    netcdf.putAtt(grp_id, v10_var_id, 'coordinates', 'lon lat time');
    netcdf.putAtt(grp_id, v10_var_id, '_FillValue', -9999.0);
    netcdf.putAtt(grp_id, v10_var_id, 'source', 'ERA5 Reanalysis');
    
    % Surface Pressure attributes
    netcdf.putAtt(grp_id, psfc_var_id, 'standard_name', 'pressure_at_sea_level');
    netcdf.putAtt(grp_id, psfc_var_id, 'long_name', 'Mean sea level pressure');
    netcdf.putAtt(grp_id, psfc_var_id, 'units', 'hPa (mb)');
    netcdf.putAtt(grp_id, psfc_var_id, 'coordinates', 'lon lat time');
    netcdf.putAtt(grp_id, psfc_var_id, '_FillValue', -9999.0);
    netcdf.putAtt(grp_id, psfc_var_id, 'source', 'ERA5 Reanalysis');
end

function add_gahm_attributes(grp_id, time_var_id, lon_var_id, lat_var_id, u10_var_id, v10_var_id, psfc_var_id)
    % Add attributes for GAHM variables
    
    % Time attributes
    netcdf.putAtt(grp_id, time_var_id, 'standard_name', 'time');
    netcdf.putAtt(grp_id, time_var_id, 'long_name', 'Time');
    netcdf.putAtt(grp_id, time_var_id, 'units', 'minutes since 1970-01-01 00:00:00');
    netcdf.putAtt(grp_id, time_var_id, 'calendar', 'gregorian');
    netcdf.putAtt(grp_id, time_var_id, 'axis', 'T');
    
    % Longitude attributes (time-varying)
    netcdf.putAtt(grp_id, lon_var_id, 'standard_name', 'longitude');
    netcdf.putAtt(grp_id, lon_var_id, 'long_name', 'Longitude (moving grid)');
    netcdf.putAtt(grp_id, lon_var_id, 'units', 'degrees_east');
    netcdf.putAtt(grp_id, lon_var_id, 'valid_min', -180.0);
    netcdf.putAtt(grp_id, lon_var_id, 'valid_max', 180.0);
    netcdf.putAtt(grp_id, lon_var_id, 'description', 'Longitude coordinates on hurricane-following moving grid');
    
    % Latitude attributes (time-varying)
    netcdf.putAtt(grp_id, lat_var_id, 'standard_name', 'latitude');
    netcdf.putAtt(grp_id, lat_var_id, 'long_name', 'Latitude (moving grid)');
    netcdf.putAtt(grp_id, lat_var_id, 'units', 'degrees_north');
    netcdf.putAtt(grp_id, lat_var_id, 'valid_min', -90.0);
    netcdf.putAtt(grp_id, lat_var_id, 'valid_max', 90.0);
    netcdf.putAtt(grp_id, lat_var_id, 'description', 'Latitude coordinates on hurricane-following moving grid');
    
    % U10 Wind Component attributes (GAHM)
    netcdf.putAtt(grp_id, u10_var_id, 'standard_name', 'eastward_wind');
    netcdf.putAtt(grp_id, u10_var_id, 'long_name', '10 metre U wind component (GAHM)');
    netcdf.putAtt(grp_id, u10_var_id, 'units', 'm s-1');
    netcdf.putAtt(grp_id, u10_var_id, 'coordinates', 'lon lat time');
    netcdf.putAtt(grp_id, u10_var_id, '_FillValue', -9999.0);
    
    % V10 Wind Component attributes (GAHM)
    netcdf.putAtt(grp_id, v10_var_id, 'standard_name', 'northward_wind');
    netcdf.putAtt(grp_id, v10_var_id, 'long_name', '10 metre V wind component (GAHM)');
    netcdf.putAtt(grp_id, v10_var_id, 'units', 'm s-1');
    netcdf.putAtt(grp_id, v10_var_id, 'coordinates', 'lon lat time');
    netcdf.putAtt(grp_id, v10_var_id, '_FillValue', -9999.0);
    
    % Surface Pressure attributes (GAHM)
    netcdf.putAtt(grp_id, psfc_var_id, 'standard_name', 'pressure_at_sea_level');
    netcdf.putAtt(grp_id, psfc_var_id, 'long_name', 'Mean sea level pressure (GAHM)');
    netcdf.putAtt(grp_id, psfc_var_id, 'units', 'hPa (mb)');
    netcdf.putAtt(grp_id, psfc_var_id, 'coordinates', 'lon lat time');
    netcdf.putAtt(grp_id, psfc_var_id, '_FillValue', -9999.0);
end