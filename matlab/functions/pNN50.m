function value = pNN50(rrMs)
%PNN50 Percentage of adjacent RR differences larger than 50 ms.

d = abs(diff(rrMs(:)));
value = 100 * mean(d > 50);
end
