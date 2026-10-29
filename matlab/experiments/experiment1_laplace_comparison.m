function [comparisonT, summaryT, effectsT, statisticsT, percentageT] = experiment1_laplace_comparison(subjects, C)
%EXPERIMENT1_LAPLACE_COMPARISON Direct subject-level comparison of fDES and LDP.
% Computes fixed exp-fDES, normalized exp-fDES sweep area, and LDP descriptors.
% All inferential resampling is performed at subject level.

featureNames = {'fixed_expFDES','sweep_expFDES_AUC','LDP_AUC', ...
    'LDP_halfDms','LDP_heterogeneity'};
featureLabels = {'Fixed exp-fDES','exp-fDES sweep area','LDP profile area', ...
    'LDP half-decay (ms)','LDP heterogeneity'};
groups = {'Young','Elderly','CHF'};
n = numel(subjects);
subject = cell(n,1); group = cell(n,1); nRR = zeros(n,1);
values = zeros(n, numel(featureNames));

for i = 1:n
    rr = subjects(i).RRms(:);
    alpha = C.alphaValuesPerSecond(:)';
    expSweep = arrayfun(@(a) exp_fDES(rr, a), alpha);
    P = laplace_des_profile(rr, C);
    subject{i} = subjects(i).ID;
    group{i} = subjects(i).Group;
    nRR(i) = numel(rr);
    values(i,:) = [exp_fDES(rr, C.mainAlphaPerSecond), ...
        trapz(alpha, expSweep)/(alpha(end)-alpha(1)), ...
        P.auc, P.halfDms, P.heterogeneity];
end

comparisonT = table(subject, group, nRR, values(:,1), values(:,2), values(:,3), ...
    values(:,4), values(:,5), 'VariableNames', ...
    {'Subject','Group','RRIntervals','fixed_expFDES','sweep_expFDES_AUC', ...
     'LDP_AUC','LDP_halfDms','LDP_heterogeneity'});
writetable(comparisonT, fullfile(C.resultsDir, 'experiment1_comparison.csv'));

summaryT = local_group_summary(values, group, groups, featureNames, C);
writetable(summaryT, fullfile(C.resultsDir, 'experiment1_group_summary.csv'));

effectsT = local_pairwise_effects(values, group, groups, featureNames, C);
writetable(effectsT, fullfile(C.resultsDir, 'experiment1_pairwise_effects.csv'));

statisticsT = local_statistics(values, group, groups, featureNames, C);
writetable(statisticsT, fullfile(C.resultsDir, 'experiment1_statistics.csv'));

percentageT = local_percentage_summary(values, group, groups, featureNames);
writetable(percentageT, fullfile(C.resultsDir, 'experiment1_percentage_comparison.csv'));

local_plot(comparisonT, summaryT, groups, featureNames, featureLabels, C);
local_percentage_plot(percentageT, groups, featureNames, featureLabels, C);
end

function T = local_percentage_summary(values, group, groups, featureNames)
% Report each group mean relative to the Young mean for that feature.
rows = numel(groups)*numel(featureNames);
Group = cell(rows,1); Feature = cell(rows,1); YoungMean = zeros(rows,1);
GroupMean = zeros(rows,1); PercentOfYoungMean = zeros(rows,1);
PercentDifferenceFromYoung = zeros(rows,1);
for f = 1:numel(featureNames)
    young = values(strcmp(group, groups{1}), f);
    reference = mean(young);
    for g = 1:numel(groups)
        row = (f-1)*numel(groups)+g;
        current = values(strcmp(group, groups{g}), f);
        Group{row} = groups{g}; Feature{row} = featureNames{f};
        YoungMean(row) = reference; GroupMean(row) = mean(current);
        PercentOfYoungMean(row) = 100*mean(current)/max(abs(reference),eps);
        PercentDifferenceFromYoung(row) = 100*(mean(current)-reference)/max(abs(reference),eps);
    end
end
T = table(Group,Feature,YoungMean,GroupMean,PercentOfYoungMean, ...
    PercentDifferenceFromYoung);
end

function T = local_group_summary(values, group, groups, featureNames, C)
rows = numel(groups)*numel(featureNames);
Group = cell(rows,1); Feature = cell(rows,1); N = zeros(rows,1);
Mean = zeros(rows,1); Median = zeros(rows,1); SD = zeros(rows,1); CV = zeros(rows,1);
BootstrapCI95Low = zeros(rows,1); BootstrapCI95High = zeros(rows,1);
row = 0;
for g = 1:numel(groups)
    for f = 1:numel(featureNames)
        row = row + 1; x = values(strcmp(group,groups{g}),f);
        boot = local_bootstrap_mean(x, C.experiment1BootstrapRepeats);
        Group{row} = groups{g}; Feature{row} = featureNames{f}; N(row) = numel(x);
        Mean(row) = mean(x); Median(row) = median(x); SD(row) = std(x);
        CV(row) = std(x)/max(abs(mean(x)),eps);
        BootstrapCI95Low(row) = prctile(boot,2.5);
        BootstrapCI95High(row) = prctile(boot,97.5);
    end
end
T = table(Group,Feature,N,Mean,Median,SD,CV,BootstrapCI95Low,BootstrapCI95High);
end

function T = local_pairwise_effects(values, group, groups, featureNames, C)
pairs = [1 2;1 3;2 3]; rows = size(pairs,1)*numel(featureNames);
Feature = cell(rows,1); GroupA = cell(rows,1); GroupB = cell(rows,1);
MeanDifference_BminusA = zeros(rows,1); CohensD = zeros(rows,1);
DifferenceCI95Low = zeros(rows,1); DifferenceCI95High = zeros(rows,1);
CohensDCI95Low = zeros(rows,1); CohensDCI95High = zeros(rows,1); PermutationP = zeros(rows,1);
row = 0;
for p = 1:size(pairs,1)
    for f = 1:numel(featureNames)
        row = row+1;
        x = values(strcmp(group,groups{pairs(p,1)}),f);
        y = values(strcmp(group,groups{pairs(p,2)}),f);
        [difference, d] = local_effect(x,y);
        [bootDifference, bootD] = local_bootstrap_effect(x,y,C.experiment1BootstrapRepeats);
        Feature{row}=featureNames{f}; GroupA{row}=groups{pairs(p,1)}; GroupB{row}=groups{pairs(p,2)};
        MeanDifference_BminusA(row)=difference; CohensD(row)=d;
        DifferenceCI95Low(row)=prctile(bootDifference,2.5); DifferenceCI95High(row)=prctile(bootDifference,97.5);
        CohensDCI95Low(row)=prctile(bootD,2.5); CohensDCI95High(row)=prctile(bootD,97.5);
        PermutationP(row)=local_two_group_permutation_p(x,y,C.experiment1PermutationRepeats);
    end
end
PermutationP_FDR_BH = local_bh_adjust(PermutationP);
T = table(Feature,GroupA,GroupB,MeanDifference_BminusA,CohensD, ...
    DifferenceCI95Low,DifferenceCI95High,CohensDCI95Low,CohensDCI95High, ...
    PermutationP,PermutationP_FDR_BH);
end

function T = local_statistics(values, group, groups, featureNames, C)
rows = numel(featureNames); Feature = featureNames(:);
PermutationF = zeros(rows,1); OmnibusPermutationP = zeros(rows,1);
CorrelationWithFixed = NaN(rows,1); CorrelationP = NaN(rows,1);
for f = 1:rows
    [PermutationF(f),OmnibusPermutationP(f)] = local_oneway_permutation(values(:,f),group,groups,C.experiment1PermutationRepeats);
    if f > 1
        CorrelationWithFixed(f) = local_correlation(values(:,1),values(:,f));
        CorrelationP(f) = local_correlation_permutation_p(values(:,1),values(:,f),C.experiment1PermutationRepeats);
    end
end
OmnibusP_FDR_BH = local_bh_adjust(OmnibusPermutationP);
T = table(Feature,PermutationF,OmnibusPermutationP,OmnibusP_FDR_BH, ...
    CorrelationWithFixed,CorrelationP);
end

function boot = local_bootstrap_mean(x,repeats)
boot = zeros(repeats,1);
for b=1:repeats, boot(b)=mean(x(randi(numel(x),numel(x),1))); end
end

function [difference,d] = local_effect(x,y)
difference = mean(y)-mean(x);
pooledSD = sqrt(((numel(x)-1)*var(x)+(numel(y)-1)*var(y))/max(numel(x)+numel(y)-2,1));
d = difference/max(pooledSD,eps);
end

function [bootDifference,bootD] = local_bootstrap_effect(x,y,repeats)
bootDifference=zeros(repeats,1); bootD=zeros(repeats,1);
for b=1:repeats
    xb=x(randi(numel(x),numel(x),1)); yb=y(randi(numel(y),numel(y),1));
    [bootDifference(b),bootD(b)]=local_effect(xb,yb);
end
end

function p = local_two_group_permutation_p(x,y,repeats)
observed=abs(mean(y)-mean(x)); combined=[x(:);y(:)]; nx=numel(x); count=0;
for b=1:repeats
    shuffled=combined(randperm(numel(combined)));
    count=count+(abs(mean(shuffled(nx+1:end))-mean(shuffled(1:nx)))>=observed);
end
p=(count+1)/(repeats+1);
end

function [F,p] = local_oneway_permutation(x,group,groups,repeats)
F=local_pseudo_f(x,group,groups); count=0;
for b=1:repeats
    count=count+(local_pseudo_f(x,group(randperm(numel(group))),groups)>=F);
end
p=(count+1)/(repeats+1);
end

function F = local_pseudo_f(x,group,groups)
grand=mean(x); between=0; within=0;
for g=1:numel(groups)
    v=x(strcmp(group,groups{g})); between=between+numel(v)*(mean(v)-grand)^2;
    within=within+sum((v-mean(v)).^2);
end
F=(between/max(numel(groups)-1,1))/max(within/max(numel(x)-numel(groups),1),eps);
end

function r = local_correlation(x,y)
x=x(:); y=y(:); r=sum((x-mean(x)).*(y-mean(y)))/sqrt(sum((x-mean(x)).^2)*sum((y-mean(y)).^2));
end

function p = local_correlation_permutation_p(x,y,repeats)
observed=abs(local_correlation(x,y)); count=0;
for b=1:repeats, count=count+(abs(local_correlation(x,y(randperm(numel(y)))))>=observed); end
p=(count+1)/(repeats+1);
end

function adjusted = local_bh_adjust(p)
[sorted,order]=sort(p); n=numel(p); adjustedSorted=zeros(n,1);
for i=n:-1:1
    value=sorted(i)*n/i;
    if i<n, value=min(value,adjustedSorted(i+1)); end
    adjustedSorted(i)=min(value,1);
end
adjusted=zeros(n,1); adjusted(order)=adjustedSorted;
end

function local_plot(T,summaryT,groups,featureNames,featureLabels,C)
figure('Name','Experiment 1: fixed fDES versus LDP','Color','w','Position',[70 70 1400 800]);
colors=lines(numel(groups));
for f=1:numel(featureNames)
    subplot(2,3,f); hold on;
    for g=1:numel(groups)
        mask=strcmp(T.Group,groups{g}); x=g+(rand(sum(mask),1)-0.5)*0.14;
        scatter(x,T{mask,featureNames{f}},44,colors(g,:),'filled','DisplayName',groups{g});
        row=strcmp(summaryT.Group,groups{g}) & strcmp(summaryT.Feature,featureNames{f});
        m=summaryT.Mean(row); lo=summaryT.BootstrapCI95Low(row); hi=summaryT.BootstrapCI95High(row);
        errorbar(g,m,m-lo,hi-m,'k','LineWidth',1.5,'CapSize',7,'HandleVisibility','off');
    end
    xlim([0.5,numel(groups)+0.5]); set(gca,'XTick',1:numel(groups),'XTickLabel',groups);
    ylabel(featureLabels{f}); title(featureLabels{f}); grid on;
    if f==1, legend('Location','best'); end
end
subplot(2,3,6); axis off;
text(0,0.90,'Experiment 1: direct fDES and LDP comparison','FontSize',14,'FontWeight','bold');
text(0,0.72,sprintf('Fixed exponential fDES: alpha = %g s^{-1}',C.mainAlphaPerSecond),'FontSize',11);
text(0,0.58,'Points: individual subjects; error bars: bootstrap 95% CI of group mean','FontSize',10);
text(0,0.44,'Statistics: subject-level permutation tests and FDR correction','FontSize',10);
text(0,0.30,'This cohort has five subjects per group; interpret as feasibility evidence.','FontSize',10);
print(gcf,fullfile(C.figureDir,'fig09_experiment1_comparison.png'),'-dpng','-r300');
end

function local_percentage_plot(T,groups,featureNames,featureLabels,C)
figure('Name','Experiment 1: percentage comparison','Color','w', ...
    'Position',[100 100 1400 750]);
for f = 1:numel(featureNames)
    subplot(2,3,f);
    pct = zeros(1,numel(groups));
    for g = 1:numel(groups)
        row = strcmp(T.Group,groups{g}) & strcmp(T.Feature,featureNames{f});
        pct(g) = T.PercentOfYoungMean(row);
    end
    bar(1:numel(groups),pct,'FaceColor',[0.20 0.45 0.75]); hold on;
    yline(100,'k--','Young = 100%','LineWidth',1);
    set(gca,'XTick',1:numel(groups),'XTickLabel',groups);
    ylabel('% of Young-group mean'); title(featureLabels{f}); grid on;
    for g = 1:numel(groups)
        text(g,pct(g),sprintf(' %.1f%%',pct(g)),'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom','FontSize',9);
    end
end
subplot(2,3,6); axis off;
text(0,0.88,'Percentage comparison','FontSize',15,'FontWeight','bold');
text(0,0.68,'Each feature is normalized independently','FontSize',11);
text(0,0.54,'Young-group mean = 100%','FontSize',11);
text(0,0.40,'This permits fDES and LDP features with different units','FontSize',10);
text(0,0.26,'Values show relative group differences, not accuracy','FontSize',10);
print(gcf,fullfile(C.figureDir,'fig10_experiment1_percentage_comparison.png'),'-dpng','-r300');
end
