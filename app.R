# AI Assistance Disclosure ------------------------------------------------------
# OpenAI Codex helped structure the reactive Shiny components, create reusable
# plotting and formatting functions, and draft the initial editorial layout.
# The group selected the research question, sourced and validated the data, and
# is responsible for reviewing the analysis and final interpretation.

library(shiny)
library(dplyr)
library(ggplot2)
library(plotly)
library(readr)
library(scales)
library(tidyr)

quarterly <- read_csv("data/quarterly_controls.csv", show_col_types = FALSE) |>
  mutate(
    quarter_start = as.Date(quarter_start),
    quarter_end = as.Date(quarter_end),
    quarter_label = paste(year, paste0("Q", quarter))
  ) |>
  arrange(quarter_start)

county_panel <- read_csv("data/county_panel.csv", show_col_types = FALSE) |>
  mutate(
    quarter_start = as.Date(quarter_start),
    quarter_label = paste(year, paste0("Q", quarter))
  ) |>
  arrange(county, quarter_start)

vmt_monthly <- read_csv("data/california_vmt_monthly.csv", show_col_types = FALSE) |>
  mutate(
    observation_month = as.Date(observation_month),
    release_month = as.Date(release_month),
    direction = if_else(yoy_change >= 0, "More driving", "Less driving")
  ) |>
  arrange(observation_month)

latest_quarter <- max(quarterly$quarter_start, na.rm = TRUE)
latest_label <- quarterly$quarter_label[quarterly$quarter_start == latest_quarter][1]

metric_config <- list(
  zev_share = list(
    label = "ZEV share of new light-duty sales", short = "ZEV share", column = "zev_share",
    axis = "ZEV share of new light-duty sales", formatter = label_percent(accuracy = 0.1),
    sentence = "the share of new light-duty sales classified as ZEVs"
  ),
  zev_sales = list(
    label = "New light-duty ZEV sales", short = "ZEV sales", column = "zev_sales",
    axis = "New light-duty ZEVs sold", formatter = label_comma(),
    sentence = "new light-duty ZEV sales"
  ),
  gas_price = list(
    label = "California gasoline price", short = "Gas price", column = "ca_regular_gas_avg",
    axis = "Dollars per gallon", formatter = label_dollar(accuracy = 0.01),
    sentence = "California's average regular gasoline price"
  ),
  ev_search = list(
    label = "EV search interest", short = "EV search", column = "trends_electric_vehicle",
    axis = "Relative Google Trends interest", formatter = label_number(accuracy = 0.1),
    sentence = "Google search interest in electric vehicles"
  )
)

fmt_delta <- function(value) {
  if (is.na(value) || !is.finite(value)) return("Not available")
  paste0(ifelse(value >= 0, "+", ""), percent(value, accuracy = 0.1))
}

quarter_axis <- function(x) {
  month_number <- as.integer(format(x, "%m"))
  paste(format(x, "%Y"), paste0("Q", ((month_number - 1L) %/% 3L) + 1L))
}

quarter_axis_stacked <- function(x) {
  month_number <- as.integer(format(x, "%m"))
  paste0(
    format(x, "%Y"),
    "\nQ",
    ((month_number - 1L) %/% 3L) + 1L
  )
}

theme_editorial <- function() {
  theme_minimal(base_family = "IBM Plex Sans", base_size = 12) +
    theme(
      plot.background = element_rect(fill = "#f6f1e7", color = NA),
      panel.background = element_rect(fill = "#f6f1e7", color = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(color = "#d8d0c2", linewidth = 0.35),
      axis.text = element_text(color = "#48443e"),
      axis.title = element_text(color = "#27241f", face = "bold"),
      plot.title = element_text(family = "DM Serif Display", size = 20, color = "#171510"),
      plot.subtitle = element_text(color = "#625d54", margin = margin(b = 14)),
      plot.caption = element_text(color = "#746e64", hjust = 0),
      legend.position = "top", legend.justification = "left",
      legend.title = element_blank()
    )
}

event_data <- tibble::tribble(
  ~date, ~event,
  as.Date("2023-11-08"), "CVRP closes",
  as.Date("2025-09-30"), "Federal credit ends",
  as.Date("2026-02-28"), "Iran war begins"
)

app_css <- "
@import url('https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=IBM+Plex+Sans:wght@400;500;600&display=swap');
:root {
  --ink: #171510; --paper: #f6f1e7; --paper-deep: #ebe2d3;
  --rust: #b9472e; --teal: #176b68; --muted: #6f685e; --line: #cfc5b6;
}
body { background: var(--paper); color: var(--ink); font-family: 'IBM Plex Sans', sans-serif; }
.container-fluid { padding: 0; }
.masthead { padding: 34px 4.5vw 28px; border-bottom: 1px solid var(--ink); position: relative; overflow: hidden; }
.masthead:after { content: 'CA'; position: absolute; right: 3vw; top: -52px; font-family: 'DM Serif Display';
  font-size: 190px; line-height: 1; color: rgba(185,71,46,.08); pointer-events: none; }
.eyebrow { color: var(--rust); font-weight: 600; letter-spacing: .16em; text-transform: uppercase; font-size: 12px; }
h1 { font-family: 'DM Serif Display', serif; font-size: clamp(42px, 5vw, 76px); line-height: .96; max-width: 930px; margin: 10px 0 16px; }
.dek { max-width: 820px; color: var(--muted); font-size: 18px; line-height: 1.55; margin: 0; }
.app-grid { display: grid; grid-template-columns: minmax(245px, 300px) 1fr; gap: 0; }
.controls { padding: 30px 25px 60px 4.5vw; border-right: 1px solid var(--line); background: var(--paper-deep); }
.controls-inner { position: sticky; top: 20px; }
.controls h2, .section-kicker { font-size: 11px; letter-spacing: .15em; text-transform: uppercase; font-weight: 600; color: var(--rust); }
.controls .form-group { margin-bottom: 22px; }
.control-label { font-size: 13px; font-weight: 600; margin-bottom: 7px; }
.form-control { border: 1px solid #9e9588; border-radius: 0; background: #fffdf8; box-shadow: none; }
.help-copy { font-size: 12px; color: var(--muted); line-height: 1.55; border-top: 1px solid var(--line); padding-top: 18px; margin-top: 26px; }
.definition-note { margin-top: 20px; padding: 16px; border: 1px solid #9e9588; background: #fffdf8; font-size: 12px; line-height: 1.45; }
.definition-note h3 { margin: 0 0 11px; color: var(--rust); font-size: 10px; font-weight: 600; letter-spacing: .14em; text-transform: uppercase; }
.definition-note dl { margin: 0; }
.definition-note dt { color: var(--ink); font-weight: 600; }
.definition-note dd { margin: 2px 0 10px; color: var(--muted); }
.definition-note p { margin: 10px 0 0; padding-top: 10px; border-top: 1px solid var(--line); color: var(--muted); }
.content { padding: 30px 4.5vw 70px 34px; min-width: 0; }
.signal-strip { display: grid; grid-template-columns: repeat(3, 1fr); border: 1px solid var(--ink); margin-bottom: 26px; }
.signal { padding: 18px 20px; min-height: 114px; background: #fffdf8; }
.signal + .signal { border-left: 1px solid var(--ink); }
.signal-label { font-size: 11px; color: var(--muted); text-transform: uppercase; letter-spacing: .09em; }
.signal-value { font-family: 'DM Serif Display'; font-size: 34px; line-height: 1.1; margin: 7px 0 3px; }
.signal-note { font-size: 12px; color: var(--muted); }
.panel { border: 0; border-top: 3px solid var(--ink); border-radius: 0; box-shadow: none; background: transparent; margin: 0 0 34px; padding-top: 16px; }
.panel-title { font-family: 'DM Serif Display'; font-size: 25px; margin: 0; }
.panel-subtitle { color: var(--muted); margin: 6px 0 12px; }
.two-up { display: grid; grid-template-columns: 1.35fr .85fr; gap: 32px; align-items: start; }
.insight-box { background: var(--teal); color: #fffdf8; padding: 25px; margin-top: 12px; position: relative; }
.insight-box:before { content: 'SO WHAT'; display: block; font-size: 10px; letter-spacing: .18em; font-weight: 600; opacity: .7; margin-bottom: 12px; }
.insight-box strong { color: #ffe0b8; }
.insight-box p { font-family: 'DM Serif Display'; font-size: 22px; line-height: 1.35; margin: 0; }
.caveat { margin-top: 15px; padding-top: 13px; border-top: 1px solid rgba(255,255,255,.35); font-family: 'IBM Plex Sans'; font-size: 12px; line-height: 1.5; opacity: .82; }
.method { border-left: 4px solid var(--rust); padding: 4px 0 4px 17px; color: var(--muted); font-size: 13px; line-height: 1.6; }
.behavior-grid { display: grid; grid-template-columns: minmax(0, 1.45fr) minmax(230px, .55fr); gap: 30px; align-items: stretch; }
.evidence-card { background: #fffdf8; border: 1px solid var(--ink); padding: 22px; display: flex; flex-direction: column; justify-content: center; }
.evidence-card h3 { font-family: 'DM Serif Display'; font-size: 22px; margin: 0 0 16px; }
.evidence-row { display: grid; grid-template-columns: 1fr auto; gap: 14px; padding: 10px 0; border-top: 1px solid var(--line); align-items: baseline; }
.evidence-label { color: var(--muted); font-size: 12px; }
.evidence-number { font-family: 'DM Serif Display'; font-size: 24px; }
.evidence-takeaway { margin: 18px 0 0; color: var(--ink); font-size: 13px; line-height: 1.55; }
.partial-flag { display: inline-block; margin-top: 14px; padding: 7px 9px; background: #f0dfc7; color: #713322; font-size: 10px; font-weight: 600; letter-spacing: .08em; text-transform: uppercase; }
@media (max-width: 920px) { .app-grid, .two-up { grid-template-columns: 1fr; } .controls { border-right: 0; border-bottom: 1px solid var(--line); padding: 24px 5vw; } .controls-inner { position: static; } .content { padding: 28px 5vw; } }
@media (max-width: 920px) { .behavior-grid { grid-template-columns: 1fr; } }
@media (max-width: 620px) { .signal-strip { grid-template-columns: 1fr; } .signal + .signal { border-left: 0; border-top: 1px solid var(--ink); } }
"

ui <- fluidPage(
  tags$head(tags$style(HTML(app_css))),
  tags$header(
    class = "masthead",
    div(class = "eyebrow", "California EV Market Shock Monitor"),
    h1("Did fuel pressure offset the loss of EV incentives?"),
    p(class = "dek", paste0(
      "Explore how California EV demand changed around the September 2025 federal tax-credit expiration ",
      "and the February 2026 Iran war. Data covers 2023 Q1 through ", latest_label, "."
    ))
  ),
  div(
    class = "app-grid",
    tags$aside(
      class = "controls",
      div(
        class = "controls-inner",
        h2("Build a comparison"),
        selectInput("county", "Geography", choices = c("California statewide", sort(unique(county_panel$county)))),
        selectInput(
          "metric", "Primary signal",
          choices = c(
            "ZEV share of new light-duty sales" = "zev_share",
            "New light-duty ZEV sales" = "zev_sales",
            "California gasoline price" = "gas_price", "EV search interest" = "ev_search"
          )
        ),
        selectInput(
          "baseline", "Comparison quarter",
          choices = setNames(quarterly$quarter_label, quarterly$quarter_label), selected = "2025 Q4"
        ),
        checkboxInput("show_events", "Show policy and war markers", value = TRUE),
        p(class = "help-copy",
          "Tip: choose a county and ZEV share to compare local adoption with the statewide market. Gas prices and search interest are statewide context signals."
        ),
        div(
          class = "definition-note",
          h3("Measure definitions"),
          tags$dl(
            tags$dt("ZEV sales"),
            tags$dd("Count of new light-duty BEVs, plug-in hybrids, and hydrogen fuel-cell vehicles."),
            tags$dt("ZEV share"),
            tags$dd("ZEV sales divided by all new light-duty vehicle sales."),
            tags$dt("Vehicle miles traveled"),
            tags$dd("Estimated miles driven on all California roads and streets; this is broader than the State Highway System.")
          ),
          p("ZEV metrics exclude used and medium- or heavy-duty vehicles. VMT includes all vehicle classes traveling on covered roads.")
        )
      )
    ),
    mainPanel(
      class = "content",
      width = 12,
      uiOutput("signal_strip"),
      tags$section(
        class = "panel",
        div(class = "section-kicker", "01 / Market timeline"),
        h2(class = "panel-title", textOutput("timeline_title", inline = TRUE)),
        p(class = "panel-subtitle", textOutput("timeline_subtitle", inline = TRUE)),
        plotlyOutput("market_plot", height = "430px")
      ),
      div(
        class = "two-up",
        tags$section(
          class = "panel",
          div(class = "section-kicker", "02 / Signals in context"),
          h2(class = "panel-title", "Three market signals, one baseline"),
          p(class = "panel-subtitle", textOutput("context_subtitle", inline = TRUE)),
          plotlyOutput("context_plot", height = "350px")
        ),
        tags$section(
          class = "panel",
          div(class = "section-kicker", "03 / Interpretation"),
          h2(class = "panel-title", "What changed?"),
          uiOutput("insight")
        )
      ),
      tags$section(
        class = "panel",
        div(class = "section-kicker", "04 / Behavior response"),
        h2(class = "panel-title", "Did Californians drive less?"),
        p(
          class = "panel-subtitle",
          paste0(
            "Each bar compares monthly vehicle miles traveled with the same month one year earlier. ",
            "The 0% line means no change; positive bars mean more driving and negative bars mean less."
          )
        ),
        div(
          class = "behavior-grid",
          plotlyOutput("vmt_plot", height = "410px"),
          uiOutput("vmt_evidence")
        )
      ),
      tags$section(
        class = "panel",
        div(class = "section-kicker", "05 / County benchmark"),
        h2(class = "panel-title", paste("County EV share in", latest_label)),
        p(class = "panel-subtitle", "Top 12 counties plus your selected county; share controls for differences in market size."),
        plotlyOutput("county_plot", height = "430px")
      ),
      div(
        class = "method",
        strong("Interpretation guardrail: "),
        "This dashboard describes timing and association; it does not prove that the war caused EV sales or driving to change. Q2 2026 is the first full post-war sales quarter, but the VMT series currently ends in May. Sources include the California Energy Commission, EIA, FRED/BLS, Google Trends, and FHWA Traffic Volume Trends using state-reported counts."
      )
    )
  )
)

server <- function(input, output, session) {
  selected_config <- reactive(metric_config[[input$metric]])

  selected_series <- reactive({
    cfg <- selected_config()
    statewide_only <- input$metric %in% c("gas_price", "ev_search") || input$county == "California statewide"

    if (statewide_only) {
      quarterly |>
        transmute(
          quarter_start, quarter_label,
          value = .data[[cfg$column]], geography = "California statewide"
        )
    } else {
      county_panel |>
        filter(county == input$county) |>
        transmute(quarter_start, quarter_label, value = .data[[cfg$column]], geography = county)
    }
  })

  comparison_values <- reactive({
    series <- selected_series()
    current <- series |> filter(quarter_start == max(quarter_start, na.rm = TRUE)) |> slice(1)
    baseline <- series |> filter(quarter_label == input$baseline) |> slice(1)
    delta <- if (nrow(baseline) && baseline$value != 0) current$value / baseline$value - 1 else NA_real_
    list(current = current, baseline = baseline, delta = delta)
  })

  output$timeline_title <- renderText({
    paste(selected_config()$label, "through", latest_label)
  })

  output$timeline_subtitle <- renderText({
    if (input$metric %in% c("gas_price", "ev_search") && input$county != "California statewide") {
      paste("This context signal is statewide; county selection remains active in the county benchmark below.")
    } else {
      paste("Selected geography:", input$county)
    }
  })

  output$signal_strip <- renderUI({
    values <- comparison_values()
    cfg <- selected_config()
    current_value <- if (nrow(values$current)) values$current$value else NA_real_
    baseline_value <- if (nrow(values$baseline)) values$baseline$value else NA_real_
    gas_now <- quarterly |> filter(quarter_start == latest_quarter) |> pull(ca_regular_gas_avg)

    div(
      class = "signal-strip",
      div(class = "signal",
          div(class = "signal-label", paste(latest_label, cfg$short)),
          div(class = "signal-value", cfg$formatter(current_value)),
          div(class = "signal-note", ifelse(input$county == "California statewide" || input$metric %in% c("gas_price", "ev_search"), "California", input$county))
      ),
      div(class = "signal",
          div(class = "signal-label", paste("Change from", input$baseline)),
          div(class = "signal-value", fmt_delta(values$delta)),
          div(class = "signal-note", paste("Baseline:", cfg$formatter(baseline_value)))
      ),
      div(class = "signal",
          div(class = "signal-label", paste(latest_label, "gas price")),
          div(class = "signal-value", dollar(gas_now, accuracy = 0.01)),
          div(class = "signal-note", "California regular gasoline average")
      )
    )
  })

  output$market_plot <- renderPlotly({
    data <- selected_series()
    cfg <- selected_config()
    baseline_value <- data$value[data$quarter_label == input$baseline][1]

    plot <- ggplot(data, aes(quarter_start, value)) +
      geom_area(fill = "#176b68", alpha = 0.11) +
      geom_line(color = "#176b68", linewidth = 1.15) +
      geom_point(color = "#f6f1e7", fill = "#b9472e", shape = 21, size = 3.2, stroke = 1) +
      geom_hline(yintercept = baseline_value, color = "#746e64", linetype = "dotted") +
      scale_x_date(
        breaks = data$quarter_start,
        labels = quarter_axis_stacked,
        expand = expansion(mult = c(.015, .035))
      ) +
      scale_y_continuous(labels = cfg$formatter, expand = expansion(mult = c(.08, .17))) +
      labs(x = NULL, y = cfg$axis,
           caption = paste("Dotted line =", input$baseline, "comparison level")) +
      theme_editorial() +
      theme(
        panel.grid.major.x = element_line(color = "#ded6c9", linewidth = 0.3),
        axis.line.x = element_line(color = "#8f877b", linewidth = 0.45),
        axis.ticks.x = element_line(color = "#48443e", linewidth = 0.5),
        axis.ticks.length.x = grid::unit(5, "pt"),
        axis.text.x = element_text(
          angle = 0,
          hjust = 0.5,
          vjust = 1,
          lineheight = 0.95,
          margin = margin(t = 7)
        )
      )

    if (isTRUE(input$show_events)) {
      plot <- plot +
        geom_vline(data = event_data, aes(xintercept = date), color = "#b9472e", linetype = "longdash", linewidth = .45) +
        geom_text(data = event_data, aes(x = date, y = Inf, label = event), inherit.aes = FALSE,
                  angle = 90, vjust = 1.25, hjust = 1.05, size = 3, color = "#7f2e20")
    }
    ggplotly(plot, tooltip = c("x", "y")) |>
      config(displayModeBar = FALSE)
  })

  output$context_plot <- renderPlotly({
    base <- quarterly |>
      select(quarter_start, quarter_label, zev_share, ca_regular_gas_avg, trends_electric_vehicle) |>
      pivot_longer(c(zev_share, ca_regular_gas_avg, trends_electric_vehicle), names_to = "signal", values_to = "value") |>
      group_by(signal) |>
      mutate(
        baseline = value[quarter_label == input$baseline][1],
        index = 100 * value / baseline
      ) |>
      ungroup() |>
      mutate(signal = recode(signal,
        zev_share = "EV market share", ca_regular_gas_avg = "Gas price", trends_electric_vehicle = "EV search interest"
      ))

    baseline_date <- base |>
      filter(quarter_label == input$baseline) |>
      summarise(value = first(quarter_start)) |>
      pull(value)

    plot <- ggplot(base, aes(
      quarter_start, index, color = signal,
      text = paste0(
        signal, "<br>", quarter_label,
        "<br>Index: ", round(index, 1),
        "<br>Raw value: ", round(value, 2)
      )
    )) +
      geom_hline(yintercept = 100, color = "#746e64", linetype = "dotted") +
      geom_vline(
        xintercept = baseline_date,
        color = "#b9472e", linetype = "longdash", linewidth = .55
      ) +
      geom_line(linewidth = 1) + geom_point(size = 2) +
      geom_point(
        data = base |> filter(quarter_label == input$baseline),
        shape = 21, size = 3.1, stroke = .8, fill = "#f6f1e7"
      ) +
      annotate(
        "text",
        x = baseline_date, y = Inf,
        label = paste(input$baseline, "baseline"),
        angle = 90, vjust = 1.25, hjust = 1.05,
        size = 3, color = "#7f2e20"
      ) +
      scale_color_manual(values = c("EV market share" = "#176b68", "Gas price" = "#b9472e", "EV search interest" = "#8b6b2f")) +
      scale_x_date(date_breaks = "6 months", labels = quarter_axis) +
      scale_y_continuous(
        labels = label_number(accuracy = 1),
        expand = expansion(mult = c(.08, .14))
      ) +
      labs(x = NULL, y = paste0("Index (", input$baseline, " = 100)")) +
      theme_editorial() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        axis.title.y = element_text(margin = margin(r = 12)),
        plot.margin = margin(t = 8, r = 8, b = 8, l = 28)
      )

    ggplotly(plot, tooltip = "text") |>
      config(displayModeBar = FALSE)
  })

  output$context_subtitle <- renderText({
    paste0(
      "All three series equal 100 in ", input$baseline,
      ". Values above or below 100 show the percentage difference from that quarter."
    )
  })

  output$insight <- renderUI({
    values <- comparison_values()
    cfg <- selected_config()
    current_value <- values$current$value
    baseline_value <- values$baseline$value
    direction <- if (is.na(values$delta)) "could not be compared with" else if (values$delta >= 0) "was higher than" else "was lower than"
    geo <- if (input$metric %in% c("gas_price", "ev_search")) "California" else input$county
    war_share <- quarterly |> filter(quarter_start == latest_quarter) |> pull(zev_share)
    q4_share <- quarterly |> filter(quarter_label == "2025 Q4") |> pull(zev_share)

    div(
      class = "insight-box",
      p(HTML(paste0(
        "In <strong>", latest_label, "</strong>, ", cfg$sentence, " in ", geo, " was <strong>",
        cfg$formatter(current_value), "</strong>. That ", direction, " ", input$baseline,
        " (", cfg$formatter(baseline_value), ") by <strong>", fmt_delta(values$delta), "</strong>."
      ))),
      div(class = "caveat", paste0(
        "Post-war checkpoint: statewide EV share moved from ", percent(q4_share, accuracy = .1),
        " in 2025 Q4 to ", percent(war_share, accuracy = .1), " in ", latest_label,
        ". Treat this as a descriptive rebound, not a causal estimate."
      ))
    )
  })

  output$vmt_plot <- renderPlotly({
    display <- vmt_monthly |>
      filter(observation_month >= as.Date("2024-01-01"))

    plot <- ggplot(display, aes(observation_month, yoy_change)) +
      geom_hline(yintercept = 0, color = "#746e64", linewidth = .45) +
      geom_col(aes(fill = direction), width = 24, alpha = .9) +
      geom_point(color = "#27241f", size = 1.4) +
      scale_fill_manual(
        values = c("More driving" = "#176b68", "Less driving" = "#b9472e"),
        breaks = c("Less driving", "More driving")
      ) +
      scale_x_date(
        date_breaks = "3 months", date_labels = "%Y\n%b",
        expand = expansion(mult = c(.015, .035))
      ) +
      scale_y_continuous(
        labels = label_percent(accuracy = 1),
        breaks = breaks_width(.02),
        expand = expansion(mult = c(.12, .16))
      ) +
      labs(
        x = NULL, y = "Year-over-year VMT change",
        caption = "May 2026 is preliminary. June 2026 was not published when this app was updated."
      ) +
      theme_editorial() +
      theme(
        panel.grid.major.x = element_line(color = "#ded6c9", linewidth = .3),
        axis.text.x = element_text(hjust = .5, lineheight = .95),
        axis.title.y = element_text(margin = margin(r = 12)),
        axis.ticks.x = element_line(color = "#48443e"),
        axis.ticks.length.x = grid::unit(4, "pt"),
        plot.margin = margin(t = 8, r = 8, b = 8, l = 32)
      )

    if (isTRUE(input$show_events)) {
      plot <- plot +
        geom_vline(
          xintercept = as.Date("2026-02-28"),
          color = "#b9472e", linetype = "longdash", linewidth = .55
        ) +
        annotate(
          "text", x = as.Date("2026-02-28"), y = Inf,
          label = "Iran war begins", angle = 90,
          vjust = 1.25, hjust = 1.05, size = 3, color = "#7f2e20"
        )
    }
    ggplotly(plot, tooltip = c("x", "y", "fill")) |>
      config(displayModeBar = FALSE)
  })

  output$vmt_evidence <- renderUI({
    get_change <- function(month) {
      vmt_monthly |>
        filter(observation_month == as.Date(month)) |>
        pull(yoy_change)
    }
    march <- get_change("2026-03-01")
    april <- get_change("2026-04-01")
    may <- get_change("2026-05-01")

    div(
      class = "evidence-card",
      h3("Early post-war evidence"),
      div(class = "evidence-row",
          span(class = "evidence-label", "March 2026 vs. March 2025"),
          span(class = "evidence-number", percent(march, accuracy = .1))),
      div(class = "evidence-row",
          span(class = "evidence-label", "April 2026 vs. April 2025"),
          span(class = "evidence-number", percent(april, accuracy = .1))),
      div(class = "evidence-row",
          span(class = "evidence-label", "May 2026 vs. May 2025"),
          span(class = "evidence-number", percent(may, accuracy = .1))),
      p(
        class = "evidence-takeaway",
        "Driving rose in March, then slipped slightly below the prior year in April and May. The pattern is mixed—not yet evidence of a large, sustained reduction in driving."
      ),
      span(class = "partial-flag", "May preliminary · June unavailable")
    )
  })

  output$county_plot <- renderPlotly({
    latest <- county_panel |>
      filter(quarter_start == latest_quarter, total_ldv_sales >= 100) |>
      arrange(desc(zev_share)) |>
      mutate(rank = row_number())

    selected <- if (input$county == "California statewide") character() else input$county
    displayed <- latest |>
      filter(rank <= 12 | county %in% selected) |>
      mutate(
        county = reorder(county, zev_share),
        highlight = if_else(as.character(county) %in% selected, "Selected county", "Other county")
      )

    plot <- ggplot(displayed, aes(
      zev_share, county, fill = highlight,
      text = paste0(
        as.character(county), "<br>ZEV share: ",
        percent(zev_share, accuracy = .1)
      )
    )) +
      geom_col(width = .68) +
      geom_text(aes(label = percent(zev_share, accuracy = .1)), hjust = -0.12, size = 3.4, color = "#27241f") +
      scale_fill_manual(values = c("Selected county" = "#b9472e", "Other county" = "#176b68"), guide = "none") +
      scale_x_continuous(labels = label_percent(), expand = expansion(mult = c(0, .18))) +
      labs(x = "ZEV share of new light-duty sales", y = NULL,
           caption = "Counties with fewer than 100 total light-duty sales in the quarter are excluded.") +
      theme_editorial()

    ggplotly(plot, tooltip = "text") |>
      config(displayModeBar = FALSE)
  })
}

shinyApp(ui, server)
