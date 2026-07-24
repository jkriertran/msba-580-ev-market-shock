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

model_candidates <- list(
  mean_only = lm(zev_share ~ 1, data = pre_event),
  time_only = lm(zev_share ~ time_index, data = pre_event),
  seasonal_only = lm(zev_share ~ calendar_quarter, data = pre_event),
  time_plus_season = seasonal_model
)

model_comparison <- do.call(rbind, lapply(
  names(model_candidates),
  function(model_name) {
    model <- model_candidates[[model_name]]
    model_residuals <- residuals(model)
    leverage <- hatvalues(model)
    parameter_count <- length(coef(model)) + 1L
    sample_size <- nobs(model)
    aicc_adjustment <- if (
      sample_size - parameter_count - 1L > 0L
    ) {
      2 * parameter_count * (parameter_count + 1L) /
        (sample_size - parameter_count - 1L)
    } else {
      NA_real_
    }
    data.frame(
      model = model_name,
      observations = sample_size,
      parameters_including_variance = parameter_count,
      r_squared = summary(model)$r.squared,
      adjusted_r_squared = summary(model)$adj.r.squared,
      aic = AIC(model),
      aicc = AIC(model) + aicc_adjustment,
      leave_one_out_rmse = sqrt(mean(
        (model_residuals / (1 - leverage))^2
      )),
      stringsAsFactors = FALSE
    )
  }
))
write.csv(
  model_comparison,
  file.path(output_dir, "regression_model_comparison.csv"),
  row.names = FALSE
)

coefficient_matrix <- coef(summary(seasonal_model))
coefficient_intervals <- confint(seasonal_model, level = 0.95)
regression_coefficients <- data.frame(
  term = rownames(coefficient_matrix),
  estimate = coefficient_matrix[, "Estimate"],
  standard_error = coefficient_matrix[, "Std. Error"],
  t_value = coefficient_matrix[, "t value"],
  p_value = coefficient_matrix[, "Pr(>|t|)"],
  confidence_low = coefficient_intervals[, 1],
  confidence_high = coefficient_intervals[, 2],
  row.names = NULL,
  stringsAsFactors = FALSE
)

model_matrix <- model.matrix(seasonal_model)
model_residuals <- residuals(seasonal_model)
sample_size <- nrow(model_matrix)
coefficient_count <- ncol(model_matrix)
inverse_crossproduct <- solve(crossprod(model_matrix))
hc1_meat <- crossprod(model_matrix, model_matrix * as.numeric(model_residuals^2))
hc1_vcov <- (
  sample_size / (sample_size - coefficient_count)
) * inverse_crossproduct %*% hc1_meat %*% inverse_crossproduct
hc1_standard_error <- sqrt(diag(hc1_vcov))
hc1_t_value <- coef(seasonal_model) / hc1_standard_error
hc1_degrees_freedom <- df.residual(seasonal_model)
regression_coefficients$hc1_standard_error <- hc1_standard_error
regression_coefficients$hc1_t_value <- hc1_t_value
regression_coefficients$hc1_p_value <- 2 * pt(
  abs(hc1_t_value),
  df = hc1_degrees_freedom,
  lower.tail = FALSE
)
regression_coefficients$hc1_confidence_low <- (
  coef(seasonal_model) -
    qt(0.975, df = hc1_degrees_freedom) * hc1_standard_error
)
regression_coefficients$hc1_confidence_high <- (
  coef(seasonal_model) +
    qt(0.975, df = hc1_degrees_freedom) * hc1_standard_error
)
write.csv(
  regression_coefficients,
  file.path(output_dir, "regression_coefficients.csv"),
  row.names = FALSE
)

shapiro_result <- shapiro.test(model_residuals)
durbin_watson_statistic <- (
  sum(diff(model_residuals)^2) / sum(model_residuals^2)
)
cooks_distance <- cooks.distance(seasonal_model)
regression_diagnostics <- data.frame(
  diagnostic = c(
    "observations",
    "residual_degrees_of_freedom",
    "residual_standard_error",
    "shapiro_wilk_statistic",
    "shapiro_wilk_p_value",
    "durbin_watson_statistic",
    "maximum_cooks_distance",
    "influential_observations_above_4_over_n",
    "leave_one_out_rmse"
  ),
  value = c(
    nobs(seasonal_model),
    df.residual(seasonal_model),
    summary(seasonal_model)$sigma,
    unname(shapiro_result$statistic),
    shapiro_result$p.value,
    durbin_watson_statistic,
    max(cooks_distance),
    sum(cooks_distance > 4 / nobs(seasonal_model)),
    sqrt(mean(
      (model_residuals / (1 - hatvalues(seasonal_model)))^2
    ))
  ),
  interpretation = c(
    "Pre-event quarterly observations used for estimation",
    "Small residual degrees of freedom limit inference",
    "Typical in-sample residual size in ZEV-share proportions",
    "Normality diagnostic; low power with only 10 observations",
    "Values below 0.05 would flag non-normal residuals",
    "Approximate residual autocorrelation diagnostic; no formal p-value",
    "Largest single-observation influence measure",
    "Count exceeding the common 4/n screening threshold",
    "Out-of-sample-style error estimated by leave-one-out residuals"
  ),
  stringsAsFactors = FALSE
)
write.csv(
  regression_diagnostics,
  file.path(output_dir, "regression_diagnostics.csv"),
  row.names = FALSE
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

if (!requireNamespace("cluster", quietly = TRUE)) {
  stop("The recommended R package 'cluster' is required for segmentation.")
}

county_segment_features <- data.frame(
  baseline_share_percentage_points = 100 *
    county_change$zev_share_2025_q4,
  change_percentage_points = county_change$change_percentage_points,
  log_average_quarterly_ldv_sales = log1p(
    county_change$average_quarterly_ldv_sales
  )
)
scaled_segment_features <- scale(county_segment_features)
segment_distance <- dist(scaled_segment_features)
candidate_k <- 2:6
set.seed(580)
segment_models <- lapply(candidate_k, function(k) {
  kmeans(scaled_segment_features, centers = k, nstart = 100)
})
mean_silhouette <- vapply(
  seq_along(candidate_k),
  function(index) {
    mean(cluster::silhouette(
      segment_models[[index]]$cluster,
      segment_distance
    )[, "sil_width"])
  },
  numeric(1)
)
cluster_selection <- data.frame(
  clusters = candidate_k,
  mean_silhouette_width = mean_silhouette,
  selected = candidate_k == 3L,
  selection_reason = ifelse(
    candidate_k == 3L,
    paste(
      "Selected for parsimony and business interpretability;",
      "its silhouette is effectively tied with the maximum."
    ),
    ""
  ),
  stringsAsFactors = FALSE
)
write.csv(
  cluster_selection,
  file.path(output_dir, "cluster_selection.csv"),
  row.names = FALSE
)

selected_segment_model <- segment_models[[which(candidate_k == 3L)]]
raw_cluster <- selected_segment_model$cluster
raw_profiles <- aggregate(
  county_segment_features,
  by = list(raw_cluster = raw_cluster),
  FUN = mean
)
stalled_cluster <- raw_profiles$raw_cluster[
  which.min(raw_profiles$change_percentage_points)
]
large_market_cluster <- raw_profiles$raw_cluster[
  which.max(raw_profiles$log_average_quarterly_ldv_sales)
]
fast_rebound_cluster <- setdiff(
  raw_profiles$raw_cluster,
  c(stalled_cluster, large_market_cluster)
)
segment_label_lookup <- setNames(
  c(
    "Low-adoption / stalled",
    "Large established EV markets",
    "Small-market / fast rebound"
  ),
  c(stalled_cluster, large_market_cluster, fast_rebound_cluster)
)
county_change$segment_id <- raw_cluster
county_change$segment <- unname(
  segment_label_lookup[as.character(raw_cluster)]
)
county_segments <- county_change[
  order(county_change$segment, county_change$county),
]
write.csv(
  county_segments,
  file.path(output_dir, "county_segments.csv"),
  row.names = FALSE
)

segment_actions <- c(
  "Low-adoption / stalled" = paste(
    "Investigate affordability and charging barriers before increasing",
    "inventory; target education and incentive communication."
  ),
  "Large established EV markets" = paste(
    "Prioritize inventory availability and conversion campaigns where",
    "the addressable market is already large."
  ),
  "Small-market / fast rebound" = paste(
    "Use light-touch campaigns and avoid inventory overreaction because",
    "small sales denominators make growth rates volatile."
  )
)
segment_profile_rows <- lapply(
  sort(unique(county_segments$segment)),
  function(segment_name) {
    segment_data <- county_segments[
      county_segments$segment == segment_name,
    ]
    data.frame(
      segment = segment_name,
      counties = nrow(segment_data),
      mean_baseline_share_percentage_points = mean(
        100 * segment_data$zev_share_2025_q4
      ),
      mean_change_percentage_points = mean(
        segment_data$change_percentage_points
      ),
      median_change_percentage_points = median(
        segment_data$change_percentage_points
      ),
      mean_average_quarterly_ldv_sales = mean(
        segment_data$average_quarterly_ldv_sales
      ),
      counties_with_increase = sum(
        segment_data$change_percentage_points > 0
      ),
      recommended_action = unname(segment_actions[segment_name]),
      stringsAsFactors = FALSE
    )
  }
)
county_segment_profiles <- do.call(rbind, segment_profile_rows)
write.csv(
  county_segment_profiles,
  file.path(output_dir, "county_segment_profiles.csv"),
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
