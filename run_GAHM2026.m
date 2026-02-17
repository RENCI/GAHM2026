%--------------------------------------------------------------------------
% Function to execute GAHM2026.m
%
% Usage:
%     run_GAHM2026              — uses default config/config_GAHM2026.m
%     run_GAHM2026('myconfig')  — uses config/myconfig.m
% 
%% See documentation/README_config.md for full configuration reference.
%
%%                        2/3/2026  Rick Luettich
%                         2/16/2026 Brian Blanton
function run_GAHM2026(config_name)

if nargin < 1
    config_name = 'config_GAHM2026';
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
fprintf('[INFO:run_GAHM2026] Configuration loaded from %s\n', config_file);
fprintf('[INFO:run_GAHM2026] Storm: %s %s, env_type=%d\n', storm_info.name, storm_info.year, env_info.type);

%% Download IBTrACS file if it does not exist
if storm_info.file_type == "IBTrACS" && ~exist(storm_info.file_name,'file')
    ibtracs_url = ['https://www.ncei.noaa.gov/data/international-best-track-archive-for-climate-stewardship-ibtracs/v04r01/access/csv/' ...
                   erase(storm_info.file_name,'input/')];
    fprintf('[INFO:run_GAHM2026] IBTrACS file not found: %s\n', storm_info.file_name);
    fprintf('[INFO:run_GAHM2026] Downloading from %s ...\n', ibtracs_url);
    try
        websave(storm_info.file_name, ibtracs_url);
        fprintf('[INFO:run_GAHM2026] Download complete.\n');
    catch ME
        error('Failed to download IBTrACS file: %s', ME.message);
    end
end

%% Check for existing output file before running
if output_info.type == "grid"
    f_out = [output_info.NetCDFfilename '.nc'];
    if exist(f_out,'file')
        error([f_out ' already exists. Delete or rename it before running.'])
    end
end

%% Auto-run ScrubEra5 if env_info.type==3 and the .mat file does not exist
if env_info.type == 3 && ~exist([env_info.file_name '.mat'], 'file')
    if ~exist('scrub_info', 'var')
        error(['EnvFields file not found: %s.mat\n' ...
               'Use a unified config (with scrub_info) to enable auto-generation, ' ...
               'or run ScrubEra5 separately first.'], env_info.file_name);
    end
    fprintf('[INFO:run_GAHM2026] EnvFields file not found: %s.mat\n', env_info.file_name);
    fprintf('[INFO:run_GAHM2026] Running ScrubEra5 to generate it ...\n');

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
    fprintf('[INFO:run_GAHM2026] ScrubEra5 complete. %s is ready.\n', expected_mat);
end

%% compute and output final TC wind/pressure fields as well as additional diagnostic information

if debug, fprintf('[DEBUG:run_GAHM2026] Calling GAHM2026 (version=%d, ntheta=%d, nr=%d, delr=%d) ...\n', ...
    GAHM_param_info.version, GAHM_compute_info.ntheta, GAHM_compute_info.nr, GAHM_compute_info.delr); end

[Reggrid_out, Reggrid_TC_out, Reggrid_Env_out, Reggrid_VVor_invtapHur_out, ...
        Trackdata, GAHM_out, VPrad]= GAHM2026(storm_info,GAHM_param_info, ...
                          GAHM_compute_info,WAF_info,env_info,output_info,debug);

if output_info.type == "grid"
    if debug, fprintf('[DEBUG:run_GAHM2026] Writing netCDF output to %s.nc\n', output_info.NetCDFfilename); end
    fprintf('[INFO:run_GAHM2026] Writing netCDF output\n')
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

    fprintf('[INFO:run_GAHM2026] Done computing values at output points\n')
end

fprintf('[INFO:run_GAHM2026] Done.\n');

end
