# EPI Low Wage Workforce Tracker

Data pipeline for the EPI Low Wage Workforce Tracker: https://www.epi.org/low-wage-workforce/

## Workflow rules

- **Always run `targets::tar_make()`** after any changes to code or input files, and verify it completes without errors.
- **Always keep this CLAUDE.md up to date** when the project structure, files, dependencies, or workflow changes.

## Project overview

The tracker is a Wordpress page containing three Observable notebooks.

This project produces CSV data files that power the notebooks:
- **Main tracker**: https://observablehq.com/@economic-policy-institute-ws/low-wage-workforce-tracker
- **Historical trends**: https://observablehq.com/@economic-policy-institute-ws/low-wage-workforce-historical
- **State-level data**: https://observablehq.com/@economic-policy-institute-ws/low-wage-workforce-states

To deploy, upload the relevant CSV outputs to those Observable notebooks.

## Pipeline

This project uses a `targets` pipeline (`_targets.R`). Run with `targets::tar_make()`.

The pipeline has three independent branches off shared upstream targets:

```
org_raw ──► org_clean ──┬──► main_results ──► low_wage_data_csv
                        │
                        └──► historical_results ──► low_wage_data_historical_csv

org_raw_states ──► state_results ──► low_wage_data_states_csv

asec_data ──► (joined into main_results)
mw_file ──► (joined into state_results)
```

### Targets

| Target | Description |
|--------|-------------|
| `org_raw` | CPS ORG microdata (2009-2025), stored as parquet |
| `org_raw_states` | CPS ORG microdata for states (2023-2025), with imputation flags, stored as parquet |
| `asec_data` | ASEC firm-size extract, read from `asec_2022_wage_firmsize.feather` |
| `mw_file` | Tracked input file: `mw_projections_state.csv` |
| `org_clean` | Cleaned/labelled ORG data with demographic and job categories, stored as parquet |
| `main_results` | Shares and counts by category and wage threshold ($10-$25) |
| `historical_results` | Monthly time series of low-wage shares and counts (nominal and real) |
| `state_results` | State-level shares and counts by threshold |
| `low_wage_data_csv` | Writes `low_wage_data.csv` |
| `low_wage_data_historical_csv` | Writes `low_wage_data_historical.csv` |
| `low_wage_data_states_csv` | Writes `low_wage_data_states.csv` |

## Project structure

```
_targets.R              # targets pipeline definition
packages.R              # library() calls and conflict resolution
R/
  helpers.R             # verify_n_months(): assert data months match expected given missing_months
  constants.R           # wage thresholds, state lists, category labels, tipped occupation codes, missing_months
  load_data.R           # load_org_data(), load_org_states_data(), load_state_minimum_wages()
  clean_data.R          # clean_org_data(): label demographic/job categories
  compute_main.R        # compute_main_results(): shares/counts by category and threshold
  compute_historical.R  # compute_historical_results(): monthly time series with CPI adjustment
  compute_states.R      # compute_state_results(): state-level shares/counts
  write_outputs.R       # write_main_csv(), write_historical_csv(), write_states_csv()
  asec_firmsize.R       # clean_asec_firmsize(): one-time IPUMS ASEC extract (not in pipeline)
```

## Data outputs

| File | Description | Observable notebook |
|------|-------------|-------------------|
| `low_wage_data.csv` | Shares and counts by category and wage threshold | low-wage-workforce-tracker |
| `low_wage_data_historical.csv` | Monthly time series of shares and counts | low-wage-workforce-historical |
| `low_wage_data_states.csv` | State-level shares and counts by threshold | low-wage-workforce-states |

## Input files

- `asec_2022_wage_firmsize.feather`: ASEC firm-size extract (gitignored; regenerate with `clean_asec_firmsize()` in `R/asec_firmsize.R`)
- `mw_projections_state.csv`: State minimum wage projections

## Key dependencies

- `epiextractr` / `epidatatools`: EPI's R packages for loading CPS microdata
- `realtalk`: CPI price deflators (provides `c_cpi_u_extended_monthly_sa`)
- `haven`: Stata-style labelled vectors
- `ipumsr`: IPUMS extract API (used only in `R/asec_firmsize.R`)
- `slider`: Rolling window calculations for historical time series
- `arrow`: Parquet storage for intermediate targets and feather I/O
- `janitor`: Column name cleaning
- `MetricsWeighted`: Weighted quantiles for ASEC firm-size threshold matching

## Other files

- `archive/`: Older version of the project (previously a Quarto site)
- `_targets/`: Pipeline cache (gitignored)
- `.env`: Environment variables including `BLS_API_KEY` (gitignored)
