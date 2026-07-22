## Helper functions used across the pipeline

# Restrict data to the most recent 12-month window and verify completeness.
# Returns the windowed data plus the window bounds and month count, so every
# pipeline defines "the latest 12 months" in exactly one place.
latest_12m_window = function(data) {
  max_date = data |>
    summarize(max(month_date)) |>
    pull()
  min_date = max_date - months(11)

  windowed = data |>
    filter(month_date >= min_date & month_date <= max_date)

  n_months = n_distinct(windowed$month_date)
  verify_n_months(n_months, min_date, max_date)

  list(
    data = windowed,
    min_date = min_date,
    max_date = max_date,
    n_months = n_months
  )
}

# Human-readable label for a date range, e.g. "January 2025 through December 2025"
format_date_range = function(min_date, max_date) {
  paste(format(min_date, "%B %Y"), "through", format(max_date, "%B %Y"))
}

# Mask CPS-imputed hourly wages to NA so low-wage shares are computed only from
# reported (non-allocated) wages. The wage source depends on how the worker is
# paid: hourly workers (paidhre == 1) use the hourly-earnings field, flagged by
# a_earnhour; non-hourly workers (paidhre == 0) use weekly earnings, flagged by
# a_weekpay. In each case a flag value of 1 means the Census allocated (imputed)
# the value rather than the respondent reporting it.
mask_imputed_wages = function(data) {
  data |>
    mutate(
      hourly_wage = case_when(
        a_earnhour == 1 & paidhre == 1 ~ NA,
        a_weekpay == 1 & paidhre == 0 ~ NA,
        .default = hourly_wage
      )
    )
}

# Verify that the number of months with data in a 12-month window matches
# expectations given the known missing months
verify_n_months = function(n_months, min_date, max_date) {
  expected = 12 - sum(missing_months >= min_date & missing_months <= max_date)
  tibble(n_months = n_months, expected = expected) |>
    verify(n_months == expected)
  invisible(n_months)
}
