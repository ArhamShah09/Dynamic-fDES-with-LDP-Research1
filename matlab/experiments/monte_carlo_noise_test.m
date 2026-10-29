function mc_results = monte_carlo_noise_test(subjects, C)
%MONTE_CARLO_NOISE_TEST Compare feature error under RR-timing perturbations.
% The artifacts represent timing-level contamination; they are deliberately
% not ECG power-line signals, which cannot be meaningfully sampled once/beat.

fprintf('Starting Monte Carlo RR-perturbation evaluation...\n');
noiseProfiles = {'gaussian_jitter', 'ectopic_beats', 'missed_beats'};
snrLevels = [30 20 10 5];
numTrials = 50;
methods = {'tDES', 'symDES', 'triFDES', 'expFDES', 'pNN50', ...
    'LDP_auc', 'LDP_halfZ', 'LDP_heterogeneity'};

mc_results = struct();
mc_results.subjects = {subjects.ID}';
mc_results.groups = {subjects.Group}';
mc_results.snrLevels = snrLevels;
mc_results.noiseProfiles = noiseProfiles;
for m = 1:numel(methods)
    for n = 1:numel(noiseProfiles)
        mc_results.(sprintf('%s_%s', methods{m}, noiseProfiles{n})) = ...
            zeros(numel(subjects), numel(snrLevels));
    end
end

for i = 1:numel(subjects)
    rrClean = subjects(i).RRms;
    clean = compute_features(rrClean, C);
    fprintf('Subject %s: running perturbation tests...\n', subjects(i).ID);
    for n = 1:numel(noiseProfiles)
        profileName = noiseProfiles{n};
        accumulated = zeros(numel(methods), numel(snrLevels));
        for trial = 1:numTrials
            for s = 1:numel(snrLevels)
                rrNoisy = inject_rr_perturbation(rrClean, profileName, snrLevels(s), C);
                noisy = compute_features(rrNoisy, C);
                for m = 1:numel(methods)
                    method = methods{m};
                    accumulated(m,s) = accumulated(m,s) + ...
                        (clean.(method) - noisy.(method)).^2;
                end
            end
        end
        for m = 1:numel(methods)
            fieldName = sprintf('%s_%s', methods{m}, profileName);
            mc_results.(fieldName)(i,:) = accumulated(m,:) / numTrials;
        end
    end
end

save_monte_carlo_results(mc_results, methods, C);
end

function rrNoisy = inject_rr_perturbation(rrClean, profileName, snrDb, C)
rrNoisy = rrClean(:);
signalStd = std(rrNoisy);
noiseStd = max(eps, signalStd / sqrt(10^(snrDb/10)));
n = numel(rrNoisy);

switch profileName
    case 'gaussian_jitter'
        rrNoisy = rrNoisy + noiseStd * randn(n,1);
    case 'ectopic_beats'
        % Premature/late pairs preserve a plausible local timing total.
        rate = max(0.005, min(0.08, 0.005 + 0.075*(30-snrDb)/25));
        count = max(1, round(rate * floor(n/2)));
        starts = randperm(max(1, n-1), count);
        medianRR = median(rrNoisy);
        for k = 1:numel(starts)
            j = starts(k);
            if j < n
                deviation = max(0.08*medianRR, 2*noiseStd) * (0.7 + 0.6*rand);
                rrNoisy(j) = rrNoisy(j) - deviation;
                rrNoisy(j+1) = rrNoisy(j+1) + deviation;
            end
        end
    case 'missed_beats'
        % A missed R-peak produces a long interval, followed by recovery.
        rate = max(0.002, min(0.03, 0.002 + 0.028*(30-snrDb)/25));
        count = max(1, round(rate * floor(n/3)));
        starts = randperm(max(1, n-2), count);
        for k = 1:numel(starts)
            j = starts(k) + 1;
            if j < n
                transferred = 0.45 * rrNoisy(j-1);
                rrNoisy(j) = rrNoisy(j) + transferred;
                rrNoisy(j+1) = rrNoisy(j+1) - 0.5*transferred;
            end
        end
    otherwise
        error('Unknown perturbation profile: %s', profileName);
end
rrNoisy = max(C.minRRms, min(C.maxRRms, rrNoisy));
end

function save_monte_carlo_results(mcResults, methods, C)
fprintf('Saving perturbation results...\n');
for n = 1:numel(mcResults.noiseProfiles)
    profileName = mcResults.noiseProfiles{n};
    T = table(mcResults.subjects, mcResults.groups, ...
        'VariableNames', {'Subject', 'Group'});
    for m = 1:numel(methods)
        fieldName = sprintf('%s_%s', methods{m}, profileName);
        for s = 1:numel(mcResults.snrLevels)
            column = sprintf('%s_SNR%ddB', methods{m}, mcResults.snrLevels(s));
            T.(column) = mcResults.(fieldName)(:,s);
        end
    end
    writetable(T, fullfile(C.resultsDir, ...
        sprintf('monte_carlo_%s.csv', profileName)));
end
end
