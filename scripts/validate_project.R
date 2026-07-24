#!/usr/bin/env Rscript

project_root <- normalizePath(
  file.path(dirname(sub("^--file=", "", grep(
    "^--file=", commandArgs(trailingOnly = FALSE), value = TRUE
  )[[1]])), ".."),
  mustWork = TRUE
)

invisible(parse(file.path(project_root, "app.R")))

required_files <- c(
  "data/washington_titles_monthly.csv",
  "data/washington_county_monthly.csv",
  "data/washington_gas_monthly.csv",
  "data/quarterly_controls.csv",
  "data/conjoint_survey.csv",
  "data/data_dictionary.csv",
  "analysis/results/washington_monthly_analysis.csv",
  "analysis/results/washington_model_comparison.csv",
  "analysis/results/washington_its_coefficients.csv",
  "analysis/results/washington_event_summary.csv",
  "analysis/results/washington_county_postwar.csv",
  "analysis/results/washington_data_audit.csv",
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
  "data/washington_titles_monthly.csv" = c(
    "month", "total_new_ldv_titles", "bev_titles", "phev_titles",
    "fcev_titles", "zev_titles", "zev_share", "source_url"
  ),
  "data/washington_county_monthly.csv" = c(
    "county", "month", "total_new_ldv_titles", "zev_titles", "zev_share"
  ),
  "data/washington_gas_monthly.csv" = c(
    "month", "washington_regular_gas_price", "weekly_observations",
    "source_url"
  ),
  "data/quarterly_controls.csv" = c(
    "quarter_start", "zev_sales", "total_ldv_sales", "zev_share"
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

washington <- read.csv(
  file.path(project_root, "data/washington_titles_monthly.csv"),
  stringsAsFactors = FALSE
)
washington$month <- as.Date(washington$month)
expected_months <- seq(
  min(washington$month),
  max(washington$month),
  by = "month"
)
if (
  nrow(washington) < 100L ||
    !identical(washington$month, expected_months) ||
    max(washington$month) < as.Date("2026-06-01")
) {
  stop("Washington statewide series must contain 100+ consecutive months.")
}
recomputed_titles <- with(
  washington,
  bev_titles + phev_titles + fcev_titles
)
if (
  any(recomputed_titles != washington$zev_titles) ||
    any(abs(
      washington$zev_share -
        washington$zev_titles / washington$total_new_ldv_titles
    ) > 1e-10)
) {
  stop("Washington ZEV numerator or share failed recomputation.")
}

county <- read.csv(
  file.path(project_root, "data/washington_county_monthly.csv"),
  stringsAsFactors = FALSE
)
known_counties <- setdiff(unique(county$county), "Unknown or Out of State")
if (length(known_counties) != 39L) {
  stop("Washington county data must contain exactly 39 named counties.")
}

models <- read.csv(
  file.path(project_root, "analysis/results/washington_model_comparison.csv"),
  stringsAsFactors = FALSE
)
if (
  nrow(models) != 3L ||
    sum(models$selected) != 1L ||
    models$rolling_rmse[models$selected] >= .05
) {
  stop("Washington model selection failed expected rolling checks.")
}

its <- read.csv(
  file.path(project_root, "analysis/results/washington_its_coefficients.csv"),
  stringsAsFactors = FALSE
)
if (!all(c("post_credit", "post_war") %in% its$term)) {
  stop("Interrupted-time-series event coefficients are missing.")
}

events <- read.csv(
  file.path(project_root, "analysis/results/washington_event_summary.csv"),
  stringsAsFactors = FALSE
)
if (
  events$months[events$period == "Post-credit / pre-war"] != 4L ||
    events$months[events$period == "Post-war"] != 4L
) {
  stop("Event summary must use four pre-war and four post-war months.")
}

conjoint <- read.csv(
  file.path(project_root, "data/conjoint_survey.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
if (
  nrow(conjoint) != 140L ||
    length(unique(conjoint$SurveyID)) != 20L ||
    any(grepl("name", names(conjoint), ignore.case = TRUE))
) {
  stop("Conjoint snapshot failed size or privacy checks.")
}
valid_ratings <- is.na(conjoint$Rating) | conjoint$Rating %in% 1:5
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

message("Washington-first project validation passed.")
