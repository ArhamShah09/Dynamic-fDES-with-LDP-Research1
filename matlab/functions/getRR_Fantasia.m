function rrMs = getRR_Fantasia(subjectID, C)
%GETRR_FANTASIA Load a Fantasia interbeat-interval text file.

path = fullfile(C.fantasiaDir, [subjectID '.txt']);
if ~isfile(path)
    error('getRR_Fantasia:MissingFile', ...
        'Missing %s. Put the Fantasia RR file in data/fantasia/.', path);
end
rrMs = cleanRR(readmatrix(path), C.minRRms, C.maxRRms);
end
