function cutlineIdx = applyCircularSmooth(cutlineIdx, numAzimuthPoints, smoothingWidth)
%applyCircularSmooth Smooth a radial cutline across the azimuth seam.
    if numel(cutlineIdx) ~= numAzimuthPoints
        error("SeparateEnvHur:AzimuthCountMismatch", ...
            "The cutline length must equal the configured azimuth count.");
    end
    tripled = [cutlineIdx; cutlineIdx; cutlineIdx];
    tripled = movmean(tripled, smoothingWidth);
    cutlineIdx = tripled(numAzimuthPoints+1:2*numAzimuthPoints);
end
