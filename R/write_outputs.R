## Write CSV output and return file path (for tar_target format = "file")

write_results_csv = function(data, path) {
  write_csv(data, path)
  path
}
