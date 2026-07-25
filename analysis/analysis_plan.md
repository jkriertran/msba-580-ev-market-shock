# Washington-First Analysis Plan

## Research question

Did Washington's share of new light-duty ZEV original-title transactions
increase after gasoline prices rose in early 2026, and was that movement large
enough to distinguish it from the post-federal-credit market?

This is an observational study. Event indicators organize time but do not
identify causal effects of the Iran war, gasoline prices, or tax policy.

## Units and outcomes

- **State-month:** Washington new light-duty original-title transactions,
  ZEV-title share, and regular gasoline price.
- **County-month:** geographic heterogeneity in the same title definition.
- **State-quarter:** California CEC ZEV sales as a secondary directional
  comparison.
- **Respondent-profile rating:** stated preferences for brand, fuel economy,
  and price.

The primary outcome is:

`(new BEV + PHEV + FCEV light-duty original titles) / all new light-duty original titles`

## Data filters

The Washington DOL query requires:

- `transaction_type = Original Title`;
- `new_or_used_vehicle = New`;
- owner state equal to Washington;
- passenger car, multipurpose passenger vehicle, or truck;
- GVWR class 1 or 2, including equivalent subcategories.

An original title can otherwise include a used vehicle entering Washington, so
the separate new-vehicle filter is essential. The resulting measure is a title
transaction, not an exact dealer sale date.

## Testable hypotheses

1. ZEV-title share fell after Washington and federal incentives rolled off in
   mid-to-late 2025.
2. ZEV-title share increased after the February 2026 war and gasoline-price
   increase.
3. County responses were heterogeneous.
4. Lower purchase prices received stronger survey ratings.

## Analytical techniques

### Pre-incentive-rolloff regression benchmark

Train through June 2025, leaving July–October as the credit
and state-incentive transition/title-processing period. Compare seasonal-only,
linear-time, and quadratic-time models with calendar-month effects and a COVID
indicator. Select using rolling one-month-ahead RMSE over January 2022–June
2025.

### Interrupted time series

Fit the selected time trend plus seasonality, COVID, a combined
post-incentive-rolloff level indicator beginning November 2025, and a post-war
level indicator beginning March 2026. Report Newey–West standard errors with
four lags. The post-war coefficient measures an additional level difference
beyond the post-rolloff period; it is not causal.

### Gas-price association

Compare current, one-month-lagged, two-month-lagged, and prior-three-month
average Washington gasoline prices against the no-gas benchmark using the same
rolling predictions. Use the prior-three-month average as the temporally
defensible exposure. Fit the full association model with trend, seasonality,
COVID, Washington incentive timing, the transition period, and the combined
post-rolloff indicator. Add Washington unemployment, electricity prices, and a
post-war indicator separately as sensitivity specifications.

### Behavioral response

Plot Washington FHWA vehicle miles traveled relative to the same month one year
earlier. Treat VMT as a separate outcome rather than a control because driving
can respond to gasoline prices.

### County heterogeneity

Pool November 2025–February 2026 and March–June 2026 within each of Washington's
39 counties. Compare ZEV-title shares, emphasizing larger title markets and
excluding the DOL `Unknown or Out of State` category.

### California comparison

Aggregate Washington months to quarters and compare with California CEC
quarterly ZEV sales after indexing both series to 100 in 2025 Q4. Use only for
directional robustness because titles and inferred sales are not identical.

### Rating-based conjoint

Model `6 - rating` using effect-coded brand, fuel economy, and price,
respondent fixed effects, and respondent-clustered standard errors. Treat price
as the cleanest attribute; brand and fuel economy are confounded in the design.

## Decision rule

Emphasize effect size, rolling forecast error, interval estimates, cross-source
consistency, and data-definition limitations. Do not infer a durable rebound
from four post-war months. Do not describe the combined rolloff coefficient as
a federal-credit effect or the gas coefficient as causal.
