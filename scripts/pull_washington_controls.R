#!/usr/bin/env Rscript

# Pull Washington-specific monthly controls and behavioral data.
#
# Outputs:
#   - Washington unemployment (BLS LAUS, seasonally adjusted)
#   - Washington residential electricity price (EIA Form EIA-861M)
#   - Washington policy-timing indicators
#   - Washington vehicle miles traveled (FHWA Traffic Volume Trends)
#
# VMT is intentionally a separate behavioral outcome. It is not used as an
# explanatory variable in the ZEV-title-share regression because driving can
# itself respond to gasoline prices.

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

unemployment_path <- file.path(
  data_dir,
  "washington_unemployment_monthly.csv"
)
electricity_path <- file.path(
  data_dir,
  "washington_electricity_monthly.csv"
)
policy_path <- file.path(data_dir, "washington_policy_monthly.csv")
vmt_path <- file.path(data_dir, "washington_vmt_monthly.csv")

required_packages <- c("dplyr", "readr", "jsonlite")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop("Install required packages: ", paste(missing_packages, collapse = ", "))
}

download_json <- function(url) {
  temporary_json <- tempfile(fileext = ".json")
  on.exit(unlink(temporary_json), add = TRUE)
  download.file(url, temporary_json, mode = "wb", quiet = TRUE)
  jsonlite::fromJSON(temporary_json, simplifyDataFrame = TRUE)
}

if (refresh || !file.exists(unemployment_path)) {
  bls_series <- "LAUST530000000000003"
  bls_url <- paste0(
    "https://api.bls.gov/publicAPI/v2/timeseries/data/",
    bls_series,
    "?startyear=2017&endyear=2026"
  )
  bls_response <- download_json(bls_url)
  if (!identical(bls_response$status, "REQUEST_SUCCEEDED")) {
    stop("BLS unemployment request did not succeed.")
  }
  unemployment <- bls_response$Results$series$data[[1]] |>
    dplyr::filter(grepl("^M(0[1-9]|1[0-2])$", period)) |>
    dplyr::transmute(
      month = as.Date(sprintf(
        "%s-%s-01",
        year,
        sub("^M", "", period)
      )),
      washington_unemployment_rate = suppressWarnings(as.numeric(value)),
      estimate_status = dplyr::case_when(
        value == "-" ~ "unavailable_federal_shutdown",
        !is.na(latest) & latest == "true" ~ "preliminary",
        TRUE ~ "published"
      ),
      source_series = bls_series,
      source_url = paste0(
        "https://data.bls.gov/timeseries/",
        bls_series
      )
    ) |>
    dplyr::arrange(month)
  readr::write_csv(unemployment, unemployment_path, na = "")
}

if (refresh || !file.exists(electricity_path)) {
  eia_url <- paste0(
    "https://api.eia.gov/v2/electricity/retail-sales/data/",
    "?api_key=DEMO_KEY&frequency=monthly&data[0]=price",
    "&facets[stateid][]=WA&facets[sectorid][]=RES",
    "&start=2017-01&sort[0][column]=period",
    "&sort[0][direction]=asc&length=5000"
  )
  eia_response <- download_json(eia_url)
  electricity <- eia_response$response$data |>
    dplyr::transmute(
      month = as.Date(paste0(period, "-01")),
      washington_residential_electricity_cents_kwh = as.numeric(price),
      source_series = "EIA-861M residential retail price",
      source_url = paste0(
        "https://www.eia.gov/electricity/data/",
        "browser/#/topic/7?agg=0,1&geo=vvvvvvvvvvvvo&endsec=8"
      )
    ) |>
    dplyr::arrange(month)
  readr::write_csv(electricity, electricity_path, na = "")
}

if (refresh || !file.exists(policy_path)) {
  policy_months <- data.frame(
    month = seq(
      as.Date("2017-01-01"),
      as.Date("2026-06-01"),
      by = "month"
    )
  ) |>
    dplyr::mutate(
      wa_sales_tax_exemption_active = as.integer(
        month >= as.Date("2019-08-01") &
          month <= as.Date("2025-07-01")
      ),
      wa_instant_rebate_active = as.integer(
        month >= as.Date("2024-08-01") &
          month <= as.Date("2025-05-01")
      ),
      federal_point_of_sale_credit_period = as.integer(
        month >= as.Date("2024-01-01") &
          month <= as.Date("2025-09-01")
      ),
      combined_incentive_transition = as.integer(
        month >= as.Date("2025-07-01") &
          month <= as.Date("2025-10-01")
      ),
      post_combined_incentive_rolloff = as.integer(
        month >= as.Date("2025-11-01")
      ),
      timing_note = paste(
        "Washington sales-tax exemption ended 2025-07-31;",
        "the instant-rebate end month is proxied by Commerce's",
        "2025-06-04 closed-program update; the federal credit ended",
        "2025-09-30; November allows one month for title processing."
      ),
      wa_sales_tax_source_url = paste0(
        "https://dor.wa.gov/forms-publications/publications-subject/",
        "special-notices/new-clean-alternative-fuel-and-plug-hybrid-",
        "vehicle-sales-and-use-tax-exemption"
      ),
      wa_instant_rebate_source_url = paste0(
        "https://www.commerce.wa.gov/clean-transportation/",
        "ev-instant-rebate/"
      )
    )
  readr::write_csv(policy_months, policy_path, na = "")
}

fhwa_release_code <- function(date) {
  month_codes <- c(
    "jan", "feb", "mar", "apr", "may", "jun",
    "jul", "aug", "sep", "oct", "nov", "dec"
  )
  paste0(
    substr(format(date, "%Y"), 3, 4),
    month_codes[as.integer(format(date, "%m"))],
    "tvt"
  )
}

pull_fhwa_vmt <- function() {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop(
      "Install the readxl package to refresh Washington VMT. ",
      "The committed VMT snapshot can be used without readxl."
    )
  }

  observation_months <- seq(
    as.Date("2023-01-01"),
    as.Date("2026-05-01"),
    by = "month"
  )
  latest_observation <- max(observation_months)
  rows <- lapply(observation_months, function(observation_month) {
    release_month <- if (observation_month < latest_observation) {
      seq(observation_month, by = "month", length.out = 2)[2]
    } else {
      observation_month
    }
    release_code <- fhwa_release_code(release_month)
    source_url <- paste0(
      "https://www.fhwa.dot.gov/policyinformation/travel_monitoring/",
      release_code,
      "/",
      release_code,
      ".xlsx"
    )
    workbook <- tempfile(fileext = ".xlsx")
    on.exit(unlink(workbook), add = TRUE)
    download.file(source_url, workbook, mode = "wb", quiet = TRUE)
    table_five <- readxl::read_excel(
      workbook,
      sheet = "Page 6",
      col_names = FALSE
    )
    washington_row <- which(
      trimws(as.character(table_five[[1]])) == "Washington"
    )[1]
    if (is.na(washington_row)) {
      stop("Washington row not found in ", source_url)
    }
    revised_value <- observation_month < latest_observation
    value_column <- if (revised_value) 9L else 5L
    change_column <- if (revised_value) 11L else 7L
    data.frame(
      month = observation_month,
      vmt_million_miles = as.numeric(
        table_five[[value_column]][washington_row]
      ),
      yoy_change = as.numeric(
        table_five[[change_column]][washington_row]
      ) / 100,
      estimate_status = ifelse(
        revised_value,
        "revised_next_month",
        "preliminary"
      ),
      release_month = release_month,
      geography = "Washington",
      road_coverage = "All estimated roads and streets",
      source_url = source_url,
      stringsAsFactors = FALSE
    )
  })
  dplyr::bind_rows(rows)
}

if (refresh || !file.exists(vmt_path)) {
  vmt <- pull_fhwa_vmt()
  readr::write_csv(vmt, vmt_path, na = "")
}

message("Washington control snapshots are ready in ", data_dir, ".")
