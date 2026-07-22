## Functions for loading CPS ORG data and state minimum wage data

load_org_data = function(epi_cps_org_files) {
  load_org(
    epi_cps_org_files,
    year,
    month,
    orgwgt,
    wageotc,
    educ,
    age,
    wbhao,
    female,
    statefips,
    region,
    mind03,
    mocc03,
    ind17,
    occ18,
    cow1,
    faminc,
    union,
    ftptstat,
    matches("a_"),
    paidhre
  ) |>
    mutate(hourly_wage = wageotc) |>
    filter(hourly_wage > 0) |>
    mutate(month_date = ym(paste(year, month)))
}

load_org_states_data = function(epi_cps_org_files) {
  load_org(
    epi_cps_org_files,
    year,
    month,
    orgwgt,
    matches("wage"),
    matches("a_"),
    paidhre,
    statefips
  ) |>
    # For state-level analysis, we need two wage measures:
    #   - hourly_wage: excludes imputed wages (NA for imputed obs), used for
    #     computing low-wage shares to avoid bias from imputation
    #   - wageotc: includes imputed wages, used for counting total wage earners
    #     per state (the denominator for low-wage counts)
    # The a_earnhour and a_weekpay flags indicate CPS wage imputation.
    mutate(hourly_wage = wageotc) |>
    mask_imputed_wages() |>
    mutate(month_date = ym(paste(year, month)))
}

load_state_minimum_wages = function(file_path, max_date) {
  read_csv(file_path) |>
    clean_names() |>
    filter(date == max_date) |>
    transmute(
      state_abb = str_to_upper(state),
      state_mw = as.numeric(regular_mw)
    )
}
