function [time, real_lon, real_lat, start_time, end_time] = loadTrackData(cfg)
    opts = detectImportOptions(cfg.track_file);
    opts = setvartype(opts, {'NAME', 'ISO_TIME'}, 'char');
    data = readtable(cfg.track_file, opts);
    
    % Find rows matching storm name and year
    raw_time = datetime(data.ISO_TIME, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    name_match = strcmpi(data.NAME, cfg.storm_name);
    year_match = data.SEASON == cfg.storm_year;
    rows = find(name_match & year_match); %  & start_match & end_match);

    raw_time = datetime(data.ISO_TIME(rows), 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
   
    % trim times
    if ~isnat(cfg.storm_end)
        idx=raw_time<=cfg.storm_end;
        rows = rows(idx);
        raw_time=raw_time(idx);
    end
    
    if ~isnat(cfg.storm_start)
        idx=raw_time>=cfg.storm_start;
        rows = rows(idx);
    end

    if isempty(rows)
        error('Storm "%s" (%d) not found in %s', ...
            cfg.storm_name, cfg.storm_year, cfg.track_file);
    end
    
    raw_lat = data.LAT(rows);
    raw_lon = data.LON(rows) + 360;
    raw_time = datetime(data.ISO_TIME(rows), 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    
    start_time = raw_time(1);
    end_time = raw_time(end);
    time = start_time:hours(1):end_time;
    time.Format='dd-MMM-uuuu HH:mm:ss';

    real_lon = interp1(raw_time, raw_lon, time);
    real_lat = interp1(raw_time, raw_lat, time);
end
