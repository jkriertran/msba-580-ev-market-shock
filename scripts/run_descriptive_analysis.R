#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- normalizePath(
  sub("^--file=", "", script_arg[[1]]),
  mustWork = TRUE
)
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
data_dir <- file.path(project_root, "data")
output_dir <- file.path(project_root, "analysis", "results")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

quarterly <- read.csv(
  file.path(data_dir, "quarterly_controls.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
county <- read.csv(
  file.path(data_dir, "county_panel.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
vmt <- read.csv(
  file.path(data_dir, "california_vmt_monthly.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)

quarterly$quarter_start <- as.Date(quarterly$quarter_start)
county$quarter_start <- as.Date(county$quarter_start)
vmt$observation_month <- as.Date(vmt$observation_month)

get_quarter <- function(label) {
  result <- quarterly[quarterly$quarter_label == label, , drop = FALSE]
  if (nrow(result) != 1L) stop("Expected one statewide row for ", label)
  result
}

event_contrast <- function(
  contrast,
  metric,
  from_quarter,
  to_quarter,
  display_unit
) {
  from_value <- get_quarter(from_quarter)[[metric]]
  to_value <- get_quarter(to_quarter)[[metric]]
  data.frame(
    contrast = contrast,
    metric = metric,
    from_quarter = from_quarter,
    to_quarter = to_quarter,
    from_value = from_value,
    to_value = to_value,
    absolute_change = to_value - from_value,
    relative_change = to_value / from_value - 1,
    display_unit = display_unit,
    stringsAsFactors = FALSE
  )
}

event_contrasts <- do.call(rbind, list(
  event_contrast(
    "Pull-forward to post-credit",
    "zev_share", "2025 Q3", "2025 Q4", "proportion"
  ),
  event_contrast(
    "Post-credit to war transition",
    "zev_share", "2025 Q4", "2026 Q1", "proportion"
  ),
  event_contrast(
    "War transition to full post-war",
    "zev_share", "2026 Q1", "2026 Q2", "proportion"
  ),
  event_contrast(
    "Post-credit/pre-war to full post-war",
    "zev_share", "2025 Q4", "2026 Q2", "proportion"
  ),
  event_contrast(
    "Post-credit/pre-war to full post-war",
    "ca_regular_gas_avg", "2025 Q4", "2026 Q2", "dollars_per_gallon"
  ),
  event_contrast(
    "Post-credit/pre-war to full post-war",
    "trends_electric_vehicle", "2025 Q4", "2026 Q2", "relative_index"
  )
))
event_contrasts$absolute_change_percentage_points <- ifelse(
  event_contrasts$metric == "zev_share",
  100 * event_contrasts$absolute_change,
  NA_real_
)
write.csv(
  event_contrasts,
  file.path(output_dir, "event_contrasts.csv"),
  row.names = FALSE,
  na = ""
)

pre_event <- quarterly[
  quarterly$quarter_start <= as.Date("2025-04-01"),
  ,
  drop = FALSE
]
pre_event$calendar_quarter <- factor(pre_event$quarter)
quarterly$calendar_quarter <- factor(
  quarterly$quarter,
  levels = levels(pre_event$calendar_quarter)
)

seasonal_model <- lm(
  zev_share ~ time_index + calendar_quarter,
  data = pre_event
)
prediction <- predict(
  seasonal_model,
  newdata = quarterly,
  interval = "prediction",
  level = 0.95
)
seasonal_benchmark <- data.frame(
  quarter_start = quarterly$quarter_start,
  quarter_label = quarterly$quarter_label,
  observed_zev_share = quarterly$zev_share,
  expected_zev_share = prediction[, "fit"],
  prediction_low = prediction[, "lwr"],
  prediction_high = prediction[, "upr"],
  observed_minus_expected = quarterly$zev_share - prediction[, "fit"],
  benchmark_training_period = quarterly$quarter_start <= as.Date("2025-04-01"),
  stringsAsFactors = FALSE
)
write.csv(
  seasonal_benchmark,
  file.path(output_dir, "seasonal_benchmark.csv"),
  row.names = FALSE
)

model_summary <- data.frame(
  statistic = c(
    "training_quarters",
    "residual_degrees_of_freedom",
    "r_squared",
    "adjusted_r_squared",
    "residual_standard_error"
  ),
  value = c(
    nrow(pre_event),
    df.residual(seasonal_model),
    summary(seasonal_model)$r.squared,
    summary(seasonal_model)$adj.r.squared,
    summary(seasonal_model)$sigma
  )
)
write.csv(
  model_summary,
  file.path(output_dir, "seasonal_model_summary.csv"),
  row.names = FALSE
)

county_base <- county[
  county$county != "Out Of State" &
    county$quarter_label %in% c("2025 Q4", "2026 Q2"),
  c("county", "quarter_label", "zev_sales", "total_ldv_sales", "zev_share")
]
county_q4 <- county_base[county_base$quarter_label == "2025 Q4", ]
county_q2 <- county_base[county_base$quarter_label == "2026 Q2", ]
county_change <- merge(
  county_q4,
  county_q2,
  by = "county",
  suffixes = c("_2025_q4", "_2026_q2"),
  all = FALSE
)
county_change$change_percentage_points <- 100 * (
  county_change$zev_share_2026_q2 - county_change$zev_share_2025_q4
)
county_change$relative_change <- (
  county_change$zev_share_2026_q2 / county_change$zev_share_2025_q4 - 1
)
county_change$average_quarterly_ldv_sales <- rowMeans(cbind(
  county_change$total_ldv_sales_2025_q4,
  county_change$total_ldv_sales_2026_q2
))
county_change$small_market_flag <- (
  county_change$average_quarterly_ldv_sales < 1000
)
county_change <- county_change[
  order(county_change$change_percentage_points, decreasing = TRUE),
]
write.csv(
  county_change,
  file.path(output_dir, "county_changes_2025q4_to_2026q2.csv"),
  row.names = FALSE
)

summarize_counties <- function(data, segment) {
  q4_share <- sum(data$zev_sales_2025_q4) /
    sum(data$total_ldv_sales_2025_q4)
  q2_share <- sum(data$zev_sales_2026_q2) /
    sum(data$total_ldv_sales_2026_q2)
  data.frame(
    segment = segment,
    counties = nrow(data),
    counties_with_increase = sum(data$change_percentage_points > 0),
    median_change_percentage_points = median(data$change_percentage_points),
    lower_quartile_change_percentage_points = unname(
      quantile(data$change_percentage_points, 0.25)
    ),
    upper_quartile_change_percentage_points = unname(
      quantile(data$change_percentage_points, 0.75)
    ),
    aggregate_2025_q4_share = q4_share,
    aggregate_2026_q2_share = q2_share,
    aggregate_change_percentage_points = 100 * (q2_share - q4_share)
  )
}
county_summary <- rbind(
  summarize_counties(county_change, "All California counties"),
  summarize_counties(
    county_change[!county_change$small_market_flag, ],
    "Counties averaging at least 1,000 quarterly LDV sales"
  )
)
write.csv(
  county_summary,
  file.path(output_dir, "county_change_summary.csv"),
  row.names = FALSE
)

share_from_counts <- function(data) {
  sum(data$zev_sales) / sum(data$total_ldv_sales)
}
official_q4 <- get_quarter("2025 Q4")
official_q2 <- get_quarter("2026 Q2")
county_q4_all <- county[county$quarter_label == "2025 Q4", ]
county_q2_all <- county[county$quarter_label == "2026 Q2", ]
county_q4_in_state <- county_q4_all[county_q4_all$county != "Out Of State", ]
county_q2_in_state <- county_q2_all[county_q2_all$county != "Out Of State", ]
county_q4_out_state <- county_q4_all[county_q4_all$county == "Out Of State", ]
county_q2_out_state <- county_q2_all[county_q2_all$county == "Out Of State", ]

geography_sensitivity <- data.frame(
  definition = c(
    "Official CEC statewide total",
    "California county mailing addresses only",
    "Out-of-state mailing-address category"
  ),
  share_2025_q4 = c(
    official_q4$zev_share,
    share_from_counts(county_q4_in_state),
    share_from_counts(county_q4_out_state)
  ),
  share_2026_q2 = c(
    official_q2$zev_share,
    share_from_counts(county_q2_in_state),
    share_from_counts(county_q2_out_state)
  ),
  stringsAsFactors = FALSE
)
geography_sensitivity$change_percentage_points <- 100 * (
  geography_sensitivity$share_2026_q2 -
    geography_sensitivity$share_2025_q4
)
geography_sensitivity$relative_change <- (
  geography_sensitivity$share_2026_q2 /
    geography_sensitivity$share_2025_q4 - 1
)
write.csv(
  geography_sensitivity,
  file.path(output_dir, "geography_definition_sensitivity.csv"),
  row.names = FALSE
)

summarize_vmt_window <- function(start_date, end_date, label) {
  window <- vmt[
    vmt$observation_month >= as.Date(start_date) &
      vmt$observation_month <= as.Date(end_date),
  ]
  data.frame(
    window = label,
    first_month = min(window$observation_month),
    last_month = max(window$observation_month),
    months = nrow(window),
    mean_yoy_change = mean(window$yoy_change),
    median_yoy_change = median(window$yoy_change),
    minimum_yoy_change = min(window$yoy_change),
    maximum_yoy_change = max(window$yoy_change),
    months_below_prior_year = sum(window$yoy_change < 0),
    stringsAsFactors = FALSE
  )
}
vmt_summary <- rbind(
  summarize_vmt_window(
    "2025-03-01", "2025-05-01", "March-May 2025 comparison window"
  ),
  summarize_vmt_window(
    "2026-03-01", "2026-05-01", "March-May 2026 post-war window"
  )
)
write.csv(
  vmt_summary,
  file.path(output_dir, "vmt_window_summary.csv"),
  row.names = FALSE
)

message("Analysis outputs written to ", output_dir)
