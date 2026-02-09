## Compute state-level low-wage workforce results

create_states_slice = function(
  threshold,
  org_clean,
  min_date,
  max_date,
  state_wage_earners
) {
  org_clean |>
    mutate(low_wage = hourly_wage < threshold) |>
    summarize(
      low_wage_share = weighted.mean(low_wage, w = orgwgt),
      obs_count = n(),
      .by = statefips
    ) |>
    inner_join(state_wage_earners, by = "statefips") |>
    mutate(
      low_wage_count = round(low_wage_share * total_wage_earners / 1000) *
        1000,
      low_wage_threshold = threshold,
      dates = paste(
        format(min_date, "%B %Y"),
        "through",
        format(max_date, "%B %Y")
      ),
    )
}

compute_state_results = function(org_raw_states, mw_file) {
  max_date = org_raw_states |>
    summarize(max(month_date)) |>
    pull()
  min_date = max_date - months(11)

  org_in_window = org_raw_states |>
    filter(month_date >= min_date & month_date <= max_date)

  n_months = n_distinct(org_in_window$month_date)
  verify_n_months(n_months, min_date, max_date)

  # keep imputed wages when calculating total wage earning population by state
  state_wage_earners = org_in_window |>
    filter(wageotc > 0) |>
    summarize(total_wage_earners = sum(orgwgt / n_months), .by = statefips)

  # use non-imputed wages for shares
  org_clean = org_raw_states |>
    filter(hourly_wage > 0)

  state_mw_current = load_state_minimum_wages(mw_file, max_date)

  results = map_dfr(
    wage_thresholds,
    \(threshold) {
      create_states_slice(
        threshold,
        org_clean,
        min_date,
        max_date,
        state_wage_earners
      )
    }
  ) |>
    mutate(state_abb = as.character(as_factor(statefips))) |>
    inner_join(state_mw_current, by = "state_abb") |>
    # Mask share and count as NA when the wage threshold is less than the
    # state minimum wage + $1. At thresholds near or below the state minimum,
    # very few workers can legally earn less, so the estimates are unreliable
    # and would be misleading. The +$1 buffer accounts for rounding and
    # measurement error in reported wages.
    mutate(across(
      matches("share|count"),
      ~ ifelse(low_wage_threshold < state_mw + 1, NA, .x)
    )) |>
    mutate(state_mw = label_dollar()(state_mw)) |>
    select(
      state_abb,
      low_wage_threshold,
      low_wage_share,
      low_wage_count,
      state_mw,
      dates,
      obs_count
    ) |>
    arrange(low_wage_threshold, state_abb)

  results
}
