% MAIN Run the complete Dynamic-fDES analysis framework.
% Prerequisite: follow ../README.md and place the RR data files first.
% 
% This implements the three-phase Dynamic-fDES framework:
% Phase 1: Core Algorithm Construction (baseline fDES)
% Phase 2: Statistical Noise Evaluation (Monte Carlo testing)
% Phase 3: Dynamic fDES Optimization (parameter adaptation)

clear; clc; close all;
C = config();
rng(C.randomSeed);
addpath(genpath(fullfile(C.matlabDir, 'functions')));
addpath(genpath(fullfile(C.matlabDir, 'experiments')));
if ~isfolder(C.resultsDir), mkdir(C.resultsDir); end
if ~isfolder(C.figureDir), mkdir(C.figureDir); end

fprintf('========================================\n');
fprintf('Dynamic-fDES Framework Analysis\n');
fprintf('========================================\n\n');

% ===== PHASE 1: Core Algorithm Construction =====
fprintf('[PHASE 1] Loading RR records and computing baseline features...\n');
subjects = load_subjects(C);

fprintf('[PHASE 1] Calculating subject-level main features (static parameters)...\n');
T = feature_table(subjects, C);
writetable(T, fullfile(C.resultsDir, 'main_features.csv'));

fprintf('[PHASE 1] Running subject-level ANOVA and post-hoc comparisons...\n');
run_statistics(T, C);

fprintf('[PHASE 1] Running parameter sweeps...\n');
sweep = parameter_sweep(subjects, C);

fprintf('[PHASE 1] Running boundary and short-data experiments...\n');
boundary_test(C);
shortT = short_data_test(subjects, C);
roughness_analysis(sweep, subjects, C);

fprintf('[PHASE 1] Computing scale-normalized Laplace-DES profiles...\n');
[T_laplace, T_laplace_stability] = laplace_profile_analysis(subjects, C);

fprintf('[PHASE 1] Running Experiment 1: fixed fDES versus LDP comparison...\n');
[T_experiment1, T_experiment1_summary, T_experiment1_effects, T_experiment1_statistics, ...
    T_experiment1_percentage] = ...
    experiment1_laplace_comparison(subjects, C);

% ===== RIGOROUS LDP EVALUATION =====
% Uses the unchanged baseline functions, full cleaned records only for
% stability/robustness, and leakage-controlled subject-level CV.
fprintf('\n[RIGOROUS] Running leakage-controlled LDP evaluation...\n');
rigorousLDP = run_rigorous_ldp_evaluation(C);

% ===== PHASE 2: Statistical Noise Evaluation (Monte Carlo) =====
fprintf('\n[PHASE 2] Starting Monte Carlo noise resilience evaluation...\n');
fprintf('[PHASE 2] This will inject synthetic noise and evaluate robustness...\n');
mc_results = monte_carlo_noise_test(subjects, C);

% ===== PHASE 3: Dynamic fDES Optimization =====
fprintf('\n[PHASE 3] Computing dynamic parameters based on signal variance...\n');
T_dynamic = table();
T_dynamic.Subject = T.Subject;
T_dynamic.Group = T.Group;

for i = 1:numel(subjects)
    f_dyn = dynamic_parameter_adjuster(subjects(i).RRms, C);
    T_dynamic.tDES_dynamic(i) = f_dyn.tDES;
    T_dynamic.symDES_dynamic(i) = f_dyn.symDES;
    T_dynamic.triFDES_dynamic(i) = f_dyn.triFDES;
    T_dynamic.expFDES_dynamic(i) = f_dyn.expFDES;
    T_dynamic.pNN50_dynamic(i) = f_dyn.pNN50;
    T_dynamic.avgVariance(i) = f_dyn.avgVariance;
    T_dynamic.dynamic_r(i) = f_dyn.dynamic_r;
    T_dynamic.dynamic_alpha(i) = f_dyn.dynamic_alpha;
end
writetable(T_dynamic, fullfile(C.resultsDir, 'dynamic_features.csv'));

fprintf('[PHASE 3] Visualizing dynamic parameter adjustments...\n');
% Call the visualization function from dynamic_parameter_adjuster module
fh = figure('Name', 'Dynamic Parameter Adjustment', 'NumberTitle', 'off', 'Color', 'w');
fh.Position = [100 100 1200 600];

% Calculate variance for all subjects
variances_by_subject = [];
groups_list = {};
for i = 1:numel(subjects)
    rr = subjects(i).RRms;
    windowSize = 50;
    stepSize = 10;
    var_vals = [];
    numWindows = floor((numel(rr) - windowSize) / stepSize) + 1;
    for j = 1:numWindows
        startIdx = 1 + (j-1) * stepSize;
        endIdx = startIdx + windowSize - 1;
        window = rr(startIdx:endIdx);
        var_vals = [var_vals; var(window)];
    end
    variances_by_subject = [variances_by_subject; mean(var_vals)];
    groups_list{i} = subjects(i).Group;
end

% Subplot 1: Variance distribution (scatter instead of boxplot - no toolbox needed)
subplot(2, 3, 1); hold on;
levels = {'Young', 'Elderly', 'CHF'};
colors = lines(3);
for g = 1:3
    mask = strcmp(groups_list, levels{g});
    y_pos = g + (rand(sum(mask),1)-0.5)*0.2; % Add jitter for visibility
    scatter(y_pos, variances_by_subject(mask), 50, colors(g,:), 'filled');
end
set(gca, 'XTick', 1:3, 'XTickLabel', levels);
ylabel('Average Variance'); title('Signal Variance by Group'); grid on;

% Subplot 2: Dynamic r distribution
subplot(2, 3, 2); hold on;
r_values = zeros(numel(subjects), 1);
for i = 1:numel(subjects)
    r_values(i) = map_var_to_r(variances_by_subject(i));
end
for g = 1:3
    mask = strcmp(groups_list, levels{g});
    y_pos = g + (rand(sum(mask),1)-0.5)*0.2;
    scatter(y_pos, r_values(mask), 50, colors(g,:), 'filled');
end
set(gca, 'XTick', 1:3, 'XTickLabel', levels);
ylabel('Dynamic r (ms)'); title('Dynamic Threshold r'); grid on;

% Subplot 3: Dynamic alpha distribution
subplot(2, 3, 3); hold on;
alpha_values = zeros(numel(subjects), 1);
for i = 1:numel(subjects)
    alpha_values(i) = map_var_to_alpha(variances_by_subject(i));
end
for g = 1:3
    mask = strcmp(groups_list, levels{g});
    y_pos = g + (rand(sum(mask),1)-0.5)*0.2;
    scatter(y_pos, alpha_values(mask), 50, colors(g,:), 'filled');
end
set(gca, 'XTick', 1:3, 'XTickLabel', levels);
ylabel('Dynamic \alpha (s^{-1})'); title('Dynamic Alpha'); grid on;

% Subplot 4: Variance vs r scatter
subplot(2, 3, 4); hold on;
for g = 1:3
    mask = strcmp(groups_list, levels{g});
    scatter(variances_by_subject(mask), r_values(mask), 50, colors(g,:), 'filled', 'DisplayName', levels{g});
end
xlabel('Average Variance'); ylabel('Dynamic r (ms)'); title('Variance-to-r Mapping'); grid on; legend();

% Subplot 5: Variance vs alpha scatter
subplot(2, 3, 5); hold on;
for g = 1:3
    mask = strcmp(groups_list, levels{g});
    scatter(variances_by_subject(mask), alpha_values(mask), 50, colors(g,:), 'filled', 'DisplayName', levels{g});
end
xlabel('Average Variance'); ylabel('Dynamic \alpha (s^{-1})'); title('Variance-to-Alpha Mapping'); grid on; legend();

% Subplot 6: Before/After feature comparison
subplot(2, 3, 6); hold on;
for i = 1:min(5, numel(subjects))
    f_static = compute_features(subjects(i).RRms, C);
    f_dynamic = dynamic_parameter_adjuster(subjects(i).RRms, C);
    scatter(f_static.expFDES, f_dynamic.expFDES, 80, 'filled');
end
plot([0 1], [0 1], 'k--', 'LineWidth', 1); xlabel('Static exp-fDES'); ylabel('Dynamic exp-fDES'); title('Feature Comparison'); grid on;

sgtitle('Dynamic Parameter Adjustment Analysis', 'FontSize', 14, 'FontWeight', 'bold');
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, fullfile(C.figureDir, 'fig07_dynamic_parameters.png'), '-dpng', '-r300');

% ===== UNIFIED VISUALIZATION =====
fprintf('\nCreating unified dashboard with all plots...\n');
plot_all_results(T, sweep, shortT, C);

% ===== SAVE RESULTS =====
save(fullfile(C.resultsDir, 'analysis_workspace.mat'), 'C', 'subjects', 'T', 'sweep', 'shortT', ...
    'mc_results', 'T_dynamic', 'T_laplace', 'T_laplace_stability', ...
    'T_experiment1', 'T_experiment1_summary', 'T_experiment1_effects', ...
    'T_experiment1_statistics', 'T_experiment1_percentage', 'rigorousLDP');

fprintf('\n========================================\n');
fprintf('Analysis Complete!\n');
fprintf('========================================\n');
fprintf('Results saved to: %s\n', C.resultsDir);
fprintf('Figures saved to: %s\n', C.figureDir);
fprintf('\nKey outputs:\n');
fprintf('  - main_features.csv          (static baseline features)\n');
fprintf('  - dynamic_features.csv       (adaptive features)\n');
fprintf('  - laplace_des_profile_features.csv (scale-normalized profile features)\n');
fprintf('  - laplace_des_short_record_stability.csv (short-record uncertainty)\n');
fprintf('  - monte_carlo_*.csv          (RR-perturbation robustness data)\n');
fprintf('  - fig00_unified_dashboard.png (comprehensive dashboard)\n');
fprintf('  - fig07_dynamic_parameters.png (parameter adaptation analysis)\n');
fprintf('  - fig08_laplace_des_profile.png (LDP profiles and stability)\n');
fprintf('  - experiment1_comparison.csv (fixed fDES versus LDP)\n');
fprintf('  - experiment1_group_summary.csv (bootstrap confidence intervals)\n');
fprintf('  - experiment1_pairwise_effects.csv (Cohen''s d comparisons)\n');
fprintf('  - experiment1_statistics.csv (permutation tests and FDR correction)\n');
fprintf('  - experiment1_percentage_comparison.csv (percentage-wise comparison)\n');
fprintf('  - fig09_experiment1_comparison.png (comparison figure)\n');
fprintf('  - fig10_experiment1_percentage_comparison.png (percentage figure)\n');
fprintf('  - rigorous_ldp_report.md (final evidence-based verdict)\n');
fprintf('  - rigorous_auc_results.csv and rigorous_paired_auc_differences.csv\n');
fprintf('  - rigorous_stability_summary.csv and rigorous_robustness_summary.csv\n');
fprintf('========================================\n');

% Helper functions for dynamic parameter mapping
function r = map_var_to_r(avgVariance)
    minVar = 0.1;
    maxVar = 500;
    normalizedVar = (avgVariance - minVar) / (maxVar - minVar);
    normalizedVar = max(0, min(1, normalizedVar));
    r_min = 5;
    r_max = 50;
    r = r_min + normalizedVar * (r_max - r_min);
end

function alpha = map_var_to_alpha(avgVariance)
    minVar = 0.1;
    maxVar = 500;
    normalizedVar = (avgVariance - minVar) / (maxVar - minVar);
    normalizedVar = max(0, min(1, normalizedVar));
    alpha_min = 5;
    alpha_max = 50;
    alpha = alpha_max - normalizedVar * (alpha_max - alpha_min);
end
