function nws13_combine_ranks(output_file, main_file, main_group, main_source, varargin)
% NWS13_COMBINE_RANKS Combine netCDF files into a single grouped NetCDF4 file.
%
%   nws13_combine_ranks(OUTPUT, MAIN_FILE, MAIN_GROUP, MAIN_SOURCE, ...)
%
%   Each input dataset becomes a named group in the output file, with a rank
%   attribute indicating priority (1 = large-scale background, 2+ = nests).
%
%   Required arguments:
%     OUTPUT      - output NetCDF4 file path
%     MAIN_FILE   - path to the main (rank 1) netCDF file
%     MAIN_GROUP  - group name for main dataset (e.g. 'Main')
%     MAIN_SOURCE - source description for main dataset (e.g. 'ERA5')
%
%   Name-value options:
%     'nests'           - cell array of cell arrays, each: {file, group, source}
%                         or {file, group, source, time_filter}
%                         Ranks are assigned in order (2, 3, ...).
%     'epoch'           - reference epoch date string (default: '1970-01-01')
%     'institution'     - institution global attribute (default: 'RENCI')
%     'pressure_units'  - output PSFC units: 'mb' (default, converts Pa to
%                         millibars) or 'Pa' (no conversion)
%     'deflate_level'   - zlib deflate compression level (0-9) applied to
%                         all variables (default: 5; 0 disables compression)
%
%   All text arguments above (including file/group/source/time_filter
%   entries inside 'nests') accept either a char vector ('...') or a
%   scalar string ("...").
%
%   Examples:
%     % Main only:
%     nws13_combine_ranks('output.nc', 'era5.nc', 'Main', 'ERA5')
%
%     % Main + one nest:
%     nws13_combine_ranks('output.nc', 'era5.nc', 'Main', 'ERA5', ...
%         'nests', {{'storm.nc', 'Carla1961', 'GAHM2026'}}, ...
%         'epoch', '1950-01-01')
%
%     % Main + multiple nests with time filter:
%     nws13_combine_ranks('output.nc', 'era5.nc', 'Main', 'ERA5', ...
%         'nests', {{'storm1.nc', 'Florence2018', 'GAHM', '2018-09-05'}, ...
%                   {'storm2.nc', 'Michael2018', 'GAHM'}}, ...
%         'epoch', '1970-01-01')
%
%     % Keep PSFC in Pa instead of converting to mb:
%     nws13_combine_ranks('output.nc', 'era5.nc', 'Main', 'ERA5', ...
%         'pressure_units', 'Pa')
%
%     % Disable deflate compression:
%     nws13_combine_ranks('output.nc', 'era5.nc', 'Main', 'ERA5', ...
%         'deflate_level', 0)

    % --- Parse inputs ---
    p = inputParser;
    addRequired(p, 'output_file', @isTextScalar);
    addRequired(p, 'main_file', @isTextScalar);
    addRequired(p, 'main_group', @isTextScalar);
    addRequired(p, 'main_source', @isTextScalar);
    addParameter(p, 'nests', {}, @iscell);
    addParameter(p, 'epoch', '1970-01-01', @isTextScalar);
    addParameter(p, 'institution', 'RENCI', @isTextScalar);
    addParameter(p, 'pressure_units', 'mb', @(x) isTextScalar(x) && any(strcmp(x, {'mb', 'Pa'})));
    addParameter(p, 'deflate_level', 5, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 9 && x == round(x));
    parse(p, output_file, main_file, main_group, main_source, varargin{:});

    opts = p.Results;

    % Normalize to char throughout -- callers may pass string scalars
    % ("...") interchangeably with char vectors ('...') for any text
    % argument; the low-level netcdf.* API used below is not consistently
    % string-aware, so everything downstream operates on plain char.
    opts.output_file     = char(opts.output_file);
    opts.main_file       = char(opts.main_file);
    opts.main_group      = char(opts.main_group);
    opts.main_source     = char(opts.main_source);
    opts.epoch           = char(opts.epoch);
    opts.institution     = char(opts.institution);
    opts.pressure_units  = char(opts.pressure_units);

    % --- Load datasets ---
    fprintf('Loading main dataset...\n');
    main_ds = load_and_prepare(opts.main_file, 1, opts.main_source, opts.epoch, '', ...
                                opts.pressure_units);

    group_names = {opts.main_group};
    datasets = {main_ds};

    for i = 1:length(opts.nests)
        nest = opts.nests{i};
        fprintf('Loading nest %d...\n', i);
        nest_file   = char(nest{1});
        nest_group  = char(nest{2});
        nest_source = char(nest{3});
        if length(nest) >= 4
            time_filter = char(nest{4});
        else
            time_filter = '';
        end
        ds = load_and_prepare(nest_file, i + 1, nest_source, opts.epoch, time_filter, ...
                               opts.pressure_units);
        datasets{end+1} = ds; %#ok<AGROW>
        group_names{end+1} = nest_group; %#ok<AGROW>
    end

    % --- Create output file ---
    group_order = strjoin(group_names, ' ');
    fprintf('\nWriting %s\n', opts.output_file);
    fprintf('  Groups: %s\n', group_order);

    ncid = netcdf.create(opts.output_file, 'NETCDF4');
    outputFileCleanup = onCleanup(@() netcdf.close(ncid));
    NC_GLOBAL    = netcdf.getConstant('NC_GLOBAL');
    NC_UNLIMITED = netcdf.getConstant('NC_UNLIMITED');

    % Global attributes
    netcdf.putAtt(ncid, NC_GLOBAL, 'group_order', group_order);
    netcdf.putAtt(ncid, NC_GLOBAL, 'institution', opts.institution);

    % --- Define all groups (define mode) ---
    num_groups = length(datasets);
    gids    = zeros(1, num_groups);
    var_ids = cell(1, num_groups);   % each element is a containers.Map

    for g = 1:num_groups
        ds  = datasets{g};
        gid = netcdf.defGrp(ncid, group_names{g});
        gids(g) = gid;

        % Define dimensions
        dim_id_map = containers.Map();
        for d = 1:length(ds.dim_names)
            dname = ds.dim_names{d};
            dlen  = ds.dim_lengths(d);
            if strcmp(dname, ds.unlimited_dim)
                dlen = NC_UNLIMITED;
            end
            did = netcdf.defDim(gid, dname, dlen);
            dim_id_map(dname) = did;
        end

        % Define variables, set fill values and attributes
        vids = containers.Map();
        for v = 1:length(ds.var_names)
            vn = ds.var_names{v};
            vs = ds.vars.(vn);

            % Map dimension names to IDs (netCDF order)
            dim_ids = cellfun(@(d) dim_id_map(d), vs.nc_dims);

            vid = netcdf.defVar(gid, vn, vs.nc_type, dim_ids);
            vids(vn) = vid;

            % Deflate compression (skip scalar variables, which have no dims)
            if ~isempty(dim_ids)
                netcdf.defVarDeflate(gid, vid, false, opts.deflate_level > 0, opts.deflate_level);
            end

            % Set fill value
            if isempty(vs.fill_value)
                netcdf.defVarFill(gid, vid, true, 0);   % no fill
            else
                fv = cast_fill_value(vs.fill_value, vs.nc_type);
                netcdf.defVarFill(gid, vid, false, fv);
            end

            % Variable attributes
            for a = 1:size(vs.attrs, 1)
                netcdf.putAtt(gid, vid, vs.attrs{a,1}, vs.attrs{a,2});
            end
        end

        % Group attributes
        netcdf.putAtt(gid, NC_GLOBAL, 'rank', ds.rank);
        netcdf.putAtt(gid, NC_GLOBAL, 'source', ds.source);

        var_ids{g} = vids;
    end

    netcdf.endDef(ncid);

    % --- Write data ---
    for g = 1:num_groups
        ds   = datasets{g};
        gid  = gids(g);
        vids = var_ids{g};

        for v = 1:length(ds.var_names)
            vn  = ds.var_names{v};
            vs  = ds.vars.(vn);
            vid = vids(vn);

            % netcdf.putVar's 2-arg "write whole variable" form is not
            % supported for variables with an unlimited dimension, so
            % always supply an explicit START/COUNT hyperslab covering
            % the full variable.
            ndims_v = length(vs.nc_dims);
            start = zeros(1, ndims_v);
            count = arrayfun(@(k) size(vs.data, k), 1:ndims_v);
            netcdf.putVar(gid, vid, start, count, vs.data);
        end

        fprintf('  Wrote group ''%s''\n', group_names{g});
    end

    fprintf('Done.\n');
end


% =========================================================================
%  LOCAL FUNCTIONS
% =========================================================================

function ds = load_and_prepare(filepath, rank, source, epoch, time_filter, pressure_units)
% LOAD_AND_PREPARE  Read a netCDF file, rename variables, convert time.
%
%   pressure_units - output PSFC units: 'mb' (converts Pa to millibars)
%                    or 'Pa' (no conversion)
%
%   Returns a struct with fields:
%     dim_names, dim_lengths, unlimited_dim  - dimension info
%     var_names                              - ordered list of output variable names
%     vars.(name).data                       - data array (MATLAB order)
%     vars.(name).nc_dims                    - dimension names (netCDF order)
%     vars.(name).nc_type                    - netCDF type string
%     vars.(name).attrs                      - Nx2 cell of {name, value}
%     vars.(name).fill_value                 - fill value (or [])
%     rank, source                           - group attributes

    info = ncinfo(filepath);

    % Variable rename map (lowercase input -> canonical output)
    rename_keys = {'msl', 'u10', 'v10', 'latitude', 'longitude'};
    rename_vals = {'PSFC', 'U10', 'V10', 'yi', 'xi'};
    rename_map  = containers.Map(rename_keys, rename_vals);

    % --- Parse dimensions (rename to match variable rename map) ---
    ds.dim_names    = {};
    ds.dim_lengths  = [];
    ds.unlimited_dim = '';
    for d = 1:length(info.Dimensions)
        dim = info.Dimensions(d);
        dname = dim.Name;
        if rename_map.isKey(lower(dname))
            dname = rename_map(lower(dname));
        end
        ds.dim_names{end+1}   = dname;
        ds.dim_lengths(end+1) = dim.Length;
        if dim.Unlimited
            ds.unlimited_dim = dname;
        end
    end

    % --- Parse time epoch for conversion ---
    time_idx = find(strcmp({info.Variables.Name}, 'time'), 1);
    time_var_info = info.Variables(time_idx);
    units_idx = find(strcmp({time_var_info.Attributes.Name}, 'units'), 1);
    input_time_units = time_var_info.Attributes(units_idx).Value;
    tokens = regexp(input_time_units, 'minutes since (.+)', 'tokens');
    input_epoch_str = strtrim(tokens{1}{1});
    input_epoch_dn  = datenum(input_epoch_str);  %#ok<DATNM>
    output_epoch_dn = datenum(epoch);             %#ok<DATNM>
    offset_minutes  = round((input_epoch_dn - output_epoch_dn) * 24 * 60);

    output_time_units = sprintf('minutes since %s 00:00:00', epoch);

    % --- Read and filter time ---
    raw_time = int32(ncread(filepath, 'time'));
    if ~isempty(time_filter)
        filter_dn  = datenum(time_filter);  %#ok<DATNM>
        filter_min = round((filter_dn - input_epoch_dn) * 24 * 60);
        keep = raw_time >= int32(filter_min);
    else
        keep = true(size(raw_time));
    end
    raw_time = raw_time(keep);
    new_time = int32(double(raw_time) + offset_minutes);

    % Update time dimension length if filtered
    if any(~keep)
        tdim_idx = strcmp(ds.dim_names, 'time');
        ds.dim_lengths(tdim_idx) = length(new_time);
    end

    % --- Read all variables ---
    ds.vars      = struct();
    ds.var_names = {};

    for v = 1:length(info.Variables)
        var = info.Variables(v);
        orig_name = var.Name;

        % Determine output name
        if rename_map.isKey(lower(orig_name))
            out_name = rename_map(lower(orig_name));
            if ~strcmp(orig_name, out_name)
                fprintf('  Renamed: %s -> %s\n', orig_name, out_name);
            end
        else
            out_name = orig_name;
        end

        % Read data
        if strcmp(orig_name, 'time')
            data = new_time;
        else
            data = ncread(filepath, orig_name);
            % Filter along time dimension if needed
            if any(~keep)
                time_pos = find(strcmp({var.Dimensions.Name}, 'time'));
                if ~isempty(time_pos)
                    ndim = length(var.Dimensions);
                    idx = repmat({':'}, 1, ndim);
                    idx{time_pos} = keep;
                    data = data(idx{:});
                end
            end
        end

        % Determine output netCDF type and cast data
        if strcmp(orig_name, 'time')
            nc_type = 'NC_INT';
        elseif any(strcmp(out_name, {'PSFC', 'U10', 'V10'}))
            nc_type = 'NC_DOUBLE';
            data = double(data);
            if strcmp(out_name, 'PSFC') && strcmp(pressure_units, 'mb')
                data = data / 100.0;
                fprintf('  Converted PSFC from Pa to mb\n');
            end
        else
            nc_type = matlab_to_nc_type(var.Datatype);
        end

        % Collect attributes (skip _FillValue — handled via defVarFill)
        attr_names  = {};
        attr_values = {};
        for a = 1:length(var.Attributes)
            att = var.Attributes(a);
            if strcmp(att.Name, '_FillValue')
                continue;
            end
            attr_names{end+1}  = att.Name;  %#ok<AGROW>
            attr_values{end+1} = att.Value; %#ok<AGROW>
        end
        attrs = [attr_names(:), attr_values(:)];   % Nx2 cell
        if isempty(attrs)
            attrs = cell(0, 2);
        end

        % Override time attributes entirely
        if strcmp(orig_name, 'time')
            attrs = {'axis',        'T'; ...
                     'coordinates',  'time'; ...
                     'units',        output_time_units; ...
                     'long_name',    'time'; ...
                     'calendar',     'gregorian'};
        end

        % Ensure canonical variables have long_name (add if missing)
        default_long_names = containers.Map( ...
            {'PSFC', 'U10', 'V10'}, ...
            {'Surface Pressure', '10 metre U wind component', '10 metre V wind component'});
        if default_long_names.isKey(out_name)
            has_long_name = any(strcmp(attrs(:,1), 'long_name'));
            if ~has_long_name
                attrs = [attrs; {'long_name', default_long_names(out_name)}]; %#ok<AGROW>
            end
        end

        % Set PSFC units attribute to match pressure_units
        if strcmp(out_name, 'PSFC')
            units_idx2 = find(strcmp(attrs(:,1), 'units'), 1);
            if isempty(units_idx2)
                attrs = [attrs; {'units', pressure_units}]; %#ok<AGROW>
            else
                attrs{units_idx2, 2} = pressure_units;
            end
        end

        % Fill value
        if strcmp(orig_name, 'time')
            fill_value = [];
        else
            fill_value = var.FillValue;
        end

        % Dimension names in netCDF order (apply rename map)
        var_dims = {var.Dimensions.Name};
        for dd = 1:length(var_dims)
            if rename_map.isKey(lower(var_dims{dd}))
                var_dims{dd} = rename_map(lower(var_dims{dd}));
            end
        end

        % Store variable
        vs = struct();
        vs.data       = data;
        vs.nc_dims    = var_dims;
        vs.nc_type    = nc_type;
        vs.attrs      = attrs;
        vs.fill_value = fill_value;

        ds.vars.(out_name) = vs;
        ds.var_names{end+1} = out_name;
    end

    % --- Expand 1D yi/xi to 2D lat/lon meshgrid if needed ---
    if isfield(ds.vars, 'yi') && isfield(ds.vars, 'xi') && ...
       ndims(ds.vars.yi.data) <= 2 && min(size(ds.vars.yi.data)) == 1
        lat_1d = double(ds.vars.yi.data(:));
        lon_1d = double(ds.vars.xi.data(:));
        [lon_2d, lat_2d] = meshgrid(lon_1d, lat_1d);

        % Remove the 1D yi/xi variables and add 2D lat/lon
        ds.vars = rmfield(ds.vars, {'yi', 'xi'});
        ds.var_names = ds.var_names(~ismember(ds.var_names, {'yi', 'xi'}));

        % MATLAB's low-level netcdf.defVar takes dimids in the reverse
        % of the order netCDF/ncdump displays them (this is why nc_dims
        % elsewhere in this file, taken straight from ncinfo, round-trips
        % correctly). So nc_dims here must be listed as {'xi','yi'}, with
        % the data transposed to match, for lat/lon to end up declared as
        % (yi,xi) in the file -- the same spatial order as
        % PSFC/U10/V10(time,yi,xi) -- so downstream readers (nctoolbox,
        % xarray, etc.) see lat/lon aligned with the data fields.
        lat_2d = lat_2d.';
        lon_2d = lon_2d.';

        % Add lat as 2D variable, declared (yi, xi) in the file
        vs_lat = struct();
        vs_lat.data       = lat_2d;
        vs_lat.nc_dims    = {'xi', 'yi'};
        vs_lat.nc_type    = 'NC_DOUBLE';
        vs_lat.attrs      = {'units', 'degrees_north'; 'long_name', 'latitude'};
        vs_lat.fill_value = NaN;
        ds.vars.lat = vs_lat;
        ds.var_names{end+1} = 'lat';

        % Add lon as 2D variable, declared (yi, xi) in the file
        vs_lon = struct();
        vs_lon.data       = lon_2d;
        vs_lon.nc_dims    = {'xi', 'yi'};
        vs_lon.nc_type    = 'NC_DOUBLE';
        vs_lon.attrs      = {'units', 'degrees_east'; 'long_name', 'longitude'};
        vs_lon.fill_value = NaN;
        ds.vars.lon = vs_lon;
        ds.var_names{end+1} = 'lon';

        fprintf('  Expanded lat/lon to 2D: [%d x %d]\n', length(lat_1d), length(lon_1d));
    end

    ds.rank   = num2str(rank);
    ds.source = source;

    fprintf('  Loaded %s -> group rank=%d, %d time steps\n', ...
            filepath, rank, length(new_time));
end


function nc_type = matlab_to_nc_type(matlab_type)
% MATLAB_TO_NC_TYPE  Map MATLAB datatype string to netCDF type constant name.
    switch matlab_type
        case 'double',  nc_type = 'NC_DOUBLE';
        case 'single',  nc_type = 'NC_FLOAT';
        case 'int32',   nc_type = 'NC_INT';
        case 'int16',   nc_type = 'NC_SHORT';
        case 'int8',    nc_type = 'NC_BYTE';
        case 'uint8',   nc_type = 'NC_UBYTE';
        case 'int64',   nc_type = 'NC_INT64';
        case 'uint64',  nc_type = 'NC_UINT64';
        case 'char',    nc_type = 'NC_CHAR';
        otherwise,      nc_type = 'NC_DOUBLE';
    end
end


function fv = cast_fill_value(fill_value, nc_type)
% CAST_FILL_VALUE  Cast fill value to match the variable's netCDF type.
    switch nc_type
        case 'NC_DOUBLE', fv = double(fill_value);
        case 'NC_FLOAT',  fv = single(fill_value);
        case 'NC_INT',    fv = int32(fill_value);
        case 'NC_SHORT',  fv = int16(fill_value);
        case 'NC_BYTE',   fv = int8(fill_value);
        case 'NC_INT64',  fv = int64(fill_value);
        otherwise,        fv = fill_value;
    end
end


function tf = isTextScalar(x)
% ISTEXTSCALAR  True for a char row vector or a scalar string.
    tf = ischar(x) || (isstring(x) && isscalar(x));
end
