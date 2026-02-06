# EPI Low Wage Workforce Tracker

Data pipeline for the EPI Low Wage Workforce Tracker: https://www.epi.org/low-wage-workforce/

## Project overview

The tracker is a Wordpress page containing three Observable notebooks.

This project produces CSV data files that power the notebooks:
- **Main tracker**: https://observablehq.com/@economic-policy-institute-ws/low-wage-workforce-tracker
- **Historical trends**: https://observablehq.com/@economic-policy-institute-ws/low-wage-workforce-historical
- **State-level data**: https://observablehq.com/@economic-policy-institute-ws/low-wage-workforce-states

To deploy, upload the relevant CSV outputs to those Observable notebooks.

## R scripts

### `low_wage_data.R` (main script)
Produces `low_wage_data.csv` and `low_wage_data_historical.csv`.

- Loads CPS Outgoing Rotation Group (ORG) microdata via `epiextractr::load_org()`
- Uses a rolling 12-month window ending at the most recent available month
- For each wage threshold ($10-$25), computes the share and count of workers earning below that threshold, broken out by demographic and job categories: race/ethnicity, gender, age, education, union status, part-time status, region, state minimum wage policy, right-to-work status, tipped occupation, public/private sector, family income, industry, occupation, and firm size
- Firm size data comes from a separate ASEC extract (`asec_2022_wage_firmsize.feather`), reweighted to match the ORG totals
- Historical data computes monthly time series (with 12-month rolling averages) of low-wage shares and counts, in both nominal and real (CPI-adjusted) dollars

### `low_wage_data_states.R` (state script)
Produces `low_wage_data_states.csv`.

- Loads CPS ORG data for recent years
- Filters out imputed wages for share calculations but includes them for total wage earner counts
- Joins state-level minimum wage data from `mw_projections_20250315_state.csv`
- Sets share/count to NA when the wage threshold is below the state minimum wage + $1
- Outputs state-by-threshold results

### `asec_firmsize.R` (ASEC extract)
Produces `asec_2022_wage_firmsize.feather`.

- Downloads a CPS ASEC extract from IPUMS with firm size data
- Computes hourly wages from annual earnings, weeks worked, and usual hours
- This is a one-time extract; the feather file is gitignored

## Data outputs

| File | Description | Observable notebook |
|------|-------------|-------------------|
| `low_wage_data.csv` | Shares and counts by category and wage threshold | low-wage-workforce-tracker |
| `low_wage_data_historical.csv` | Monthly time series of shares and counts | low-wage-workforce-historical |
| `low_wage_data_states.csv` | State-level shares and counts by threshold | low-wage-workforce-states |

## Key dependencies

- `epiextractr` / `epidatatools`: EPI's R packages for loading CPS microdata
- `realtalk`: CPI price deflators (provides `c_cpi_u_extended_monthly_sa`)
- `haven`: Stata-style labelled vectors
- `ipumsr`: IPUMS extract API (used only in `asec_firmsize.R`)
- `slider`: Rolling window calculations for historical time series

## Other files

- `mw_projections_20250315_state.csv`: State minimum wage projections (input to state script)
- `archive/`: Contains an older version of the project (previously a Quarto site)
