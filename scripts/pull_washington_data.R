#!/usr/bin/env Rscript

# Pull and sanitize Washington's public monthly title-transaction data.
#
# Primary outcome definition:
#   New light-duty ZEV original titles / all new light-duty original titles
#
# "Original title" alone is not sufficient because it can include a used
# vehicle entering Washington. The API filter therefore also requires the
# Department of Licensing's New or Used Vehicle field to equal "New".

options(stringsAsFactors = FALSE, timeout = 180)

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- normalizePath(
  sub("^--file=", "", script_arg[[1]]),
  mustWork = TRUE
)
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
data_dir <- file.path(project_root, "data")
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

refresh <- tolower(Sys.getenv("WASHINGTON_REFRESH", "false")) %in%
  c("1", "true", "yes")

statewide_path <- file.path(data_dir, "washington_titles_monthly.csv")
county_path <- file.path(data_dir, "washington_county_monthly.csv")
gas_path <- file.path(data_dir, "washington_gas_monthly.csv")

required_packages <- c("dplyr", "readr", "tidyr", "jsonlite")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop("Install required packages: ", paste(missing_packages, collapse = ", "))
}

api_url <- "https://data.wa.gov/resource/cdk6-5kdf.csv"
title_source_url <- paste0(
  "https://data.wa.gov/Transportation/",
  "Vehicle-Title-Transactions-by-Department-of-Licens/cdk6-5kdf"
)
eia_source_url <- paste0(
  "https://api.eia.gov/v2/petroleum/pri/gnd/data/",
  "?api_key=DEMO_KEY&frequency=weekly&data[0]=value",
  "&facets[series][]=EMM_EPMR_PTE_SWA_DPG",
  "&start=2017-01-01&sort[0][column]=period",
  "&sort[0][direction]=asc&length=5000"
)

light_duty_classes <- c(
  "1", "1A", "1B", "1C", "1D",
  "2", "2E", "2F", "2G", "2H"
)
vehicle_types <- c(
  "PASSENGER CAR",
  "MULTIPURPOSE PASSENGER VEHICLE (MPV)",
  "TRUCK"
)

sql_values <- function(values) {
  paste0("'", paste(values, collapse = "','"), "'")
}

where_filter <- paste0(
  "transaction_type='Original Title'",
  " AND new_or_used_vehicle='New'",
  " AND state='WA'",
  " AND vehicle_type IN(", sql_values(vehicle_types), ")",
  " AND (gross_vehicle_weight_rating_class IS NULL",
  " OR gross_vehicle_weight_rating_class IN(",
  sql_values(light_duty_classes), "))"
)

build_url <- function(select, group, order = NULL, limit = 50000L) {
  parameters <- c(
    "$select" = select,
    "$where" = where_filter,
    "$group" = group,
    if (!is.null(order)) c("$order" = order),
    "$limit" = as.character(limit)
  )
  encoded <- vapply(
    parameters,
    utils::URLencode,
    character(1),
    reserved = TRUE
  )
  paste0(
    api_url,
    "?",
    paste0(names(parameters), "=", encoded, collapse = "&")
  )
}

classify_powertrain <- function(electrification_level, primary_fuel) {
  dplyr::case_when(
    grepl("^BEV", electrification_level) ~ "BEV",
    grepl("^PHEV", electrification_level) ~ "PHEV",
    primary_fuel == "Hydrogen Fuel Cell" ~ "FCEV",
    TRUE ~ "Other"
  )
}

summarize_titles <- function(data, geography_columns = character()) {
  data |>
    dplyr::mutate(
      month = as.Date(start_of_month),
      titles = as.numeric(titles),
      powertrain = classify_powertrain(
        electrification_level,
        fuel_type_primary
      )
    ) |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(c(geography_columns, "month"))),
      powertrain
    ) |>
    dplyr::summarise(titles = sum(titles, na.rm = TRUE), .groups = "drop") |>
    tidyr::pivot_wider(
      names_from = powertrain,
      values_from = titles,
      values_fill = 0
    ) |>
    dplyr::mutate(
      total_new_ldv_titles = BEV + PHEV + FCEV + Other,
      zev_titles = BEV + PHEV + FCEV,
      zev_share = zev_titles / total_new_ldv_titles,
      source_url = title_source_url
    ) |>
    dplyr::rename(
      bev_titles = BEV,
      phev_titles = PHEV,
      fcev_titles = FCEV,
      other_powertrain_titles = Other
    ) |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(c(geography_columns, "month")))
    )
}

if (refresh || !all(file.exists(c(statewide_path, county_path)))) {
  select_statewide <- paste(
    "start_of_month",
    "electrification_level",
    "fuel_type_primary",
    "sum(vehicle_record_count) as titles",
    sep = ","
  )
  statewide_group <- paste(
    "start_of_month",
    "electrification_level",
    "fuel_type_primary",
    sep = ","
  )
  statewide_raw <- readr::read_csv(
    build_url(
      select_statewide,
      statewide_group,
      "start_of_month"
    ),
    show_col_types = FALSE
  )

  select_county <- paste(
    "start_of_month",
    "county",
    "electrification_level",
    "fuel_type_primary",
    "sum(vehicle_record_count) as titles",
    sep = ","
  )
  county_group <- paste(
    "start_of_month",
    "county",
    "electrification_level",
    "fuel_type_primary",
    sep = ","
  )
  county_raw <- readr::read_csv(
    build_url(
      select_county,
      county_group,
      "start_of_month,county"
    ),
    show_col_types = FALSE
  )

  statewide <- summarize_titles(statewide_raw)
  county <- county_raw |>
    dplyr::filter(!is.na(county), nzchar(county)) |>
    summarize_titles("county")

  readr::write_csv(statewide, statewide_path, na = "")
  readr::write_csv(county, county_path, na = "")
}

if (refresh || !file.exists(gas_path)) {
  temporary_json <- tempfile(fileext = ".json")
  download.file(eia_source_url, temporary_json, mode = "wb", quiet = TRUE)
  eia_response <- jsonlite::fromJSON(temporary_json, simplifyDataFrame = TRUE)
  weekly <- eia_response$response$data |>
    dplyr::transmute(
      observation_date = as.Date(period),
      month = as.Date(format(observation_date, "%Y-%m-01")),
      washington_regular_gas_price = as.numeric(value)
    )
  monthly_gas <- weekly |>
    dplyr::group_by(month) |>
    dplyr::summarise(
      washington_regular_gas_price = mean(
        washington_regular_gas_price,
        na.rm = TRUE
      ),
      weekly_observations = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      source_url = paste0(
        "https://www.eia.gov/dnav/pet/hist/",
        "LeafHandler.ashx?f=W&n=PET&s=EMM_EPMR_PTE_SWA_DPG"
      )
    )
  readr::write_csv(monthly_gas, gas_path, na = "")
}

message(
  "Washington monthly title and gasoline snapshots are ready in ",
  data_dir,
  "."
)
