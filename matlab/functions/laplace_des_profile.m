function profile = laplace_des_profile(rrMs, C)
%LAPLACE_DES_PROFILE Scale-normalized Laplace-DES fluctuation profile.
% Uses D = abs(diff(RR)) and L(z) = mean(exp(-z*D/s)), where s is a
% robust, strictly positive scale. z is dimensionless.

rrMs = rrMs(:);
d = abs(diff(rrMs));
d = d(isfinite(d));
if isempty(d)
    error('laplace_des_profile:InsufficientData', ...
        'At least two finite RR intervals are required.');
end

s = prctile(d, C.laplaceScalePercentile);
if ~isfinite(s) || s <= eps
    positiveD = d(d > eps);
    if isempty(positiveD)
        s = 1;
    else
        s = prctile(positiveD, C.laplaceScalePercentile);
    end
end

z = C.laplaceZGrid(:)';
values = mean(exp(-(d / s) * z), 1)';

% AUC is normalized by the profile-domain width, so it remains in [0, 1].
auc = trapz(z, values) / (z(end) - z(1));
halfZ = local_crossing(z, values, 0.5);
halfDms = halfZ * s;

% Departure from the best one-parameter exponential exp(-c*z).
% The origin constraint preserves the defining property L(0) = 1.
c = max(0, -sum(z(:) .* log(max(values, realmin))) / sum(z(:).^2));
singleExponential = exp(-c * z(:));
heterogeneity = trapz(z, (values - singleExponential).^2) / (z(end) - z(1));

profile = struct('z', z(:), 'values', values, 'scaleMs', s, ...
    'auc', auc, 'halfZ', halfZ, 'halfDms', halfDms, ...
    'decayRate', c, 'heterogeneity', heterogeneity, ...
    'meanAbsDiffMs', mean(d), 'nDifferences', numel(d));
end

function x = local_crossing(grid, values, target)
idx = find(values <= target, 1, 'first');
if isempty(idx)
    x = NaN;
elseif idx == 1
    x = grid(1);
else
    x = interp1(values(idx-1:idx), grid(idx-1:idx), target, 'linear');
end
end
