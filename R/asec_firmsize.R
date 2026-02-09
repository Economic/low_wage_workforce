clean_asec_firmsize = function() {
  # variables for extract
  raw_variables = c(
    "YEAR",
    "ASECWT",
    "INCWAGE",
    "WKSWORK1",
    "UHRSWORKLY",
    "CLASSWLY",
    "FIRMSIZE"
  )

  # sample ids from https://cps.ipums.org/cps-action/samples/sample_ids
  sample_ids = c("cps2022_03s")

  # extract specification
  extract_definition = define_extract_cps(
    description = "ASEC extract with firm sizes",
    samples = sample_ids,
    variables = raw_variables
  )

  # submit extract
  submitted_extract = submit_extract(extract_definition)

  # wait until ready
  downloadable_extract = wait_for_extract(submitted_extract)

  # download extract and save path
  path_to_ddi_file = download_extract(downloadable_extract)

  # read data
  read_ipums_micro(path_to_ddi_file) |>
    clean_names() |>
    filter(
      asecwt > 0,
      incwage > 0 & incwage < 99999998,
      wkswork1 > 0,
      uhrsworkly <= 99,
      classwly >= 22 & classwly <= 28
    ) |>
    mutate(wage = incwage / (wkswork1 * uhrsworkly)) |>
    select(asecwt, wage, firmsize) |>
    write_feather("asec_2022_wage_firmsize.feather")
}
