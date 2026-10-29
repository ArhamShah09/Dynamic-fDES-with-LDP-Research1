function features = dynamic_parameter_adjuster(rrMs, C)
%DYNAMIC_PARAMETER_ADJUSTER Phase 3: Adaptive parameter adjustment based on signal variance.

windowSize = 50;
stepSize = 10;

variances = calculate_rolling_variance(rrMs, windowSize, stepSize);
avgVariance = mean(variances);

dynamic_r = map_variance_to_r(avgVariance, C);
dynamic_alpha = map_variance_to_alpha(avgVariance, C);

features.tDES = tDES(rrMs, dynamic_r);
features.symDES = symDES(rrMs, C.mainNBins, C.symbolRangeMs);
features.triFDES = tri_fDES(rrMs, dynamic_r);
features.expFDES = exp_fDES(rrMs, dynamic_alpha);
features.pNN50 = pNN50(rrMs);

features.avgVariance = avgVariance;
features.dynamic_r = dynamic_r;
features.dynamic_alpha = dynamic_alpha;
end

function variances = calculate_rolling_variance(rrMs, windowSize, stepSize)
%CALCULATE_ROLLING_VARIANCE Compute variance in sliding windows.

rrMs = rrMs(:);
numWindows = floor((numel(rrMs) - windowSize) / stepSize) + 1;
variances = zeros(numWindows, 1);

for i = 1:numWindows
    startIdx = 1 + (i-1) * stepSize;
    endIdx = startIdx + windowSize - 1;
    window = rrMs(startIdx:endIdx);
    variances(i) = var(window);
end
end

function r = map_variance_to_r(avgVariance, C)
%MAP_VARIANCE_TO_R Map rolling variance to optimal threshold r.

minVar = 0.1;
maxVar = 500;
normalizedVar = (avgVariance - minVar) / (maxVar - minVar);
normalizedVar = max(0, min(1, normalizedVar));

r_min = 5;
r_max = 50;
r = r_min + normalizedVar * (r_max - r_min);
end

function alpha = map_variance_to_alpha(avgVariance, C)
%MAP_VARIANCE_TO_ALPHA Map rolling variance to optimal exponential decay constant.

minVar = 0.1;
maxVar = 500;
normalizedVar = (avgVariance - minVar) / (maxVar - minVar);
normalizedVar = max(0, min(1, normalizedVar));

alpha_min = 5;
alpha_max = 50;
alpha = alpha_max - normalizedVar * (alpha_max - alpha_min);
end

function visualize_dynamic_adjustment(subjects, C)
%VISUALIZE_DYNAMIC_ADJUSTMENT Plot dynamic parameter changes across subjects.

f = figure('Name', 'Dynamic Parameter Adjustment', 'NumberTitle', 'off', 'Color', 'w');
f.Position = [100 100 1200 600];

variances_by_subject = [];
groups = {};
for i = 1:numel(subjects)
    rr = subjects(i).RRms;
    windowSize = 50;
    stepSize = 10;
    var_vals = calculate_rolling_variance(rr, windowSize, stepSize);
    variances_by_subject = [variances_by_subject; mean(var_vals)];
    groups{i} = subjects(i).Group;
end

subplot(2, 3, 1);
boxplot(variances_by_subject, groups);
ylabel('Average Variance'); 
title('Signal Variance by Group'); 
grid on;

subplot(2, 3, 2);
r_values = zeros(numel(subjects), 1);
for i = 1:numel(subjects)
    r_values(i) = map_variance_to_r(variances_by_subject(i), C);
end
boxplot(r_values, groups);
ylabel('Dynamic r (ms)'); 
title('Dynamic Threshold r'); 
grid on;

subplot(2, 3, 3);
alpha_values = zeros(numel(subjects), 1);
for i = 1:numel(subjects)
    alpha_values(i) = map_variance_to_alpha(variances_by_subject(i), C);
end
boxplot(alpha_values, groups);
ylabel('Dynamic \alpha (s^{-1})'); 
title('Dynamic Alpha'); 
grid on;

subplot(2, 3, 4);
levels = {'Young', 'Elderly', 'CHF'};
colors = lines(3);
for g = 1:3
    mask = strcmp(groups, levels{g});
    scatter(variances_by_subject(mask), r_values(mask), 50, 'filled', 'DisplayName', levels{g});
    hold on;
end
xlabel('Average Variance'); 
ylabel('Dynamic r (ms)');
title('Variance-to-r Mapping'); 
grid on;
legend();

subplot(2, 3, 5);
for g = 1:3
    mask = strcmp(groups, levels{g});
    scatter(variances_by_subject(mask), alpha_values(mask), 50, 'filled', 'DisplayName', levels{g});
    hold on;
end
xlabel('Average Variance'); 
ylabel('Dynamic \alpha (s^{-1})');
title('Variance-to-Alpha Mapping'); 
grid on;
legend();

subplot(2, 3, 6);
hold on;
for i = 1:min(3, numel(subjects))
    f_static = compute_features(subjects(i).RRms, C);
    f_dynamic = dynamic_parameter_adjuster(subjects(i).RRms, C);
    scatter(f_static.expFDES, f_dynamic.expFDES, 80, 'filled');
end
plot([0 1], [0 1], 'k--', 'LineWidth', 1);
xlabel('Static exp-fDES'); 
ylabel('Dynamic exp-fDES');
title('Feature Comparison'); 
grid on; 
axis equal;

sgtitle('Dynamic Parameter Adjustment Analysis', 'FontSize', 14, 'FontWeight', 'bold');
end
