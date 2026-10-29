function [profileT, stabilityT] = laplace_profile_analysis(subjects, C)
%LAPLACE_PROFILE_ANALYSIS Export LDP descriptors and short-record stability.

n = numel(subjects);
subject = cell(n,1); group = cell(n,1);
scaleMs = zeros(n,1); auc = zeros(n,1); halfZ = zeros(n,1);
halfDms = zeros(n,1); decayRate = zeros(n,1); heterogeneity = zeros(n,1);
allProfiles = zeros(numel(C.laplaceZGrid), n);
for i = 1:n
    P = laplace_des_profile(subjects(i).RRms, C);
    subject{i} = subjects(i).ID; group{i} = subjects(i).Group;
    scaleMs(i) = P.scaleMs; auc(i) = P.auc; halfZ(i) = P.halfZ;
    halfDms(i) = P.halfDms; decayRate(i) = P.decayRate;
    heterogeneity(i) = P.heterogeneity; allProfiles(:,i) = P.values;
end
profileT = table(subject, group, scaleMs, auc, halfZ, halfDms, decayRate, heterogeneity, ...
    'VariableNames', {'Subject','Group','scaleMs','AUC','halfZ','halfDms','decayRate','heterogeneity'});
writetable(profileT, fullfile(C.resultsDir, 'laplace_des_profile_features.csv'));

lengths = C.laplaceShortLengths(:);
rows = n*numel(lengths);
subjectOut = cell(rows,1); groupOut = cell(rows,1); lengthOut = zeros(rows,1);
aucCV = zeros(rows,1); halfZCV = zeros(rows,1); heterogeneityCV = zeros(rows,1);
row = 0;
for i = 1:n
    rr = subjects(i).RRms(:);
    for j = 1:numel(lengths)
        segmentLength = min(lengths(j), numel(rr));
        values = zeros(C.laplaceBootstrapRepeats, 3);
        maximumStart = numel(rr) - segmentLength + 1;
        for b = 1:C.laplaceBootstrapRepeats
            start = randi(maximumStart);
            P = laplace_des_profile(rr(start:start+segmentLength-1), C);
            values(b,:) = [P.auc P.halfZ P.heterogeneity];
        end
        row = row + 1;
        subjectOut{row} = subjects(i).ID; groupOut{row} = subjects(i).Group;
        lengthOut(row) = segmentLength;
        aucCV(row) = local_cv(values(:,1));
        halfZCV(row) = local_cv(values(:,2));
        heterogeneityCV(row) = local_cv(values(:,3));
    end
end
stabilityT = table(subjectOut, groupOut, lengthOut, aucCV, halfZCV, heterogeneityCV, ...
    'VariableNames', {'Subject','Group','Length','AUC_CV','halfZ_CV','heterogeneity_CV'});
writetable(stabilityT, fullfile(C.resultsDir, 'laplace_des_short_record_stability.csv'));

local_plot_profiles(C, allProfiles, group, stabilityT);
end

function value = local_cv(x)
x = x(isfinite(x));
if isempty(x) || abs(mean(x)) <= eps
    value = NaN;
else
    value = std(x) / abs(mean(x));
end
end

function local_plot_profiles(C, allProfiles, groups, stabilityT)
figure('Name', 'Scale-normalized Laplace-DES profile', 'Color', 'w', ...
    'Position', [100 100 1100 450]);
subplot(1,2,1); hold on;
levels = {'Young','Elderly','CHF'}; colors = lines(3);
for g = 1:numel(levels)
    indices = strcmp(groups, levels{g});
    plot(C.laplaceZGrid, allProfiles(:,indices), 'Color', colors(g,:), ...
        'HandleVisibility', 'off');
    plot(C.laplaceZGrid, mean(allProfiles(:,indices),2), 'Color', colors(g,:), ...
        'LineWidth', 2, 'DisplayName', levels{g});
end
xlabel('Dimensionless decay z'); ylabel('L(z)');
title('Laplace-DES profiles'); legend('Location', 'northeast'); grid on;

subplot(1,2,2); hold on;
for g = 1:numel(levels)
    indices = strcmp(stabilityT.Group, levels{g});
    lengths = unique(stabilityT.Length(indices));
    y = arrayfun(@(x) mean(stabilityT.AUC_CV(indices & stabilityT.Length == x), 'omitnan'), lengths);
    plot(lengths, y, '-o', 'Color', colors(g,:), 'LineWidth', 1.5, 'DisplayName', levels{g});
end
set(gca, 'XScale', 'log'); xlabel('RR intervals per segment'); ylabel('AUC coefficient of variation');
title('Short-record stability'); legend('Location', 'northeast'); grid on;
print(gcf, fullfile(C.figureDir, 'fig08_laplace_des_profile.png'), '-dpng', '-r300');
end
