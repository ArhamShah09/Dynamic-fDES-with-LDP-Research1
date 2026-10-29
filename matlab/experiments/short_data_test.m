function shortT = short_data_test(subjects, C)
%SHORT_DATA_TEST Evaluate feature stability across short segments and starts.

rows = {};
for i = 1:numel(subjects)
    rr = subjects(i).RRms;
    for n = C.shortLengths
        for start = C.shortStarts
            stop = start + n - 1;
            if stop <= numel(rr)
                f = compute_features(rr(start:stop), C);
                rows(end+1,:) = {subjects(i).ID, subjects(i).Group, n, start, ...
                    f.tDES, f.symDES, f.triFDES, f.expFDES, f.pNN50}; %#ok<AGROW>
            end
        end
    end
end
shortT = cell2table(rows, 'VariableNames', {'Subject','Group','Length','Start', ...
    'tDES','symDES','triFDES','expFDES','pNN50'});
writetable(shortT, fullfile(C.resultsDir, 'short_data_results.csv'));
end
