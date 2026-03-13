%  Sample call lines for conplot_GAHM2026.m
%  Uses output variables from GAHM2026.m / run_GAHM2026.m
%
%  Available output variables after running run_GAHM2026.m:
%     Reggrid_out              - grid coordinates, datetime, masks
%     Reggrid_TC_out           - final blended TC wind/pressure
%     Reggrid_Env_out          - environmental wind/pressure
%     Reggrid_VVor_invtapHur_out - GAHM vortex + inverse-tapered hurricane
%                                  (only meaningful for env_info.type=3)
%     Trackdata                - storm track data
%     GAHM_out                 - per-timestep GAHM parameters
%
%  An optional opts struct can be passed to override defaults.
%  See plotDefaults.m for all available options.
%
%                R. Luettich 7/13/2025
%                updated 2/8/2026 - corrected variable names

opts = plotDefaults();

% plot the final blended TC velocity field with mask lines
conplot_GAHM2026(Reggrid_TC_out, Reggrid_out, Trackdata, 'mvelcon', 20, opts)

%% Other example calls (uncomment as needed):
%
% % final blended TC velocity (no mask)
% conplot_GAHM2026(Reggrid_TC_out, Reggrid_out, Trackdata, 'velcon', 20, opts)
%
% % final blended TC pressure
% conplot_GAHM2026(Reggrid_TC_out, Reggrid_out, Trackdata, 'mprecon', 120, opts)
%
% % environmental velocity field
% conplot_GAHM2026(Reggrid_Env_out, Reggrid_out, Trackdata, 'mvelcon', 220, opts)
%
% % GAHM vortex + inverse-tapered hurricane (env_type=3 only)
% conplot_GAHM2026(Reggrid_VVor_invtapHur_out, Reggrid_out, Trackdata, 'mvelcon', 320, opts)
%
%% Example: fixed domain with no animation
% opts.domain.mode = 'fixed';
% opts.domain.fixedLimits = [-85 -60 20 45];
% opts.anim.gif = false;
% opts.anim.mp4 = false;
% conplot_GAHM2026(Reggrid_TC_out, Reggrid_out, Trackdata, 'mvelcon', 20, opts)
