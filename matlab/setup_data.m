% SETUP_DATA Download the public RR subset and small CHF annotation files.
% This script downloads data to ../data. It does not install the WFDB Toolbox.

clear; clc;
C = config();
if ~isfolder(C.fantasiaDir), mkdir(C.fantasiaDir); end
if ~isfolder(C.chfDir), mkdir(C.chfDir); end

fantasiaBase = 'https://physionet.org/files/fantasia/1.0.0/subset/';
ids = [C.youngIDs C.elderlyIDs];
for i = 1:numel(ids)
    target = fullfile(C.fantasiaDir, [ids{i} '.txt']);
    if ~isfile(target)
        fprintf('Downloading %s...\n', ids{i});
        websave(target, [fantasiaBase ids{i} '.txt']);
    end
end

% The annotation and header allow the WFDB route; set chfInputMode to wfdb.
chfBase = 'https://physionet.org/files/chfdb/1.0.0/';
for i = 1:numel(C.chfIDs)
    for suffix = {'.hea','.ecg'}
        target = fullfile(C.chfDir, [C.chfIDs{i} suffix{1}]);
        if ~isfile(target)
            fprintf('Downloading %s%s...\n', C.chfIDs{i}, suffix{1});
            websave(target, [chfBase C.chfIDs{i} suffix{1}]);
        end
    end
end

fprintf(['Data download complete. Fantasia is ready. For CHF, install the WFDB MATLAB ' ...
    'Toolbox, set C.chfInputMode to ''wfdb'', then run main.\n']);
