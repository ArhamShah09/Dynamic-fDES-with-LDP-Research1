# Fuzzy DES heartbeat project

## Scale-Normalized Laplace-DES Profile

The project now includes a scale-normalized Laplace-DES Profile (LDP) for
successive RR differences, with profile descriptors and short-record stability
estimates. See `docs/LAPLACE_DES_PROFILE.md` for definitions and limits.

This is a MATLAB project for comparing threshold DES (tDES), equally spaced symbolic DES (symDES), triangular fuzzy DES, exponential fuzzy DES, and pNN50 on subject-level RR-interval data from young, elderly, and CHF groups.

## Before running

1. Put Fantasia RR files in `data/fantasia/` as `Y1.txt` to `Y5.txt` and `O1.txt` to `O5.txt`. Each file must contain one RR interval per row in **seconds**.
2. Put CHF data in `data/chf/`:
   - preferred simple route: `chf01_rr.txt` to `chf05_rr.txt`, one RR interval per row in seconds or milliseconds; or
   - WFDB route: download the `chf01`–`chf05` records and install the WFDB MATLAB Toolbox. Set `C.chfInputMode = 'wfdb'` in `matlab/config.m`.
3. Open MATLAB, change to `matlab/`, and run `main`.

To download the 10 public Fantasia files and the compact CHF headers/annotations automatically, run `setup_data` first. The CHF annotation route still requires the WFDB MATLAB Toolbox.

The project writes CSV files to `matlab/results/` and figures to `figures/`.

The expanded dataset configuration uses 10 subjects per group: `Y1`-`Y10`,
`O1`-`O10`, and `chf01`-`chf10`. Records added from the supplied PhysioNet ZIP
files are documented in `data/expanded_dataset_manifest.csv`. The reproducible
conversion tool is `tools/import_expanded_datasets.py`.

## Scientific conventions used here

- RR intervals are converted to milliseconds before analysis.
- Statistical observations are subjects, never individual beats.
- `symDES` is an equally spaced-bin comparative baseline; it is not claimed to reproduce a complete symDES recipe from the reference paper.
- Exponential fDES is calculated as `mean(exp(-alpha * abs(diff(RR_ms))/1000))`; therefore alpha has units of inverse seconds. This makes the `1:200` sweep numerically meaningful while RR data remain in milliseconds.
- Results are exploratory with five subjects per group. Do not state that fDES establishes ground-truth accuracy; state continuity, boundary robustness, and observed group discrimination.
