function cutlineIdx = applyCircularSmooth(cutlineIdx)
    tripled = [cutlineIdx; cutlineIdx; cutlineIdx];
    tripled = movmean(tripled, 3);
    cutlineIdx = tripled(25:48);
end
