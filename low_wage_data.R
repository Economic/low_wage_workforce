library(tidyverse)
library(epiextractr)
library(epidatatools)
library(lubridate)
library(haven)

org_raw <- load_org(2022:2022) |>
  mutate(my_wage = wageotc) |>
  filter(my_wage > 0) |>
  mutate(month_date = ym(paste(year, month)))

max_date <- org_raw |>
  summarize(max(month_date)) |>
  pull()
min_date <- max_date - months(11)

tipped_occs <- c(
  4040,4055,4110,4130,4400,4500,4510,4521,4522,4525
)
tipped_inds <- c(
  8580,8590,8660,8670,8680,8690,8970,8980,8990,9090
)

state_follows_fed_min <- c("AL", "GA", "ID", "IN", "IA", "KS", "KY", "LA", "MS", "NH", "NC", "ND", "OK", "PA", "SC", "TN", "TX", "UT", "WI", "WY")

org_clean <- org_raw %>% 
  filter(month_date >= min_date & month_date <= max_date) |>
  mutate(all = 1) |>
  mutate(all = labelled(all, c("All workers" = 1))) |>
  mutate(union = labelled(union, c("In a union" = 1, "Not in a union" = 0))) |>
  mutate(part_time = if_else(ftptstat >= 6 & ftptstat <= 10, 1, 0)) |>
  mutate(part_time = labelled(part_time, c("Works part-time" = 1, "Works full-time" = 0))) |>
  mutate(new_educ = ifelse(educ <= 4, educ, 4)) |>
  mutate(new_educ = labelled(new_educ, c(
    "Less than high school diploma" = 1,
    "High school diploma" = 2,
    "Some college" = 3,
    "College or advanced degree" = 4
  ))) |>
  mutate(new_age = case_when(
    age >= 16 & age <= 24 ~ 1,
    age >= 25 & age <= 34 ~ 2,
    age >= 35 & age <= 44 ~ 3,
    age >= 45 & age <= 54 ~ 4,
    age >= 55 & age <= 64 ~ 5,
    age >= 65 ~ 6
  )) |> 
  mutate(new_age = labelled(new_age , c(
    "Ages 16-24" = 1,
    "Ages 25-34" = 2,
    "Ages 35-44" = 3,
    "Ages 45-54" = 4,
    "Ages 55-64" = 5,
    "Ages 65 and above" = 6
  ))) |>
  mutate(above_fedmw = if_else(
    as_factor(statefips) %in% state_follows_fed_min, 0, 1
  )) |>
  mutate(above_fedmw = labelled(above_fedmw, c(
    "State minimum exceeds federal minimum" = 1,
    "State minimum follows federal minimum" = 0
  ))) %>% 
  mutate(tipped = case_when(
    occ18 %in% tipped_occs ~ 1,
    occ18 == 4120 & ind17 %in% tipped_inds ~ 1,
    TRUE ~ 0
  )) %>% 
  mutate(tipped = labelled(tipped, c(
    "Works in a tipped occupation" = 1,
    "Works in a non-tipped occupation" = 0
  ))) %>% 
  mutate(public = case_when(
    cow1 >= 1 & cow1 <= 3 ~ 1,
    cow1 >= 4 & cow1 <= 5 ~ 0
  )) %>% 
  mutate(public = labelled(public, c(
    "Government employee" = 1,
    "Private-sector employee" = 0
  ))) %>% 
  mutate(new_faminc = case_when(
    faminc >= 1 & faminc <= 7 ~ 1,
    faminc >= 8 & faminc <= 11 ~ 2,
    faminc == 12 ~ 3,
    faminc == 13 ~ 4,
    faminc >= 14 ~ 5
  )) %>% 
  mutate(new_faminc = labelled(new_faminc, c(
    "Family income  $24,999 or less" = 1,
    "Family income  $25,000 - $49,999" = 2,
    "Family income  $50,000 - $74,999" = 3,
    "Family income  $75,000 - $99,999" = 4,
    "Family income $100,000 or more" = 5
  )))

create_slice <- function(threshold) {
  org_clean |>
    mutate(low_wage = my_wage < threshold) |>
    summarize_groups(
      all|wbhao|female|union|part_time|new_educ|new_age|above_fedmw|region|tipped|public|new_faminc|mind03|mocc03, 
      low_wage_share = weighted.mean(low_wage, w = orgwgt),
      low_wage_count = round(sum(low_wage * orgwgt / 12) / 1000)*1000
    ) |>
    mutate(dates = paste(format(min_date, "%B %Y"), "through", format(max_date, "%B %Y"))) |>
    mutate(low_wage_threshold = threshold)
}

results <- map_dfr(15:25, create_slice) |>
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
  mutate(priority = case_when(
    category_group == "all" ~ 100,
    category_group == "wbhao" ~ 99,
    category_group == "female" ~ 98,
    category == "Ages 65 and above" ~ 1,
    category_group == "new_age" ~ 2,
    TRUE ~ 0
  )) |>
  mutate(category_group = case_when(
    category_group == "all" ~ "All workers",
    category_group == "female" ~ "Gender",
    category_group == "union" ~ "Union status",
    category_group == "wbhao" ~ "Race and ethnicity",
    category_group == "part_time" ~ "Part-time status",
    category_group == "new_educ" ~ "Education",
    category_group == "new_age" ~ "Age group",
    category_group == "above_fedmw" ~ "State minimum wage",
    category_group == "region" ~ "Region",
    category_group == "tipped" ~ "Tipped occupation",
    category_group == "public" ~ "Private/public sector",
    category_group == "new_faminc" ~ "Annual family income",
    category_group == "mind03" ~ "Industry",
    category_group == "mocc03" ~ "Occupation"
  )) |>
  arrange(low_wage_threshold, desc(priority), category_group, category) 

results |>
  print(n=Inf)

write_csv(results, "low_wage_data.csv")
