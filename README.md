# Washington EV Title Response Monitor

## Research question

Did Washington's monthly share of new light-duty ZEV original-title
transactions increase after gasoline prices rose in early 2026, and was that
movement distinguishable from the market after state and federal incentives
rolled off?

## Run the project

```r
install.packages(c(
  "shiny", "dplyr", "ggplot2", "plotly", "readr",
  "rmarkdown", "scales", "tidyr", "jsonlite", "readxl"
))

system("Rscript scripts/pull_washington_data.R")
system("Rscript scripts/pull_washington_controls.R")
system("Rscript scripts/run_washington_analysis.R")
system("Rscript scripts/run_conjoint_analysis.R")
system("Rscript scripts/validate_project.R")
shiny::runApp()
```

Committed data snapshots are used by default so the app and GitHub validation
do not require network access. Set `WASHINGTON_REFRESH=true` to refresh the
Washington DOL, EIA, BLS, policy, and FHWA snapshots. `readxl` is needed only
when refreshing FHWA VMT workbooks. Set `CONJOINT_REFRESH=true` to refresh only
the anonymous Survey tab; respondent names are never downloaded.

## Repository contents

- `app.R`: Washington-first Shiny dashboard.
- `scripts/pull_washington_data.R`: refreshes monthly Washington title and
  gasoline snapshots.
- `scripts/pull_washington_controls.R`: refreshes unemployment, electricity,
  policy-timing, and VMT snapshots.
- `scripts/run_washington_analysis.R`: rolling model selection, pre-rolloff
  benchmark, gas-price association, interrupted time series, event summaries,
  and county comparisons.
- `scripts/run_conjoint_analysis.R`: rating-based conjoint model and audit.
- `data/washington_titles_monthly.csv`: statewide observed monthly title
  outcomes.
- `data/washington_county_monthly.csv`: county-month title outcomes.
- `data/washington_gas_monthly.csv`: EIA regular gasoline prices.
- `data/washington_unemployment_monthly.csv`: BLS Washington unemployment.
- `data/washington_electricity_monthly.csv`: EIA residential electricity
  prices.
- `data/washington_policy_monthly.csv`: documented state and federal policy
  timing.
- `data/washington_vmt_monthly.csv`: FHWA Washington monthly VMT.
- `data/quarterly_controls.csv`: California quarterly comparison data.
- `analysis/results/`: reproducible model and summary tables.
- `report/final_report.Rmd`: reproducible capstone report.
- `report/final_report.html`: rendered report.
- `analysis/analysis_plan.md`: hypotheses and specifications.
- `docs/methodology.md`: definitions, model details, and limitations.
- `presentation/capstone_presentation_outline.md`: 12-minute presentation.
- `washington-scope.md`: implementation plan for the scope change.

## Shiny requirements

- Five inputs: geography, metric, timeline start, event toggle, and conjoint
  attribute.
- Seven interactive Plotly sections: monthly market, regression benchmark,
  gas-price association, VMT response, county response, California comparison,
  and conjoint utilities.
- Reactive KPI and regression-evidence cards.
- A decision-oriented conclusion rather than a collection of unrelated charts.

## Data sources

- [Washington DOL Vehicle Title Transactions](https://data.wa.gov/Transportation/Vehicle-Title-Transactions-by-Department-of-Licens/cdk6-5kdf)
- [EIA Washington regular gasoline prices](https://www.eia.gov/dnav/pet/hist/LeafHandler.ashx?f=W&n=PET&s=EMM_EPMR_PTE_SWA_DPG)
- [BLS Washington unemployment](https://data.bls.gov/timeseries/LAUST530000000000003)
- [EIA monthly electricity data](https://www.eia.gov/electricity/data/browser/)
- [FHWA Traffic Volume Trends](https://www.fhwa.dot.gov/policyinformation/travel_monitoring/tvt.cfm)
- [Washington clean-vehicle sales-tax exemption](https://dor.wa.gov/forms-publications/publications-subject/special-notices/new-clean-alternative-fuel-and-plug-hybrid-vehicle-sales-and-use-tax-exemption)
- [Washington EV Instant Rebate](https://www.commerce.wa.gov/clean-transportation/ev-instant-rebate/)
- [California Energy Commission ZEV sales](https://www.energy.ca.gov/data-reports/energy-almanac/zero-emission-vehicle-and-infrastructure-statistics-collection/new-zev)
- Group conjoint survey, anonymous Survey tab only

## Primary result

The pooled Washington ZEV-title share increased from 13.9% in
November 2025–February 2026 to 14.5% in March–June 2026 while gasoline prices
rose 33.8%. The interrupted-time-series estimate of the additional post-war
change is +1.15 percentage points with Newey–West p = 0.285. Current evidence
does not establish a distinct or durable post-war rebound.

The prior-three-month gasoline-price measure improves rolling prediction RMSE
by 7.9%. The policy-adjusted association is +2.77 ZEV-share percentage points
per $1/gallon, but it falls to +2.00 points and is no longer statistically clear
after controlling for Washington electricity prices. This is a predictive
association, not a causal fuel-price effect.

## Limitations

- Original-title transactions are not exact dealer sale dates.
- Only four post-war months are available.
- Federal policy, fuel prices, incentives, interest rates, and other events
  overlap.
- Washington's sales-tax exemption and the federal credit ended close together,
  so their separate effects cannot be identified reliably.
- California titles and CEC-inferred sales are not identical measures.
- County observations are not independent replications of the statewide shock.
- The conjoint sample contains 18 rated respondents and confounds brand with
  fuel economy.

## AI-assisted revision log

The app's comment header discloses AI assistance. Formal peer feedback belongs
in `feedback/peer_feedback_received.md`; each accepted, modified, or rejected
suggestion should be recorded before the final release.
