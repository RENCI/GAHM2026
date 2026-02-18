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

function Result = run_GAHM2026(config_name)

if nargin < 1
    config_name = 'config_GAHM2026_default';
end

addpath('util')

if ~exist('input', 'dir'),  mkdir('input');  end
if ~exist('output', 'dir'), mkdir('output'); end

warning off

%% Load configuration parameters
config_file = fullfile('config', config_name);
if ~exist([config_file '.m'], 'file')
    error('Config file not found: %s.m', config_file);
end
run(config_file)

if ~exist('debug','var'), debug = false; end
logMsg(-1, 'INFO', 'Configuration loaded from %s', config_file);
logMsg(-1, 'INFO', 'Storm: %s %s, env_type=%d', storm_info.name, storm_info.year, env_info.type);

%% Validate storm_year vs storm_start/storm_end
sy = str2double(storm_info.year);
if isdatetime(storm_info.starttime) && year(storm_info.starttime) ~= sy
    logMsg(-1, 'ERROR', 'storm_year (%d) does not match year of storm_start (%d)', sy, year(storm_info.starttime));
end
if isdatetime(storm_info.endtime) && year(storm_info.endtime) ~= sy
    logMsg(-1, 'WARNING', 'storm_year (%d) does not match year of storm_end (%d) — storm may span year boundary', sy, year(storm_info.endtime));
end

%% Download IBTrACS file if it does not exist
if storm_info.file_type == "IBTrACS" && ~exist(storm_info.track_file,'file')
    ibtracs_url = ['https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/csv/' ...
                   erase(storm_info.track_file,'input/')];
    logMsg(-1, 'INFO', 'IBTrACS file not found: %s', storm_info.track_file);
    logMsg(-1, 'INFO', 'Downloading from %s ...', ibtracs_url);
    try
        websave(storm_info.track_file, ibtracs_url);
        logMsg(-1, 'INFO', 'Download complete.');
    catch ME
        error('Failed to download IBTrACS file: %s', ME.message);
    end
end

%% Check for existing output file before running
if output_info.type == "grid"
    f_out = [output_info.NetCDFfilename '.nc'];
    if exist(f_out,'file')
        % error([f_out ' already exists. Delete or rename it before running.'])
        logMsg(-1,'ERROR',[f_out ' already exists. Delete or rename it before running.'])
    end
end

%% Auto-run ScrubEra5 if env_info.type==3 and the .mat file does not exist
if env_info.type == 3 && ~exist([env_info.file_name '.mat'], 'file')
    % TODO:  the following does not look right.  just because the variable
    % scrub_info (which contains the scrubera5 config parameters) exists
    % does NOT mean that the EnvFields.mat file does.   Basically, we need
    % to get rid of this auto-trun stuff and just compute the env fields
    % every time.
    if ~exist('scrub_info', 'var')
        error(['EnvFields file not found: %s.mat\n' ...
               'Use a unified config (with scrub_info) to enable auto-generation, ' ...
               'or run ScrubEra5 separately first.'], env_info.file_name);
    end
    logMsg(-1, 'INFO', 'EnvFields file not found: %s.mat', env_info.file_name);
    logMsg(-1, 'INFO', 'Running ScrubEra5 to generate it ...');

    % Locate ScrubEra5 — subdirectory of GAHM2026
    scrub_dir = fullfile(pwd, 'ScrubEra5');
    if ~exist(fullfile(scrub_dir, 'ScrubEra5.m'), 'file')
        error('Cannot find ScrubEra5.m in %s.', scrub_dir);
    end
    addpath(scrub_dir);

    % Run ScrubEra5 with the scrub_info struct from the unified config
    ScrubEra5(scrub_info);

    % ScrubEra5 saves its output as <storm_name>_<storm_year>.mat in its
    % own working directory.  Move it here if needed.
    expected_mat = [env_info.file_name '.mat'];
    if ~exist(expected_mat, 'file')
        error('ScrubEra5 completed but %s was not found.', expected_mat);
    end
    logMsg(-1, 'INFO', 'ScrubEra5 complete. %s is ready.', expected_mat);
else
    logMsg(-1, 'INFO', 'EnvField file %s from ScrubEra5 already exists.  Using.', [env_info.file_name '.mat']);
end

%% compute and output final TC wind/pressure fields as well as additional diagnostic information

if debug, logMsg(-1, 'DEBUG', 'Calling GAHM2026 (version=%d, ntheta=%d, nr=%d, delr=%d) ...', ...
    GAHM_param_info.version, GAHM_compute_info.ntheta, GAHM_compute_info.nr, GAHM_compute_info.delr); end

[Reggrid_out, Reggrid_TC_out, Reggrid_Env_out, Reggrid_VVor_invtapHur_out, ...
        Trackdata, GAHM_out, VPrad]= GAHM2026(storm_info,GAHM_param_info, ...
                          GAHM_compute_info,WAF_info,env_info,output_info,debug);

if output_info.type == "grid"
    if debug, logMsg(-1, 'DEBUG', 'Writing netCDF output to %s.nc', output_info.NetCDFfilename); end
    logMsg(-1, 'INFO', 'Writing netCDF output')
    err=writeGAHM2026NetCdf(output_info.NetCDFfilename,Reggrid_out,Reggrid_TC_out);
elseif output_info.type == "points"
    nt=length(Reggrid_out);
    for i=1:nt
        Points_TC_out(i).datetime=Reggrid_out(i).datetime;
        Points_TC_out(i).Lon=Reggrid_out(i).Lon;
        Points_TC_out(i).Lat=Reggrid_out(i).Lat;
        Points_TC_out(i).U10=Reggrid_TC_out(i).VelU;
        Points_TC_out(i).V10=Reggrid_TC_out(i).VelV;
        Points_TC_out(i).Press=Reggrid_TC_out(i).Press;
        Points_Env_out(i).datetime=Reggrid_out(i).datetime;
        Points_Env_out(i).Lon=Reggrid_out(i).Lon;
        Points_Env_out(i).Lat=Reggrid_out(i).Lat;
        Points_Env_out(i).U10=Reggrid_Env_out(i).VelU;
        Points_Env_out(i).V10=Reggrid_Env_out(i).VelV;
        Points_Env_out(i).Press=Reggrid_Env_out(i).Press;        
    end

    logMsg(-1, 'INFO', 'Done computing values at output points')
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

logMsg(-1, 'INFO', 'Done.');

end
