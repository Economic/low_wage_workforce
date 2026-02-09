## Load your packages, e.g. library(targets).
source("./packages.R")

## Load your R files
tar_source()

## pipeline
tar_assign({
  # --- data loading ---

  epi_cps_org_files = dir_ls(Sys.getenv("EPIEXTRACTS_CPSORG_DIR")) |>
    tar_file()

  asec_data = "asec_2022_wage_firmsize.feather" |>
    tar_file_read(read_feather(!!.x))

  mw_file = "mw_projections_state.csv" |>
    tar_file()

  org_raw = load_org_data(epi_cps_org_files) |>
    tar_parquet()

  org_raw_states = load_org_states_data(epi_cps_org_files) |>
    tar_parquet()

  # --- main pipeline ---

  org_clean = clean_org_data(org_raw) |>
    tar_parquet()

  main_results = compute_main_results(org_clean, asec_data) |>
    tar_target()

  low_wage_data_csv = write_main_csv(main_results) |>
    tar_file()

  # --- historical pipeline ---

  historical_results = compute_historical_results(org_clean) |>
    tar_target()

  low_wage_data_historical_csv = write_historical_csv(historical_results) |>
    tar_file()

  # --- state pipeline ---

  state_results = compute_state_results(org_raw_states, mw_file) |>
    tar_target()

  low_wage_data_states_csv = write_states_csv(state_results) |>
    tar_file()
})
