# Dynamic-fDES Quick Start Guide

## ⚡ 60-Second Overview

You now have a **three-phase Dynamic-fDES framework** with a unified dashboard displaying all results in a single window.

```
Input RR Data → Phase 1 (Baseline) → Phase 2 (Noise Test) → Phase 3 (Adapt) → Unified Dashboard
```

---

## 🚀 Getting Started (5 minutes)

### Step 1: Prepare Data
```matlab
cd matlab/
setup_data    % Downloads public Fantasia + CHF data automatically
```

OR manually place files:
- `data/fantasia/Y1.txt` to `Y5.txt` (young subjects)
- `data/fantasia/O1.txt` to `O5.txt` (elderly subjects)
- `data/chf/chf01_rr.txt` to `chf05_rr.txt` (CHF patients)

### Step 2: Run Analysis
```matlab
main          % Runs complete 3-phase analysis
```

### Step 3: View Results
✓ **fig00_unified_dashboard.png** — All 6 plots in one window (YOUR MAIN RESULT)
✓ Results/ — CSV files with detailed data
✓ Console output — Progress updates

---

## 📊 What You Get

### Main Dashboard (`fig00_unified_dashboard.png`)
A single 3×2 grid showing:

| Position | Content | What It Shows |
|----------|---------|---------------|
| Top-Left | Conceptual Functions | How 4 methods weight RR differences |
| Top-Right | tDES Sweep | Threshold method behavior across r values |
| Mid-Left | Tri-fDES Sweep | Triangular fuzzy method across r values |
| Mid-Right | Exp-fDES Sweep | Exponential fuzzy method across α values |
| Bottom-Left | Feature Distributions | Group comparison (Young/Elderly/CHF) |
| Bottom-Right | Short-Data Robustness | Stability with fewer RR intervals |

### Output Files (in `matlab/results/`)

**Phase 1 (Baseline):**
- `main_features.csv` — Core results (use for your main table)
- `anova_summary.csv` — Statistical significance
- `sweep_*.csv` — Parameter sweep data
- `short_data_results.csv` — Short recording stability

**Phase 2 (Noise Resilience):**
- `monte_carlo_gaussian.csv` — Random noise robustness
- `monte_carlo_powerline.csv` — 50/60 Hz interference robustness
- `monte_carlo_baseline_wander.csv` — Drift artifact robustness

**Phase 3 (Dynamic Adaptation):**
- `dynamic_features.csv` — Adaptive parameter values

---

## 🎯 Key Changes from Original

### ✨ What's New
1. **Unified Dashboard** — All plots in one window (instead of 6 separate windows)
2. **Monte Carlo Testing** — Automated noise resilience evaluation
3. **Dynamic Adaptation** — Automatic parameter adjustment based on signal variance
4. **Enhanced Documentation** — 3 detailed guides + quick start

### ✅ What's Preserved
- All original baseline algorithms (tDES, symDES, tri-fDES, exp-fDES, pNN50)
- All original CSV outputs and statistical results
- All original individual PNG figures (plus new unified dashboard)
- Original configuration system

---

## 📖 Reading the Dashboard

### For Clinical Users
1. Look at **Bottom-Left** (Distributions) to see group differences
2. Check **Bottom-Right** (Short-Data) if you have short recordings
3. Use optimal method identified in top plots

### For Researchers
1. Compare **Sweep Curves** (Top 3 tiles) to assess smoothness
2. Check **Distributions** for statistical power
3. Evaluate **Robustness** for validation requirements

### For Method Developers
1. Study **Conceptual Functions** (Top-Left) to understand algorithm behavior
2. Compare **Sweep Shapes** to identify algorithm properties
3. Assess **Noise Resilience** data (Phase 2) for robustness metrics

---

## 🔧 Customization

### Change Parameter Ranges
Edit `matlab/config.m`:
```matlab
C.rValuesMs = 1:100;              % Sweep range for r
C.alphaValuesPerSecond = 1:200;   % Sweep range for alpha
C.mainRms = 12;                   % Main r value (default)
C.mainAlphaPerSecond = 25;        % Main alpha value (default)
```

### Adjust Monte Carlo Settings
Edit `monte_carlo_noise_test.m`:
```matlab
snrLevels = [30 20 10 5];         % SNR levels in dB
numTrials = 50;                   % Trials per SNR
```

### Modify Dashboard Layout
Edit `plot_all_results.m`:
```matlab
t = tiledlayout(3, 2, ...);       % Change to (2, 3) for 2-row layout
f.Position = [50 50 1800 1100];   % Change figure size
```

---

## 📚 Documentation Hierarchy

| Document | Purpose | Read If... |
|----------|---------|-----------|
| This file | Quick overview | You have 5 minutes |
| `UNIFIED_DASHBOARD_GUIDE.md` | Detailed interpretation | You want to understand each tile |
| `IMPLEMENTATION_SUMMARY.md` | Technical documentation | You're implementing or extending |
| `RUNBOOK.md` | Execution instructions | You need step-by-step guidance |
| Code comments | Function-level details | You're modifying algorithms |

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| "Missing data files" | Run `setup_data` OR place files manually in data/ folders |
| "Function not found" | Make sure you're in `matlab/` directory when running main |
| "Out of memory" | Reduce `numTrials` in monte_carlo_noise_test.m |
| "Plots overlap" | Increase figure size: `f.Position = [50 50 2000 1200]` |
| "Missing WFDB" | Use RR text files (chf*_rr.txt) instead of WFDB route |

---

## ⏱️ Timing

Expected execution times:
- **Phase 1** (baseline): ~30 seconds
- **Phase 2** (Monte Carlo): ~2-3 minutes (depending on trials)
- **Phase 3** (dynamic): ~15 seconds
- **Plotting**: ~15 seconds
- **Total**: 3-5 minutes

---

## 📈 Typical Workflow

### 1️⃣ First Run: Explore Results
```matlab
main                    % Run once to see all results
```
View `fig00_unified_dashboard.png` and skim CSV files

### 2️⃣ Detailed Analysis
Open MATLAB workspace:
```matlab
load('matlab/results/analysis_workspace.mat');
plot(sweep.r, sweep.tDES);  % Custom plotting
```

### 3️⃣ Publication Preparation
- Use `fig00_unified_dashboard.png` as main figure
- Reference `main_features.csv` for tables
- Cite ANOVA results from `anova_summary.csv`
- Include `monte_carlo_*.csv` in supplementary materials

### 4️⃣ Clinical Application (Optional)
- Identify best-performing method from dashboard
- Use `dynamic_features.csv` for adaptive parameters
- Test on new subjects with `compute_features.m`

---

## 🎓 Key Papers/Concepts

**Baseline Methods:**
- **tDES**: Threshold-based distribution of equal states
- **symDES**: Symbolic dynamics with equal-width binning
- **tri-fDES**: Triangular membership fuzzy distribution
- **exp-fDES**: Exponential membership fuzzy distribution
- **pNN50**: Classical heart rate variability metric

**Noise Types (Phase 2):**
- Gaussian white noise (0-50 Hz contamination)
- Powerline interference (50/60 Hz)
- Baseline wander (0.1-0.5 Hz drift)

**Adaptation (Phase 3):**
- Rolling window variance detection
- Dynamic parameter adjustment
- Variance-to-parameter mapping

---

## 🤝 Next Steps

### To Use Results
1. Choose optimal method from dashboard
2. Extract parameters from `dynamic_features.csv`
3. Apply to new patient data using `compute_features.m`

### To Extend Framework
1. Add new noise types to `monte_carlo_noise_test.m`
2. Modify variance mapping in `dynamic_parameter_adjuster.m`
3. Create new figure layouts in `plot_all_results.m`

### To Deploy Clinically
1. Validate on larger cohorts (~100+ subjects)
2. Compare with ground truth labels
3. Implement in embedded/cloud platform
4. Pursue FDA clearance (if required)

---

## 📞 Quick Help

**Run analysis:**
```matlab
cd matlab; main
```

**View dashboard:**
File → `figures/fig00_unified_dashboard.png`

**Access raw data:**
```matlab
load('matlab/results/analysis_workspace.mat');
```

**Read detailed guides:**
See `docs/` folder for IMPLEMENTATION_SUMMARY.md and UNIFIED_DASHBOARD_GUIDE.md

---

## ✅ Verification Checklist

After running `main`, verify you see:
- ✓ Console output showing all 3 phases
- ✓ `fig00_unified_dashboard.png` with 6 subplots
- ✓ `main_features.csv` with 15 rows (5 subjects × 3 groups)
- ✓ `monte_carlo_*.csv` files (3 files)
- ✓ `dynamic_features.csv` with dynamic parameters
- ✓ All figures saved to `figures/` folder

---

## 🎉 You're Ready!

The Dynamic-fDES framework is now fully implemented with:
✓ Phase 1: Core algorithms  
✓ Phase 2: Noise resilience testing  
✓ Phase 3: Dynamic adaptation  
✓ Unified dashboard visualization  
✓ Complete documentation  

**Run `main` in MATLAB and explore your results!**

---

Last Updated: September 3, 2026  
Status: Complete ✓
