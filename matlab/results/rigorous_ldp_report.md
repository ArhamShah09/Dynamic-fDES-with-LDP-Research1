# Rigorous LDP versus exponential fDES

Subjects: 30; groups: Young=10, Elderly=10, CHF=10.

## Definitions

D_i=|RR_{i+1}-RR_i| in ms. The LDP uses a positive 75th-percentile scale s and L(z)=mean(exp(-zD_i/s)), where z is dimensionless. Area is normalized by the z-grid width; half-decay is in ms; heterogeneity is normalized squared residual from the best exp(-c z). Original exp-fDES remains mean(exp(-alpha D_i/1000)), alpha in s^-1.

## Statistical design

Discrimination uses subject-level stratified 5-fold outer CV. Best alpha is selected only on training subjects by inner CV. Bootstrap CIs resample subjects within class; paired permutation tests and BH-FDR are reported. Stability uses repeated valid contiguous segments at 50, 100, 200, 500, and 1000 intervals. Robustness uses RR jitter and controlled ectopic/missed-beat perturbations.

## Honest interpretation

Positive paired AUC differences favor LDP; negative values favor fixed fDES. The cohort has only 10 subjects per group, so inference is feasibility evidence. The final verdict must be read from rigorous_auc_results.csv, rigorous_paired_auc_differences.csv, rigorous_stability_summary.csv, and rigorous_robustness_summary.csv; no winner is assumed. Parameter-bound saturation is explicitly recorded in rigorous_parameter_selection.csv.
