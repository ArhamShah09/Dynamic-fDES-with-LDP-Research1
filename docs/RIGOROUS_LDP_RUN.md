# Rigorous LDP evaluation

Run the complete existing MATLAB project from the MATLAB Command Window:

```matlab
cd('C:\Users\ayush\OneDrive\Desktop\DSP 2\matlab')
main
```

The added evaluator is `experiments/run_rigorous_ldp_evaluation.m`. It is called by `main.m`; it does not alter `functions/exp_fDES.m` or the original baseline feature definitions.

The important outputs are:

- `results/rigorous_auc_results.csv`: subject-level outer-CV AUC and bootstrap 95% CIs.
- `results/rigorous_macro_auc_results.csv`: macro-average AUC across the three pairwise group comparisons.
- `results/rigorous_paired_auc_differences.csv`: paired differences against fixed exponential fDES, permutation p-values, and BH-FDR values.
- `results/rigorous_parameter_selection.csv`: training-only alpha selection and boundary rate.
- `results/rigorous_stability_summary.csv`: CV versus 50/100/200/500/1000 RR intervals.
- `results/rigorous_robustness_summary.csv`: jitter, ectopic-like, and missed-beat perturbation results.
- `results/rigorous_sensitivity.csv`: scale-invariance check.
- `results/rigorous_ldp_report.md`: concise methods, limitations, and interpretation.

Interpretation is deliberately two-sided. A positive AUC difference favors the named LDP method; a negative value favors fixed fDES. The dataset contains 10 subjects per group, so these are feasibility results and not clinical validation. The existing exploratory CSV is not a substitute for the new nested-CV outputs.
