# Unified Dashboard Guide

## Overview
The Dynamic-fDES framework now displays all analysis results in a **single comprehensive dashboard window** (fig00_unified_dashboard.png). This guide explains each tile and how to interpret the results.

---

## Dashboard Layout

```
┌─────────────────────────────────────────────────────────┐
│  Dynamic-fDES Comprehensive Analysis Dashboard          │
├──────────────────────────┬──────────────────────────────┤
│ Tile 1: Conceptual       │ Tile 2: tDES Sweep           │
│ Similarity Functions     │ (r = 1 to 100 ms)            │
│                          │                              │
│ Shows 4 methods:         │ Shows 3 groups:              │
│ • tDES (step)            │ • Young (blue)               │
│ • symDES (spikes)        │ • Elderly (red)              │
│ • tri-fDES (linear)      │ • CHF (yellow)               │
│ • exp-fDES (smooth)      │                              │
├──────────────────────────┼──────────────────────────────┤
│ Tile 3: Triangular fDES  │ Tile 4: Exponential fDES     │
│ Sweep (r = 1 to 100 ms)  │ Sweep (α = 1 to 200 s⁻¹)    │
│                          │                              │
│ Linear membership fuzzy  │ Exponential membership fuzzy │
│ Shows r sensitivity      │ Shows α sensitivity          │
├──────────────────────────┼──────────────────────────────┤
│ Tile 5: Feature          │ Tile 6: Short-Data           │
│ Distributions            │ Robustness                   │
│                          │                              │
│ Boxplots by group        │ exp-fDES stability across    │
│ Shows feature variance   │ segment lengths (log scale)  │
└──────────────────────────┴──────────────────────────────┘
```

---

## Detailed Tile Descriptions

### Tile 1: Conceptual Similarity Functions
**Purpose:** Compare how each algorithm weights RR differences.

**What You See:**
- X-axis: Absolute difference between consecutive RR intervals (|ΔRR| in ms)
- Y-axis: Similarity contribution (0 to 1)
- 4 colored lines representing the 4 main methods

**Key Features:**
- **tDES (solid line, step)**: Binary (0 or 1) — sharp cutoff at r=12ms
- **symDES (spiky)**: Discontinuous jumps at symbolic bin boundaries
- **tri-fDES (linear slope)**: Smooth linear decay within r threshold
- **exp-fDES (smooth curve)**: Smooth exponential decay, no hard threshold

**What It Shows:**
- `tri-fDES` and `exp-fDES` produce continuous transitions (fewer artifacts)
- `symDES` shows boundary discontinuities where symbols change
- `tDES` is insensitive to magnitude changes within threshold

---

### Tile 2: tDES Parameter Sweep
**Purpose:** Show how tDES feature values change with threshold parameter r.

**What You See:**
- X-axis: Threshold r (1 to 100 ms)
- Y-axis: tDES feature value (proportion of consecutive RR diffs ≤ r)
- Error bars: Mean ± SEM per group
- 3 group curves: Young, Elderly, CHF

**Interpretation:**
- **Steep rise at low r:** Signal exhibits small consecutive differences
- **Plateau at high r:** Most differences fall within large threshold
- **Group separation:** Different baseline RR variability between groups
- **Slope shape:** Indicates how clustered the RR differences are

**Clinical Insight:**
Higher tDES values at moderate r suggest more regular heartbeat patterns (healthier).

---

### Tile 3: Triangular fDES Sweep
**Purpose:** Show continuous fuzzy weighting behavior across r values.

**What You See:**
- Same layout as Tile 2
- X-axis: r parameter (1 to 100 ms)
- Y-axis: Triangular fDES feature value (mean membership)
- 3 group curves with error bars

**Comparison to tDES (Tile 2):**
- **Smoother curves:** No sharp discontinuities
- **Earlier plateau:** Fuzzy membership allows gradual transition
- **Subtle group differences:** Better separation in continuous space

**Advantage:**
Captures finer distinctions in RR variability that binary tDES misses.

---

### Tile 4: Exponential fDES Sweep
**Purpose:** Show exponential weighting across α (decay constant) values.

**What You See:**
- X-axis: α parameter (1 to 200 s⁻¹)
- Y-axis: Exponential fDES feature value
- 3 group curves with error bars
- Most continuous and smooth of the three sweep plots

**α Interpretation:**
- **Low α (1-10):** Slow decay — weights all RR differences similarly
- **Mid α (20-50):** Standard decay — good discrimination
- **High α (100-200):** Fast decay — emphasizes only very small differences

**Clinical Insight:**
The smoothest curves here suggest exponential fuzzy membership best captures continuous physiology.

---

### Tile 5: Feature Distributions
**Purpose:** Compare baseline feature values across groups.

**What You See:**
- Boxplot by group (Young, Elderly, CHF)
- Box: Interquartile range (25th to 75th percentile)
- Line inside box: Median value
- Whiskers: 1.5 × IQR or min/max
- Dots: Individual subjects

**Key Questions to Ask:**
- Do medians differ between groups? → Check group-level effects
- How much overlap exists? → Assess discriminative power
- Are outliers present? → Identify unusual subjects

**Statistical Context:**
Compare with ANOVA p-values in `anova_summary.csv`:
- p < 0.05: Significant group difference
- p > 0.05: No significant difference

---

### Tile 6: Short-Data Robustness
**Purpose:** Evaluate feature stability when using short RR segments.

**What You See:**
- X-axis: Segment length (log scale, 5 to 1000 RR intervals)
- Y-axis: Exponential fDES value
- Error bars: Mean ± SEM across different segment start positions
- 3 group curves

**Robustness Indicators:**
- **Flat lines:** Feature stable regardless of segment length (robust)
- **Rising curves:** Feature improves with more data (convergence expected)
- **Steep rises:** High variance with short data (less reliable for short recordings)

**Clinical Application:**
If your recordings are limited to 50-100 beats, check the curve at that point:
- **Narrow error bars:** Reliable for short recordings
- **Wide error bars:** Use longer recordings when possible

---

## Integrated Interpretation

### Workflow for Results Analysis:

1. **Start with Tile 1 (Conceptual)**
   - Understand algorithmic differences
   - Note which methods have smoother response curves

2. **Compare Tiles 2-4 (Sweeps)**
   - Which shows the clearest group separation?
   - Which shows the smoothest curves (fewer artifacts)?
   - Which shows the steepest discrimination?

3. **Check Tile 5 (Distributions)**
   - Do medians confirm the sweep patterns?
   - Which method has least overlap between groups?

4. **Validate with Tile 6 (Short-Data)**
   - Is your preferred method robust to short segments?
   - How many beats do you need to get stable estimates?

### Example Interpretation:

**Scenario:** You want to discriminate CHF from healthy subjects on short ECG recordings (~100 beats).

**Analysis Path:**
1. Tile 4: exp-fDES sweep shows clear separation between CHF and controls ✓
2. Tile 5: exp-fDES boxplot confirms minimal overlap ✓
3. Tile 6: exp-fDES at 100 beats shows narrow error bars and good separation ✓

**Conclusion:** Use exponential fDES with α ≈ 25 s⁻¹ for clinical screening.

---

## Connecting to Detailed Results

For each tile, corresponding detailed CSV files contain the underlying data:

| Tile | Related CSV Files |
|------|------------------|
| Tiles 2-4 | `sweep_tDES.csv`, `sweep_triFDES.csv`, `sweep_expFDES.csv` |
| Tile 5 | `main_features.csv`, `anova_summary.csv`, `posthoc_*.csv` |
| Tile 6 | `short_data_results.csv` |

### Accessing Raw Data:
```matlab
% Load workspace with all data
load('analysis_workspace.mat');

% Access sweep data
plot(sweep.r, sweep.tDES);  % tDES curves for all subjects

% Access feature table
disp(T);  % Main features by subject

% Access short-data results
disp(shortT);  % Short segment features
```

---

## Monte Carlo & Dynamic Phases

The unified dashboard focuses on Phase 1 (baseline analysis). For Phases 2-3 results:

**Phase 2 (Noise Resilience):**
- See `monte_carlo_*.csv` files for artifact impact quantification
- Lower MSE = more robust to that noise type

**Phase 3 (Dynamic Adaptation):**
- See `fig07_dynamic_parameters.png` (6-panel dynamic analysis)
- See `dynamic_features.csv` for adaptive parameter values per subject

---

## Tips for Publication

### For Reports/Papers:
1. Use **fig00_unified_dashboard.png** as main results figure
2. Reference specific tiles for different aspects:
   - Methods: Cite Tile 1
   - Group effects: Cite Tile 5
   - Robustness: Cite Tile 6

### For Presentations:
1. Show Tile 1 when introducing methods
2. Highlight Tile 5 for group comparison results
3. Use Tile 6 to justify data requirements

### For Technical Documentation:
- Include all 6 tiles with captions
- Reference corresponding CSV files in supplementary material
- Explain parameter choices (r_main, alpha_main from config.m)

---

## Customization

To modify dashboard appearance, edit `plot_all_results.m`:

```matlab
% Change figure size (line ~4)
f.Position = [50 50 1800 1100];  % [left, bottom, width, height]

% Change tile layout (line ~7)
t = tiledlayout(3, 2, ...);  % Change to (2,3) for 2-row layout

% Adjust font sizes in tile functions
'FontSize', 11  % Main title
'FontSize', 9   % Axis labels
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Plots overlap or cut off | Increase figure.Position width/height |
| Labels unreadable | Zoom in or export at higher DPI (already 300 DPI) |
| Missing groups in legend | Check data loading; ensure all 15 subjects present |
| Blank tiles | Check that all sweep ranges have data; adjust C.rValuesMs, C.alphaValuesPerSecond |

---

## Summary

The unified dashboard provides a complete overview of Dynamic-fDES performance in a single, publication-ready figure. Use it to:
- Compare algorithmic approaches
- Assess group-level discrimination
- Validate robustness properties
- Inform clinical application decisions

All detailed results remain available in CSV/MAT formats for statistical validation and custom analysis.
