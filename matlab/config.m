function C = config()
%CONFIG Central settings for the Fuzzy DES heartbeat project.

thisFile = mfilename('fullpath');
C.matlabDir = fileparts(thisFile);
C.rootDir = fileparts(C.matlabDir);
C.dataDir = fullfile(C.rootDir, 'data');
C.fantasiaDir = fullfile(C.dataDir, 'fantasia');
C.chfDir = fullfile(C.dataDir, 'chf');
C.resultsDir = fullfile(C.matlabDir, 'results');
C.figureDir = fullfile(C.rootDir, 'figures');

% Dataset and analysis scope.
C.youngIDs = arrayfun(@(k) sprintf('Y%d', k), 1:10, 'UniformOutput', false);
C.elderlyIDs = arrayfun(@(k) sprintf('O%d', k), 1:10, 'UniformOutput', false);
C.chfIDs = arrayfun(@(k) sprintf('chf%02d', k), 1:10, 'UniformOutput', false);
C.chfInputMode = 'rr_text'; % 'rr_text' or 'wfdb'
C.chfFs = 250;              % used only by the WFDB route
C.segmentLength = 1000;
C.minRRms = 300;
C.maxRRms = 2000;

% Main comparison parameters.
C.mainRms = 12;
C.mainNBins = 10;
C.symbolRangeMs = [600 1200];
C.mainAlphaPerSecond = 25;

% Scale-normalized Laplace-DES profile (LDP).
% L(z) = mean(exp(-z*abs(diff(RR))/s)); z is dimensionless and s is a
% subject-level robust scale, retained separately as an absolute feature.
C.laplaceScalePercentile = 75;
C.laplaceZGrid = linspace(0, 8, 161);
C.laplaceShortLengths = [50 100 200 500 1000];
C.laplaceBootstrapRepeats = 100;
C.experiment1BootstrapRepeats = 2000;
C.experiment1PermutationRepeats = 10000;
C.rigorousOuterFolds = 5;
C.rigorousInnerFolds = 3;
C.rigorousBootstrapRepeats = 1000;
C.rigorousPermutationRepeats = 2000;
C.rigorousStabilityRepeats = 100;
C.rigorousRobustnessRepeats = 30;
C.rigorousJitterMs = [0 2 5 10 20];
C.rigorousErrorRates = [0 0.005 0.01 0.02 0.05];

% Parameter sweeps.
C.rValuesMs = 1:100;
C.alphaValuesPerSecond = 1:200;
C.nBinsValues = [4 6 8 10 12 16 20];
C.shortLengths = [5 10 20 30 50 100 200 500 1000];
C.shortStarts = [1 51 101 151 201];

% Reproducibility.
C.randomSeed = 20260828;
end
