function filtered = applyButterworthFilter2D(field, filt, rows, cols)
    filtered = field;

    for r = rows
        fwd = filtfilt(filt, field(r, cols));
        rev = filtfilt(filt, flip(field(r, cols)));
        filtered(r, cols) = (fwd + flip(rev)) / 2;
    end

    for c = cols
        fwd = filtfilt(filt, filtered(rows, c));
        rev = filtfilt(filt, flip(filtered(rows, c)));
        filtered(rows, c) = (fwd + flip(rev)) / 2;
    end
end
