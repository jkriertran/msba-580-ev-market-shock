# California EV Market Shock Monitor

## Live application

[Open the deployed Shiny app](https://jnn2zr-jonathan-krier.shinyapps.io/ev_market_shock_app/)

## Research question

Did rising fuel pressure after the February 2026 Iran war coincide with an EV-demand rebound large enough to offset the decline following the September 2025 federal tax-credit expiration?

## Run the app

```r
install.packages(c(
  "shiny", "dplyr", "ggplot2", "plotly", "readr", "rmarkdown",
  "scales", "tidyr"
))
shiny::runApp()
```

Required packages: `shiny`, `dplyr`, `ggplot2`, `plotly`, `readr`,
`rmarkdown`, `scales`, and `tidyr`. The recommended `cluster` package ships
with standard R installations and is used by the analytical pipeline.

## Rebuild the analysis and report

```r
system("Rscript scripts/run_descriptive_analysis.R")
system("Rscript scripts/run_conjoint_analysis.R")
rmarkdown::render("report/final_report.Rmd")
```

The committed conjoint snapshot is used by default. Set
`CONJOINT_REFRESH=true` before running the conjoint script to refresh only the
anonymous Survey tab from Google Sheets; the names tab is never downloaded.

The rendered report is also available at
[`report/final_report.html`](report/final_report.html).

## Repository contents

- `app.R`: complete Shiny application.
- `data/quarterly_controls.csv`: statewide quarterly ZEV outcomes and context signals.
- `data/county_panel.csv`: quarterly county-level ZEV outcomes and context signals.
- `data/california_vmt_monthly.csv`: monthly California vehicle-miles traveled.
- `data/conjoint_survey.csv`: sanitized rating profiles without respondent
  names.
- `data/data_dictionary.csv`: definitions for the fields used by the application.
- `scripts/validate_project.R`: reproducibility and data-contract checks.
- `scripts/run_descriptive_analysis.R`: event contrasts, seasonal benchmark,
  county heterogeneity, and VMT summaries.
- `scripts/run_conjoint_analysis.R`: survey audit, rating-based part-worth
  model, clustered inference, and design diagnostics.
- `analysis/analysis_plan.md`: research questions, hypotheses, and methods.
- `analysis/preliminary_findings.md`: current effect sizes, interpretation, and
  presentation-ready conclusion.
- `analysis/results/`: reproducible analytical output tables.
- `report/final_report.Rmd`: reproducible capstone report with regression,
  segmentation, conjoint analysis, and recommendations.
- `report/final_report.html`: rendered report ready for review or RPubs upload.
- `feedback/`: formal peer-feedback templates and received/given critique.
- `presentation/`: mini-project and 12-minute capstone presentation outlines.
- `docs/methodology.md`: analytical definitions, transformations, and limitations.

## Draft feature checklist

- Five interactive inputs: geography, primary signal, comparison quarter,
  event-marker toggle, and conjoint-attribute filter.
- Seven reactive output groups: KPI strip, market timeline, normalized context
  chart, dynamic interpretation, driving-response evidence, county benchmark,
  and stated-preference evidence.
- Five interactive Plotly charts with point-level hover details.
- Cleaned, project-produced California EV and market-control data.
- A clear analytical question and visible interpretation guardrail.

## Data sources

- California Energy Commission: ZEV and total light-duty vehicle sales.
- U.S. Energy Information Administration: California gasoline and residential electricity prices.
- Federal Reserve/BLS via FRED: auto-loan rates, vehicle CPI, and unemployment.
- Google Trends: California relative search interest.
- FHWA Traffic Volume Trends: monthly California vehicle miles traveled on all estimated roads and streets, based on state-reported traffic counts.
- Group conjoint survey: anonymous profile ratings for brand, fuel economy, and
  price.

## Challenges and limitations

- Q2 2026 is the first complete post-war quarter, so the app describes associations and timing rather than a causal war effect.
- Google Trends is normalized search interest, not search volume.
- County sales measure registrations reported in the CEC data and may be revised.
- Manufacturer incentives and charging data are not exhaustive.
- CarGurus blocks automated retrieval, so its price trend is not used in this draft.
- The VMT series currently ends in May 2026. May is preliminary and June is unavailable, so the app uses monthly year-over-year changes instead of treating Q2 as a complete quarterly total.
- The conjoint sample contains 18 rated respondents and 123 completed ratings.
  Brand and fuel economy are confounded in the design, so only the price result
  supports a relatively clean attribute conclusion.

## Working AI-assisted revision log

This working log records preliminary design feedback addressed while preparing
the draft. It does not replace the formal critique required from another group.
Formal feedback will be saved in `feedback/peer_feedback_received.md`, and the
post-critique decisions will be documented before the final release.

| Design feedback | Decision | Revision | Reason |
|---|---|---|---|
| Timeline labels are difficult to match to individual points, and the x-axis has no ticks. | Accepted | Added a centered two-line label and visible tick under every quarter, plus faint vertical quarter guides. | Each point can now be traced directly to its quarter; event lines remain at their actual dates. |
| The difference between light-duty sales and ZEV sales is unclear. | Accepted | Renamed both metrics and added an always-visible definition box explaining the numerator, denominator, included powertrains, and excluded vehicle classes. | Prevents viewers from mistaking ZEV sales for all vehicle classes or confusing an absolute count with market share. |
| The app only showed vehicle purchases, not whether consumers responded to fuel pressure by driving less. | Accepted | Added a monthly California VMT section with year-over-year bars, post-war evidence values, and data-completeness warnings. | Adds a second behavioral channel while controlling visually for normal seasonal travel patterns. |
| The context-chart y-axis title is clipped, and the selected index baseline is easy to mistake for the first observation. | Accepted | Shortened the y-axis title, increased its left margin, named the selected baseline in the subtitle, and added a vertical baseline marker with highlighted 100-index points. | Makes clear that every series equals 100 in the selected comparison quarter rather than at the beginning of the chart. |
| The behavior-response y-axis title is clipped, and the comparison level is not explicit. | Accepted | Shortened the y-axis title, increased the left margin, and rewrote the subtitle to define the 0% year-over-year line and the meaning of positive and negative bars. | Makes the chart readable and distinguishes its year-over-year comparison from the indexed baseline used in the context chart. |
| The capstone guide requires at least three interactive Plotly visualizations. | Accepted | Converted the market timeline, indexed context chart, VMT response chart, and county benchmark to Plotly with hover details. | Meets the interaction requirement while preserving the app's established visual design. |

## Version workflow

- `draft-v1`: frozen app version submitted before formal peer critique.
- `peer-critique-revision`: branch used to address formal human feedback.
- `final-v1.0`: presentation-ready release after the critique is resolved.

## Future work

Washington Department of Licensing monthly original-title transactions are
being validated as a possible cross-state robustness check. They are not part
of `draft-v1`, because Washington title transactions and California
CEC-inferred sales are not definitionally identical.
