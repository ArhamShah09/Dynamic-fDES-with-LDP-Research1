function sweep = parameter_sweep(subjects, C)
%PARAMETER_SWEEP Run tDES, triangular fDES, exponential fDES and symDES sweeps.

n = numel(subjects);
nr = numel(C.rValuesMs); na = numel(C.alphaValuesPerSecond); nb = numel(C.nBinsValues);
sweep.r = C.rValuesMs; sweep.alpha = C.alphaValuesPerSecond; sweep.nBins = C.nBinsValues;
sweep.tDES = zeros(n,nr); sweep.triFDES = zeros(n,nr);
sweep.expFDES = zeros(n,na); sweep.symDES = zeros(n,nb);
sweep.Group = cell(n,1);
for i = 1:n
    rr = subjects(i).RRms;
    sweep.Group{i} = subjects(i).Group;
    for j = 1:nr
        sweep.tDES(i,j) = tDES(rr, C.rValuesMs(j));
        sweep.triFDES(i,j) = tri_fDES(rr, C.rValuesMs(j));
    end
    for j = 1:na
        sweep.expFDES(i,j) = exp_fDES(rr, C.alphaValuesPerSecond(j));
    end
    for j = 1:nb
        sweep.symDES(i,j) = symDES(rr, C.nBinsValues(j), C.symbolRangeMs);
    end
end

write_sweep_csv(C.rValuesMs, sweep.tDES, subjects, 'sweep_tDES.csv', C);
write_sweep_csv(C.rValuesMs, sweep.triFDES, subjects, 'sweep_triFDES.csv', C);
write_sweep_csv(C.alphaValuesPerSecond, sweep.expFDES, subjects, 'sweep_expFDES.csv', C);
write_sweep_csv(C.nBinsValues, sweep.symDES, subjects, 'sweep_symDES.csv', C);
end

function write_sweep_csv(x, values, subjects, name, C)
T = array2table(values, 'VariableNames', strcat('P', string(x)));
T = addvars(T, {subjects.ID}', {subjects.Group}', 'Before', 1, ...
    'NewVariableNames', {'Subject','Group'});
writetable(T, fullfile(C.resultsDir, name));
end
