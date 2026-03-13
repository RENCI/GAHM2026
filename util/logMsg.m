function logMsg(fid, level, fmt, varargin)
% Print a formatted log message to stdout and optionally to a log file.
% The caller name is determined automatically via dbstack.
%
% Inputs:
%       fid      - file identifier for log file (use -1 to skip file output)
%       level    - log level string: 'DEBUG', 'INFO', 'WARNING', or 'ERROR'
%                  'ERROR' logs the message and then calls error() to terminate
%       fmt      - fprintf format string (newline is appended automatically)
%       varargin - arguments for the format string
%
% Output format:
%       [LEVEL:caller] message
%
% Usage:
%       logMsg(fid, 'INFO', 'step %d complete', i);
%       logMsg(-1, 'WARNING', 'Missing data at time %s', t);
%       logMsg(fid, 'DEBUG', 'grid=%dx%d', nx, ny);
%       logMsg(fid, 'ERROR', 'File not found: %s', fname);

st = dbstack;
caller = "base";
if length(st) >= 2
    caller = st(2).name;
end

msg = sprintf('[%s:%s] %s\n', level, caller, fmt);

if level == "ERROR"
    error('[%s:%s] %s', level, caller, sprintf(fmt, varargin{:}));
end

fprintf(msg, varargin{:});
if fid > 0
    fprintf(fid, msg, varargin{:});
end

end
