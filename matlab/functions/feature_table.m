function T = feature_table(subjects, C)
%FEATURE_TABLE Produce the subject-level main-results table.

n = numel(subjects);
subject = cell(n,1); group = cell(n,1);
t = zeros(n,1); s = zeros(n,1); tri = zeros(n,1); ex = zeros(n,1); p = zeros(n,1);
ldpScale = zeros(n,1); ldpAuc = zeros(n,1); ldpHalfZ = zeros(n,1);
ldpHalfDms = zeros(n,1); ldpRate = zeros(n,1); ldpHet = zeros(n,1);
for i = 1:n
    f = compute_features(subjects(i).RRms, C);
    subject{i} = subjects(i).ID;
    group{i} = subjects(i).Group;
    t(i) = f.tDES; s(i) = f.symDES; tri(i) = f.triFDES;
    ex(i) = f.expFDES; p(i) = f.pNN50;
    ldpScale(i) = f.LDP_scaleMs; ldpAuc(i) = f.LDP_auc;
    ldpHalfZ(i) = f.LDP_halfZ; ldpHalfDms(i) = f.LDP_halfDms;
    ldpRate(i) = f.LDP_decayRate; ldpHet(i) = f.LDP_heterogeneity;
end
T = table(subject, group, t, s, tri, ex, p, ldpScale, ldpAuc, ldpHalfZ, ...
    ldpHalfDms, ldpRate, ldpHet, 'VariableNames', ...
    {'Subject','Group','tDES','symDES','triFDES','expFDES','pNN50', ...
     'LDP_scaleMs','LDP_auc','LDP_halfZ','LDP_halfDms','LDP_decayRate','LDP_heterogeneity'});
end
