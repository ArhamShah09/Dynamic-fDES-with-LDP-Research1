function R = run_rigorous_ldp_evaluation(C)
%RUN_RIGOROUS_LDP_EVALUATION Leakage-controlled LDP versus fDES evaluation.
% The original exp_fDES.m is intentionally unchanged.
% D_i=abs(diff(RR_i)) [ms]; s=positive robust scale [ms].
% L(z)=mean(exp(-z*D_i/s)), z dimensionless.
% LDP_AUC is normalized profile area [dimensionless], LDP_halfDms is [ms],
% and LDP_heterogeneity is the normalized residual from one exponential.

if nargin < 1, C = config(); end
if ~isfolder(C.resultsDir), mkdir(C.resultsDir); end
if ~isfolder(C.figureDir), mkdir(C.figureDir); end
rng(C.randomSeed + 701, 'twister');
fprintf('[RIGOROUS] Loading full cleaned records...\n');
subjects = load_subjects(C, true);
base = load_subjects(C, false);
[X, featureT] = local_features(base, C);
writetable(featureT, fullfile(C.resultsDir,'rigorous_subject_features.csv'));

fprintf('[RIGOROUS] Nested subject-level cross-validation...\n');
[aucT,diffT,rocT,selectT,macroT] = local_cv(base,X,C);
writetable(aucT,fullfile(C.resultsDir,'rigorous_auc_results.csv'));
writetable(macroT,fullfile(C.resultsDir,'rigorous_macro_auc_results.csv'));
writetable(diffT,fullfile(C.resultsDir,'rigorous_paired_auc_differences.csv'));
writetable(rocT,fullfile(C.resultsDir,'rigorous_oof_scores.csv'));
writetable(selectT,fullfile(C.resultsDir,'rigorous_parameter_selection.csv'));

fprintf('[RIGOROUS] Short-record stability...\n');
stability = local_stability(subjects,C);
stabilitySummary = local_stability_summary(stability,C);
writetable(stability,fullfile(C.resultsDir,'rigorous_stability_subject.csv'));
writetable(stabilitySummary,fullfile(C.resultsDir,'rigorous_stability_summary.csv'));

fprintf('[RIGOROUS] Perturbation robustness...\n');
robust = local_robustness(base,C);
robustSummary = local_robustness_summary(robust,C);
writetable(robust,fullfile(C.resultsDir,'rigorous_robustness_subject.csv'));
writetable(robustSummary,fullfile(C.resultsDir,'rigorous_robustness_summary.csv'));

sensitivity = local_sensitivity(base,C);
writetable(sensitivity,fullfile(C.resultsDir,'rigorous_sensitivity.csv'));
local_figures(aucT,diffT,rocT,stabilitySummary,robustSummary,featureT,C);
report = fullfile(C.resultsDir,'rigorous_ldp_report.md');
local_report(report,subjects,C);
R = struct('AUC',aucT,'macroAUC',macroT,'pairedAUC',diffT,'OOF',rocT,'selection',selectT, ...
    'stability',stability,'stabilitySummary',stabilitySummary, ...
    'robustness',robust,'robustnessSummary',robustSummary, ...
    'sensitivity',sensitivity,'features',featureT,'report',report);
save(fullfile(C.resultsDir,'rigorous_ldp_results.mat'),'R','C','-v7.3');
fprintf('[RIGOROUS] Complete. Report: %s\n',report);
end

function [X,T] = local_features(S,C)
n=numel(S); X=zeros(n,5); id=cell(n,1); gr=cell(n,1); nr=zeros(n,1);
for i=1:n
    rr=S(i).RRms(:); a=C.alphaValuesPerSecond(:)'; v=arrayfun(@(q)exp_fDES(rr,q),a); P=laplace_des_profile(rr,C);
    X(i,:)=[exp_fDES(rr,C.mainAlphaPerSecond),trapz(a,v)/(a(end)-a(1)),P.auc,P.halfDms,P.heterogeneity];
    id{i}=S(i).ID; gr{i}=S(i).Group; nr(i)=numel(rr);
end
T=table(id,gr,nr,X(:,1),X(:,2),X(:,3),X(:,4),X(:,5), ...
    'VariableNames',{'Subject','Group','RRIntervals','fixed_expFDES','sweep_expFDES_AUC','LDP_AUC','LDP_halfDms','LDP_heterogeneity'});
end

function [AT,DT,RT,ST,MT] = local_cv(S,X,C)
groups={'Young','Elderly','CHF'}; pairs=[1 2;1 3;2 3];
methods={'fixed_expFDES','best_expFDES','sweep_expFDES_AUC','LDP_AUC','LDP_halfDms','LDP_heterogeneity','LDP_all','fDES_plus_LDP'};
ar={}; dr={}; rr={}; sr={};
for p=1:size(pairs,1)
    ga=groups{pairs(p,1)}; gb=groups{pairs(p,2)}; ia=find(strcmp({S.Group},ga)); ib=find(strcmp({S.Group},gb));
    folds=local_folds(ia,ib,C.rigorousOuterFolds); scores=cell(numel(methods),1); for m=1:numel(methods),scores{m}=[];end; y=[]; ids={}; selected=[];
    for f=1:numel(folds)
        te=folds{f}; tr=setdiff([ia ib],te); alpha=local_alpha(tr(strcmp({S(tr).Group},ga)),tr(strcmp({S(tr).Group},gb)),S,C); selected(end+1)=alpha;
        best=zeros(numel(S),1); for j=[ia ib],best(j)=exp_fDES(S(j).RRms,alpha);end
        z={X(:,1),best,X(:,2),X(:,3),X(:,4),X(:,5)};
        z{7}=X(:,3:5); z{8}=X(:,[1 2 3:5]);
        fold={local_score(z{1},tr,te,S,ga,gb),local_score(z{2},tr,te,S,ga,gb),local_score(z{3},tr,te,S,ga,gb),local_score(z{4},tr,te,S,ga,gb),local_score(z{5},tr,te,S,ga,gb),local_score(z{6},tr,te,S,ga,gb),local_multi(z{7},tr,te,S,ga,gb),local_multi(z{8},tr,te,S,ga,gb)};
        yy=double(strcmp({S(te).Group},gb))'; y=[y;yy]; ids=[ids,{S(te).ID}];
        for m=1:numel(methods),scores{m}=[scores{m};fold{m}];end
    end
    for m=1:numel(methods)
        [lo,hi]=local_auc_ci(y,scores{m},C.rigorousBootstrapRepeats); ar(end+1,:)={ga,gb,methods{m},sum(y==0),sum(y==1),local_auc(y,scores{m}),lo,hi,mean(selected),mean(selected==min(C.alphaValuesPerSecond)|selected==max(C.alphaValuesPerSecond))}; %#ok<AGROW>
        for k=1:numel(y),rr(end+1,:)={ga,gb,methods{m},ids{k},y(k),scores{m}(k)};end %#ok<AGROW>
    end
    for m=2:numel(methods), [lo,hi]=local_diff_ci(y,scores{1},scores{m},C.rigorousBootstrapRepeats); dr(end+1,:)={ga,gb,methods{m},local_auc(y,scores{m})-local_auc(y,scores{1}),lo,hi,local_perm(y,scores{1},scores{m},C.rigorousPermutationRepeats)};end %#ok<AGROW>
    sr(end+1,:)={ga,gb,mean(selected),min(selected),max(selected),mean(selected==min(C.alphaValuesPerSecond)|selected==max(C.alphaValuesPerSecond))}; %#ok<AGROW>
end
AT=cell2table(ar,'VariableNames',{'GroupA','GroupB','Method','N_A','N_B','AUC','CI95Low','CI95High','MeanSelectedAlpha','BoundaryRate'});
DT=cell2table(dr,'VariableNames',{'GroupA','GroupB','Method','AUC_Difference_vs_fixed','CI95Low','CI95High','PermutationP'}); DT.P_FDR_BH=bh(DT.PermutationP);
RT=cell2table(rr,'VariableNames',{'GroupA','GroupB','Method','Subject','Label','Score'});
ST=cell2table(sr,'VariableNames',{'GroupA','GroupB','MeanSelectedAlpha','MinSelectedAlpha','MaxSelectedAlpha','BoundaryRate'});
macro={};
for m=1:numel(methods)
    q=strcmp(AT.Method,methods{m}); macro(end+1,:)={methods{m},mean(AT.AUC(q)),mean(AT.CI95Low(q)),mean(AT.CI95High(q))}; %#ok<AGROW>
end
MT=cell2table(macro,'VariableNames',{'Method','MacroAUC','ApproxCI95Low','ApproxCI95High'});
end

function folds=local_folds(a,b,K)
K=min([K,numel(a),numel(b)]); folds=cell(K,1); for k=1:K,folds{k}=[a(mod((0:numel(a)-1),K)+1==k),b(mod((0:numel(b)-1),K)+1==k)];end
end
function alpha=local_alpha(a,b,S,C)
vals=C.alphaValuesPerSecond(:)'; folds=local_folds(a,b,min(C.rigorousInnerFolds,numel(a))); best=-Inf;alpha=vals(1); ga=S(a(1)).Group;gb=S(b(1)).Group;
for q=vals,sc=[];yy=[];for k=1:numel(folds),te=folds{k};tr=setdiff([a b],te);v=zeros(numel(S),1);for j=[a b],v(j)=exp_fDES(S(j).RRms,q);end;sc=[sc;local_score(v,tr,te,S,ga,gb)];yy=[yy;double(strcmp({S(te).Group},gb))'];end;u=local_auc(yy,sc);if u>best,best=u;alpha=q;end;end
end
function s=local_score(v,tr,te,S,ga,gb)
mu=mean(v(tr),'omitnan');sd=std(v(tr),'omitnan');if ~isfinite(sd)||sd<eps,sd=1;end;z=(v-mu)/sd;a=strcmp({S(tr).Group},ga);b=strcmp({S(tr).Group},gb);ca=mean(z(tr(a)));cb=mean(z(tr(b)));s=(z(te)-ca).^2-(z(te)-cb).^2;
end
function s=local_multi(v,tr,te,S,ga,gb)
mu=mean(v(tr,:),1);sd=std(v(tr,:),0,1);sd(sd<eps|~isfinite(sd))=1;z=(v-mu)./sd;a=strcmp({S(tr).Group},ga);b=strcmp({S(tr).Group},gb);ca=mean(z(tr(a),:),1);cb=mean(z(tr(b),:),1);s=sum((z(te,:)-ca).^2,2)-sum((z(te,:)-cb).^2,2);
end

function T=local_stability(S,C)
methods={'expFDES','LDP_AUC','LDP_halfDms','LDP_heterogeneity'};rows={};
for i=1:numel(S),rr=S(i).RRms(:);for L=C.laplaceShortLengths,if numel(rr)<L,continue;end;v=zeros(C.rigorousStabilityRepeats,4);st=randi(numel(rr)-L+1,C.rigorousStabilityRepeats,1);for b=1:numel(st),q=rr(st(b):st(b)+L-1);P=laplace_des_profile(q,C);v(b,:)=[exp_fDES(q,C.mainAlphaPerSecond),P.auc,P.halfDms,P.heterogeneity];end;for m=1:4,x=v(:,m);rows(end+1,:)={S(i).ID,S(i).Group,L,methods{m},mean(x),std(x),std(x)/max(abs(mean(x)),eps)};end;end;end
T=cell2table(rows,'VariableNames',{'Subject','Group','Length','Method','Mean','SD','CV'});
end
function T=local_stability_summary(S,C)
G=unique(S.Group,'stable');M=unique(S.Method,'stable');rows={};
for L=unique(S.Length)',for g=1:numel(G),for m=1:numel(M),x=S.CV(S.Length==L&strcmp(S.Group,G{g})&strcmp(S.Method,M{m}));[lo,hi]=bootmean(x,C.rigorousBootstrapRepeats);rows(end+1,:)={G{g},L,M{m},mean(x),lo,hi};end;end;end
T=cell2table(rows,'VariableNames',{'Group','Length','Method','MeanCV','CI95Low','CI95High'});
end

function T=local_robustness(S,C)
methods={'expFDES','LDP_AUC','LDP_halfDms','LDP_heterogeneity'};modes={'jitter','ectopic','missed'};rows={};
for i=1:numel(S),rr=S(i).RRms(:);clean=method_values(rr,C);for q=1:numel(C.rigorousErrorRates),rate=C.rigorousErrorRates(q);for h=1:numel(modes),e=zeros(C.rigorousRobustnessRepeats,4);for b=1:size(e,1),z=perturb(rr,modes{h},rate,C.rigorousJitterMs(min(q,numel(C.rigorousJitterMs))),C);e(b,:)=abs((method_values(z,C)-clean)./max(abs(clean),1e-9));end;for m=1:4,rows(end+1,:)={S(i).ID,S(i).Group,modes{h},rate,methods{m},mean(e(:,m)),std(e(:,m))};end;end;end;end
T=cell2table(rows,'VariableNames',{'Subject','Group','Perturbation','Severity','Method','RelativeErrorMean','RelativeErrorSD'});
end
function v=method_values(rr,C),P=laplace_des_profile(rr,C);v=[exp_fDES(rr,C.mainAlphaPerSecond),P.auc,P.halfDms,P.heterogeneity];end
function x=perturb(x,mode,rate,jit,C)
switch mode,case 'jitter',x=x+jit*randn(size(x));case 'ectopic',n=round(rate*numel(x));if n>0,ix=randperm(numel(x),min(n,numel(x)));x(ix)=x(ix)+0.25*mean(x);end;case 'missed',n=round(rate*(numel(x)-1));if n>0,ix=sort(randperm(numel(x)-1,min(n,numel(x)-1)));keep=true(numel(x),1);keep(ix+1)=false;x=x(keep);end;end;x=min(max(x,C.minRRms),C.maxRRms);
end
function T=local_robustness_summary(S,C)
P=unique(S.Perturbation,'stable');M=unique(S.Method,'stable');rows={};for p=1:numel(P),for q=unique(S.Severity)',for m=1:numel(M),x=S.RelativeErrorMean(strcmp(S.Perturbation,P{p})&S.Severity==q&strcmp(S.Method,M{m}));[lo,hi]=bootmean(x,C.rigorousBootstrapRepeats);rows(end+1,:)={P{p},q,M{m},mean(x),lo,hi};end;end;end;T=cell2table(rows,'VariableNames',{'Perturbation','Severity','Method','MeanRelativeError','CI95Low','CI95High'});
end

function T=local_sensitivity(S,C)
rows={};for i=1:numel(S),P=laplace_des_profile(S(i).RRms,C);for q=[0.5 2 10],Q=laplace_des_profile(S(i).RRms*q,C);rows(end+1,:)={S(i).ID,q,abs(P.auc-Q.auc),abs(P.heterogeneity-Q.heterogeneity),Q.halfDms/P.halfDms};end;end;T=cell2table(rows,'VariableNames',{'Subject','ScaleFactor','AbsAucChange','AbsHeterogeneityChange','HalfDecayRatio'});
end

function [lo,hi]=bootmean(x,n),b=zeros(n,1);for k=1:n,b(k)=mean(x(randi(numel(x),numel(x),1)));end;lo=prctile(b,2.5);hi=prctile(b,97.5);end
function [lo,hi]=local_auc_ci(y,s,n),b=zeros(n,1);a=find(y==0);c=find(y==1);for k=1:n,ix=[a(randi(numel(a),numel(a),1));c(randi(numel(c),numel(c),1))];b(k)=local_auc(y(ix),s(ix));end;lo=prctile(b,2.5);hi=prctile(b,97.5);end
function [lo,hi]=local_diff_ci(y,a,b,n),d=zeros(n,1);i=find(y==0);j=find(y==1);for k=1:n,ix=[i(randi(numel(i),numel(i),1));j(randi(numel(j),numel(j),1))];d(k)=local_auc(y(ix),b(ix))-local_auc(y(ix),a(ix));end;lo=prctile(d,2.5);hi=prctile(d,97.5);end
function p=local_perm(y,a,b,n),o=abs(local_auc(y,b)-local_auc(y,a));c=0;for k=1:n,z=y(randperm(numel(y)));c=c+(abs(local_auc(z,b)-local_auc(z,a))>=o);end;p=(c+1)/(n+1);end
function a=local_auc(y,s),[~,o]=sort(s);r=zeros(size(y));r(o)=1:numel(y);n1=sum(y==1);n0=sum(y==0);a=(sum(r(y==1))-n1*(n1+1)/2)/max(n1*n0,1);end
function q=bh(p),[s,o]=sort(p);z=zeros(size(s));for i=numel(s):-1:1,z(i)=min(1,s(i)*numel(s)/i);if i<numel(s),z(i)=min(z(i),z(i+1));end;end;q=zeros(size(p));q(o)=z;end

function local_figures(A,D,R,S,B,F,C)
try
 f=figure('Color','w','Position',[50 50 1500 800]);pairs=unique(strcat(A.GroupA,' vs ',A.GroupB),'stable');M=unique(A.Method,'stable');for p=1:numel(pairs),subplot(1,3,p);hold on;for m=1:numel(M),ix=strcmp(strcat(R.GroupA,' vs ',R.GroupB),pairs{p})&strcmp(R.Method,M{m});[x,y]=roc(R.Label(ix),R.Score(ix));aa=A.AUC(strcmp(strcat(A.GroupA,' vs ',A.GroupB),pairs{p})&strcmp(A.Method,M{m}));plot(x,y,'DisplayName',sprintf('%s %.3f',M{m},aa),'LineWidth',1.2);end;plot([0 1],[0 1],'k--');title(pairs{p});xlabel('FPR');ylabel('TPR');legend('Location','southeast');grid on;end;print(f,fullfile(C.figureDir,'fig11_rigorous_roc_auc.png'),'-dpng','-r300');close(f);
 f=figure('Color','w');x=1:height(D);bar(x,D.AUC_Difference_vs_fixed);set(gca,'XTick',x,'XTickLabel',strcat(D.GroupA,' vs ',D.GroupB),'XTickLabelRotation',35);ylabel('AUC difference vs fixed fDES');grid on;print(f,fullfile(C.figureDir,'fig12_paired_auc_differences.png'),'-dpng','-r300');close(f);
 f=figure('Color','w');gscatter(S.Length,S.MeanCV,S.Method);xlabel('RR intervals');ylabel('CV');grid on;print(f,fullfile(C.figureDir,'fig13_short_record_cv.png'),'-dpng','-r300');close(f);
 f=figure('Color','w');gscatter(B.Severity,B.MeanRelativeError,B.Method);xlabel('Severity');ylabel('Relative error');grid on;print(f,fullfile(C.figureDir,'fig14_robustness.png'),'-dpng','-r300');close(f);
 f=figure('Color','w');gscatter(F.LDP_AUC,F.LDP_heterogeneity,F.Group);xlabel('LDP area');ylabel('LDP heterogeneity');grid on;print(f,fullfile(C.figureDir,'fig15_ldp_features.png'),'-dpng','-r300');close(f);
catch ME
    if exist('f','var') && isgraphics(f), close(f); end
    warning('LDP:Figures','Figure generation warning: %s',ME.message);
end
end
function [x,y]=roc(l,s),[s,o]=sort(s,'descend');l=l(o);P=max(sum(l==1),1);N=max(sum(l==0),1);x=[0;cumsum(l==0)/N];y=[0;cumsum(l==1)/P];end
function local_report(path,S,C)
fid=fopen(path,'w');fprintf(fid,'# Rigorous LDP versus exponential fDES\n\n');fprintf(fid,'Subjects: %d; groups: Young=%d, Elderly=%d, CHF=%d.\n\n',numel(S),sum(strcmp({S.Group},'Young')),sum(strcmp({S.Group},'Elderly')),sum(strcmp({S.Group},'CHF')));fprintf(fid,'## Definitions\n\nD_i=|RR_{i+1}-RR_i| in ms. The LDP uses a positive 75th-percentile scale s and L(z)=mean(exp(-zD_i/s)), where z is dimensionless. Area is normalized by the z-grid width; half-decay is in ms; heterogeneity is normalized squared residual from the best exp(-c z). Original exp-fDES remains mean(exp(-alpha D_i/1000)), alpha in s^-1.\n\n## Statistical design\n\nDiscrimination uses subject-level stratified %d-fold outer CV. Best alpha is selected only on training subjects by inner CV. Bootstrap CIs resample subjects within class; paired permutation tests and BH-FDR are reported. Stability uses repeated valid contiguous segments at 50, 100, 200, 500, and 1000 intervals. Robustness uses RR jitter and controlled ectopic/missed-beat perturbations.\n\n## Honest interpretation\n\nPositive paired AUC differences favor LDP; negative values favor fixed fDES. The cohort has only 10 subjects per group, so inference is feasibility evidence. The final verdict must be read from rigorous_auc_results.csv, rigorous_paired_auc_differences.csv, rigorous_stability_summary.csv, and rigorous_robustness_summary.csv; no winner is assumed. Parameter-bound saturation is explicitly recorded in rigorous_parameter_selection.csv.\n',C.rigorousOuterFolds);fclose(fid);
end
