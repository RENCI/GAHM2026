% Print a formatted message to stdout and optionally to a log file.
% Replaces the pattern of duplicated fprintf(stdout) + fprintf(fid,...).
%
% Inputs:
%       fid  - file identifier for log file (use -1 to skip file output)
%       fmt  - fprintf format string
%       varargin - arguments for the format string
%
% Usage:
%       logMsg(fid, ' %s %s\n', 'WARNING:', msg);

function logMsg(fid, fmt, varargin)

fprintf(fmt, varargin{:});
if fid > 0
    fprintf(fid, fmt, varargin{:});
end
