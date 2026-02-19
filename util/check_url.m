function check_url(url)
try
    % Attempt to read a small amount of data or just get the header
    % webread can be used directly for simple cases, but may download the whole resource.
    % A better approach is to use the http interface for a 'HEAD' request.
    
    % --- Using the modern matlab.net.http interface (R2014a or later) ---
    uri = matlab.net.URI(url);
    request = matlab.net.http.RequestMessage;
    
    % Send a HEAD request to avoid downloading the entire file
    response = request.send(uri);
    
    % Check if the status code indicates success (e.g., 200 OK)
    if response.StatusCode == matlab.net.http.StatusCode.OK
        disp('URL exists and is accessible.');
        % You can proceed with webread, websave, imread etc. if needed
    else
        disp(['URL might not exist or returned status: ', num2str(response.StatusCode)]);
    end
    
catch ME
    % Catch potential connection errors or other issues
    disp(['An error occurred: ', ME.message]);
    disp('URL does not seem to be accessible.');
end