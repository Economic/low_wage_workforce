## Clean and label ORG data for the main and historical pipelines

clean_org_data = function(org_raw) {
  org_raw |>
    mutate(
      all = labelled(1, c("All workers" = 1)),
      union = labelled(union, c("In a union" = 1, "Not in a union" = 0)),
      part_time = labelled(
        if_else(ftptstat >= 6 & ftptstat <= 10, 1, 0),
        c("Works part-time" = 1, "Works full-time" = 0)
      ),
      educ_group = labelled(
        ifelse(educ <= 4, educ, 4),
        c(
          "Less than high school diploma" = 1,
          "High school diploma" = 2,
          "Some college" = 3,
          "College or advanced degree" = 4
        )
      ),
      age_group = labelled(
        case_when(
          age >= 16 & age <= 24 ~ 1,
          age >= 25 & age <= 34 ~ 2,
          age >= 35 & age <= 44 ~ 3,
          age >= 45 & age <= 54 ~ 4,
          age >= 55 & age <= 64 ~ 5,
          age >= 65 ~ 6
        ),
        c(
          "Ages 16-24" = 1,
          "Ages 25-34" = 2,
          "Ages 35-44" = 3,
          "Ages 45-54" = 4,
          "Ages 55-64" = 5,
          "Ages 65 and above" = 6
        )
      ),
      above_fedmw = labelled(
        if_else(as_factor(statefips) %in% state_follows_fed_min, 0, 1),
        c(
          "State minimum exceeds federal minimum" = 1,
          "State minimum follows federal minimum" = 0
        )
      ),
      rtw_state = labelled(
        if_else(as_factor(statefips) %in% state_is_rtw, 1, 0),
        c(
          "Right-to-work state" = 1,
          "Non-right-to-work state" = 0
        )
      ),
      tipped = labelled(
        case_when(
          occ18 %in% tipped_occs ~ 1,
          occ18 == 4120 & ind17 %in% tipped_inds ~ 1,
          TRUE ~ 0
        ),
        c(
          "Works in a tipped occupation" = 1,
          "Works in a non-tipped occupation" = 0
        )
      ),
      public = labelled(
        case_when(
          cow1 >= 1 & cow1 <= 3 ~ 1,
          cow1 >= 4 & cow1 <= 5 ~ 0
        ),
        c(
          "Government employee" = 1,
          "Private-sector employee" = 0
        )
      ),
      faminc_group = labelled(
        case_when(
          faminc >= 1 & faminc <= 7 ~ 1,
          faminc >= 8 & faminc <= 11 ~ 2,
          faminc == 12 ~ 3,
          faminc == 13 ~ 4,
          faminc >= 14 ~ 5
        ),
        c(
          "Family income  $24,999 or less" = 1,
          "Family income  $25,000 - $49,999" = 2,
          "Family income  $50,000 - $74,999" = 3,
          "Family income  $75,000 - $99,999" = 4,
          "Family income $100,000 or more" = 5
        )
      )
    )
}
