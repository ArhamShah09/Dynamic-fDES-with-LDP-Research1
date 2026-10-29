function boundary = boundary_test(C)
%BOUNDARY_TEST Demonstrate hard symbolic bin-boundary errors with toy RR pairs.

edge = C.symbolRangeMs(1) + (C.symbolRangeMs(2)-C.symbolRangeMs(1))/C.mainNBins;
pairs = [edge-2 edge+2; edge-2 edge-1; edge-10 edge+10];
n = size(pairs,1);
boundary = table(pairs(:,1), pairs(:,2), abs(diff(pairs,1,2)), zeros(n,1), zeros(n,1), zeros(n,1), ...
    'VariableNames', {'RR_A_ms','RR_B_ms','AbsoluteDifference_ms','symDES','triFDES','expFDES'});
for i = 1:n
    pair = pairs(i,:);
    boundary.symDES(i) = symDES(pair, C.mainNBins, C.symbolRangeMs);
    boundary.triFDES(i) = tri_fDES(pair, C.mainRms);
    boundary.expFDES(i) = exp_fDES(pair, C.mainAlphaPerSecond);
end
writetable(boundary, fullfile(C.resultsDir, 'boundary_test.csv'));
end
