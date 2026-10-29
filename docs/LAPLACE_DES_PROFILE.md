# Scale-Normalized Laplace-DES Profile (LDP)

For `D = abs(diff(RR))`, robust scale `s = Q75(D)`, and dimensionless decay `z`, the profile is `L(z) = mean(exp(-z*D/s))`.

LDP exports `scaleMs`, normalized profile area, half-decay location, exponential decay rate, and deviation from a single-exponential curve. Multiplying all RR differences by a common positive constant leaves the normalized profile unchanged; the scale is retained separately as an absolute-amplitude feature.

Running `matlab/main.m` writes `laplace_des_profile_features.csv`, `laplace_des_short_record_stability.csv`, and `fig08_laplace_des_profile.png`.

The stability output estimates within-subject coefficients of variation using random contiguous records of 50, 100, 200, 500, and 1000 RR intervals. It is feasibility evidence, not external validation.

The revised Monte Carlo code now calculates feature-specific squared errors. It models RR-level timing contamination as Gaussian jitter, ectopic-like compensatory pairs, and missed-beat-like long intervals; it does not claim to simulate ECG waveform artifacts.

A publishable novelty claim still requires a systematic literature review, larger independent cohorts, subject-level splits, confidence intervals, multiple-test correction, and comparison against DES, entropy-profile, and multiscale-entropy baselines.

## Experiment 1: direct comparison

The main pipeline compares fixed exponential fDES at the configured alpha, the
area under the exponential fDES parameter sweep, and LDP descriptors. Each row
represents one subject. It writes:

- `experiment1_comparison.csv`: subject-level feature values.
- `experiment1_group_summary.csv`: group means, standard deviations, CV values,
  and bootstrap 95% confidence intervals.
- `experiment1_pairwise_effects.csv`: pairwise group mean differences and
  Cohen's d values.
- `fig09_experiment1_comparison.png`: subject-level distributions and group means.

These outputs test whether LDP provides information that differs from one fixed
exponential fDES value. They do not by themselves prove superiority; that
requires a larger cohort and a pre-specified statistical comparison.
