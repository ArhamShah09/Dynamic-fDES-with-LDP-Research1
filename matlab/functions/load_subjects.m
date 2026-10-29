function subjects = load_subjects(C, retainFullRecord)
%LOAD_SUBJECTS Load and clean configured subjects.
% retainFullRecord=false preserves the historical fixed-length baseline.
% retainFullRecord=true keeps the complete cleaned RR record for stability
% and perturbation experiments without changing the original baseline.
if nargin < 2
    retainFullRecord = false;
end

ids = [C.youngIDs, C.elderlyIDs, C.chfIDs];
groups = [repmat({'Young'}, 1, numel(C.youngIDs)), ...
          repmat({'Elderly'}, 1, numel(C.elderlyIDs)), ...
          repmat({'CHF'}, 1, numel(C.chfIDs))];
subjects = struct('ID', ids, 'Group', groups, 'RRms', cell(size(ids)));

for i = 1:numel(ids)
    if strcmp(groups{i}, 'CHF')
        rr = getRR_CHF(ids{i}, C);
    else
        rr = getRR_Fantasia(ids{i}, C);
    end
    if numel(rr) < C.segmentLength
        error('load_subjects:ShortRecord', '%s has %d RR intervals; %d are required.', ...
            ids{i}, numel(rr), C.segmentLength);
    end
    if retainFullRecord
        subjects(i).RRms = rr(:);
    else
        subjects(i).RRms = rr(1:C.segmentLength);
    end
end
end
