# Runbook

## 1. Get data into the expected form

For the Fantasia subset, obtain interbeat-interval text files and place them as:

```
data/fantasia/Y1.txt ... Y5.txt
data/fantasia/O1.txt ... O5.txt
```

Each file needs a single numerical RR interval per row. The loader recognizes seconds (typical values near 0.8) and converts them to milliseconds.

For CHF, use one of these routes.

### Route A — prepared RR files (recommended)

Put one RR interval per row in:

```
data/chf/chf01_rr.txt ... chf05_rr.txt
```

Values may be seconds or milliseconds. This requires no WFDB installation.

### Route B — WFDB annotations

Download the five record files into `data/chf/`, install the WFDB Toolbox for MATLAB, and change this line in `matlab/config.m`:

```matlab
C.chfInputMode = 'wfdb';
```

Before relying on this route, inspect `rdann` output for your local CHF source and confirm that the selected annotation codes in `getRR_CHF.m` represent valid beats. The loader defaults to 250 Hz; update `C.chfFs` if the records differ.

## 2. Run the project

In MATLAB:

```matlab
cd('.../DSD/matlab')
setup_data  % optional: downloads the public source files
self_test
main
```

`self_test` does not need data. It checks expected behaviour for constant and ramp RR signals. `main` needs all 15 records.

## 3. Outputs

`matlab/results/` receives:

- `main_features.csv` — one row per subject; use this for the principal table.
- `anova_summary.csv` and `posthoc_*.csv` — subject-level inferential results.
- `sweep_*.csv` — raw parameter curves for every subject.
- `short_data_results.csv` — all subject/start/length combinations.
- `boundary_test.csv` — toy bin-boundary demonstration.
- `roughness_summary.csv` — second-difference roughness per subject.
- `analysis_workspace.mat` — saved MATLAB workspace.

`figures/` receives six PNG figures, each at 300 DPI.

## 4. How to write results without overclaiming

Report fDES as a continuous weighting of successive RR differences. State whether it produced smoother parameter-response curves, reduced symbolic boundary discontinuities in the toy test, and showed exploratory subject-level group separation. Do not claim clinical diagnostic performance or ground-truth accuracy from this 15-subject pilot.

## 5. Final checks

- RR values in `main_features.csv` must have been calculated from milliseconds.
- The exponential parameter is in inverse seconds: `exp(-alpha * abs(diff(RR_ms))/1000)`.
- The unit of analysis in ANOVA is a subject.
- The source and version of each downloaded dataset should be cited in the report.
- If a record has fewer than 1000 plausible RR values, reduce `C.segmentLength` uniformly for every subject and disclose the change.
