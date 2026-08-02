# AI Assistance Disclosure
# OpenAI Codex helped structure the reactive Shiny components, implement the
# Washington title-data pipeline and statistical displays, and draft initial
# explanatory language. The group selected the question, sourced the data, and
# is responsible for reviewing the analysis and final interpretation.

library(shiny)
library(dplyr)
library(ggplot2)
library(plotly)
library(readr)
library(scales)
library(tidyr)

wa_monthly <- read_csv(
  "analysis/results/washington_monthly_analysis.csv",
  show_col_types = FALSE
) |>
  mutate(month = as.Date(month))
wa_county_monthly <- read_csv(
  "data/washington_county_monthly.csv",
  show_col_types = FALSE
) |>
  mutate(month = as.Date(month))
wa_county_postwar <- read_csv(
  "analysis/results/washington_county_postwar.csv",
  show_col_types = FALSE
)
wa_event_summary <- read_csv(
  "analysis/results/washington_event_summary.csv",
  show_col_types = FALSE
)
wa_model_comparison <- read_csv(
  "analysis/results/washington_model_comparison.csv",
  show_col_types = FALSE
)
wa_its <- read_csv(
  "analysis/results/washington_its_coefficients.csv",
  show_col_types = FALSE
)
wa_audit <- read_csv(
  "analysis/results/washington_data_audit.csv",
  show_col_types = FALSE
)
wa_gas_model_comparison <- read_csv(
  "analysis/results/washington_gas_model_comparison.csv",
  show_col_types = FALSE
)
wa_gas_coefficients <- read_csv(
  "analysis/results/washington_gas_model_coefficients.csv",
  show_col_types = FALSE
)
wa_gas_sensitivity <- read_csv(
  "analysis/results/washington_gas_model_sensitivity.csv",
  show_col_types = FALSE
)
wa_vmt <- read_csv(
  "data/washington_vmt_monthly.csv",
  show_col_types = FALSE
) |>
  mutate(month = as.Date(month))
california_quarterly <- read_csv(
  "data/quarterly_controls.csv",
  show_col_types = FALSE
) |>
  mutate(
    quarter_start = as.Date(quarter_start),
    quarter_label = paste(year, paste0("Q", quarter))
  )
conjoint_partworths <- read_csv(
  "analysis/results/conjoint_partworths.csv",
  show_col_types = FALSE
)
conjoint_attribute_tests <- read_csv(
  "analysis/results/conjoint_attribute_tests.csv",
  show_col_types = FALSE
)
conjoint_audit <- read_csv(
  "analysis/results/conjoint_data_audit.csv",
  show_col_types = FALSE
)
conjoint_pairwise <- read_csv(
  "analysis/results/conjoint_pairwise_contrasts.csv",
  show_col_types = FALSE
)

latest_month <- max(wa_monthly$month)
latest_label <- format(latest_month, "%B %Y")

audit_value <- function(metric_name) {
  wa_audit |>
    filter(metric == metric_name) |>
    pull(value)
}

event_markers <- tibble::tribble(
  ~date, ~event,
  as.Date("2025-07-31"), "WA sales-tax exemption ends",
  as.Date("2025-09-30"), "Federal credit ends",
  as.Date("2026-02-28"), "Iran war begins"
)

postwar <- wa_event_summary |> filter(period == "Post-war")
prewar <- wa_event_summary |>
  filter(period == "Post-incentive-rolloff / pre-war")
war_coefficient <- wa_its |> filter(term == "post_war")
rolloff_coefficient <- wa_its |>
  filter(term == "post_combined_incentive_rolloff")
gas_coefficient <- wa_gas_coefficients |>
  filter(term == "gas_price_prior_3m")
gas_electricity_sensitivity <- wa_gas_sensitivity |>
  filter(model == "plus_electricity")

metric_config <- list(
  zev_share = list(
    label = "New light-duty ZEV title share",
    column = "zev_share",
    axis = "Share of new light-duty original titles",
    formatter = label_percent(accuracy = .1)
  ),
  zev_titles = list(
    label = "New light-duty ZEV original titles",
    column = "zev_titles",
    axis = "ZEV original-title transactions",
    formatter = label_comma()
  ),
  total_titles = list(
    label = "All new light-duty original titles",
    column = "total_new_ldv_titles",
    axis = "New light-duty original-title transactions",
    formatter = label_comma()
  ),
  gas_price = list(
    label = "Washington regular gasoline price",
    column = "washington_regular_gas_price",
    axis = "Dollars per gallon",
    formatter = label_dollar(accuracy = .01)
  )
)

paper <- "#f6f1e7"
ink <- "#27241f"
teal <- "#176b68"
rust <- "#b9472e"
gold <- "#8b6b2f"
muted <- "#746e64"

theme_editorial <- function() {
  theme_minimal(base_family = "IBM Plex Sans", base_size = 12) +
    theme(
      plot.background = element_rect(fill = paper, color = NA),
      panel.background = element_rect(fill = paper, color = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_line(color = "#ded6c9", linewidth = .3),
      panel.grid.major.y = element_line(color = "#d8d0c2", linewidth = .35),
      axis.text = element_text(color = "#48443e"),
      axis.title = element_text(color = ink, face = "bold"),
      axis.title.y = element_text(margin = margin(r = 12)),
      plot.title = element_text(
        family = "DM Serif Display",
        size = 20,
        color = "#171510"
      ),
      plot.subtitle = element_text(color = "#625d54", margin = margin(b = 12)),
      plot.caption = element_text(color = muted, hjust = 0),
      legend.position = "top",
      legend.justification = "left",
      legend.title = element_blank(),
      plot.margin = margin(8, 8, 8, 24)
    )
}

quarter_axis <- function(x) {
  paste0(
    format(x, "%Y"),
    "\nQ",
    ((as.integer(format(x, "%m")) - 1L) %/% 3L) + 1L
  )
}

calculation_note <- function(
  title,
  measure,
  formula,
  variables,
  interpretation,
  caution = NULL
) {
  tags$details(
    class = "calculation-note",
    tags$summary(
      span(class = "calculation-label", "How this chart is calculated"),
      span(class = "calculation-title", title),
      span(class = "calculation-action", "View method")
    ),
    div(
      class = "calculation-body",
      div(
        class = "calculation-cell",
        h3("Measure"),
        div(class = "calculation-copy", measure)
      ),
      div(
        class = "calculation-cell calculation-formula-cell",
        h3("Calculation"),
        div(class = "formula-box", formula)
      ),
      div(
        class = "calculation-cell",
        h3("Variables that matter"),
        div(class = "calculation-copy", variables)
      ),
      div(
        class = "calculation-cell",
        h3("How to interpret it"),
        div(class = "calculation-copy", interpretation)
      )
    ),
    if (!is.null(caution)) {
      div(
        class = "calculation-caution",
        strong("Guardrail: "),
        caution
      )
    }
  )
}

app_css <- "
@import url('https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=IBM+Plex+Sans:wght@400;500;600&display=swap');
:root { --ink:#171510; --paper:#f6f1e7; --deep:#ebe2d3; --rust:#b9472e; --teal:#176b68; --muted:#6f685e; --line:#cfc5b6; }
body { background:var(--paper); color:var(--ink); font-family:'IBM Plex Sans',sans-serif; }
.container-fluid { padding:0; }
.masthead { padding:34px 4.5vw 28px; border-bottom:1px solid var(--ink); position:relative; overflow:hidden; }
.masthead:after { content:'WA'; position:absolute; right:3vw; top:-52px; font-family:'DM Serif Display'; font-size:180px; color:rgba(185,71,46,.08); }
.eyebrow,.section-kicker { color:var(--rust); font-weight:600; letter-spacing:.16em; text-transform:uppercase; font-size:11px; }
h1 { font-family:'DM Serif Display'; font-size:clamp(42px,5vw,74px); line-height:.98; max-width:980px; margin:10px 0 16px; }
.dek { max-width:900px; color:var(--muted); font-size:18px; line-height:1.55; margin:0; }
.app-grid { display:grid; grid-template-columns:minmax(250px,305px) 1fr; }
.controls { padding:30px 25px 60px 4.5vw; border-right:1px solid var(--line); background:var(--deep); }
.controls-inner { position:sticky; top:20px; }
.controls h2 { font-size:11px; letter-spacing:.15em; text-transform:uppercase; color:var(--rust); }
.controls .form-group { margin-bottom:21px; }
.control-label { font-size:13px; font-weight:600; }
.form-control { border:1px solid #9e9588; border-radius:0; background:#fffdf8; }
.help-copy { font-size:12px; color:var(--muted); line-height:1.55; border-top:1px solid var(--line); padding-top:18px; margin-top:25px; }
.definition-note { margin-top:18px; padding:15px; border:1px solid #9e9588; background:#fffdf8; font-size:12px; line-height:1.48; }
.definition-note h3 { margin:0 0 9px; color:var(--rust); font-size:10px; letter-spacing:.14em; text-transform:uppercase; }
.content { padding:30px 4.5vw 70px 34px; min-width:0; }
.signal-strip { display:grid; grid-template-columns:repeat(3,1fr); border:1px solid var(--ink); margin-bottom:28px; }
.signal { padding:18px 20px; min-height:112px; background:#fffdf8; }
.signal + .signal { border-left:1px solid var(--ink); }
.signal-label { font-size:11px; color:var(--muted); text-transform:uppercase; letter-spacing:.09em; }
.signal-value { font-family:'DM Serif Display'; font-size:34px; line-height:1.1; margin:7px 0 3px; }
.signal-note { font-size:12px; color:var(--muted); }
.panel { border:0; border-top:3px solid var(--ink); border-radius:0; box-shadow:none; background:transparent; margin:0 0 35px; padding-top:16px; }
.panel-title { font-family:'DM Serif Display'; font-size:27px; margin:0; }
.panel-subtitle { color:var(--muted); margin:6px 0 12px; line-height:1.5; }
.two-up { display:grid; grid-template-columns:minmax(0,1.45fr) minmax(250px,.55fr); gap:30px; align-items:stretch; }
.evidence-card { background:#fffdf8; border:1px solid var(--ink); padding:22px; display:flex; flex-direction:column; justify-content:center; }
.evidence-card h3 { font-family:'DM Serif Display'; font-size:22px; margin:0 0 14px; }
.evidence-row { display:grid; grid-template-columns:1fr auto; gap:14px; padding:10px 0; border-top:1px solid var(--line); align-items:baseline; }
.evidence-label { color:var(--muted); font-size:12px; }
.evidence-number { font-family:'DM Serif Display'; font-size:24px; }
.evidence-takeaway { margin:17px 0 0; color:var(--ink); font-size:13px; line-height:1.55; }
.flag { display:inline-block; margin-top:14px; padding:7px 9px; background:#f0dfc7; color:#713322; font-size:10px; font-weight:600; letter-spacing:.08em; text-transform:uppercase; }
.benchmark-explainer { margin-top:22px; border:1px solid var(--ink); background:#fffdf8; }
.explainer-lead { display:grid; grid-template-columns:minmax(145px,.38fr) minmax(0,1.62fr); border-bottom:1px solid var(--ink); }
.explainer-label { padding:18px 20px; background:var(--rust); color:#fffdf8; font-size:10px; font-weight:600; letter-spacing:.14em; text-transform:uppercase; }
.explainer-question { padding:16px 22px; font-family:'DM Serif Display'; font-size:20px; line-height:1.25; }
.explainer-grid { display:grid; grid-template-columns:repeat(4,1fr); }
.explainer-cell { padding:19px 20px 21px; min-width:0; }
.explainer-cell + .explainer-cell { border-left:1px solid var(--line); }
.explainer-number { display:block; margin-bottom:9px; color:var(--rust); font-size:10px; font-weight:600; letter-spacing:.14em; text-transform:uppercase; }
.explainer-cell h3 { margin:0 0 8px; font-family:'DM Serif Display'; font-size:18px; }
.explainer-cell p { margin:0; color:var(--muted); font-size:12px; line-height:1.58; }
.measurement-equation { display:block; margin:9px 0; padding:8px 10px; border-left:3px solid var(--teal); background:var(--paper); color:var(--ink); font-size:11px; line-height:1.45; }
.benchmark-guardrail { margin:0; padding:13px 20px; border-top:1px solid var(--line); color:#713322; background:#f0dfc7; font-size:12px; line-height:1.55; }
.method { border-left:4px solid var(--rust); padding:4px 0 4px 17px; color:var(--muted); font-size:13px; line-height:1.6; }
.calculation-note { margin-top:16px; border:1px solid var(--line); background:#fffdf8; }
.calculation-note summary { display:grid; grid-template-columns:auto minmax(0,1fr) auto; gap:14px; align-items:center; padding:15px 18px; cursor:pointer; list-style:none; }
.calculation-note summary::-webkit-details-marker { display:none; }
.calculation-note summary:focus-visible { outline:3px solid rgba(23,107,104,.32); outline-offset:2px; }
.calculation-label { color:var(--teal); font-size:10px; font-weight:600; letter-spacing:.13em; text-transform:uppercase; }
.calculation-title { color:var(--ink); font-family:'DM Serif Display'; font-size:17px; line-height:1.25; }
.calculation-action { color:var(--muted); font-size:11px; font-weight:600; letter-spacing:.04em; white-space:nowrap; }
.calculation-action:after { content:' +'; color:var(--rust); font-size:16px; }
.calculation-note[open] .calculation-action:after { content:' −'; }
.calculation-note[open] summary { border-bottom:1px solid var(--ink); }
.calculation-body { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); }
.calculation-cell { padding:18px 20px 20px; min-width:0; }
.calculation-cell:nth-child(even) { border-left:1px solid var(--line); }
.calculation-cell:nth-child(n+3) { border-top:1px solid var(--line); }
.calculation-cell h3 { margin:0 0 8px; color:var(--rust); font-size:10px; font-weight:600; letter-spacing:.13em; text-transform:uppercase; }
.calculation-copy { color:var(--muted); font-size:12px; line-height:1.6; }
.calculation-copy p { margin:0 0 8px; }
.calculation-copy p:last-child { margin-bottom:0; }
.formula-box { padding:11px 13px; border-left:3px solid var(--teal); background:var(--paper); color:var(--ink); font-family:'IBM Plex Mono','SFMono-Regular',Consolas,monospace; font-size:11px; line-height:1.65; overflow-wrap:anywhere; }
.formula-box code { padding:0; color:inherit; background:transparent; font:inherit; white-space:normal; }
.calculation-caution { padding:13px 20px; border-top:1px solid var(--line); background:#f0dfc7; color:#713322; font-size:12px; line-height:1.55; }
.methods-reference { margin:45px 0 30px; padding-top:18px; border-top:3px solid var(--ink); }
.methods-reference h2 { margin:4px 0 8px; font-family:'DM Serif Display'; font-size:27px; }
.methods-intro { max-width:780px; margin:0 0 18px; color:var(--muted); line-height:1.55; }
.methods-grid { display:grid; grid-template-columns:repeat(3,1fr); border:1px solid var(--ink); background:#fffdf8; }
.method-card { padding:19px 20px 21px; }
.method-card + .method-card { border-left:1px solid var(--line); }
.method-card h3 { margin:0 0 8px; font-family:'DM Serif Display'; font-size:19px; }
.method-card p { margin:0; color:var(--muted); font-size:12px; line-height:1.58; }
.method-tag { display:block; margin-bottom:8px; color:var(--rust); font-size:10px; font-weight:600; letter-spacing:.13em; text-transform:uppercase; }
@media(max-width:1100px){.explainer-grid{grid-template-columns:repeat(2,1fr)}.explainer-cell:nth-child(3){border-left:0;border-top:1px solid var(--line)}.explainer-cell:nth-child(4){border-top:1px solid var(--line)}.methods-grid{grid-template-columns:1fr}.method-card+.method-card{border-left:0;border-top:1px solid var(--line)}}
@media(max-width:920px){.app-grid,.two-up{grid-template-columns:1fr}.controls{border-right:0;border-bottom:1px solid var(--line);padding:24px 5vw}.controls-inner{position:static}.content{padding:28px 5vw}}
@media(max-width:620px){.signal-strip,.explainer-lead,.explainer-grid,.calculation-body{grid-template-columns:1fr}.signal+.signal,.explainer-cell+.explainer-cell,.explainer-cell:nth-child(3),.explainer-cell:nth-child(4),.calculation-cell:nth-child(even){border-left:0}.calculation-cell+.calculation-cell{border-top:1px solid var(--line)}.calculation-note summary{grid-template-columns:1fr auto}.calculation-label{grid-column:1/-1}.calculation-title{font-size:16px}}
"

ui <- fluidPage(
  tags$head(tags$style(HTML(app_css))),
  tags$header(
    class = "masthead",
    div(class = "eyebrow", "Washington EV Title Response Monitor"),
    h1("Did higher fuel costs revive ZEV demand after incentives rolled off?"),
    p(
      class = "dek",
      paste0(
        "Observed monthly Washington original-title transactions from January ",
        "2017 through ", latest_label,
        ", with California retained as a quarterly comparison."
      )
    )
  ),
  div(
    class = "app-grid",
    tags$aside(
      class = "controls",
      div(
        class = "controls-inner",
        h2("Build a comparison"),
        selectInput(
          "county",
          "Washington geography",
          choices = c(
            "Washington statewide",
            sort(setdiff(
              unique(wa_county_monthly$county),
              "Unknown or Out of State"
            ))
          )
        ),
        selectInput(
          "metric",
          "Primary signal",
          choices = c(
            "New light-duty ZEV title share" = "zev_share",
            "New light-duty ZEV original titles" = "zev_titles",
            "All new light-duty original titles" = "total_titles",
            "Washington gasoline price" = "gas_price"
          )
        ),
        selectInput(
          "window_start",
          "Timeline begins",
          choices = c(
            "2017 — full history" = "2017-01-01",
            "2021 — recent adoption period" = "2021-01-01",
            "2024 — event detail" = "2024-01-01"
          ),
          selected = "2021-01-01"
        ),
        checkboxInput(
          "show_events",
          "Show policy and war markers",
          value = TRUE
        ),
        selectInput(
          "conjoint_attribute",
          "Conjoint attribute",
          choices = c("All attributes", "Price", "Fuel economy", "Brand")
        ),
        p(
          class = "help-copy",
          paste(
            "County selection affects title outcomes.",
            "Gasoline prices and the regression benchmark are statewide."
          )
        ),
        div(
          class = "definition-note",
          h3("Primary measure"),
          p(
            strong("ZEV title share: "),
            paste(
              "new light-duty BEV, PHEV, and FCEV original titles divided",
              "by all new light-duty original titles."
            )
          ),
          p(
            paste(
              "Original titles are registration transactions, not dealer sale",
              "dates. The filter separately requires the DOL new-vehicle flag."
            )
          ),
          p(
            strong("Policy label: "),
            paste(
              "post-incentive-rolloff combines Washington's July 2025",
              "sales-tax-exemption expiration with the September 2025",
              "federal-credit expiration; the data cannot cleanly separate them."
            )
          )
        )
      )
    ),
    mainPanel(
      class = "content",
      width = 12,
      uiOutput("signal_strip"),
      tags$section(
        class = "panel",
        div(class = "section-kicker", "01 / Monthly market"),
        h2(class = "panel-title", textOutput("timeline_title", inline = TRUE)),
        p(class = "panel-subtitle", textOutput("timeline_subtitle", inline = TRUE)),
        plotlyOutput("market_plot", height = "430px"),
        calculation_note(
          title = "Monthly titles, title share, and gasoline price",
          measure = tagList(
            p(
              "The selector displays a monthly transaction count, a pooled ",
              "ZEV share, or Washington's statewide regular gasoline price."
            ),
            p(
              "ZEV includes battery electric, plug-in hybrid, and fuel-cell ",
              "vehicles classified as new light-duty original titles."
            )
          ),
          formula = tagList(
            code("ZEV share_t = ZEV titles_t / all new LDV titles_t"),
            tags$br(),
            code("ZEV titles_t = BEV_t + PHEV_t + FCEV_t")
          ),
          variables = tagList(
            p(strong("Numerator: "), "qualifying ZEV original titles."),
            p(strong("Denominator: "), "all new light-duty original titles."),
            p(
              strong("Filters: "),
              "selected geography, starting month, and vehicle-title rules."
            )
          ),
          interpretation = p(
            "A one-percentage-point change means one more ZEV title per 100 ",
            "qualifying new light-duty titles. Counts can move with market ",
            "volume even when the share is stable."
          ),
          caution = paste(
            "Title processing month is not necessarily the dealer sale date.",
            "Gasoline price is statewide even when a county is selected."
          )
        )
      ),
      tags$section(
        class = "panel",
        div(class = "section-kicker", "02 / Regression benchmark"),
        h2(class = "panel-title", "Observed share versus pre-rolloff expectation"),
        p(
          class = "panel-subtitle",
          paste(
            "The benchmark uses 102 pre-event months, calendar-month effects,",
            "a quadratic adoption trend, and a COVID disruption indicator."
          )
        ),
        div(
          class = "two-up",
          plotlyOutput("benchmark_plot", height = "440px"),
          uiOutput("regression_evidence")
        ),
        uiOutput("benchmark_explainer"),
        calculation_note(
          title = "Pre-rolloff forecast benchmark and interrupted time series",
          measure = p(
            "The gold line is the ZEV share expected from pre-rolloff history. ",
            "The interrupted-time-series coefficients estimate level changes ",
            "after the combined incentive rolloff and after March 2026."
          ),
          formula = tagList(
            code(
              "share_t = beta0 + beta1(time) + beta2(time^2) + month effects + COVID_t + error_t"
            ),
            tags$br(),
            code("empirical band = expected_t ± 1.96 × rolling RMSE"),
            tags$br(),
            code("ITS adds rolloff_t and postwar_t level indicators")
          ),
          variables = tagList(
            p(
              strong("Outcome: "),
              "monthly statewide ZEV title share."
            ),
            p(
              strong("Baseline predictors: "),
              "time, time squared, calendar month, and COVID disruption."
            ),
            p(
              strong("Event terms: "),
              "combined incentive rolloff and post-war period."
            )
          ),
          interpretation = p(
            "Observed minus expected shows departure from the historical path. ",
            "An ITS coefficient is a percentage-point level shift after ",
            "accounting for the modeled baseline."
          ),
          caution = paste(
            "The shaded region is a forecast-error band, not a causal",
            "confidence interval. The two incentive expirations overlap in time."
          )
        )
      ),
      tags$section(
        class = "panel",
        div(class = "section-kicker", "03 / Gas-price association"),
        h2(class = "panel-title", "Did gasoline prices add predictive signal?"),
        p(
          class = "panel-subtitle",
          paste(
            "The predictor is Washington's average regular gasoline price",
            "during the three months before each title month. Policy timing,",
            "trend, seasonality, and COVID are controlled."
          )
        ),
        div(
          class = "two-up",
          plotlyOutput("gas_sensitivity_plot", height = "390px"),
          uiOutput("gas_evidence")
        ),
        calculation_note(
          title = "Lagged gasoline-price association across model specifications",
          measure = p(
            "Each point is the estimated change in ZEV title share associated ",
            "with a $1-per-gallon increase in the average gasoline price during ",
            "the prior three months."
          ),
          formula = tagList(
            code("gas_prior_3m_t = mean(gas_{t-1}, gas_{t-2}, gas_{t-3})"),
            tags$br(),
            code(
              "share_t = baseline controls + beta(gas_prior_3m_t) + error_t"
            )
          ),
          variables = tagList(
            p(
              strong("Core controls: "),
              "quadratic time trend, calendar month, COVID, and policy timing."
            ),
            p(
              strong("Sensitivity controls: "),
              "unemployment, residential electricity price, or post-war timing."
            )
          ),
          interpretation = p(
            "The point is the estimated percentage-point association per $1. ",
            "The horizontal line is a Newey-West 95% interval. If it crosses ",
            "zero, the estimate is not statistically distinct from zero."
          ),
          caution = paste(
            "This is a predictive association. Fuel prices can move with other",
            "economic conditions, and the estimate changes across specifications."
          )
        )
      ),
      tags$section(
        class = "panel",
        div(class = "section-kicker", "04 / Behavioral response"),
        h2(class = "panel-title", "Did Washingtonians drive less?"),
        p(
          class = "panel-subtitle",
          paste(
            "Monthly Washington vehicle miles traveled compared with the",
            "same month one year earlier. VMT is a separate outcome, not a",
            "control in the ZEV-title regression."
          )
        ),
        plotlyOutput("vmt_plot", height = "410px"),
        calculation_note(
          title = "Year-over-year change in vehicle miles traveled",
          measure = p(
            "The bars compare total Washington vehicle miles traveled with the ",
            "same calendar month one year earlier, which controls for recurring ",
            "seasonal driving patterns."
          ),
          formula = code(
            "VMT YoY_t = ((VMT_t / VMT_{t-12}) - 1) × 100"
          ),
          variables = tagList(
            p(strong("VMT_t: "), "million vehicle miles in the current month."),
            p(
              strong("VMT_{t-12}: "),
              "million vehicle miles in the same month one year earlier."
            )
          ),
          interpretation = p(
            "A negative value means less total driving than in the same month ",
            "last year. This tests behavioral response, not vehicle choice."
          ),
          caution = paste(
            "VMT is kept out of the ZEV-title model because it may occur after",
            "a fuel-price shock and could mediate the relationship of interest.",
            "May 2026 is preliminary."
          )
        )
      ),
      tags$section(
        class = "panel",
        div(class = "section-kicker", "05 / County response"),
        h2(class = "panel-title", "Where did ZEV title share change?"),
        p(
          class = "panel-subtitle",
          paste(
            "Post-war March–June 2026 versus post-rolloff/pre-war",
            "November 2025–February 2026; largest county markets shown."
          )
        ),
        plotlyOutput("county_plot", height = "470px"),
        calculation_note(
          title = "County-level change between pooled four-month periods",
          measure = p(
            "For each county, the chart compares the pooled March-June 2026 ",
            "ZEV title share with the pooled November 2025-February 2026 share."
          ),
          formula = tagList(
            code("period share_c = sum(ZEV titles_c) / sum(all new LDV titles_c)"),
            tags$br(),
            code("change_c = postwar share_c - prewar share_c")
          ),
          variables = tagList(
            p(strong("c: "), "county."),
            p(
              strong("Pre-period: "),
              "November 2025 through February 2026."
            ),
            p(strong("Post-period: "), "March through June 2026.")
          ),
          interpretation = p(
            "Bars show percentage-point changes. Pooling title counts gives ",
            "higher-volume months the appropriate weight within each county."
          ),
          caution = paste(
            "County changes are descriptive and can be volatile in smaller",
            "markets. Unknown or out-of-state geography is excluded."
          )
        )
      ),
      tags$section(
        class = "panel",
        div(class = "section-kicker", "06 / California comparison"),
        h2(class = "panel-title", "Did the neighboring market move similarly?"),
        p(
          class = "panel-subtitle",
          paste(
            "Both series are indexed to 100 in 2025 Q4.",
            "Washington titles and California CEC-inferred sales are",
            "directionally comparable but not identical measures."
          )
        ),
        plotlyOutput("state_comparison_plot", height = "390px"),
        calculation_note(
          title = "Quarterly shares indexed to a common baseline",
          measure = p(
            "Each state's quarterly ZEV share is expressed relative to its own ",
            "2025 Q4 value. Indexing makes direction and proportional movement ",
            "comparable despite different starting shares."
          ),
          formula = tagList(
            code("quarterly share_s,q = sum(ZEV) / sum(all eligible vehicles)"),
            tags$br(),
            code("index_s,q = 100 × share_s,q / share_s,2025Q4")
          ),
          variables = tagList(
            p(strong("s: "), "state; q: quarter."),
            p(
              strong("Washington: "),
              "new light-duty original-title share."
            ),
            p(strong("California: "), "CEC-inferred new-vehicle sales share.")
          ),
          interpretation = p(
            "An index of 110 means the state's share is 10% above its own 2025 ",
            "Q4 level. It does not mean ZEV share is 110%."
          ),
          caution = paste(
            "The states use related but non-identical measures. Compare movement",
            "and timing, not absolute share levels."
          )
        )
      ),
      tags$section(
        class = "panel",
        div(class = "section-kicker", "07 / Stated preferences"),
        h2(class = "panel-title", "What did survey respondents value?"),
        p(
          class = "panel-subtitle",
          paste(
            "Rating-based part-worth utilities complement observed titles;",
            "positive values indicate greater stated preference."
          )
        ),
        div(
          class = "two-up",
          plotlyOutput("conjoint_plot", height = "510px"),
          uiOutput("conjoint_evidence")
        ),
        calculation_note(
          title = "Effect-coded part-worth utilities from profile ratings",
          measure = p(
            "Part-worths estimate how each attribute level changes stated ",
            "preference after accounting for each respondent's general rating ",
            "tendency."
          ),
          formula = tagList(
            code("preference = 6 - original rating"),
            tags$br(),
            code(
              "preference = respondent effects + brand + fuel economy + price + error"
            )
          ),
          variables = tagList(
            p(
              strong("Attributes: "),
              "brand, fuel economy, and purchase price."
            ),
            p(
              strong("Adjustment: "),
              "respondent fixed effects, effect coding, and respondent-clustered ",
              "standard errors."
            )
          ),
          interpretation = p(
            "Positive utility means greater stated preference relative to the ",
            "attribute's average level. The horizontal interval shows estimation ",
            "uncertainty. Utilities are comparable within, not across, attributes."
          ),
          caution = paste(
            "The sample is small. Brand and fuel economy are confounded because",
            "Tesla was consistently paired with 110 MPGe, so price is the clearest",
            "attribute result."
          )
        )
      ),
      tags$section(
        class = "methods-reference",
        div(class = "section-kicker", "Methods reference"),
        h2("How to read the evidence"),
        p(
          class = "methods-intro",
          paste(
            "The calculation panels separate what is directly observed from",
            "what is modeled. Use the strength of the design, not visual size",
            "alone, when interpreting a chart."
          )
        ),
        div(
          class = "methods-grid",
          div(
            class = "method-card",
            span(class = "method-tag", "Observed"),
            h3("Counts, shares, and changes"),
            p(
              paste(
                "Sections 01, 04, 05, and 06 summarize recorded titles, driving,",
                "or comparison data. They describe what happened without assigning",
                "a cause."
              )
            )
          ),
          div(
            class = "method-card",
            span(class = "method-tag", "Modeled"),
            h3("Expected path and event shifts"),
            p(
              paste(
                "Section 02 compares observed share with a rolling-validated",
                "pre-event forecast and estimates level shifts with an",
                "interrupted time series."
              )
            )
          ),
          div(
            class = "method-card",
            span(class = "method-tag", "Estimated association"),
            h3("Fuel price and stated preference"),
            p(
              paste(
                "Sections 03 and 07 report coefficients with uncertainty.",
                "Intervals and specification sensitivity matter as much as the",
                "point estimate."
              )
            )
          )
        )
      ),
      div(
        class = "method",
        strong("Interpretation guardrail: "),
        paste(
          "This is an observational interrupted-time-series study.",
          "The post-war period contains four months, and overlapping policy,",
          "price, incentive, and market changes prevent causal attribution."
        )
      )
    )
  )
)

server <- function(input, output, session) {
  selected_series <- reactive({
    if (input$county == "Washington statewide") {
      wa_monthly
    } else {
      wa_county_monthly |>
        filter(county == input$county) |>
        left_join(
          select(
            wa_monthly,
            month,
            washington_regular_gas_price
          ),
          by = "month"
        )
    }
  })

  output$signal_strip <- renderUI({
    share_change <- postwar$pooled_zev_share - prewar$pooled_zev_share
    gas_change <- postwar$mean_gas_price / prewar$mean_gas_price - 1
    div(
      class = "signal-strip",
      div(
        class = "signal",
        div(class = "signal-label", "March–June 2026 ZEV title share"),
        div(
          class = "signal-value",
          percent(postwar$pooled_zev_share, accuracy = .1)
        ),
        div(class = "signal-note", "Washington statewide")
      ),
      div(
        class = "signal",
        div(class = "signal-label", "Change from Nov.–Feb."),
        div(
          class = "signal-value",
          number(100 * share_change, accuracy = .1, suffix = " pp")
        ),
        div(class = "signal-note", "Pooled title share")
      ),
      div(
        class = "signal",
        div(class = "signal-label", "Gas-price change"),
        div(class = "signal-value", percent(gas_change, accuracy = .1)),
        div(class = "signal-note", "Post-war vs. Nov.–Feb. average")
      )
    )
  })

  output$timeline_title <- renderText({
    paste(metric_config[[input$metric]]$label, "through", latest_label)
  })

  output$timeline_subtitle <- renderText({
    if (input$metric == "gas_price" && input$county != "Washington statewide") {
      "Gasoline price is statewide; the selected county remains active below."
    } else {
      paste("Selected geography:", input$county)
    }
  })

  output$market_plot <- renderPlotly({
    cfg <- metric_config[[input$metric]]
    data <- selected_series() |>
      filter(month >= as.Date(input$window_start)) |>
      mutate(value = .data[[cfg$column]])

    plot <- ggplot(data, aes(month, value)) +
      geom_area(fill = teal, alpha = .10) +
      geom_line(color = teal, linewidth = 1) +
      geom_point(color = rust, size = 1.7) +
      scale_x_date(date_breaks = "6 months", date_labels = "%Y\n%b") +
      scale_y_continuous(
        labels = cfg$formatter,
        expand = expansion(mult = c(.08, .16))
      ) +
      labs(x = NULL, y = cfg$axis) +
      theme_editorial()

    if (isTRUE(input$show_events)) {
      plot <- plot +
        geom_vline(
          data = event_markers,
          aes(xintercept = date),
          color = rust,
          linetype = "longdash",
          linewidth = .5
        )
    }
    ggplotly(plot, tooltip = c("x", "y")) |>
      config(displayModeBar = FALSE)
  })

  output$benchmark_plot <- renderPlotly({
    display <- wa_monthly |>
      filter(month >= as.Date(input$window_start))
    plot <- ggplot(display, aes(month)) +
      geom_ribbon(
        aes(
          ymin = empirical_prediction_low,
          ymax = empirical_prediction_high
        ),
        fill = teal,
        alpha = .12
      ) +
      geom_line(
        aes(y = expected_zev_share, color = "Pre-rolloff expectation"),
        linewidth = .9
      ) +
      geom_line(
        aes(y = zev_share, color = "Observed ZEV title share"),
        linewidth = 1.1
      ) +
      geom_vline(
        xintercept = as.Date("2025-11-01"),
        color = rust,
        linetype = "longdash"
      ) +
      geom_vline(
        xintercept = as.Date("2026-03-01"),
        color = rust,
        linetype = "dotted"
      ) +
      scale_color_manual(values = c(
        "Observed ZEV title share" = teal,
        "Pre-rolloff expectation" = gold
      )) +
      scale_x_date(date_breaks = "6 months", date_labels = "%Y\n%b") +
      scale_y_continuous(labels = label_percent(accuracy = 1)) +
      labs(
        x = NULL,
        y = "ZEV share",
        caption = paste(
          "Shading uses ±1.96 rolling-validation RMSE.",
          "Dashed = post-incentive-rolloff period; dotted = post-war period."
        )
      ) +
      theme_editorial()
    ggplotly(plot, tooltip = c("x", "y", "colour")) |>
      config(displayModeBar = FALSE)
  })

  output$regression_evidence <- renderUI({
    selected_model <- wa_model_comparison |> filter(selected)
    div(
      class = "evidence-card",
      h3("What the model supports"),
      div(
        class = "evidence-row",
        span(class = "evidence-label", "Pre-event training months"),
        span(
          class = "evidence-number",
          audit_value("benchmark_training_months")
        )
      ),
      div(
        class = "evidence-row",
        span(class = "evidence-label", "Rolling forecast RMSE"),
        span(
          class = "evidence-number",
          number(100 * selected_model$rolling_rmse, accuracy = .1, suffix = " pp")
        )
      ),
      div(
        class = "evidence-row",
        span(class = "evidence-label", "Additional post-war change"),
        span(
          class = "evidence-number",
          number(
            100 * war_coefficient$estimate,
            accuracy = .1,
            suffix = " pp"
          )
        )
      ),
      p(
        class = "evidence-takeaway",
        paste0(
          "The combined post-incentive-rolloff level shift was ",
          number(100 * rolloff_coefficient$estimate, accuracy = .1),
          " percentage points (Newey–West p < 0.001). ",
          "The additional post-war change was not statistically distinct ",
          "(p = ", number(war_coefficient$p_value, accuracy = .001), ")."
        )
      ),
      span(class = "flag", "Four post-war months · association, not causation")
    )
  })

  output$benchmark_explainer <- renderUI({
    selected_model <- wa_model_comparison |> filter(selected)
    empirical_half_width <- 1.96 * selected_model$rolling_rmse

    div(
      class = "benchmark-explainer",
      div(
        class = "explainer-lead",
        div(class = "explainer-label", "What is measured"),
        div(
          class = "explainer-question",
          paste(
            "Did Washington's statewide ZEV title share depart from the",
            "path its pre-incentive-rolloff history would predict?"
          )
        )
      ),
      div(
        class = "explainer-grid",
        div(
          class = "explainer-cell",
          span(class = "explainer-number", "01 / Outcome"),
          h3("Monthly ZEV title share"),
          span(
            class = "measurement-equation",
            "New light-duty BEV + PHEV + FCEV original titles",
            tags$br(),
            "÷ all new light-duty original titles"
          ),
          p(
            paste(
              "This is a statewide registration-transaction measure,",
              "not a dealer-sales measure."
            )
          )
        ),
        div(
          class = "explainer-cell",
          span(class = "explainer-number", "02 / Benchmark"),
          h3("Expected without the event terms"),
          p(
            paste(
              "The model learned from January 2017–June 2025:",
              "a quadratic adoption trend, calendar-month seasonality,",
              "and a COVID disruption indicator. It was selected using",
              "42 rolling one-month-ahead forecasts."
            )
          )
        ),
        div(
          class = "explainer-cell",
          span(class = "explainer-number", "03 / Read the chart"),
          h3("Observed versus expected"),
          p(
            paste0(
              "Teal is observed share; gold is expected share. The pale band ",
              "is an empirical forecast-error band of ±", number(
                100 * empirical_half_width,
                accuracy = .1
              ), " percentage points—not a causal confidence interval. ",
              "Dashed marks the post-incentive-rolloff title period; ",
              "dotted marks post-war."
            )
          )
        ),
        div(
          class = "explainer-cell",
          span(class = "explainer-number", "04 / Finding"),
          h3("No distinct post-war rebound yet"),
          p(
            paste0(
              "For March–June 2026, observed share was ",
              percent(postwar$pooled_zev_share, accuracy = .1),
              " versus ", percent(postwar$mean_expected_zev_share, accuracy = .1),
              " expected; observed minus expected was ", number(
                100 * postwar$observed_minus_expected,
                accuracy = .1,
                suffix = " pp"
              ), ". The additional post-war estimate was ",
              number(100 * war_coefficient$estimate, accuracy = .1, suffix = " pp"),
              " (95% CI ", number(
                100 * war_coefficient$confidence_low,
                accuracy = .1
              ), " to ", number(
                100 * war_coefficient$confidence_high,
                accuracy = .1
              ), "; p = ", number(war_coefficient$p_value, accuracy = .001), ")."
            )
          )
        )
      ),
      p(
        class = "benchmark-guardrail",
        strong("Important distinction: "),
        paste(
          "gasoline price is not a predictor in this benchmark; it is modeled",
          "separately in Section 03. The benchmark does not prove that the",
          "state or federal incentive expirations, or the war, caused the change."
        )
      )
    )
  })

  output$gas_sensitivity_plot <- renderPlotly({
    display <- wa_gas_sensitivity |>
      mutate(
        specification = recode(
          model,
          policy_adjusted = "Policy-adjusted",
          plus_unemployment = "+ WA unemployment",
          plus_electricity = "+ WA electricity price",
          plus_postwar_indicator = "+ Post-war indicator"
        ),
        specification = factor(
          specification,
          levels = rev(c(
            "Policy-adjusted",
            "+ WA unemployment",
            "+ WA electricity price",
            "+ Post-war indicator"
          ))
        ),
        estimate_pp = 100 * gas_estimate,
        low_pp = 100 * gas_confidence_low,
        high_pp = 100 * gas_confidence_high,
        tooltip = paste0(
          specification,
          "<br>Estimate: ",
          number(estimate_pp, accuracy = .1),
          " pp per $1",
          "<br>95% CI: ",
          number(low_pp, accuracy = .1),
          " to ",
          number(high_pp, accuracy = .1),
          " pp"
        )
      )
    plot <- ggplot(
      display,
      aes(estimate_pp, specification, text = tooltip)
    ) +
      geom_vline(xintercept = 0, color = muted, linetype = "dotted") +
      geom_errorbar(
        aes(xmin = low_pp, xmax = high_pp),
        orientation = "y",
        width = .16,
        color = gold,
        linewidth = .8
      ) +
      geom_point(color = teal, size = 3.2) +
      labs(
        x = "ZEV-share association per $1/gallon (percentage points)",
        y = NULL,
        caption = paste(
          "Newey–West 95% intervals.",
          "Association estimates are not causal effects."
        )
      ) +
      theme_editorial()
    ggplotly(plot, tooltip = "text") |>
      config(displayModeBar = FALSE)
  })

  output$gas_evidence <- renderUI({
    no_gas <- wa_gas_model_comparison |> filter(model == "no_gas")
    prior_three <- wa_gas_model_comparison |>
      filter(model == "prior_three_month_average_gas")
    rmse_improvement <- 1 - prior_three$rolling_rmse / no_gas$rolling_rmse
    div(
      class = "evidence-card",
      h3("What the gas model supports"),
      div(
        class = "evidence-row",
        span(class = "evidence-label", "Rolling RMSE improvement"),
        span(
          class = "evidence-number",
          percent(rmse_improvement, accuracy = .1)
        )
      ),
      div(
        class = "evidence-row",
        span(class = "evidence-label", "Policy-adjusted association"),
        span(
          class = "evidence-number",
          number(
            100 * gas_coefficient$estimate,
            accuracy = .1,
            suffix = " pp / $1"
          )
        )
      ),
      div(
        class = "evidence-row",
        span(class = "evidence-label", "95% interval"),
        span(
          class = "evidence-number",
          paste0(
            number(100 * gas_coefficient$confidence_low, accuracy = .1),
            " to ",
            number(100 * gas_coefficient$confidence_high, accuracy = .1),
            " pp"
          )
        )
      ),
      p(
        class = "evidence-takeaway",
        paste0(
          "The prior-three-month gas measure modestly improved historical ",
          "prediction. After adding Washington electricity prices, the estimate ",
          "fell to ", number(
            100 * gas_electricity_sensitivity$gas_estimate,
            accuracy = .1
          ), " pp per $1 and its interval included zero (p = ", number(
            gas_electricity_sensitivity$gas_p_value,
            accuracy = .001
          ), ")."
        )
      ),
      span(
        class = "flag",
        "Predictive association · sensitive to specification"
      )
    )
  })

  output$vmt_plot <- renderPlotly({
    display <- wa_vmt |>
      filter(month >= as.Date(input$window_start)) |>
      mutate(
        direction = if_else(
          yoy_change < 0,
          "Less driving",
          "More driving"
        ),
        tooltip = paste0(
          format(month, "%B %Y"),
          "<br>Year-over-year: ",
          percent(yoy_change, accuracy = .1),
          "<br>VMT: ",
          comma(vmt_million_miles),
          " million miles"
        )
      )
    plot <- ggplot(
      display,
      aes(month, yoy_change, fill = direction, text = tooltip)
    ) +
      geom_hline(yintercept = 0, color = muted) +
      geom_col(width = 24) +
      geom_vline(
        xintercept = as.Date("2026-03-01"),
        color = rust,
        linetype = "longdash"
      ) +
      scale_fill_manual(values = c(
        "Less driving" = rust,
        "More driving" = teal
      )) +
      scale_x_date(date_breaks = "6 months", date_labels = "%Y\n%b") +
      scale_y_continuous(labels = label_percent(accuracy = 1)) +
      labs(
        x = NULL,
        y = "Change from same month one year earlier",
        caption = paste(
          "FHWA Traffic Volume Trends.",
          "May 2026 is preliminary; dashed line marks March 2026."
        )
      ) +
      theme_editorial()
    ggplotly(plot, tooltip = "text") |>
      config(displayModeBar = FALSE)
  })

  output$county_plot <- renderPlotly({
    selected_county <- if (
      input$county == "Washington statewide"
    ) character() else input$county
    display <- wa_county_postwar |>
      arrange(desc(postwar_new_ldv_titles)) |>
      mutate(rank = row_number()) |>
      filter(rank <= 15 | county %in% selected_county) |>
      mutate(
        county = reorder(county, change_percentage_points),
        direction = if_else(
          change_percentage_points >= 0,
          "Higher post-war share",
          "Lower post-war share"
        )
      )
    plot <- ggplot(
      display,
      aes(
        change_percentage_points,
        county,
        fill = direction,
        text = paste0(
          county,
          "<br>Change: ",
          number(change_percentage_points, accuracy = .1),
          " pp<br>Post-war share: ",
          percent(postwar_zev_share, accuracy = .1)
        )
      )
    ) +
      geom_vline(xintercept = 0, color = muted) +
      geom_col(width = .7) +
      scale_fill_manual(values = c(
        "Higher post-war share" = teal,
        "Lower post-war share" = rust
      )) +
      labs(x = "Change in ZEV title share (percentage points)", y = NULL) +
      theme_editorial()
    ggplotly(plot, tooltip = "text") |>
      config(displayModeBar = FALSE)
  })

  output$state_comparison_plot <- renderPlotly({
    washington_quarterly <- wa_monthly |>
      filter(month >= as.Date("2023-01-01")) |>
      mutate(
        year = as.integer(format(month, "%Y")),
        quarter = ((as.integer(format(month, "%m")) - 1L) %/% 3L) + 1L,
        quarter_start = as.Date(paste0(
          year,
          "-",
          sprintf("%02d", 1 + 3 * (quarter - 1L)),
          "-01"
        ))
      ) |>
      group_by(quarter_start) |>
      summarise(
        share = sum(zev_titles) / sum(total_new_ldv_titles),
        .groups = "drop"
      ) |>
      mutate(series = "Washington new-title share")
    california <- california_quarterly |>
      transmute(
        quarter_start,
        share = zev_share,
        series = "California CEC sales share"
      )
    comparison <- bind_rows(washington_quarterly, california) |>
      group_by(series) |>
      mutate(
        baseline = share[quarter_start == as.Date("2025-10-01")][1],
        index = 100 * share / baseline
      ) |>
      ungroup()
    plot <- ggplot(
      comparison,
      aes(quarter_start, index, color = series, group = series)
    ) +
      geom_hline(yintercept = 100, color = muted, linetype = "dotted") +
      geom_line(linewidth = 1) +
      geom_point(size = 2) +
      scale_color_manual(values = c(
        "Washington new-title share" = teal,
        "California CEC sales share" = rust
      )) +
      scale_x_date(date_breaks = "6 months", labels = quarter_axis) +
      labs(x = NULL, y = "Index (2025 Q4 = 100)") +
      theme_editorial()
    ggplotly(plot, tooltip = c("x", "y", "colour")) |>
      config(displayModeBar = FALSE)
  })

  output$conjoint_plot <- renderPlotly({
    display <- conjoint_partworths
    if (input$conjoint_attribute != "All attributes") {
      display <- display |> filter(attribute == input$conjoint_attribute)
    }
    display <- display |>
      mutate(
        attribute = factor(
          attribute,
          levels = c("Brand", "Fuel economy", "Price")
        ),
        level = factor(level, levels = rev(unique(level))),
        hover = paste0(
          attribute, ": ", level,
          "<br>Utility: ", number(utility, accuracy = .01),
          "<br>95% interval: ",
          number(confidence_low, accuracy = .01), " to ",
          number(confidence_high, accuracy = .01)
        )
      )
    plot <- ggplot(
      display,
      aes(utility, level, color = attribute, text = hover)
    ) +
      geom_vline(xintercept = 0, color = muted, linetype = "dotted") +
      geom_errorbar(
        aes(xmin = confidence_low, xmax = confidence_high),
        orientation = "y",
        width = .16
      ) +
      geom_point(size = 3) +
      facet_grid(
        rows = vars(attribute),
        scales = "free_y",
        space = "free_y"
      ) +
      scale_color_manual(values = c(
        "Brand" = teal,
        "Fuel economy" = gold,
        "Price" = rust
      )) +
      labs(
        x = "Part-worth utility (higher = preferred)",
        y = NULL,
        caption = "Utilities are zero-centered within attribute."
      ) +
      theme_editorial() +
      theme(
        legend.position = "none",
        strip.text = element_text(face = "bold", hjust = 0),
        strip.background = element_blank()
      )
    ggplotly(plot, tooltip = "text") |>
      config(displayModeBar = FALSE)
  })

  output$conjoint_evidence <- renderUI({
    conjoint_audit_value <- function(metric_name) {
      conjoint_audit |>
        filter(metric == metric_name) |>
        pull(value)
    }
    price_test <- conjoint_attribute_tests |> filter(attribute == "Price")
    price_contrast <- conjoint_pairwise |>
      filter(
        attribute == "Price",
        level_1 == "$30,000",
        level_2 == "$120,000"
      )
    div(
      class = "evidence-card",
      h3("What the survey supports"),
      div(
        class = "evidence-row",
        span(class = "evidence-label", "Respondents with ratings"),
        span(
          class = "evidence-number",
          number(
            conjoint_audit_value(
              "survey_ids_with_at_least_one_rating"
            ),
            accuracy = 1
          )
        )
      ),
      div(
        class = "evidence-row",
        span(class = "evidence-label", "Usable profile ratings"),
        span(
          class = "evidence-number",
          number(conjoint_audit_value("complete_ratings"), accuracy = 1)
        )
      ),
      div(
        class = "evidence-row",
        span(class = "evidence-label", "$30K vs. $120K difference"),
        span(
          class = "evidence-number",
          number(price_contrast$preference_difference, accuracy = .01)
        )
      ),
      p(
        class = "evidence-takeaway",
        paste0(
          "Price was the clearest attribute (p = ",
          number(price_test$p_value, accuracy = .001),
          "). Brand and fuel economy cannot be cleanly separated because ",
          "Tesla was consistently paired with 110 MPGe."
        )
      ),
      span(class = "flag", "Small class sample · stated ratings")
    )
  })
}

shinyApp(ui, server)
