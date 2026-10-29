# Dynamic-fDES Implementation Summary

## Overview
This document summarizes the implementation of the Dynamic-fDES framework as outlined in the Software Development Framework document. The project now includes three integrated phases with unified visualization.

---

## Phase 1: Core Algorithm Construction ✓

**Status:** Complete

### Files Modified:
- `matlab/main.m` - Updated to orchestrate all three phases
- `matlab/config.m` - No changes (baseline configuration maintained)

### Baseline fDES Methods Implemented:
1. **tDES (Threshold DES)** - `matlab/functions/tDES.m`
   - Binary threshold on successive RR differences
   - Parameter: r (milliseconds)

2. **symDES (Symbolic DES)** - `matlab/functions/symDES.m`
   - Equal-width bins with fixed boundaries
   - Parameter: nBins, symbolRangeMs

3. **tri-fDES (Triangular Fuzzy DES)** - `matlab/functions/tri_fDES.m`
   - Linear membership function
   - Parameter: r (milliseconds)

4. **exp-fDES (Exponential Fuzzy DES)** - `matlab/functions/exp_fDES.m`
   - Exponential decay membership function
   - Parameter: alpha (inverse seconds)

5. **pNN50** - `matlab/functions/pNN50.m`
   - Percentage of adjacent RR differences > 50ms
   - Baseline comparison metric

### Data Pipeline:
- `getRR_Fantasia.m` - Load young/elderly Fantasia data
- `getRR_CHF.m` - Load CHF data (text or WFDB)
- `cleanRR.m` - Validate and convert RR intervals to milliseconds
- `load_subjects.m` - Orchestrate data loading and segmentation

### Core Feature Computation:
- `compute_features.m` - Calculate all 5 methods at main parameters
- `feature_table.m` - Generate subject-level main results table

### Statistical Analysis:
- `run_statistics.m` - One-way ANOVA and post-hoc comparisons
- `parameter_sweep.m` - Sweep r, alpha, and nBins across ranges
- `boundary_test.m` - Demonstrate symbolic boundary discontinuities
- `short_data_test.m` - Evaluate stability on short segments
- `roughness_analysis.m` - Quantify parameter-curve smoothness via 2nd differences

---

## Phase 2: Statistical Noise Evaluation ✓

**Status:** Complete

### New File Created:
- `matlab/experiments/monte_carlo_noise_test.m`

### Functionality:
Implements Monte Carlo simulation framework for noise resilience testing.

**Synthetic Noise Profiles:**
1. **Gaussian White Noise** - Random artifact
2. **Powerline Interference** - 50/60 Hz simulated interference
3. **Baseline Wander** - Low-frequency drift (0.1-0.5 Hz)

**Parameters:**
- SNR Levels: 30, 20, 10, 5 dB
- Trials per configuration: 50
- Evaluation metric: Mean Squared Error (MSE) relative to clean signal

**Output:**
- `monte_carlo_gaussian.csv` - MSE results for Gaussian noise
- `monte_carlo_powerline.csv` - MSE results for powerline interference
- `monte_carlo_baseline_wander.csv` - MSE results for baseline drift

**Helper Function:**
- `inject_noise()` - Generates synthetic noisy signals

### Interpretation:
Lower MSE indicates better noise resilience. Compare results across methods to identify which algorithms are most robust to specific artifact types.

---

## Phase 3: Dynamic fDES Optimization ✓

**Status:** Complete

### New Files Created:
- `matlab/functions/dynamic_parameter_adjuster.m`

### Functionality:
Implements adaptive parameter adjustment based on real-time signal variance.

**Core Concept:**
- High variance signals (noisy) → Broader threshold (higher r, lower alpha)
- Low variance signals (clean) → Tighter threshold (lower r, higher alpha)

**Adaptive Mechanisms:**
1. **Rolling Variance Calculation** - 50 RR interval windows, 10 RR step size
2. **Variance-to-r Mapping** - Maps variance to r ∈ [5, 50] ms
3. **Variance-to-Alpha Mapping** - Maps variance to α ∈ [5, 50] s⁻¹

**Output:**
- `dynamic_features.csv` - Dynamic feature values per subject
- Additional columns: `avgVariance`, `dynamic_r`, `dynamic_alpha`

**Visualization Function:**
- `visualize_dynamic_adjustment()` - 6-panel analysis dashboard showing:
  - Signal variance distribution by group
  - Dynamic r distribution by group
  - Dynamic alpha distribution by group
  - Variance-to-r scatter plot
  - Variance-to-alpha scatter plot
  - Static vs. dynamic feature comparison

---

## Unified Visualization ✓

**Status:** Complete

### File Modified:
- `matlab/experiments/plot_all_results.m`

### Unified Dashboard:
All plots displayed in a **single comprehensive figure window** (1800×1100 pixels, 3×2 grid layout):

**Tile 1:** Conceptual Similarity Functions
- Shows all four methods' membership functions
- Legend: tDES, symDES, tri-fDES, exp-fDES

**Tile 2:** tDES Parameter Sweep
- Error bars show mean ± SEM by group
- X-axis: r (1 to 100 ms)
- Groups: Young, Elderly, CHF

**Tile 3:** Triangular fDES Parameter Sweep
- Same layout as tDES sweep

**Tile 4:** Exponential fDES Parameter Sweep
- X-axis: alpha (1 to 200 s⁻¹)

**Tile 5:** Feature Boxplots
- Displays distribution of feature values by group

**Tile 6:** Short-Data Robustness
- Shows exp-fDES stability vs. segment length
- Log scale on X-axis

### Output Files:
- **fig00_unified_dashboard.png** - Main comprehensive dashboard (300 DPI)
- Individual PNG files still generated for compatibility

### New Helper Functions:
- `plot_concept_tile()` - Tile-formatted conceptual plot
- `plot_group_sweep_tile()` - Tile-formatted sweep plot
- `plot_group_boxplots_tile()` - Tile-formatted boxplot
- `plot_short_data_tile()` - Tile-formatted short-data plot

---

## Main Workflow Changes

### Updated `matlab/main.m`:
```
[PHASE 1] Load RR records → Compute baseline features → ANOVA → Sweeps
   ↓
[PHASE 2] Monte Carlo noise injection → Robustness evaluation
   ↓
[PHASE 3] Dynamic parameter computation → Variance-based adaptation
   ↓
[VISUALIZATION] Unified dashboard (all 6 plots in one window)
   ↓
[OUTPUT] Save all results, figures, and workspace
```

### Output Summary:
Key files generated in `matlab/results/`:
1. `main_features.csv` - Static baseline features
2. `dynamic_features.csv` - Adaptive features with variance metrics
3. `monte_carlo_*.csv` (3 files) - Noise resilience data
4. `anova_summary.csv` - Statistical test results
5. `posthoc_*.csv` (5 files) - Post-hoc comparisons
6. `sweep_*.csv` (4 files) - Parameter sweep data
7. `short_data_results.csv` - Short segment stability
8. `roughness_summary.csv` - Curve roughness metrics
9. `boundary_test.csv` - Symbolic boundary artifacts
10. `analysis_workspace.mat` - Complete MATLAB workspace

Figures in `figures/`:
1. `fig00_unified_dashboard.png` - **NEW: All plots in one window**
2. `fig01_conceptual_similarity.png`
3. `fig02_tdes_sweep.png`
4. `fig03_tri_fdes_sweep.png`
5. `fig04_exp_fdes_sweep.png`
6. `fig05_group_boxplots.png`
7. `fig06_short_data_robustness.png`
8. `fig07_dynamic_parameters.png` - **NEW: Dynamic adjustment analysis**

---

## Next Steps (Future Work)

### Potential Enhancements:
1. **Adaptive Window Sizing** - Vary window size based on signal stability
2. **Machine Learning Integration** - Train models on variance-to-parameter mapping
3. **Real-Time Streaming** - Implement as continuous online algorithm
4. **Multi-Subject Optimization** - Learn group-specific variance thresholds
5. **Clinical Validation** - Compare against medical ground truth on larger cohorts

### Extension Architecture:
- Phase 4: Real-time adaptation with feedback
- Phase 5: Hybrid methods (e.g., adaptive symDES)
- Phase 6: Hardware implementation (FPGA/embedded)

---

## Running the Framework

```matlab
cd matlab/
setup_data        % Optional: Download public data
self_test         % Validate implementations
main              % Run complete three-phase analysis
```

The analysis typically completes in 2-5 minutes on standard hardware (depending on Monte Carlo trial count).

---

## Reference

For detailed mathematical formulations and phase descriptions, see `Dynamic-fDES Software Development Framework.docx`.
