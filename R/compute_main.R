## Compute main low-wage workforce results by category and threshold

summarize_data = function(data, ...) {
  summarize_groups(
    data,
    ...,
    low_wage_share = weighted.mean(low_wage, w = orgwgt),
    low_wage_count = round(sum(low_wage * orgwgt / 12) / 1000) * 1000
  )
}

compute_main_results = function(org_clean, asec_data) {
  max_date = org_clean |>
    summarize(max(month_date)) |>
    pull()
  min_date = max_date - months(11)

  create_slice = function(threshold) {
    org_source = org_clean |>
      filter(month_date >= min_date & month_date <= max_date) |>
      mutate(low_wage = hourly_wage < threshold)

    org_percentile = org_source |>
      summarize(weighted.mean(low_wage, w = orgwgt)) |>
      pull()

    org_total = org_source |>
      summarize(sum(orgwgt)) |>
      pull()

    # Firm-size breakdowns come from the ASEC (which has firm-size data the ORG
    # lacks). To make the ASEC results comparable to the ORG:
    #   1. Reweight ASEC observations so total weight matches the ORG total
    #   2. Find the ASEC wage at the same percentile as the ORG low-wage share
    #      (quantile matching), so the ASEC threshold corresponds to the same
    #      population fraction despite differences in the two wage distributions
    #   3. Classify ASEC workers as low-wage using this matched threshold
    asec_results = asec_data |>
      mutate(orgwgt = asecwt * org_total / sum(asecwt)) |>
      mutate(
        wage_threshold = weighted_quantile(
          wage,
          w = orgwgt,
          p = org_percentile
        )
      ) |>
      mutate(low_wage = wage < wage_threshold) |>
      summarize_data(firmsize)

    org_source |>
      summarize_data(
        all |
          wbhao |
          female |
          union |
          part_time |
          educ_group |
          age_group |
          above_fedmw |
          region |
          tipped |
          public |
          faminc_group |
          mind03 |
          mocc03 |
          statefips |
          rtw_state
      ) |>
      bind_rows(asec_results) |>
      mutate(
        dates = paste(
          format(min_date, "%B %Y"),
          "through",
          format(max_date, "%B %Y")
        )
      ) |>
      mutate(low_wage_threshold = threshold)
  }

  results = map_dfr(wage_thresholds, create_slice) |>
    filter(
      group_value_label != "Other",
      group_value_label != "Armed Forces"
    ) |>
    transmute(
      category = group_value_label,
      category_group = group_name,
      low_wage_share = round(low_wage_share * 100),
      low_wage_threshold,
      low_wage_count,
      dates
    ) |>
    mutate(
      priority = case_when(
        category_group == "all" ~ 100,
        category_group == "wbhao" ~ 99,
        category_group == "female" ~ 98,
        category == "Ages 65 and above" ~ 1,
        category_group == "age_group" ~ 2,
        TRUE ~ 0
      )
    ) |>
    mutate(category_group = category_group_labels[category_group]) |>
    mutate(
      category = case_when(
        category == "Under 10" ~ "Under 10 employees",
        category == "10 to 24" ~ "10 to 24 employees",
        category == "25 to 99" ~ "25 to 99 employees",
        category == "100 to 499" ~ "100 to 499 employees",
        category == "500 to 999" ~ "500 to 999 employees",
        category == "1000+" ~ "1000 or more employees",
        .default = category
      )
    ) |>
    # Use factor ordering for firm-size categories so they sort by size
    # rather than alphabetically (e.g., "1000 or more" before "10 to 24")
    mutate(
      sort_key = if_else(
        category_group == "Firm size",
        factor(category, levels = firmsize_display_order) |> as.integer(),
        0L
      )
    ) |>
    arrange(
      low_wage_threshold,
      desc(priority),
      category_group,
      sort_key,
      category
    ) |>
    select(-sort_key)

  results |>
    select(-priority) |>
    filter(category_group != "State") |>
    relocate(
      low_wage_threshold,
      category_group,
      category,
      low_wage_share,
      low_wage_count,
      dates
    )
}
