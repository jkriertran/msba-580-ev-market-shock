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
  "data/conjoint_survey.csv",
  "data/data_dictionary.csv",
  "analysis/results/cluster_selection.csv",
  "analysis/results/county_segment_profiles.csv",
  "analysis/results/county_segments.csv",
  "analysis/results/regression_coefficients.csv",
  "analysis/results/regression_diagnostics.csv",
  "analysis/results/regression_model_comparison.csv",
  "analysis/results/conjoint_data_audit.csv",
  "analysis/results/conjoint_partworths.csv",
  "analysis/results/conjoint_attribute_tests.csv",
  "analysis/results/conjoint_pairwise_contrasts.csv",
  "report/final_report.Rmd"
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
  ),
  "data/conjoint_survey.csv" = c(
    "SurveyID", "orderShown", "Brand", "MPG", "Price", "Rating"
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

county_segments <- read.csv(
  file.path(project_root, "analysis/results/county_segments.csv"),
  stringsAsFactors = FALSE
)
segment_profiles <- read.csv(
  file.path(project_root, "analysis/results/county_segment_profiles.csv"),
  stringsAsFactors = FALSE
)
cluster_selection <- read.csv(
  file.path(project_root, "analysis/results/cluster_selection.csv"),
  stringsAsFactors = FALSE
)

if (nrow(county_segments) != 58L) {
  stop("County segmentation must contain exactly 58 California counties.")
}
if (length(unique(county_segments$segment)) != 3L) {
  stop("County segmentation must contain exactly three named segments.")
}
if (sum(segment_profiles$counties) != 58L) {
  stop("County segment profile counts must sum to 58.")
}
if (
  sum(cluster_selection$selected) != 1L ||
    cluster_selection$clusters[cluster_selection$selected] != 3L
) {
  stop("Exactly the three-cluster solution must be marked selected.")
}

conjoint <- read.csv(
  file.path(project_root, "data/conjoint_survey.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
if (nrow(conjoint) != 140L || length(unique(conjoint$SurveyID)) != 20L) {
  stop("Conjoint snapshot must contain 140 profiles across 20 SurveyIDs.")
}
if (any(grepl("name", names(conjoint), ignore.case = TRUE))) {
  stop("The sanitized conjoint snapshot must not contain a name column.")
}
valid_ratings <- is.na(conjoint$Rating) |
  conjoint$Rating %in% 1:5
if (!all(valid_ratings) || sum(!is.na(conjoint$Rating)) != 123L) {
  stop("Conjoint ratings must contain 123 valid values from 1 through 5.")
}

partworths <- read.csv(
  file.path(project_root, "analysis/results/conjoint_partworths.csv"),
  stringsAsFactors = FALSE
)
if (
  nrow(partworths) != 9L ||
    any(abs(tapply(
      partworths$utility,
      partworths$attribute,
      sum
    )) > 1e-8)
) {
  stop("Conjoint part-worth utilities must contain nine effect-coded levels.")
}

message("Project validation passed.")
