function statsTable = run_statistics(T, C)
%RUN_STATISTICS Subject-level one-way ANOVA and post-hoc CSV output.

methods = {'tDES','symDES','triFDES','expFDES','pNN50'};
statsTable = table(methods(:), nan(numel(methods),1), ...
    'VariableNames', {'Method','ANOVA_p'});

hasStatsToolbox = (exist('anova1', 'file') == 2 || exist('anova1', 'builtin') == 5 || exist('anova1', 'file') == 6);

for i = 1:numel(methods)
    values = T.(methods{i});
    if hasStatsToolbox
        [p,~,stats] = anova1(values, T.Group, 'off');
        statsTable.ANOVA_p(i) = p;
        if exist('multcompare', 'file') == 2 || exist('multcompare', 'builtin') == 5
            comparisons = multcompare(stats, 'Display', 'off');
            labels = stats.gnames;
            comparison = cell(size(comparisons,1),1);
            for k = 1:size(comparisons,1)
                comparison{k} = [labels{comparisons(k,1)} ' vs ' labels{comparisons(k,2)}];
            end
            posthoc = table(comparison, comparisons(:,6), ...
                'VariableNames', {'Comparison','Adjusted_p'});
            writetable(posthoc, fullfile(C.resultsDir, ['posthoc_' methods{i} '.csv']));
        end
    else
        % Native MATLAB fallback (no Statistics Toolbox required)
        [p, posthoc] = native_anova1(values, T.Group);
        statsTable.ANOVA_p(i) = p;
        if ~isempty(posthoc)
            writetable(posthoc, fullfile(C.resultsDir, ['posthoc_' methods{i} '.csv']));
        end
    end
end
writetable(statsTable, fullfile(C.resultsDir, 'anova_summary.csv'));
end

function [pVal, posthocTable] = native_anova1(y, group)
% NATIVE_ANOVA1 One-way ANOVA and pairwise comparisons with Bonferroni correction
% using core MATLAB built-in functions (betainc).
groups = unique(group);
k = numel(groups);
N = numel(y);

groupMeans = zeros(k, 1);
groupCounts = zeros(k, 1);
SS_within = 0;
grandMean = mean(y);

for g = 1:k
    mask = strcmp(group, groups{g});
    yg = y(mask);
    groupCounts(g) = numel(yg);
    groupMeans(g) = mean(yg);
    SS_within = SS_within + sum((yg - groupMeans(g)).^2);
end

SS_between = sum(groupCounts .* (groupMeans - grandMean).^2);
df_between = k - 1;
df_within = N - k;

MS_between = SS_between / df_between;
MS_within = SS_within / df_within;

if MS_within > 0
    F = MS_between / MS_within;
    x = (df_between * F) / (df_between * F + df_within);
    pVal = 1 - betainc(x, df_between / 2, df_within / 2);
else
    if MS_between == 0
        pVal = 1;
    else
        pVal = 0;
    end
end

% Pairwise post-hoc tests with Bonferroni correction
numPairs = k * (k - 1) / 2;
compNames = cell(numPairs, 1);
adjP = zeros(numPairs, 1);
idx = 1;

for g1 = 1:k
    for g2 = (g1+1):k
        compNames{idx} = sprintf('%s vs %s', groups{g1}, groups{g2});
        diffMean = abs(groupMeans(g1) - groupMeans(g2));
        se = sqrt(MS_within * (1/groupCounts(g1) + 1/groupCounts(g2)));
        if se > 0
            tStat = diffMean / se;
            xt = df_within / (df_within + tStat^2);
            rawP = betainc(xt, df_within / 2, 0.5);
            adjP(idx) = min(1, rawP * numPairs);
        else
            adjP(idx) = 1;
        end
        idx = idx + 1;
    end
end

posthocTable = table(compNames, adjP, 'VariableNames', {'Comparison', 'Adjusted_p'});
end
