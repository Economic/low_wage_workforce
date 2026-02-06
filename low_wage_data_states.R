library(tidyverse)
library(epiextractr)
library(epidatatools)
library(haven)

org_raw <- load_org(
  2023:2025,
  year,
  month,
  orgwgt,
  matches("wage"),
  matches("a_"),
  paidhre,
  statefips
) |>
  mutate(my_wage = wageotc) |>
  mutate(
    my_wage = case_when(
      a_earnhour == 1 & paidhre == 1 ~ NA,
      a_weekpay == 1 & paidhre == 0 ~ NA,
      .default = my_wage
    )
  ) %>%
  mutate(month_date = ym(paste(year, month))) |>
  filter(month_date <= ym("2025 June"))

max_date <- org_raw |>
  summarize(max(month_date)) |>
  pull()
min_date <- max_date - months(11)

# keep imputed wages when calculating total wage earning population by state
state_wage_earners <- org_raw %>%
  filter(month_date >= min_date & month_date <= max_date) %>%
  filter(wageotc > 0) %>%
  summarize(total_wage_earners = sum(orgwgt / 12), .by = statefips)

# use non-imputed wages for shares
org_clean <- org_raw %>%
  filter(my_wage > 0)

state_mw_current <- read_csv("mw_projections_20250315_state.csv") |>
  janitor::clean_names() |>
  mutate(notes = my(notes)) |>
  filter(notes == max_date) %>%
  select(-cpi_value, -notes, -us) %>%
  pivot_longer(everything(), names_to = "state_abb", values_to = "state_mw") %>%
  mutate(
    state_abb = str_to_upper(state_abb),
    state_mw = as.numeric(str_replace(state_mw, "\\$", ""))
  )

create_slice <- function(threshold) {
  org_clean |>
    mutate(low_wage = my_wage < threshold) |>
    summarize(
      low_wage_share = weighted.mean(low_wage, w = orgwgt),
      obs_count = n(),
      .by = statefips
    ) |>
    inner_join(state_wage_earners, by = "statefips") %>%
    mutate(
      low_wage_count = round(low_wage_share * total_wage_earners / 1000) * 1000,
      low_wage_threshold = threshold,
      dates = paste(
        format(min_date, "%B %Y"),
        "through",
        format(max_date, "%B %Y")
      ),
    )
}

results <- map_dfr(10:25, create_slice) |>
  mutate(state_abb = as.character(haven::as_factor(statefips))) %>%
  inner_join(state_mw_current, by = "state_abb") %>%
  mutate(across(
    matches("share|count"),
    ~ ifelse(low_wage_threshold < state_mw + 1, NA, .x)
  )) %>%
  mutate(state_mw = scales::label_dollar()(state_mw)) %>%
  select(
    state_abb,
    low_wage_threshold,
    low_wage_share,
    low_wage_count,
    state_mw,
    dates,
    obs_count
  ) %>%
  arrange(low_wage_threshold, state_abb)

results %>%
  write_csv("low_wage_data_states.csv")
