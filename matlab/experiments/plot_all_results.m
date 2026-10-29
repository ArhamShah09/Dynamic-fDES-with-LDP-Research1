function plot_all_results(T, sweep, shortT, C)
%PLOT_ALL_RESULTS Create a unified dashboard with all plots in one figure window.
% NO SEPARATE FIGURES - ONLY UNIFIED DASHBOARD

% Create main dashboard figure with larger size
f = figure('Name', 'Dynamic-fDES Analysis Dashboard', 'NumberTitle', 'off', 'Color', 'w');
f.Position = [50 50 1800 1100]; % Large window for all plots

% Use tiledlayout for 3x2 grid
t = tiledlayout(3, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% Tile 1: Conceptual similarity functions
nexttile;
plot_concept_tile(C);

% Tile 2: tDES sweep
nexttile;
plot_group_sweep_tile(C.rValuesMs, sweep.tDES, sweep.Group, 'tDES', 'r (ms)');

% Tile 3: Triangular fDES sweep
nexttile;
plot_group_sweep_tile(C.rValuesMs, sweep.triFDES, sweep.Group, 'Triangular fDES', 'r (ms)');

% Tile 4: Exponential fDES sweep
nexttile;
plot_group_sweep_tile(C.alphaValuesPerSecond, sweep.expFDES, sweep.Group, 'Exponential fDES', '\alpha (s^{-1})');

% Tile 5: Group boxplots (all 5 methods)
nexttile;
plot_group_boxplots_tile(T);

% Tile 6: Short-data robustness
nexttile;
plot_short_data_tile(shortT);

% Add overall title
sgtitle(t, 'Dynamic-fDES Comprehensive Analysis Dashboard', 'FontSize', 14, 'FontWeight', 'bold');

% Save as unified PNG
set(f, 'PaperPositionMode', 'auto');
print(f, fullfile(C.figureDir, 'fig00_unified_dashboard.png'), '-dpng', '-r300');

fprintf('Unified dashboard saved: fig00_unified_dashboard.png\n');

end

% ===== TILE-BASED PLOTTING FUNCTIONS (for unified dashboard only) =====

function plot_concept_tile(C)
%PLOT_CONCEPT_TILE Conceptual similarity functions (tile version).
d = 0:0.1:100;
t = double(d <= C.mainRms);
tri = max(0, 1-d/C.mainRms);
ex = exp(-C.mainAlphaPerSecond*d/1000);
binWidth = diff(C.symbolRangeMs)/C.mainNBins;
left = C.symbolRangeMs(1) + binWidth - 1;
edges = linspace(C.symbolRangeMs(1), C.symbolRangeMs(2), C.mainNBins + 1);
leftSymbol = discretize(left, edges);
rightSymbols = discretize(min(left+d, C.symbolRangeMs(2)), edges);
sym = double(rightSymbols == leftSymbol);

hold on;
plot(d,t,'LineWidth',1.7, 'DisplayName', 'tDES'); 
plot(d,sym,'LineWidth',1.2, 'DisplayName', 'symDES');
plot(d,tri,'LineWidth',1.7, 'DisplayName', 'tri-fDES'); 
plot(d,ex,'LineWidth',1.7, 'DisplayName', 'exp-fDES');
xlabel('|\Delta RR| (ms)'); 
ylabel('Similarity contribution'); 
ylim([-0.05 1.05]); 
grid on;
legend('Location','northeast', 'FontSize', 9);
title('Conceptual Similarity Functions', 'FontSize', 11, 'FontWeight', 'bold');
end

function plot_group_sweep_tile(x, values, groups, yLabel, xLabel)
%PLOT_GROUP_SWEEP_TILE Parameter sweep (tile version).
hold on;
levels = {'Young','Elderly','CHF'}; 
colors = lines(3);
for g = 1:numel(levels)
    mask = strcmp(groups, levels{g});
    y = values(mask,:); 
    m = mean(y,1); 
    se = std(y,0,1)./sqrt(sum(mask));
    errorbar(x,m,se,'Color',colors(g,:),'LineWidth',1.4,'DisplayName',levels{g}, 'Marker', 'o', 'MarkerSize', 3);
end
xlabel(xLabel, 'FontSize', 9); 
ylabel(yLabel, 'FontSize', 9); 
title([yLabel ' Sweep'], 'FontSize', 11, 'FontWeight', 'bold'); 
grid on; 
legend('Location','best', 'FontSize', 9);
end

function plot_group_boxplots_tile(T)
%PLOT_GROUP_BOXPLOTS_TILE All feature boxplots (tile version - no toolbox needed).
hold on;
groups = unique(T.Group);
colors = lines(3);
for g = 1:numel(groups)
    gv = T.tDES(strcmp(T.Group, groups{g}));
    y_pos = g + (rand(size(gv)) - 0.5) * 0.2; % Add jitter
    scatter(y_pos, gv, 50, colors(g,:), 'filled', 'DisplayName', groups{g});
end

set(gca, 'XTick', 1:numel(groups), 'XTickLabel', groups);
ylabel('Feature value', 'FontSize', 9); 
title('Feature Distributions', 'FontSize', 11, 'FontWeight', 'bold'); 
grid on;
end

function plot_short_data_tile(shortT)
%PLOT_SHORT_DATA_TILE Short-data robustness (tile version).
hold on;
levels = {'Young','Elderly','CHF'}; 
colors = lines(3); 
lengths = unique(shortT.Length)';
for g = 1:numel(levels)
    y = zeros(size(lengths)); 
    se = zeros(size(lengths));
    for j = 1:numel(lengths)
        v = shortT.expFDES(strcmp(shortT.Group,levels{g}) & shortT.Length == lengths(j));
        if ~isempty(v)
            y(j) = mean(v); 
            se(j) = std(v)/sqrt(numel(v));
        end
    end
    errorbar(lengths,y,se,'-o','Color',colors(g,:),'LineWidth',1.4,'DisplayName',levels{g}, 'MarkerSize', 4);
end
set(gca,'XScale','log'); 
xlabel('RR intervals per segment', 'FontSize', 9); 
ylabel('Exponential fDES', 'FontSize', 9);
title('Short-Data Robustness', 'FontSize', 11, 'FontWeight', 'bold'); 
grid on; 
legend('Location','best', 'FontSize', 9);
end
