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
      dates = format_date_range(min_date, max_date),
    )
}

compute_state_results = function(org_raw_states, mw_file) {
  window = latest_12m_window(org_raw_states)
  org_in_window = window$data
  min_date = window$min_date
  max_date = window$max_date
  n_months = window$n_months

  # keep imputed wages when calculating total wage earning population by state
  state_wage_earners = org_in_window |>
    filter(wageotc > 0) |>
    summarize(total_wage_earners = sum(orgwgt / n_months), .by = statefips)

  # use non-imputed wages for shares, restricted to the same 12-month window
  org_clean = org_in_window |>
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
