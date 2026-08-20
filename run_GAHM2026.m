function Result = run_GAHM2026(config_name)
%--------------------------------------------------------------------------
% Function to execute GAHM2026.m
%
% Usage:
%     run_GAHM2026              — uses default config/config_GAHM2026_default.m
%     run_GAHM2026('myconfig')  — uses config/myconfig.m
%
%% See documentation/README.md for full configuration reference.
%
%                        2/3/2026  Rick Luettich
%                        2/16/2026 Brian Blanton

arguments
    config_name (1,1) string = "config_GAHM2026_default"
end

addpath('util')
addpath('static')
addpath('PlotEvalScripts')
addpath('SeparateEnvHur')

if ~exist('input', 'dir'),  mkdir('input');  end
if ~exist('output', 'dir'), mkdir('output'); end

datetime.setDefaultFormats('default','yyyy-MM-dd hh:mm:ss')
datetime.setDefaultFormats('defaultdate','yyyy-MM-dd hh:mm:ss')

%% Load configuration parameters
config_file = fullfile('config', config_name);
assert(exist(config_file+".m", 'file') ~= 0, "Config file not found: %s.m", config_file);
run(config_file)

if ~exist('debug', 'var'), debug = false; end
fid = fopen(output_info.diagnostics, 'wt');
cleanupFid = onCleanup(@() fclose(fid));
logMsg(fid, "INFO", "Configuration loaded from %s", config_file);
logMsg(fid, "INFO", "Storm: %s/%s/%s, env_type=%d", storm_info.name, storm_info.year, storm_info.designation, env_info.type);

%% Validate storm_year vs storm_start/storm_end
sy = str2double(storm_info.year);
if isdatetime(storm_info.starttime) && year(storm_info.starttime) ~= sy
    logMsg(fid, "ERROR", "storm_year (%d) does not match year of storm_start (%d)", sy, year(storm_info.starttime));
end
if isdatetime(storm_info.endtime) && year(storm_info.endtime) ~= sy
    logMsg(fid, "WARNING", "storm_year (%d) does not match year of storm_end (%d) — storm may span year boundary", sy, year(storm_info.endtime));
end

%% Download IBTrACS file if it does not exist
if storm_info.file_type == "IBTrACS" && ~exist(storm_info.track_file, 'file')
    ibtracs_url = ['https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/csv/' ...
                   erase(storm_info.track_file, 'input/')];
    logMsg(fid, "INFO", "IBTrACS file not found: %s", storm_info.track_file);
    logMsg(fid, "INFO", "Downloading from %s ...", ibtracs_url);
    try
        websave(storm_info.track_file, ibtracs_url);
        logMsg(fid, "INFO", "Download complete.");
    catch ME
        error("Failed to download IBTrACS file: %s", ME.message);
    end
end

%% Load storm track data
logMsg(fid, "INFO", "Loading %s %s %s ... ", storm_info.designation, storm_info.year, storm_info.name);
if storm_info.file_type == "ATCF" || storm_info.file_type == "fort22"
    ATCF_data_in = readATCFfort22(storm_info.track_file, storm_info.file_type);
elseif storm_info.file_type == "IBTrACS"
    ATCF_data_in = readIBTrACS(storm_info);
end
if ATCF_data_in(1).sname_cha == storm_info.name
    logMsg(fid, "INFO", "%s %s %s found in track file", storm_info.designation, storm_info.year, storm_info.name);
else
    logMsg(fid, "ERROR", "Mismatch in storm_name. %s/%s/%s in config file, but %s does not match.", ...
        storm_info.designation, storm_info.year, storm_info.name, ATCF_data_in(1).sname_cha);
end

%% Check for existing output file before running
if output_info.type == "grid"
    f_out = [output_info.NetCDFfilename '.nc'];
    assert(~exist(f_out, 'file'), f_out + " already exists. Delete or rename it before running.")
end

%% Auto-run SeparateEnvHur if env_info.type==3 and the .mat file does not exist
if env_info.type == 3 && ~exist([env_info.file_name '.mat'], 'file')
    % TODO:  THE FOLLOWING DOES NOT LOOK RIGHT.  Just because the variable
    % sepenvhur (which contains the separateenvhur config parameters) exists
    % does NOT mean that the EnvFields.mat file does.
    assert(exist('sepenvhur', 'var') ~= 0, ...
        "EnvFields file not found: %s.mat\n" + ...
        "Use a unified config (with sepenvhur) to enable auto-generation, " + ...
        "or run SeparateEnvHur separately first.", env_info.file_name);
    logMsg(fid, "INFO", "EnvFields file not found: %s.mat", env_info.file_name);
    logMsg(fid, "INFO", "Running SeparateEnvHur to generate it ...");

    % Locate SeparateEnvHur — subdirectory of GAHM2026
    sep_dir = fullfile(pwd, 'SeparateEnvHur');
    assert(exist(fullfile(sep_dir, 'SeparateEnvHur.m'), 'file') ~= 0, ...
        "Cannot find SeparateEnvHur.m in %s.", sep_dir);
    addpath(sep_dir);

    % Run SeparateEnvHur with the sepenvhur struct and pre-loaded track data
    SeparateEnvHur(sepenvhur, ATCF_data_in);

    % SeparateEnvHur saves its output as <storm_name>_<storm_year>.mat in its
    % own working directory.  Move it here if needed.
    expected_mat = [env_info.file_name '.mat'];
    assert(exist(expected_mat, 'file') ~= 0, ...
        "SeparateEnvHur completed but %s was not found.", expected_mat);
    logMsg(fid, "INFO", "SeparateEnvHur complete. %s is ready.", expected_mat);
else
    logMsg(fid, "INFO", "EnvField file %s from SeparateEnvHur already exists.  Using.", [env_info.file_name '.mat']);
end

%% compute and output final TC wind/pressure fields as well as additional diagnostic information

logMsg(fid, "INFO", "Calling GAHM2026 (version=%d, ntheta=%d, nr=%d, delr=%d) ...", ...
       GAHM_param_info.version, GAHM_compute_info.ntheta, ...
       GAHM_compute_info.nr, GAHM_compute_info.delr);

[Reggrid_out, Reggrid_TC_out, Reggrid_Env_out, Reggrid_VVor_invtapHur_out, ...
        Trackdata, GAHM_out, VPrad] = ...
        GAHM2026(storm_info, ATCF_data_in, GAHM_param_info, ...
                 GAHM_compute_info, WAF_info, env_info, output_info, debug);

if output_info.type == "grid"
    if debug, logMsg(fid, "DEBUG", "Writing netCDF output to %s.nc", output_info.NetCDFfilename); end
    logMsg(fid, "INFO", "Writing netCDF output")
    err = writeGAHM2026NetCdf(output_info.NetCDFfilename, Reggrid_out, Reggrid_TC_out, output_info);
elseif output_info.type == "points"
    nt = length(Reggrid_out);
    for i = 1:nt
        Points_TC_out(i).datetime = Reggrid_out(i).datetime;
        Points_TC_out(i).Lon = Reggrid_out(i).Lon;
        Points_TC_out(i).Lat = Reggrid_out(i).Lat;
        Points_TC_out(i).U10 = Reggrid_TC_out(i).VelU;
        Points_TC_out(i).V10 = Reggrid_TC_out(i).VelV;
        Points_TC_out(i).Press = Reggrid_TC_out(i).Press;
        Points_Env_out(i).datetime = Reggrid_out(i).datetime;
        Points_Env_out(i).Lon = Reggrid_out(i).Lon;
        Points_Env_out(i).Lat = Reggrid_out(i).Lat;
        Points_Env_out(i).U10 = Reggrid_Env_out(i).VelU;
        Points_Env_out(i).V10 = Reggrid_Env_out(i).VelV;
        Points_Env_out(i).Press = Reggrid_Env_out(i).Press;
    end

    logMsg(fid, "INFO", "Done computing values at output points")
end

%% Package results for return

Result.Reggrid_out     = Reggrid_out;
Result.Reggrid_TC_out  = Reggrid_TC_out;
Result.Reggrid_Env_out = Reggrid_Env_out;
Result.Reggrid_VVor_invtapHur_out = Reggrid_VVor_invtapHur_out;
Result.Trackdata       = Trackdata;
Result.GAHM_out        = GAHM_out;
Result.VPrad           = VPrad;
Result.storm_info      = storm_info;
Result.env_info        = env_info;

if output_info.type == "points"
    Result.Points_TC_out  = Points_TC_out;
    Result.Points_Env_out = Points_Env_out;
end

logMsg(fid, "INFO", "Done.");

end
