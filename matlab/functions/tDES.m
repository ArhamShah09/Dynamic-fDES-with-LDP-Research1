function value = tDES(rrMs, rMs)
%TDES Threshold distribution of equal states on consecutive RR differences.

validateattributes(rMs, {'numeric'}, {'scalar','positive','finite'});
d = abs(diff(rrMs(:)));
value = mean(d <= rMs);
end
