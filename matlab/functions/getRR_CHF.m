function rrMs = getRR_CHF(subjectID, C)
%GETRR_CHF Load CHF RR intervals from text, or derive them from WFDB annotations.

switch lower(C.chfInputMode)
    case 'rr_text'
        path = fullfile(C.chfDir, [subjectID '_rr.txt']);
        if ~isfile(path)
            error('getRR_CHF:MissingFile', ['Missing %s. Add a one-column RR file ' ...
                'or set C.chfInputMode to ''wfdb''.'], path);
        end
        rrMs = cleanRR(readmatrix(path), C.minRRms, C.maxRRms);

    case 'wfdb'
        recordPath = fullfile(C.chfDir, subjectID);
        if exist('rdann', 'file') ~= 2
            error('getRR_CHF:WFDBMissing', ['WFDB Toolbox function rdann was not found. ' ...
                'Install it or use RR text files.']);
        end
        [ann, type] = rdann(recordPath, 'ecg'); %#ok<ASGLU>
        % Retain beat annotations only. Confirm symbols against your local database.
        beatMask = ismember(type, ['N','L','R','A','V','F','j','E','a','J','S']);
        ann = ann(beatMask);
        rrMs = cleanRR(diff(ann(:)) ./ C.chfFs * 1000, C.minRRms, C.maxRRms);

    otherwise
        error('getRR_CHF:BadMode', 'C.chfInputMode must be rr_text or wfdb.');
end
end
