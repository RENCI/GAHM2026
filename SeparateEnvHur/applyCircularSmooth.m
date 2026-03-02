function count = applyCircularSmooth(count)
    tem = [count; count; count];
    tem = movmean(tem, 3);
    count = tem(25:48);
end
