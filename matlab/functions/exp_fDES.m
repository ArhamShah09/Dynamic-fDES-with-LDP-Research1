function value = exp_fDES(rrMs, alphaPerSecond)
%EXP_FDES Exponential fuzzy DES. RR differences are converted from ms to s.

validateattributes(alphaPerSecond, {'numeric'}, {'scalar','positive','finite'});
dSeconds = abs(diff(rrMs(:))) ./ 1000;
value = mean(exp(-alphaPerSecond .* dSeconds));
end
