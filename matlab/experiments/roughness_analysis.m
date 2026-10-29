function roughT = roughness_analysis(sweep, subjects, C)
%ROUGHNESS_ANALYSIS Quantify parameter-curve roughness using second differences.

n = numel(subjects);
roughT = table({subjects.ID}', {subjects.Group}', zeros(n,1), zeros(n,1), zeros(n,1), ...
    'VariableNames', {'Subject','Group','tDES_Roughness','triFDES_Roughness','expFDES_Roughness'});
for i = 1:n
    roughT.tDES_Roughness(i) = mean(abs(diff(sweep.tDES(i,:),2)));
    roughT.triFDES_Roughness(i) = mean(abs(diff(sweep.triFDES(i,:),2)));
    roughT.expFDES_Roughness(i) = mean(abs(diff(sweep.expFDES(i,:),2)));
end
writetable(roughT, fullfile(C.resultsDir, 'roughness_summary.csv'));
end
