# Methodology

## Primary measure

Washington's outcome is the share of new light-duty original-title
transactions classified as BEV, PHEV, or FCEV. The denominator contains all
powertrains meeting the same new, original-title, Washington-owner, vehicle-type,
and light-duty GVWR filters.

The measure is not literal monthly dealer sales. Titles may be processed after
purchase, and an original title can represent a used vehicle entering the
state. Requiring DOL's `New` classification prevents those imported used
vehicles from entering the primary series.

## Regression benchmark

The benchmark training period is January 2017–June 2025. Candidate models use:

- calendar-month fixed effects;
- a March 2020–June 2021 COVID disruption indicator;
- no time trend, a linear trend, or a quadratic trend.

Models are compared with 42 rolling one-month-ahead forecasts. The quadratic
model is selected because it has the lowest rolling RMSE. Its empirical display
band is the prediction plus or minus 1.96 times rolling RMSE.

## Interrupted time series

The full-sample model adds:

- `post_credit = 1` beginning November 2025;
- `post_war = 1` beginning March 2026.

November allows one month for credit-expiration purchases to enter the title
system. The post-war coefficient is the additional level difference after
March, conditional on the post-credit indicator, trend, seasonality, and COVID.
Newey–West standard errors use four lags because residuals are autocorrelated.

## County comparison

County shares pool November 2025–February 2026 and March–June 2026. The
`Unknown or Out of State` category is excluded. Small counties can exhibit
large percentage-point movements from few transactions, so the app emphasizes
the largest markets.

## California comparison

Washington is aggregated to quarters and indexed alongside California CEC
sales. Both include BEV, PHEV, and FCEV in the numerator, but Washington counts
new original titles and California reports inferred new sales. Only direction,
not exact level equivalence, should be interpreted.

## Conjoint analysis

Ratings are reversed to `6 - rating`. Effect-coded brand, fuel economy, and
price are estimated with respondent fixed effects and CR1 respondent-clustered
standard errors. Tesla's near-exclusive pairing with 110 MPGe confounds brand
and fuel economy, so willingness-to-pay and simulated-choice claims are not
reported.

## Principal limitations

- Only four post-war title months are available.
- Title dates may lag purchases.
- Tax policy, gasoline prices, incentives, rates, and vehicle availability
  overlap.
- The time-series model is observational, not a causal counterfactual.
- County outcomes share the same statewide environment.
- The conjoint sample is small and partially confounded.
