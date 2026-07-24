#!/usr/bin/env Rscript

project_root <- normalizePath(
  file.path(dirname(sub("^--file=", "", grep(
    "^--file=", commandArgs(trailingOnly = FALSE), value = TRUE
  )[[1]])), ".."),
  mustWork = TRUE
)

invisible(parse(file.path(project_root, "app.R")))

required_files <- c(
  "data/quarterly_controls.csv",
  "data/county_panel.csv",
  "data/california_vmt_monthly.csv",
  "data/data_dictionary.csv"
)

missing_files <- required_files[
  !file.exists(file.path(project_root, required_files))
]
if (length(missing_files)) {
  stop("Missing required files: ", paste(missing_files, collapse = ", "))
}

required_columns <- list(
  "data/quarterly_controls.csv" = c(
    "quarter_start", "quarter_label", "zev_sales", "total_ldv_sales",
    "zev_share", "ca_regular_gas_avg", "trends_electric_vehicle"
  ),
  "data/county_panel.csv" = c(
    "year", "quarter", "county", "zev_sales", "total_ldv_sales", "zev_share"
  ),
  "data/california_vmt_monthly.csv" = c(
    "observation_month", "vmt_million_miles", "yoy_change",
    "estimate_status", "source_url"
  )
)

for (path in names(required_columns)) {
  header <- names(read.csv(
    file.path(project_root, path),
    nrows = 1,
    check.names = FALSE
  ))
  missing_columns <- setdiff(required_columns[[path]], header)
  if (length(missing_columns)) {
    stop(path, " is missing: ", paste(missing_columns, collapse = ", "))
  }
}

message("Project validation passed.")
