%--------------------------------------------------------------------------
% Generate a baseline snapshot of GAHM26 outputs for regression testing.
%
% This script runs GAHM2026 with the standard Florence configuration
% and saves the key output variables to a .mat file. This baseline is then
% used by compare_to_baseline.m to verify that refactoring has not changed
% numerical results.
%
% Four test configurations are run:
%   1. env_type=1 (ADCIRC/ASWIP, no gridded env file needed, fast)
%   2. env_type=2 (Lin & Chavez 2012, no gridded env file needed, fast)
%   3. env_type=3 (gridded env, 51x51 grid — auto-runs SeparateEnvHur)
%   4. env_type=3 (full Florence 351x351 — auto-runs SeparateEnvHur)
%
% Usage:
%   cd into the GAHM26 directory, then run:
%     >> generate_baseline
%
% Output:
%   tools/baseline_env1.mat      - baseline for env_type=1 test
%   tools/baseline_env2.mat      - baseline for env_type=2 test
%   tools/baseline_env3.mat      - baseline for env_type=3 test
%   tools/baseline_florence.mat  - baseline for full Florence test
%
%                    February 2026
%--------------------------------------------------------------------------

warning off

fprintf('\n=== GAHM26 Baseline Generator ===\n\n')

toolsdir = fileparts(mfilename('fullpath'));
projdir  = fileparts(toolsdir);
addpath(projdir)
addpath(fullfile(projdir, 'util'))
addpath(fullfile(projdir, 'SeparateEnvHur'))

%% Common parameters (match run_GAHM2026.m)

storm_info.track_file = fullfile(projdir, 'input', 'ibtracs.NA.list.v04r01.csv');
storm_info.file_type  = "IBTrACS";
storm_info.name       = 'FLORENCE';
storm_info.year       = '2018';
storm_info.designation = 'AL06';
storm_info.starttime  = datetime(2018,9,13,12,0,0);
storm_info.endtime    = datetime(2018,9,15,0,0,0);

ATCF_data_in = readIBTrACS(storm_info);

% SeparateEnvHur config for auto-generating env fields
sepenvhur.background_file      = 'https://tdsres.apps.renci.org/thredds/dodsC/Datalayers/ERA5/global.1/uvp/<year>/<year>.nc';
sepenvhur.storm_start           = storm_info.starttime;
sepenvhur.storm_end             = storm_info.endtime;
sepenvhur.grid_half_size        = 40;
sepenvhur.output_half_size      = 40;
sepenvhur.filter_domain_size    = 120;
sepenvhur.num_radial_points     = 1000;
sepenvhur.num_azimuth_points    = 360;
sepenvhur.max_radius_deg        = 10;
sepenvhur.search_range          = 6;
MS2KT = gahmPhysicalConstants().ms2kt;
sepenvhur.wind_threshold_outer  = 20/MS2KT;
sepenvhur.wind_threshold_inner  = 34/MS2KT;
sepenvhur.debug                 = false;
sepenvhur.output_dir            = toolsdir;
sepenvhur.storm_name            = storm_info.name;
sepenvhur.storm_year            = str2double(storm_info.year);
sepenvhur.storm_designation     = storm_info.designation;
sepenvhur.track_file            = storm_info.track_file;

env_file_base = fullfile(toolsdir, sprintf('%s_%s_%s', ...
    storm_info.name, storm_info.designation, storm_info.year));

GAHM_param_info.Vmax_multiplier    = 1;
GAHM_param_info.one2tenF           = 0.89;
GAHM_param_info.BLF                = 0.9;
GAHM_param_info.Bmin               = 0.5;
GAHM_param_info.Bmax               = 2.5;
GAHM_param_info.SVorMax_10_tblmin  = 20;
GAHM_param_info.SVorQuad_10_tblmin = 5;
GAHM_param_info.rhoa               = 1.204;
GAHM_param_info.pback_def          = 1013;
GAHM_param_info.version            = 3;
GAHM_param_info.Bg0M               = 1;
GAHM_param_info.c0                 = 0;

GAHM_compute_info.ntheta = 24;
GAHM_compute_info.nr     = 800;
GAHM_compute_info.delr   = 1000;

output_info.diagnostics    = fullfile(toolsdir, 'baseline_diagnostics.dat');
output_info.NetCDFfilename = fullfile(toolsdir, 'baseline_test');
output_info.timeinc        = 1;
output_info.type           = "grid";
output_info.nlon           = 51;
output_info.nlat           = 51;
output_info.dellon         = 0.1;
output_info.dellat         = 0.1;

%% Test 1: env_type = 1 (lightweight, no Florence.mat needed)

fprintf('--- Test 1: env_type=1 (ADCIRC/ASWIP) ---\n')

env_info_1.type           = 1;
env_info_1.taper_flag     = false;
env_info_1.taper_mindelr2r1 = 0.1;
env_info_1.taper_a        = 2;

WAF_info_1.flag = false;

try
    tic;
    [Reggrid_out, Reggrid_TC_out, Reggrid_Env_out, Reggrid_VVor_invtapHur_out, ...
        Trackdata, GAHM_out] = GAHM2026(storm_info, ATCF_data_in, GAHM_param_info, ...
        GAHM_compute_info, WAF_info_1, env_info_1, output_info);
    elapsed = toc;

    baseline = extract_baseline_fields(Reggrid_out, Reggrid_TC_out, ...
                                       Reggrid_Env_out, GAHM_out, Trackdata);
    baseline.elapsed_seconds = elapsed;
    baseline.generated = datetime('now');
    baseline.config.env_type = 1;
    baseline.config.GAHM_version = GAHM_param_info.version;
    baseline.config.starttime = storm_info.starttime;
    baseline.config.endtime = storm_info.endtime;

    outfile1 = fullfile(toolsdir, 'baseline_env1.mat');
    save(outfile1, 'baseline', '-v7.3');
    fprintf('  Saved: %s (%.1f seconds)\n', outfile1, elapsed);
    fprintf('  Timesteps: %d\n', baseline.nt);
catch ME
    fprintf('  FAILED: %s\n', ME.message);
end

%% Test 2: env_type = 2 (Lin & Chavez 2012, lightweight)

fprintf('\n--- Test 2: env_type=2 (Lin & Chavez 2012) ---\n')

env_info_2.type             = 2;
env_info_2.taper_flag       = false;
env_info_2.taper_mindelr2r1 = 0.1;
env_info_2.taper_a          = 2;

WAF_info_2.flag = false;

try
    tic;
    [Reggrid_out, Reggrid_TC_out, Reggrid_Env_out, Reggrid_VVor_invtapHur_out, ...
        Trackdata, GAHM_out] = GAHM2026(storm_info, ATCF_data_in, GAHM_param_info, ...
        GAHM_compute_info, WAF_info_2, env_info_2, output_info);
    elapsed = toc;

    baseline = extract_baseline_fields(Reggrid_out, Reggrid_TC_out, ...
                                       Reggrid_Env_out, GAHM_out, Trackdata);
    baseline.elapsed_seconds = elapsed;
    baseline.generated = datetime('now');
    baseline.config.env_type = 2;
    baseline.config.GAHM_version = GAHM_param_info.version;
    baseline.config.starttime = storm_info.starttime;
    baseline.config.endtime = storm_info.endtime;

    outfile2 = fullfile(toolsdir, 'baseline_env2.mat');
    save(outfile2, 'baseline', '-v7.3');
    fprintf('  Saved: %s (%.1f seconds)\n', outfile2, elapsed);
    fprintf('  Timesteps: %d\n', baseline.nt);
catch ME
    fprintf('  FAILED: %s\n', ME.message);
end

%% Auto-generate env fields if needed (shared by Tests 3 and 4)

if ~exist([env_file_base '.mat'], 'file')
    fprintf('--- Generating env fields via SeparateEnvHur ---\n')
    SeparateEnvHur(sepenvhur, ATCF_data_in);
    fprintf('  Saved: %s.mat\n', env_file_base);
end

%% Test 3: env_type = 3 (full pipeline, 51x51 grid)

fprintf('\n--- Test 3: env_type=3 (gridded env + taper, 51x51) ---\n')

env_info_3.type             = 3;
env_info_3.file_name        = env_file_base;
env_info_3.taper_flag       = true;
env_info_3.taper_mindelr2r1 = 0.1;
env_info_3.taper_a          = 2;

WAF_info_3.flag = false;

try
    tic;
    [Reggrid_out, Reggrid_TC_out, Reggrid_Env_out, Reggrid_VVor_invtapHur_out, ...
        Trackdata, GAHM_out] = GAHM2026(storm_info, ATCF_data_in, GAHM_param_info, ...
        GAHM_compute_info, WAF_info_3, env_info_3, output_info);
    elapsed = toc;

    baseline = extract_baseline_fields(Reggrid_out, Reggrid_TC_out, ...
                                       Reggrid_Env_out, GAHM_out, Trackdata);
    baseline.elapsed_seconds = elapsed;
    baseline.generated = datetime('now');
    baseline.config.env_type = 3;
    baseline.config.GAHM_version = GAHM_param_info.version;
    baseline.config.starttime = storm_info.starttime;
    baseline.config.endtime = storm_info.endtime;

    outfile3 = fullfile(toolsdir, 'baseline_env3.mat');
    save(outfile3, 'baseline', '-v7.3');
    fprintf('  Saved: %s (%.1f seconds)\n', outfile3, elapsed);
    fprintf('  Timesteps: %d\n', baseline.nt);
catch ME
    fprintf('  FAILED: %s\n', ME.message);
end

%% Test 4: Full Florence case (351x351 grid, env_type=3)

fprintf('\n--- Test 4: Full Florence (351x351 grid, env_type=3) ---\n')

env_info_full.type             = 3;
env_info_full.file_name        = env_file_base;
env_info_full.taper_flag       = true;
env_info_full.taper_mindelr2r1 = 0.1;
env_info_full.taper_a          = 2;

WAF_info_full.flag = false;

output_info_full.diagnostics    = fullfile(toolsdir, 'baseline_florence_diagnostics.dat');
output_info_full.NetCDFfilename = fullfile(toolsdir, 'baseline_florence');
output_info_full.timeinc        = 1;
output_info_full.type           = "grid";
output_info_full.nlon           = 351;
output_info_full.nlat           = 351;
output_info_full.dellon         = 0.05;
output_info_full.dellat         = 0.05;

try
    tic;
    [Reggrid_out, Reggrid_TC_out, Reggrid_Env_out, Reggrid_VVor_invtapHur_out, ...
        Trackdata, GAHM_out] = GAHM2026(storm_info, ATCF_data_in, GAHM_param_info, ...
        GAHM_compute_info, WAF_info_full, env_info_full, output_info_full);
    elapsed = toc;

    baseline = extract_baseline_fields(Reggrid_out, Reggrid_TC_out, ...
                                       Reggrid_Env_out, GAHM_out, Trackdata);
    baseline.elapsed_seconds = elapsed;
    baseline.generated = datetime('now');
    baseline.config.env_type = 3;
    baseline.config.GAHM_version = GAHM_param_info.version;
    baseline.config.starttime = storm_info.starttime;
    baseline.config.endtime = storm_info.endtime;
    baseline.config.nlon = 351;
    baseline.config.nlat = 351;
    baseline.config.dellon = 0.05;
    baseline.config.dellat = 0.05;

    outfile_florence = fullfile(toolsdir, 'baseline_florence.mat');
    save(outfile_florence, 'baseline', '-v7.3');
    fprintf('  Saved: %s (%.1f seconds)\n', outfile_florence, elapsed);
    fprintf('  Timesteps: %d\n', baseline.nt);
catch ME
    fprintf('  FAILED: %s\n', ME.message);
end

fprintf('\n=== Baseline generation complete ===\n')

%% Helper function: extract key fields into a compact struct

function bl = extract_baseline_fields(Reggrid_out, Reggrid_TC_out, ...
                                       Reggrid_Env_out, GAHM_out, Trackdata)
    nt = length(Reggrid_out);
    bl.nt = nt;

    % Grid output fields (TC and Env velocity/pressure per timestep)
    for i = 1:nt
        bl.TC_VelU{i}  = Reggrid_TC_out(i).VelU;
        bl.TC_VelV{i}  = Reggrid_TC_out(i).VelV;
        bl.TC_Press{i} = Reggrid_TC_out(i).Press;
        if isstruct(Reggrid_Env_out) && isfield(Reggrid_Env_out(i), 'VelU')
            bl.Env_VelU{i}  = Reggrid_Env_out(i).VelU;
            bl.Env_VelV{i}  = Reggrid_Env_out(i).VelV;
            bl.Env_Press{i} = Reggrid_Env_out(i).Press;
        end
    end

    % GAHM parameter fields per track timestep
    nt_gahm = length(GAHM_out);
    bl.nt_gahm = nt_gahm;
    for i = 1:nt_gahm
        bl.GAHM_B(i)       = GAHM_out(i).B;
        bl.GAHM_Rmax_in(i) = GAHM_out(i).Rmax_in;
        bl.GAHM_Rmax{i}    = GAHM_out(i).Rmax;
        bl.GAHM_Bg{i}      = GAHM_out(i).Bg;
        bl.GAHM_phi{i}     = GAHM_out(i).phi;
        bl.GAHM_RmaxQ{i}   = GAHM_out(i).RmaxQ;
        bl.GAHM_flag{i}    = GAHM_out(i).flag;
        bl.GAHM_Rmax_tot(i) = GAHM_out(i).Rmax_tot;
        bl.GAHM_SVorMax(i)  = GAHM_out(i).SVorMax_10_10;
    end

    % Track data summary
    nt_track = length(Trackdata);
    bl.nt_track = nt_track;
    for i = 1:nt_track
        bl.Track_Lat(i) = Trackdata(i).Lat;
        bl.Track_Lon(i) = Trackdata(i).Lon;
    end
end
