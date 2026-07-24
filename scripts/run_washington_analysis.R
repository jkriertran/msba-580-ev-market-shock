#!/usr/bin/env Rscript

# Washington-first observed-market analysis.
#
# The primary unit is state-month. The outcome is the share of new light-duty
# original-title transactions classified as BEV, PHEV, or FCEV. Event models
# are descriptive because tax policy, gasoline prices, incentives, and other
# market forces overlap.

options(stringsAsFactors = FALSE)

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- normalizePath(
  sub("^--file=", "", script_arg[[1]]),
  mustWork = TRUE
)
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
output_dir <- file.path(project_root, "analysis", "results")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

pull_script <- file.path(project_root, "scripts", "pull_washington_data.R")
pull_status <- system2(file.path(R.home("bin"), "Rscript"), pull_script)
if (pull_status != 0L) stop("Washington data preparation did not complete.")

required_packages <- c("dplyr", "readr", "tidyr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop("Install required packages: ", paste(missing_packages, collapse = ", "))
}

titles <- readr::read_csv(
  file.path(project_root, "data", "washington_titles_monthly.csv"),
  show_col_types = FALSE
) |>
  dplyr::mutate(month = as.Date(month)) |>
  dplyr::arrange(month)
gas <- readr::read_csv(
  file.path(project_root, "data", "washington_gas_monthly.csv"),
  show_col_types = FALSE
) |>
  dplyr::mutate(month = as.Date(month))
county <- readr::read_csv(
  file.path(project_root, "data", "washington_county_monthly.csv"),
  show_col_types = FALSE
) |>
  dplyr::mutate(month = as.Date(month))

expected_months <- seq(min(titles$month), max(titles$month), by = "month")
if (
  nrow(titles) != length(expected_months) ||
    !identical(titles$month, expected_months)
) {
  stop("Washington statewide title series must contain consecutive months.")
}
if (
  any(titles$total_new_ldv_titles <= 0) ||
    any(titles$zev_titles > titles$total_new_ldv_titles)
) {
  stop("Washington title counts failed numerator/denominator checks.")
}

analysis_data <- titles |>
  dplyr::left_join(
    dplyr::select(gas, month, washington_regular_gas_price),
    by = "month"
  ) |>
  dplyr::mutate(
    time_index = dplyr::row_number(),
    calendar_month = factor(format(month, "%m")),
    covid_disruption = as.integer(
      month >= as.Date("2020-03-01") &
        month <= as.Date("2021-06-01")
    ),
    post_credit = as.integer(month >= as.Date("2025-11-01")),
    post_war = as.integer(month >= as.Date("2026-03-01")),
    event_period = dplyr::case_when(
      month >= as.Date("2026-03-01") ~ "Post-war",
      month >= as.Date("2025-11-01") ~ "Post-credit / pre-war",
      month >= as.Date("2025-07-01") ~ "Credit pull-forward / processing",
      TRUE ~ "Pre-event"
    )
  )

benchmark_end <- as.Date("2025-06-01")
benchmark_training <- dplyr::filter(
  analysis_data,
  month <= benchmark_end
)

candidate_formulas <- list(
  seasonal_only = zev_share ~ calendar_month + covid_disruption,
  linear_time_season = (
    zev_share ~ time_index + calendar_month + covid_disruption
  ),
  quadratic_time_season = (
    zev_share ~ time_index + I(time_index^2) +
      calendar_month + covid_disruption
  )
)

rolling_start <- which(analysis_data$month == as.Date("2022-01-01"))
rolling_end <- which(analysis_data$month == benchmark_end)
rolling_rows <- list()
for (model_name in names(candidate_formulas)) {
  errors <- numeric()
  for (test_index in seq(rolling_start, rolling_end)) {
    rolling_training <- analysis_data[seq_len(test_index - 1L), ]
    rolling_model <- lm(
      candidate_formulas[[model_name]],
      data = rolling_training
    )
    rolling_prediction <- predict(
      rolling_model,
      newdata = analysis_data[test_index, , drop = FALSE]
    )
    errors <- c(
      errors,
      analysis_data$zev_share[test_index] - rolling_prediction
    )
  }
  fitted_model <- lm(
    candidate_formulas[[model_name]],
    data = benchmark_training
  )
  rolling_rows[[model_name]] <- data.frame(
    model = model_name,
    training_months = nrow(benchmark_training),
    parameters = length(coef(fitted_model)),
    adjusted_r_squared = summary(fitted_model)$adj.r.squared,
    aic = AIC(fitted_model),
    rolling_months = length(errors),
    rolling_rmse = sqrt(mean(errors^2)),
    rolling_mae = mean(abs(errors)),
    stringsAsFactors = FALSE
  )
}
model_comparison <- dplyr::bind_rows(rolling_rows) |>
  dplyr::mutate(selected = rolling_rmse == min(rolling_rmse))
readr::write_csv(
  model_comparison,
  file.path(output_dir, "washington_model_comparison.csv")
)

selected_name <- model_comparison$model[model_comparison$selected][1]
selected_formula <- candidate_formulas[[selected_name]]
benchmark_model <- lm(selected_formula, data = benchmark_training)
rolling_rmse <- model_comparison$rolling_rmse[model_comparison$selected][1]
expected_share <- as.numeric(predict(benchmark_model, newdata = analysis_data))
analysis_data <- analysis_data |>
  dplyr::mutate(
    expected_zev_share = expected_share,
    empirical_prediction_low = pmax(0, expected_share - 1.96 * rolling_rmse),
    empirical_prediction_high = pmin(1, expected_share + 1.96 * rolling_rmse),
    observed_minus_expected = zev_share - expected_share,
    benchmark_training_period = month <= benchmark_end
  )
readr::write_csv(
  analysis_data,
  file.path(output_dir, "washington_monthly_analysis.csv")
)

newey_west_vcov <- function(model, lag = 4L) {
  design <- model.matrix(model)
  model_residuals <- residuals(model)
  observations <- nrow(design)
  coefficients <- ncol(design)
  meat <- matrix(0, coefficients, coefficients)
  for (row_index in seq_len(observations)) {
    meat <- meat + model_residuals[row_index]^2 *
      tcrossprod(design[row_index, ])
  }
  for (lag_index in seq_len(lag)) {
    weight <- 1 - lag_index / (lag + 1)
    for (row_index in seq.int(lag_index + 1L, observations)) {
      current <- design[row_index, ]
      lagged <- design[row_index - lag_index, ]
      cross_term <- tcrossprod(current, lagged)
      meat <- meat + weight *
        model_residuals[row_index] *
        model_residuals[row_index - lag_index] *
        (cross_term + t(cross_term))
    }
  }
  bread <- solve(crossprod(design))
  finite_sample <- observations / (observations - coefficients)
  finite_sample * bread %*% meat %*% bread
}

event_model <- lm(
  zev_share ~ time_index + I(time_index^2) +
    calendar_month + covid_disruption + post_credit + post_war,
  data = analysis_data
)
event_vcov <- newey_west_vcov(event_model, lag = 4L)
event_estimates <- coef(event_model)
event_standard_errors <- sqrt(diag(event_vcov))
event_degrees_freedom <- df.residual(event_model)
event_critical <- qt(0.975, df = event_degrees_freedom)
event_coefficients <- data.frame(
  term = names(event_estimates),
  estimate = as.numeric(event_estimates),
  newey_west_standard_error = event_standard_errors,
  t_value = event_estimates / event_standard_errors,
  p_value = 2 * pt(
    abs(event_estimates / event_standard_errors),
    df = event_degrees_freedom,
    lower.tail = FALSE
  ),
  confidence_low = event_estimates -
    event_critical * event_standard_errors,
  confidence_high = event_estimates +
    event_critical * event_standard_errors,
  stringsAsFactors = FALSE
)
readr::write_csv(
  event_coefficients,
  file.path(output_dir, "washington_its_coefficients.csv")
)

period_definitions <- data.frame(
  period = c(
    "Pre-credit reference",
    "Credit pull-forward / processing",
    "Post-credit / pre-war",
    "Post-war"
  ),
  start = as.Date(c(
    "2025-01-01",
    "2025-07-01",
    "2025-11-01",
    "2026-03-01"
  )),
  end = as.Date(c(
    "2025-06-01",
    "2025-10-01",
    "2026-02-01",
    "2026-06-01"
  ))
)
event_summary_rows <- lapply(
  seq_len(nrow(period_definitions)),
  function(row_index) {
    definition <- period_definitions[row_index, ]
    period_data <- dplyr::filter(
      analysis_data,
      month >= definition$start,
      month <= definition$end
    )
    data.frame(
      period = definition$period,
      start_month = definition$start,
      end_month = definition$end,
      months = nrow(period_data),
      new_ldv_titles = sum(period_data$total_new_ldv_titles),
      zev_titles = sum(period_data$zev_titles),
      pooled_zev_share = (
        sum(period_data$zev_titles) /
          sum(period_data$total_new_ldv_titles)
      ),
      mean_expected_zev_share = weighted.mean(
        period_data$expected_zev_share,
        period_data$total_new_ldv_titles
      ),
      observed_minus_expected = (
        sum(period_data$zev_titles) /
          sum(period_data$total_new_ldv_titles)
      ) - weighted.mean(
        period_data$expected_zev_share,
        period_data$total_new_ldv_titles
      ),
      mean_gas_price = mean(
        period_data$washington_regular_gas_price,
        na.rm = TRUE
      )
    )
  }
)
event_summary <- dplyr::bind_rows(event_summary_rows)
readr::write_csv(
  event_summary,
  file.path(output_dir, "washington_event_summary.csv")
)

county_period <- county |>
  dplyr::filter(county != "Unknown or Out of State") |>
  dplyr::mutate(
    period = dplyr::case_when(
      month >= as.Date("2026-03-01") &
        month <= as.Date("2026-06-01") ~ "Post-war",
      month >= as.Date("2025-11-01") &
        month <= as.Date("2026-02-01") ~ "Post-credit / pre-war",
      TRUE ~ NA_character_
    )
  ) |>
  dplyr::filter(!is.na(period)) |>
  dplyr::group_by(county, period) |>
  dplyr::summarise(
    new_ldv_titles = sum(total_new_ldv_titles),
    zev_titles = sum(zev_titles),
    zev_share = zev_titles / new_ldv_titles,
    .groups = "drop"
  ) |>
  tidyr::pivot_wider(
    names_from = period,
    values_from = c(new_ldv_titles, zev_titles, zev_share),
    names_sep = "__"
  ) |>
  dplyr::transmute(
    county,
    prewar_new_ldv_titles = `new_ldv_titles__Post-credit / pre-war`,
    postwar_new_ldv_titles = `new_ldv_titles__Post-war`,
    prewar_zev_titles = `zev_titles__Post-credit / pre-war`,
    postwar_zev_titles = `zev_titles__Post-war`,
    prewar_zev_share = `zev_share__Post-credit / pre-war`,
    postwar_zev_share = `zev_share__Post-war`,
    change_percentage_points = 100 * (
      postwar_zev_share - prewar_zev_share
    )
  ) |>
  dplyr::arrange(dplyr::desc(postwar_new_ldv_titles))
readr::write_csv(
  county_period,
  file.path(output_dir, "washington_county_postwar.csv")
)

unknown_county_titles <- county |>
  dplyr::filter(county == "Unknown or Out of State") |>
  dplyr::summarise(value = sum(total_new_ldv_titles)) |>
  dplyr::pull(value)
data_audit <- data.frame(
  metric = c(
    "first_month",
    "last_month",
    "consecutive_months",
    "total_new_ldv_titles",
    "total_zev_titles",
    "counties_excluding_unknown",
    "unknown_or_out_of_state_title_share",
    "benchmark_training_months",
    "rolling_validation_months",
    "selected_benchmark_model",
    "selected_rolling_rmse"
  ),
  value = c(
    as.character(min(titles$month)),
    as.character(max(titles$month)),
    nrow(titles),
    sum(titles$total_new_ldv_titles),
    sum(titles$zev_titles),
    dplyr::n_distinct(
      county$county[county$county != "Unknown or Out of State"]
    ),
    unknown_county_titles / sum(titles$total_new_ldv_titles),
    nrow(benchmark_training),
    rolling_end - rolling_start + 1L,
    selected_name,
    rolling_rmse
  ),
  stringsAsFactors = FALSE
)
readr::write_csv(
  data_audit,
  file.path(output_dir, "washington_data_audit.csv")
)

message("Washington analysis outputs written to ", output_dir, ".")
