function value = symDES(rrMs, nBins, binRangeMs)
%SYMDES Equal-width symbolic DES baseline with fixed global bin boundaries.

validateattributes(nBins, {'numeric'}, {'scalar','integer','>=',2});
validateattributes(binRangeMs, {'numeric'}, {'vector','numel',2,'increasing'});
edges = linspace(binRangeMs(1), binRangeMs(2), nBins + 1);
rr = min(max(rrMs(:), binRangeMs(1)), binRangeMs(2));
symbols = discretize(rr, edges);
symbols(isnan(symbols)) = nBins; % only applies to an exact upper edge
value = mean(symbols(1:end-1) == symbols(2:end));
end
