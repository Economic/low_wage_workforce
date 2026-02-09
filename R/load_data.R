## Functions for loading CPS ORG data and state minimum wage data

load_org_data = function(dummy) {
  load_org(
    2009:2025,
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
    ftptstat
  ) |>
    mutate(hourly_wage = wageotc) |>
    filter(hourly_wage > 0) |>
    mutate(month_date = ym(paste(year, month))) |>
    filter(month_date <= ym("2025 June"))
}

load_org_states_data = function(dummy) {
  load_org(
    2023:2025,
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
    mutate(
      hourly_wage = case_when(
        a_earnhour == 1 & paidhre == 1 ~ NA,
        a_weekpay == 1 & paidhre == 0 ~ NA,
        .default = hourly_wage
      )
    ) |>
    mutate(month_date = ym(paste(year, month))) |>
    filter(month_date <= ym("2025 June"))
}

load_state_minimum_wages = function(file_path, max_date) {
  read_csv(file_path) |>
    clean_names() |>
    mutate(notes = my(notes)) |>
    filter(notes == max_date) |>
    select(-cpi_value, -notes, -us) |>
    pivot_longer(
      everything(),
      names_to = "state_abb",
      values_to = "state_mw"
    ) |>
    mutate(
      state_abb = str_to_upper(state_abb),
      state_mw = as.numeric(str_replace(state_mw, "\\$", ""))
    )
}
