function value = tri_fDES(rrMs, rMs)
%TRI_FDES Triangular fuzzy distribution of equal states.

validateattributes(rMs, {'numeric'}, {'scalar','positive','finite'});
d = abs(diff(rrMs(:)));
membership = max(0, 1 - d ./ rMs);
value = mean(membership);
end
