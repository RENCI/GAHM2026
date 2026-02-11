%--------------------------------------------------------------------------
% Generate a baseline snapshot of GAHM26 outputs for regression testing.
%
% This script runs GAHM2026 with the standard Florence configuration
% and saves the key output variables to a .mat file. This baseline is then
% used by compare_to_baseline.m to verify that refactoring has not changed
% numerical results.
%
% Two test configurations are run:
%   1. env_type=1 (ADCIRC/ASWIP, no gridded env file needed, fast)
%   2. env_type=3 (gridded env, requires Florence.mat, full pipeline)
%
% Usage:
%   cd into the GAHM26 directory, then run:
%     >> generate_baseline
%
% Output:
%   tools/baseline_env1.mat  - baseline for env_type=1 test
%   tools/baseline_env3.mat  - baseline for env_type=3 test (if Florence.mat exists)
%
%                    February 2026
%--------------------------------------------------------------------------

warning off

fprintf('\n=== GAHM26 Baseline Generator ===\n\n')

toolsdir = fileparts(mfilename('fullpath'));
projdir  = fileparts(toolsdir);
addpath(fullfile(projdir, 'util'))

%% Common parameters (match run_GAHM2026.m)

storm_info.file_name  = fullfile(projdir, 'input', 'ibtracs.NA.list.v04r01.csv');
storm_info.file_type  = "IBTrACS";
storm_info.name       = 'FLORENCE';
storm_info.year       = '2018';
storm_info.designation = 'AL06';
storm_info.starttime  = '2018091312';
storm_info.endtime    = '2018091500';

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

output_info.warnings       = fullfile(toolsdir, 'baseline_warnings.dat');
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
        Trackdata, GAHM_out] = GAHM2026(storm_info, GAHM_param_info, ...
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

%% Test 2: env_type = 3 (full pipeline, requires Florence.mat)

florence_file = fullfile(projdir, 'Florence.mat');
if exist(florence_file, 'file')
    fprintf('\n--- Test 2: env_type=3 (gridded env + taper + WAF) ---\n')

    env_info_3.type             = 3;
    env_info_3.file_name        = 'Florence';
    env_info_3.taper_flag       = true;
    env_info_3.taper_mindelr2r1 = 0.1;
    env_info_3.taper_a          = 2;

    WAF_info_3.flag = false;
    waf_file = fullfile(projdir, 'WAF_15deg_10km_6km_raster_test.tif');
    if exist(waf_file, 'file')
        WAF_info_3.flag      = true;
        WAF_info_3.file_name = waf_file;
    else
        fprintf('  WAF raster not found, running without WAF\n');
    end

    try
        tic;
        [Reggrid_out, Reggrid_TC_out, Reggrid_Env_out, Reggrid_VVor_invtapHur_out, ...
            Trackdata, GAHM_out] = GAHM2026(storm_info, GAHM_param_info, ...
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
        baseline.config.WAF_flag = WAF_info_3.flag;

        outfile3 = fullfile(toolsdir, 'baseline_env3.mat');
        save(outfile3, 'baseline', '-v7.3');
        fprintf('  Saved: %s (%.1f seconds)\n', outfile3, elapsed);
        fprintf('  Timesteps: %d\n', baseline.nt);
    catch ME
        fprintf('  FAILED: %s\n', ME.message);
    end
else
    fprintf('\n--- Test 2: SKIPPED (Florence.mat not found) ---\n')
end

%% Test 3: Full Florence case (matches run_GAHM2026.m exactly)

if exist(florence_file, 'file')
    fprintf('\n--- Test 3: Full Florence (351x351 grid, WAF, env_type=3) ---\n')

    env_info_full.type             = 3;
    env_info_full.file_name        = 'Florence';
    env_info_full.taper_flag       = true;
    env_info_full.taper_mindelr2r1 = 0.1;
    env_info_full.taper_a          = 2;

    WAF_info_full.flag = false;
    waf_file = fullfile(projdir, 'WAF_15deg_10km_6km_raster_test.tif');
    if exist(waf_file, 'file')
        WAF_info_full.flag      = true;
        WAF_info_full.file_name = waf_file;
    else
        fprintf('  WAF raster not found, running without WAF\n');
    end

    output_info_full.warnings       = fullfile(toolsdir, 'baseline_florence_warnings.dat');
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
            Trackdata, GAHM_out] = GAHM2026(storm_info, GAHM_param_info, ...
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
        baseline.config.WAF_flag = WAF_info_full.flag;
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
else
    fprintf('\n--- Test 3: SKIPPED (Florence.mat not found) ---\n')
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
