%  Sample call lines for radplot_GAHM2026.m
%  Uses output variables from GAHM2026.m / run_GAHM2026.m
%
%  After running run_GAHM2026.m, the VPrad struct contains:
%     VPrad.r, VPrad.theta  - radial grid coordinates
%     VPrad.VVor_bt(i)      - vortex fields before taper
%     VPrad.VVor_at(i)      - vortex fields after taper
%     VPrad.Env(i)          - environmental radial fields (if env_type=3)
%     VPrad.EnvVor_bt(i)    - combined env+vortex before taper (if env_type=3)
%     VPrad.EnvHur_final(i) - final blended output on radial grid
%
%  An optional opts struct can be passed to override defaults.
%  See plot_defaults.m for all available options.
%
%                R. Luettich 11/10/2024
%                updated 2/8/2026 - uses VPrad struct

opts = plot_defaults();

% plot radial pressure profiles (every other radial)
radplot_GAHM2026(VPrad, Trackdata, 2, 'prerad', 20, opts)

%% Other example calls (uncomment as needed):
%
% % radial velocity profiles
% radplot_GAHM2026(VPrad, Trackdata, 2, 'velrad', 20, opts)
