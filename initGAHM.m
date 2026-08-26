function initGAHM
%--------------------------------------------------------------------------
% Function to initialize GAHM2026 paths
%
% Usage:
%     addpath(<path/to/GAHM2026directory>)
%     initGAHM  

fpath= fileparts(mfilename('fullpath'));
addpath(fullfile(fpath,'util'))
addpath(fullfile(fpath,'static'))
addpath(fullfile(fpath,'PlotEvalScripts'))
addpath(fullfile(fpath,'SeparateEnvHur'))

%if ~exist('input', 'dir'),  mkdir('input');  end
%f ~exist('output', 'dir'), mkdir('output'); end

% Use a 24-hour, unambiguous default datetime format.  The lower-case "hh"
% format is a 12-hour clock with no AM/PM designator, so 18:00 renders as
% "06:00:00" and a date with no time component renders as "12:00:00".  Any
% datetime converted to text under that format (e.g. the "minutes since ..."
% units string written to the output NetCDF, or the epoch parsed from the
% gridded input file in getERA5Data) is silently shifted by 12 hours.
datetimeFormat = 'yyyy-MMM-dd HH:mm:ss';
datetime.setDefaultFormats('default',datetimeFormat);
datetime.setDefaultFormats('defaultdate',datetimeFormat);

