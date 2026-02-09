## Compute historical low-wage workforce time series

summarize_history = function(df, org_count) {
  df |>
    mutate(low_wage = hourly_wage < threshold) |>
    summarize(
      share = weighted.mean(low_wage, w = orgwgt),
      threshold = mean(threshold),
      .by = month_date
    ) |>
    mutate(count = share * org_count / 10^6) |>
    pivot_longer(c(share, count)) |>
    arrange(name, month_date) |>
    mutate(
      value_12m = slide_mean(value, before = 11, complete = TRUE),
      .by = name
    )
}

create_historical_slice = function(
  threshold,
  org_clean,
  cpi_data,
  cpi_base,
  cpi_base_date,
  org_count
) {
  nominal_results = org_clean |>
    mutate(threshold = threshold) |>
    summarize_history(org_count) |>
    mutate(threshold_type = "nominal")

  org_clean |>
    inner_join(cpi_data, by = "month_date") |>
    mutate(threshold = threshold * cpi_u / cpi_base) |>
    summarize_history(org_count) |>
    mutate(threshold_type = "real", real_dollars_date = cpi_base_date) |>
    bind_rows(nominal_results) |>
    filter(month_date >= ym("2010m1")) |>
    rename(threshold_actual = threshold) |>
    # After renaming the column to threshold_actual, `threshold` here
    # resolves to the function argument (the nominal dollar value),
    # not a column -- this is intentional.
    mutate(threshold_nominal = threshold)
}

compute_historical_results = function(org_clean) {
  max_date = org_clean |>
    summarize(max(month_date)) |>
    pull()
  min_date = max_date - months(11)

  cpi_data = c_cpi_u_extended_monthly_sa |>
    mutate(month_date = ym(paste(year, month))) |>
    select(month_date, cpi_u = c_cpi_u_extended)

  cpi_base = cpi_data |>
    filter(month_date == max_date) |>
    pull(cpi_u)

  cpi_base_date = format(max_date, "%B %Y")

  org_count = org_clean |>
    filter(month_date >= min_date & month_date <= max_date) |>
    summarize(sum(orgwgt / 12)) |>
    pull()

  map_dfr(
    wage_thresholds,
    \(threshold) {
      create_historical_slice(
        threshold,
        org_clean,
        cpi_data,
        cpi_base,
        cpi_base_date,
        org_count
      )
    }
  )
}
