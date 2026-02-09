## Hard-coded constants used across the pipeline

wage_thresholds = 10:25

# Firm-size categories in display order (used for sorting in compute_main.R)
firmsize_display_order = c(
  "Under 10 employees",
  "10 to 24 employees",
  "25 to 99 employees",
  "100 to 499 employees",
  "500 to 999 employees",
  "1000 or more employees"
)

# Map from internal column names to display names for category groups.
# summarize_groups() returns the column name as group_name; this translates
# those internal names to the human-readable names used in the CSV output.
category_group_labels = c(
  "all" = "All workers",
  "female" = "Gender",
  "union" = "Union status",
  "wbhao" = "Race and ethnicity",
  "part_time" = "Part-time status",
  "educ_group" = "Education",
  "age_group" = "Age group",
  "above_fedmw" = "State minimum wage",
  "region" = "Region",
  "tipped" = "Tipped occupation",
  "public" = "Private/public sector",
  "faminc_group" = "Annual family income",
  "mind03" = "Industry",
  "mocc03" = "Occupation",
  "statefips" = "State",
  "firmsize" = "Firm size",
  "rtw_state" = "Right-to-work"
)

tipped_occs = c(
  4040,
  4055,
  4110,
  4130,
  4400,
  4500,
  4510,
  4521,
  4522,
  4525
)

tipped_inds = c(
  8580,
  8590,
  8660,
  8670,
  8680,
  8690,
  8970,
  8980,
  8990,
  9090
)

state_follows_fed_min = c(
  "AL",
  "GA",
  "ID",
  "IN",
  "IA",
  "KS",
  "KY",
  "LA",
  "MS",
  "NH",
  "NC",
  "ND",
  "OK",
  "PA",
  "SC",
  "TN",
  "TX",
  "UT",
  "WI",
  "WY"
)

state_is_rtw = c(
  "AL",
  "AZ",
  "AR",
  "FL",
  "GA",
  "ID",
  "IN",
  "IA",
  "KS",
  "KY",
  "LA",
  "MS",
  "NE",
  "NV",
  "NC",
  "ND",
  "OK",
  "SC",
  "SD",
  "TN",
  "TX",
  "UT",
  "VA",
  "WV",
  "WI",
  "WY"
)
