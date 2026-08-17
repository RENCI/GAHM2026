function err = writeGAHM2026NetCdf(FileName,Reggrid_out, Reggrid_TC_out, output_info)
% writeGAHM2026NetCdf  Write GAHM2026 output to NetCDF.
%
% Write GAHM2026 (blended) wind velocity and pressure values on a grid in
% netCDF. This format is designed to be easily merged with parent large
% scale gridded met output (e.g., ERA5) for use with ADCIRC nws=13.
%
% FileName should not include an extension.  .nc is appended
% Reggrid_out and Reggrid_TC_out are data structures created by GAHM2026
%
%                     Rick Luettich 2/2/2026

    arguments
        FileName (1,1) string
        Reggrid_out (1,:) struct
        Reggrid_TC_out (1,:) struct
        output_info (1,1) struct
    end

err = 0;

% Determine pressure units (default: mb, no conversion)
if nargin >= 4 && isfield(output_info, 'pres_units') && strcmpi(output_info.pres_units, 'Pa')
    pres_scale = 100;
    pres_units = 'Pa';
else
    pres_scale = 1;
    pres_units = 'mb';
end

f_out = FileName + ".nc";
assert(~exist(f_out, 'file'), f_out + " already exists. Terminal.")

[yi,xi] = size(Reggrid_out(1).Lon);
nt = length(Reggrid_out);
time_data = zeros(1, nt);
lon_mat = zeros(nt, yi, xi);
lat_mat = zeros(nt, yi, xi);
PSFC_mat = zeros(nt, yi, xi);
U10_mat = zeros(nt, yi, xi);
V10_mat = zeros(nt, yi, xi);

timetemp=[Reggrid_out.datetime];
timetemp.Format="yyyy-MM-dd HH:mm:ss";

for i = 1:nt
    time_data(i) = minutes(timetemp(i) - timetemp(1));
    lon_mat(i,:,:) = Reggrid_out(i).Lon(:,:);
    lat_mat(i,:,:) = Reggrid_out(i).Lat(:,:);
    PSFC_mat(i,:,:) = pres_scale*Reggrid_TC_out(i).Press(:,:);
    U10_mat(i,:,:) = Reggrid_TC_out(i).VelU(:,:);
    V10_mat(i,:,:) = Reggrid_TC_out(i).VelV(:,:);
end
time_units = ['minutes since ',char(timetemp(1))];

% Create NETCDF4 file
ncid = netcdf.create(f_out, 'NETCDF4');

% Create an onCleanup object to ensure the file is closed even if error
cleanupObj = onCleanup(@() netcdf.close(ncid));

% Define dimensions
dim_time = netcdf.defDim(ncid, 'time', netcdf.getConstant('NC_UNLIMITED')); % unlimited
dim_yi = netcdf.defDim(ncid, 'yi', yi);
dim_xi = netcdf.defDim(ncid, 'xi', xi);

% Define variables (dimension order: time, yi, xi)  (yi,xi = row,col)
% time: integer
var_time = netcdf.defVar(ncid, 'time', 'NC_INT', dim_time);
netcdf.putAtt(ncid, var_time, 'axis', 'T');
netcdf.putAtt(ncid, var_time, 'units', time_units);
netcdf.putAtt(ncid, var_time, 'coordinates', 'time');
netcdf.putAtt(ncid, var_time, 'calendar', 'gregorian');

% lon: double(time, yi, xi)
var_lon = netcdf.defVar(ncid, 'lon', 'NC_DOUBLE', [dim_yi, dim_xi, dim_time]);
netcdf.putAtt(ncid, var_lon, '_FillValue', double(NaN));
netcdf.putAtt(ncid, var_lon, 'units', 'degrees_east');
netcdf.putAtt(ncid, var_lon, 'long_name', 'longitude');
netcdf.putAtt(ncid, var_lon, 'axis', 'X');
netcdf.putAtt(ncid, var_lon, 'coordinates', 'lon lat time');

% lat: double(time, yi, xi)
var_lat = netcdf.defVar(ncid, 'lat', 'NC_DOUBLE', [dim_yi, dim_xi, dim_time]);
netcdf.putAtt(ncid, var_lat, '_FillValue', double(NaN));
netcdf.putAtt(ncid, var_lat, 'units', 'degrees_north');
netcdf.putAtt(ncid, var_lat, 'long_name', 'latitude');
netcdf.putAtt(ncid, var_lat, 'axis', 'Y');
netcdf.putAtt(ncid, var_lat, 'coordinates', 'lon lat time');

% PSFC: float(time, yi, xi)
var_PSFC = netcdf.defVar(ncid, 'PSFC', 'NC_DOUBLE', [dim_yi, dim_xi, dim_time]);
netcdf.putAtt(ncid, var_PSFC, '_FillValue', double(NaN));
netcdf.putAtt(ncid, var_PSFC, 'units', pres_units);
netcdf.putAtt(ncid, var_PSFC, 'coordinates', 'lon lat time');

% U10: double(time, yi, xi)
var_U10 = netcdf.defVar(ncid, 'U10', 'NC_DOUBLE', [dim_yi, dim_xi, dim_time]);
netcdf.putAtt(ncid, var_U10, '_FillValue', double(NaN));
netcdf.putAtt(ncid, var_U10, 'units', 'm s-1');
netcdf.putAtt(ncid, var_U10, 'coordinates', 'lon lat time');

% V10: double(time, yi, xi)
var_V10 = netcdf.defVar(ncid, 'V10', 'NC_DOUBLE', [dim_yi, dim_xi, dim_time]);
netcdf.putAtt(ncid, var_V10, '_FillValue', double(NaN));
netcdf.putAtt(ncid, var_V10, 'units', 'm s-1');
netcdf.putAtt(ncid, var_V10, 'coordinates', 'lon lat time');

% Global attributes
netcdf.putAtt(ncid, netcdf.getConstant('NC_GLOBAL'), 'rank', '2');
source_info = [char(FileName),', BestTrack, GAHM2026'];
netcdf.putAtt(ncid, netcdf.getConstant('NC_GLOBAL'), 'source', source_info);

% End define mode
netcdf.endDef(ncid);

start = [0, 0, 0]; % start indices in each dim [xi, yi, time]
count = [yi, xi, nt]; % counts per dim

% Write time (1D, start and count along time)
netcdf.putVar(ncid, var_time, 0, nt, time_data);

% Permute arrays and write
netcdf.putVar(ncid, var_lon, start, count, permute(lon_mat, [2,3,1]));
netcdf.putVar(ncid, var_lat, start, count, permute(lat_mat, [2,3,1]));
netcdf.putVar(ncid, var_PSFC, start, count, permute(PSFC_mat, [2,3,1]));
netcdf.putVar(ncid, var_U10, start, count, permute(U10_mat, [2,3,1]));
netcdf.putVar(ncid, var_V10, start, count, permute(V10_mat, [2,3,1]));

% File is closed automatically by onCleanup when function exits

end
