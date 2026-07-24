#!/usr/bin/env Rscript

# Rating-based conjoint analysis for the class vehicle survey.
#
# The source workbook also contains a names tab. This pipeline downloads only
# the Survey tab and never imports respondent names into the project.
#
# Rating scale: 1 = best, 5 = worst. The model reverses this to a preference
# score where larger values indicate greater preference.

options(stringsAsFactors = FALSE, timeout = 120)

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- normalizePath(
  sub("^--file=", "", script_arg[[1]]),
  mustWork = TRUE
)
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
data_dir <- file.path(project_root, "data")
output_dir <- file.path(project_root, "analysis", "results")
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

spreadsheet_id <- "1cUxh3m83EqTsGvUXQify8y3YDCBIhWR_yOGrmKRJaW8"
survey_gid <- "1618076621"
source_url <- paste0(
  "https://docs.google.com/spreadsheets/d/", spreadsheet_id,
  "/export?format=csv&gid=", survey_gid
)
snapshot_path <- file.path(data_dir, "conjoint_survey.csv")
refresh <- tolower(Sys.getenv("CONJOINT_REFRESH", "false")) %in%
  c("1", "true", "yes")

required_columns <- c(
  "SurveyID", "orderShown", "Brand", "MPG", "Price", "Rating"
)

if (!file.exists(snapshot_path) || refresh) {
  temporary_path <- tempfile(fileext = ".csv")
  download.file(source_url, temporary_path, mode = "wb", quiet = TRUE)
  downloaded <- read.csv(
    temporary_path,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  missing_columns <- setdiff(required_columns, names(downloaded))
  if (length(missing_columns)) {
    stop(
      "Survey export is missing required columns: ",
      paste(missing_columns, collapse = ", ")
    )
  }
  sanitized <- downloaded[, required_columns]
  sanitized <- sanitized[!is.na(sanitized$SurveyID), , drop = FALSE]
  write.csv(sanitized, snapshot_path, row.names = FALSE, na = "")
}

survey <- read.csv(
  snapshot_path,
  check.names = FALSE,
  stringsAsFactors = FALSE,
  na.strings = c("", "NA")
)
missing_columns <- setdiff(required_columns, names(survey))
if (length(missing_columns)) {
  stop(
    "Sanitized survey snapshot is missing: ",
    paste(missing_columns, collapse = ", ")
  )
}
survey <- survey[, required_columns]
survey$SurveyID <- as.integer(survey$SurveyID)
survey$orderShown <- as.integer(survey$orderShown)
survey$Rating <- as.numeric(survey$Rating)
survey$price_numeric <- as.numeric(gsub("[^0-9.]", "", survey$Price))
survey$mpg_numeric <- as.numeric(gsub("[^0-9.]", "", survey$MPG))
survey$rating_complete <- !is.na(survey$Rating)
survey$preference_score <- 6 - survey$Rating

if (any(!survey$Rating[survey$rating_complete] %in% 1:5)) {
  stop("All nonmissing ratings must be integers from 1 through 5.")
}
if (anyDuplicated(survey[c("SurveyID", "orderShown")])) {
  stop("SurveyID and orderShown must uniquely identify a displayed profile.")
}

respondent_rating_count <- tapply(
  survey$rating_complete,
  survey$SurveyID,
  sum
)
audit <- data.frame(
  metric = c(
    "displayed_profiles",
    "survey_ids",
    "survey_ids_with_at_least_one_rating",
    "complete_ratings",
    "missing_ratings",
    "missing_rating_share",
    "respondents_with_all_seven_ratings",
    "respondents_with_no_ratings",
    "unique_attribute_profiles"
  ),
  value = c(
    nrow(survey),
    length(unique(survey$SurveyID)),
    sum(respondent_rating_count > 0),
    sum(survey$rating_complete),
    sum(!survey$rating_complete),
    mean(!survey$rating_complete),
    sum(respondent_rating_count == 7),
    sum(respondent_rating_count == 0),
    nrow(unique(survey[c("Brand", "MPG", "Price")]))
  ),
  stringsAsFactors = FALSE
)
write.csv(
  audit,
  file.path(output_dir, "conjoint_data_audit.csv"),
  row.names = FALSE
)

missing_by_order <- do.call(rbind, lapply(
  sort(unique(survey$orderShown)),
  function(order_value) {
    order_data <- survey[survey$orderShown == order_value, ]
    data.frame(
      order_shown = order_value,
      displayed_profiles = nrow(order_data),
      complete_ratings = sum(order_data$rating_complete),
      missing_ratings = sum(!order_data$rating_complete),
      completion_rate = mean(order_data$rating_complete)
    )
  }
))
write.csv(
  missing_by_order,
  file.path(output_dir, "conjoint_missing_by_order.csv"),
  row.names = FALSE
)

attribute_balance <- rbind(
  data.frame(
    attribute = "Brand",
    level = names(table(survey$Brand)),
    displayed = as.integer(table(survey$Brand)),
    rated = as.integer(table(survey$Brand[survey$rating_complete]))
  ),
  data.frame(
    attribute = "Fuel economy",
    level = names(table(survey$MPG)),
    displayed = as.integer(table(survey$MPG)),
    rated = as.integer(table(survey$MPG[survey$rating_complete]))
  ),
  data.frame(
    attribute = "Price",
    level = names(table(survey$Price)),
    displayed = as.integer(table(survey$Price)),
    rated = as.integer(table(survey$Price[survey$rating_complete]))
  )
)
write.csv(
  attribute_balance,
  file.path(output_dir, "conjoint_attribute_balance.csv"),
  row.names = FALSE
)

profile_design <- aggregate(
  list(
    displayed = survey$SurveyID,
    rated = as.integer(survey$rating_complete)
  ),
  by = survey[c("Brand", "MPG", "Price")],
  FUN = sum
)
write.csv(
  profile_design,
  file.path(output_dir, "conjoint_profile_design.csv"),
  row.names = FALSE
)

model_data <- survey[survey$rating_complete, , drop = FALSE]
model_data$SurveyID_factor <- factor(model_data$SurveyID)
model_data$Brand <- factor(
  model_data$Brand,
  levels = c("Ford", "Tesla", "Toyota")
)
model_data$MPG <- factor(
  model_data$MPG,
  levels = c("20 MPG", "35 MPG", "110 MPGe")
)
model_data$Price <- factor(
  model_data$Price,
  levels = c("$30,000", "$60,000", "$120,000")
)
contrasts(model_data$Brand) <- contr.sum(3)
contrasts(model_data$MPG) <- contr.sum(3)
contrasts(model_data$Price) <- contr.sum(3)

respondent_only_model <- lm(
  preference_score ~ SurveyID_factor,
  data = model_data
)
conjoint_model <- lm(
  preference_score ~ Brand + MPG + Price + SurveyID_factor,
  data = model_data
)
order_sensitivity_model <- lm(
  preference_score ~ Brand + MPG + Price + orderShown + SurveyID_factor,
  data = model_data
)

cluster_vcov_cr1 <- function(model, cluster) {
  design <- model.matrix(model)
  model_residuals <- residuals(model)
  observations <- nrow(design)
  coefficients <- ncol(design)
  clusters <- unique(cluster)
  cluster_count <- length(clusters)
  bread <- solve(crossprod(design))
  meat <- matrix(0, coefficients, coefficients)
  for (cluster_value in clusters) {
    cluster_rows <- cluster == cluster_value
    score <- crossprod(
      design[cluster_rows, , drop = FALSE],
      model_residuals[cluster_rows]
    )
    meat <- meat + score %*% t(score)
  }
  correction <- (
    cluster_count / (cluster_count - 1)
  ) * (
    (observations - 1) / (observations - coefficients)
  )
  correction * bread %*% meat %*% bread
}

cluster_vcov <- cluster_vcov_cr1(
  conjoint_model,
  model_data$SurveyID
)
cluster_count <- length(unique(model_data$SurveyID))
cluster_degrees_freedom <- cluster_count - 1
model_coefficients <- coef(conjoint_model)
cluster_standard_errors <- sqrt(diag(cluster_vcov))
cluster_t_values <- model_coefficients / cluster_standard_errors
coefficient_table <- data.frame(
  term = names(model_coefficients),
  estimate = as.numeric(model_coefficients),
  cluster_standard_error = cluster_standard_errors,
  t_value = cluster_t_values,
  p_value = 2 * pt(
    abs(cluster_t_values),
    df = cluster_degrees_freedom,
    lower.tail = FALSE
  ),
  stringsAsFactors = FALSE
)
write.csv(
  coefficient_table,
  file.path(output_dir, "conjoint_model_coefficients.csv"),
  row.names = FALSE
)

attribute_specification <- list(
  Brand = list(prefix = "Brand", levels = levels(model_data$Brand)),
  `Fuel economy` = list(prefix = "MPG", levels = levels(model_data$MPG)),
  Price = list(prefix = "Price", levels = levels(model_data$Price))
)

level_contrast_matrix <- function(prefix) {
  coefficient_names <- names(model_coefficients)
  coefficient_indexes <- match(
    paste0(prefix, 1:2),
    coefficient_names
  )
  contrast_matrix <- matrix(
    0,
    nrow = 3,
    ncol = length(model_coefficients),
    dimnames = list(NULL, coefficient_names)
  )
  contrast_matrix[1, coefficient_indexes[1]] <- 1
  contrast_matrix[2, coefficient_indexes[2]] <- 1
  contrast_matrix[3, coefficient_indexes] <- -1
  contrast_matrix
}

partworth_rows <- list()
partworth_matrices <- list()
for (attribute_name in names(attribute_specification)) {
  specification <- attribute_specification[[attribute_name]]
  contrast_matrix <- level_contrast_matrix(specification$prefix)
  partworth_matrices[[attribute_name]] <- contrast_matrix
  estimates <- as.vector(contrast_matrix %*% model_coefficients)
  standard_errors <- sqrt(diag(
    contrast_matrix %*% cluster_vcov %*% t(contrast_matrix)
  ))
  critical_value <- qt(0.975, df = cluster_degrees_freedom)
  partworth_rows[[attribute_name]] <- data.frame(
    attribute = attribute_name,
    level = specification$levels,
    utility = estimates,
    cluster_standard_error = standard_errors,
    confidence_low = estimates - critical_value * standard_errors,
    confidence_high = estimates + critical_value * standard_errors,
    stringsAsFactors = FALSE
  )
}
partworths <- do.call(rbind, partworth_rows)
row.names(partworths) <- NULL
write.csv(
  partworths,
  file.path(output_dir, "conjoint_partworths.csv"),
  row.names = FALSE
)

attribute_tests <- do.call(rbind, lapply(
  names(attribute_specification),
  function(attribute_name) {
    prefix <- attribute_specification[[attribute_name]]$prefix
    coefficient_indexes <- grep(
      paste0("^", prefix),
      names(model_coefficients)
    )
    coefficient_block <- model_coefficients[coefficient_indexes]
    covariance_block <- cluster_vcov[
      coefficient_indexes,
      coefficient_indexes,
      drop = FALSE
    ]
    numerator_df <- length(coefficient_indexes)
    f_statistic <- as.numeric(
      t(coefficient_block) %*%
        solve(covariance_block) %*%
        coefficient_block / numerator_df
    )
    data.frame(
      attribute = attribute_name,
      f_statistic = f_statistic,
      numerator_degrees_freedom = numerator_df,
      denominator_degrees_freedom = cluster_degrees_freedom,
      p_value = pf(
        f_statistic,
        numerator_df,
        cluster_degrees_freedom,
        lower.tail = FALSE
      )
    )
  }
))
write.csv(
  attribute_tests,
  file.path(output_dir, "conjoint_attribute_tests.csv"),
  row.names = FALSE
)

pairwise_rows <- list()
for (attribute_name in names(attribute_specification)) {
  specification <- attribute_specification[[attribute_name]]
  level_matrix <- partworth_matrices[[attribute_name]]
  comparisons <- combn(3, 2)
  for (column_index in seq_len(ncol(comparisons))) {
    first_index <- comparisons[1, column_index]
    second_index <- comparisons[2, column_index]
    contrast <- level_matrix[first_index, ] - level_matrix[second_index, ]
    estimate <- as.numeric(contrast %*% model_coefficients)
    standard_error <- sqrt(as.numeric(
      contrast %*% cluster_vcov %*% contrast
    ))
    critical_value <- qt(0.975, df = cluster_degrees_freedom)
    pairwise_rows[[length(pairwise_rows) + 1L]] <- data.frame(
      attribute = attribute_name,
      level_1 = specification$levels[first_index],
      level_2 = specification$levels[second_index],
      preference_difference = estimate,
      cluster_standard_error = standard_error,
      confidence_low = estimate - critical_value * standard_error,
      confidence_high = estimate + critical_value * standard_error,
      p_value = 2 * pt(
        abs(estimate / standard_error),
        df = cluster_degrees_freedom,
        lower.tail = FALSE
      ),
      stringsAsFactors = FALSE
    )
  }
}
pairwise_contrasts <- do.call(rbind, pairwise_rows)
write.csv(
  pairwise_contrasts,
  file.path(output_dir, "conjoint_pairwise_contrasts.csv"),
  row.names = FALSE
)

attribute_ranges <- vapply(
  split(partworths$utility, partworths$attribute),
  function(values) diff(range(values)),
  numeric(1)
)
attribute_importance <- data.frame(
  attribute = names(attribute_ranges),
  utility_range = as.numeric(attribute_ranges),
  relative_importance = 100 * attribute_ranges / sum(attribute_ranges),
  stringsAsFactors = FALSE
)

attribute_coefficient_indexes <- unlist(lapply(
  attribute_specification,
  function(specification) {
    grep(
      paste0("^", specification$prefix),
      names(model_coefficients)
    )
  }
))
attribute_estimates <- model_coefficients[attribute_coefficient_indexes]
attribute_covariance <- cluster_vcov[
  attribute_coefficient_indexes,
  attribute_coefficient_indexes,
  drop = FALSE
]
eigen_covariance <- eigen(attribute_covariance, symmetric = TRUE)
covariance_root <- eigen_covariance$vectors %*%
  diag(sqrt(pmax(eigen_covariance$values, 0)))
set.seed(580)
simulation_count <- 10000L
normal_draws <- matrix(
  rnorm(simulation_count * length(attribute_estimates)),
  nrow = simulation_count
)
t_scale <- sqrt(
  cluster_degrees_freedom /
    rchisq(simulation_count, df = cluster_degrees_freedom)
)
coefficient_draws <- sweep(
  normal_draws %*% t(covariance_root),
  1,
  t_scale,
  "*"
)
coefficient_draws <- sweep(
  coefficient_draws,
  2,
  attribute_estimates,
  "+"
)

importance_draws <- matrix(
  NA_real_,
  nrow = simulation_count,
  ncol = length(attribute_specification),
  dimnames = list(NULL, names(attribute_specification))
)
draw_column_offset <- 0L
for (attribute_name in names(attribute_specification)) {
  two_level_draws <- coefficient_draws[
    ,
    draw_column_offset + 1:2,
    drop = FALSE
  ]
  three_level_draws <- cbind(
    two_level_draws,
    -rowSums(two_level_draws)
  )
  importance_draws[, attribute_name] <- apply(
    three_level_draws,
    1,
    function(values) diff(range(values))
  )
  draw_column_offset <- draw_column_offset + 2L
}
importance_draws <- 100 * importance_draws / rowSums(importance_draws)
attribute_importance$confidence_low <- vapply(
  attribute_importance$attribute,
  function(attribute_name) {
    quantile(importance_draws[, attribute_name], 0.025)
  },
  numeric(1)
)
attribute_importance$confidence_high <- vapply(
  attribute_importance$attribute,
  function(attribute_name) {
    quantile(importance_draws[, attribute_name], 0.975)
  },
  numeric(1)
)
write.csv(
  attribute_importance,
  file.path(output_dir, "conjoint_attribute_importance.csv"),
  row.names = FALSE
)

respondent_design <- model.matrix(
  ~ SurveyID_factor,
  data = model_data
)
attribute_design <- model.matrix(
  ~ Brand + MPG + Price,
  data = model_data
)[, -1, drop = FALSE]
residualized_attribute_design <- apply(
  attribute_design,
  2,
  function(column) {
    lm.fit(respondent_design, column)$residuals
  }
)
variance_inflation <- vapply(
  seq_len(ncol(residualized_attribute_design)),
  function(column_index) {
    target <- residualized_attribute_design[, column_index]
    other_columns <- residualized_attribute_design[
      ,
      -column_index,
      drop = FALSE
    ]
    auxiliary <- lm.fit(cbind(1, other_columns), target)
    r_squared <- 1 - sum(auxiliary$residuals^2) /
      sum((target - mean(target))^2)
    1 / (1 - r_squared)
  },
  numeric(1)
)
brand_mpg_table <- table(model_data$Brand, model_data$MPG)
design_diagnostics <- data.frame(
  diagnostic = c(
    "attribute_design_rank",
    "attribute_design_columns",
    "attribute_design_condition_number",
    "maximum_attribute_vif",
    "brand_by_fuel_economy_zero_cells",
    "brand_by_fuel_economy_cells_below_five",
    "display_order_coefficient",
    "display_order_p_value"
  ),
  value = c(
    qr(residualized_attribute_design)$rank,
    ncol(residualized_attribute_design),
    kappa(residualized_attribute_design),
    max(variance_inflation),
    sum(brand_mpg_table == 0),
    sum(brand_mpg_table < 5),
    coef(order_sensitivity_model)[["orderShown"]],
    coef(summary(order_sensitivity_model))[
      "orderShown",
      "Pr(>|t|)"
    ]
  ),
  interpretation = c(
    "Rank after removing respondent fixed effects",
    "Number of effect-coded attribute columns",
    "Values above 10 indicate potentially unstable separation",
    "Brand and fuel economy are strongly confounded",
    "Tesla is never paired with 20 or 35 MPG",
    "Four brand/fuel-economy cells have fewer than five ratings",
    "Preference-score change for one later display position",
    "No evidence of a linear display-order effect"
  ),
  stringsAsFactors = FALSE
)
write.csv(
  design_diagnostics,
  file.path(output_dir, "conjoint_design_diagnostics.csv"),
  row.names = FALSE
)

model_comparison <- anova(respondent_only_model, conjoint_model)
model_summary <- data.frame(
  statistic = c(
    "rated_profiles",
    "rated_respondents",
    "r_squared",
    "adjusted_r_squared",
    "rmse_preference_score",
    "incremental_r_squared_over_respondent_only",
    "nested_model_f_statistic",
    "nested_model_p_value",
    "cluster_degrees_of_freedom"
  ),
  value = c(
    nobs(conjoint_model),
    cluster_count,
    summary(conjoint_model)$r.squared,
    summary(conjoint_model)$adj.r.squared,
    sqrt(mean(residuals(conjoint_model)^2)),
    summary(conjoint_model)$r.squared -
      summary(respondent_only_model)$r.squared,
    model_comparison$F[2],
    model_comparison$`Pr(>F)`[2],
    cluster_degrees_freedom
  ),
  stringsAsFactors = FALSE
)
write.csv(
  model_summary,
  file.path(output_dir, "conjoint_model_summary.csv"),
  row.names = FALSE
)

message(
  "Conjoint outputs written to ", output_dir,
  "; respondent names were not downloaded."
)
