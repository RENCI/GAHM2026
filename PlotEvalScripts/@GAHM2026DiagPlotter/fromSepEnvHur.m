function obj = fromSepEnvHur(sepfile, opts)
% fromSepEnvHur  Static factory: build GAHM2026DiagPlotter from SeparateEnvHur output.
%
%   obj = GAHM2026DiagPlotter.fromSepEnvHur(sepfile)
%   obj = GAHM2026DiagPlotter.fromSepEnvHur(sepfile, opts)
%
%   SEPFILE can be:
%     - a char/string path to a .mat file containing the variable env_vals
%     - a pre-loaded struct with the same fields as env_vals
%
%   The env_vals struct is expected to contain (NT = number of timesteps,
%   NY x NX = spatial grid dimensions):
%       Time                 — datetime array  (NT)
%       Lo, La               — longitude / latitude  (NT x NY x NX)
%       Vortex_mask_inner    — inner vortex mask     (NT x NY x NX)
%       Vortex_mask          — outer vortex mask     (NT x NY x NX)
%       env_msl, env_u10, env_v10  — environmental fields  (NT x NY x NX)
%       hur_msl, hur_u10, hur_v10  — hurricane fields       (NT x NY x NX)
%       BestTrack_lon, BestTrack_lat — track coordinates    (NT)
%
%   OPTS  (optional) is a plotting-options struct as returned by
%         plot_defaults().  When omitted, plot_defaults() is called and
%         colour-limit presets appropriate for each component are stored
%         in Result.sep_opts.
%
%   See also GAHM2026DiagPlotter, plot_defaults.
%
%                Rick Luettich / UNC/IMS/CNHR/EMES
%                Brian Blanton / UNC/RENCI

    %% ---- Load / validate input ------------------------------------------
    if ischar(sepfile) || isstring(sepfile)
        tmp = load(sepfile, 'env_vals');
        ev  = tmp.env_vals;
    elseif isstruct(sepfile)
        ev = sepfile;
    else
        error('GAHM2026DiagPlotter:fromSepEnvHur', ...
              'sepfile must be a filename (char/string) or a struct.');
    end

    NT = numel(ev.Time);

    %% ---- Build pseudo-Result struct -------------------------------------
    Reggrid_out    = struct([]);
    Reggrid_TC_out = struct([]);
    Reggrid_Env_out = struct([]);
    Reggrid_Hur_out = struct([]);
    Trackdata       = struct([]);

    for i = 1:NT
        % Grid coordinates and masks (squeeze NT dimension)
        Reggrid_out(i).datetime = ev.Time(i);
        Reggrid_out(i).Lon      = squeeze(ev.Lo(i,:,:));
        Reggrid_out(i).Lat      = squeeze(ev.La(i,:,:));
        Reggrid_out(i).Mask1    = squeeze(ev.Vortex_mask_inner(i,:,:));
        Reggrid_out(i).Mask2    = squeeze(ev.Vortex_mask(i,:,:));

        % Combined env + hur (total ERA5)
        Reggrid_TC_out(i).datetime = ev.Time(i);
        Reggrid_TC_out(i).Press    = squeeze(ev.env_msl(i,:,:)) + squeeze(ev.hur_msl(i,:,:));
        Reggrid_TC_out(i).VelU     = squeeze(ev.env_u10(i,:,:)) + squeeze(ev.hur_u10(i,:,:));
        Reggrid_TC_out(i).VelV     = squeeze(ev.env_v10(i,:,:)) + squeeze(ev.hur_v10(i,:,:));

        % Environmental only
        Reggrid_Env_out(i).datetime = ev.Time(i);
        Reggrid_Env_out(i).Press    = squeeze(ev.env_msl(i,:,:));
        Reggrid_Env_out(i).VelU     = squeeze(ev.env_u10(i,:,:));
        Reggrid_Env_out(i).VelV     = squeeze(ev.env_v10(i,:,:));

        % Hurricane only
        Reggrid_Hur_out(i).datetime = ev.Time(i);
        Reggrid_Hur_out(i).Press    = squeeze(ev.hur_msl(i,:,:));
        Reggrid_Hur_out(i).VelU     = squeeze(ev.hur_u10(i,:,:));
        Reggrid_Hur_out(i).VelV     = squeeze(ev.hur_v10(i,:,:));

        % Track
        Trackdata(i).Lon      = ev.BestTrack_lon(i);
        Trackdata(i).Lat      = ev.BestTrack_lat(i);
        Trackdata(i).datetime = ev.Time(i);
    end

    Result.Reggrid_out     = Reggrid_out;
    Result.Reggrid_TC_out  = Reggrid_TC_out;
    Result.Reggrid_Env_out = Reggrid_Env_out;
    Result.Reggrid_Hur_out = Reggrid_Hur_out;
    Result.Trackdata       = Trackdata;

    %% ---- Default colour-limit presets -----------------------------------
    if nargin < 2 || isempty(opts)
        opts = plot_defaults();

        sep_opts.env.wind.clims    = [0 16];
        sep_opts.env.pres.clims    = [980 1020];
        sep_opts.hur.wind.clims    = [0 50];
        sep_opts.hur.pres.clims    = [-50 50];
        sep_opts.envhur.wind.clims = [0 50];
        sep_opts.envhur.pres.clims = [980 1020];

        Result.sep_opts = sep_opts;
    end

    %% ---- Construct plotter object ---------------------------------------
    obj = GAHM2026DiagPlotter(Result, opts, 'sepenvhur');
end
