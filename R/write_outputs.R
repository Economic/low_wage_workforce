## Write CSV outputs and return file paths (for tar_target format = "file")

write_main_csv = function(main_results) {
  path = "low_wage_data.csv"
  write_csv(main_results, path)
  path
}

write_historical_csv = function(historical_results) {
  path = "low_wage_data_historical.csv"
  write_csv(historical_results, path)
  path
}

write_states_csv = function(state_results) {
  path = "low_wage_data_states.csv"
  write_csv(state_results, path)
  path
}
