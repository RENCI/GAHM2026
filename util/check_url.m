function check_url(url)
% check_url - verify that a URL is accessible via HTTP HEAD request
%
% Inputs:
%       url - full URL string (e.g., 'http://example.com/data.nc.html')

try
    uri = matlab.net.URI(url);
    request = matlab.net.http.RequestMessage;
    response = request.send(uri);

    if response.StatusCode == matlab.net.http.StatusCode.OK
        logMsg(-1, 'INFO', 'URL is accessible: %s', url);
    else
        logMsg(-1, 'ERROR', 'URL returned status %d: %s', int32(response.StatusCode), url);
    end

catch ME
    logMsg(-1, 'ERROR', 'URL not accessible: %s (%s)', url, ME.message);
end
