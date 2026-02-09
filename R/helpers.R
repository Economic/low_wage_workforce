## Helper functions used across the pipeline

# Verify that the number of months with data in a 12-month window matches
# expectations given the known missing months
verify_n_months = function(n_months, min_date, max_date) {
  expected = 12 - sum(missing_months >= min_date & missing_months <= max_date)
  tibble(n_months = n_months, expected = expected) |>
    verify(n_months == expected)
  invisible(n_months)
}
