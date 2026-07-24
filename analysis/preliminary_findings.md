# Preliminary Findings

## Recommended conclusion

California's official ZEV share partially rebounded in 2026 Q2, but the current
data do not show that fuel pressure fully offset the loss of federal purchase
incentives.

The official share returned to approximately its 2025 Q4 post-credit level,
while remaining below a simple pre-event seasonal benchmark. Gasoline prices
and EV search interest increased sharply, but the timing alone does not
establish that either change caused additional ZEV purchases.

## Evidence

### ZEV market sequence

- ZEV share rose to 28.3% in 2025 Q3, the purchase pull-forward quarter.
- It fell 9.43 percentage points to 18.9% in 2025 Q4 after the federal credit
  expired, a 33.3% relative decline.
- It fell another 3.14 percentage points to 15.8% in the 2026 Q1 transition
  quarter.
- It rebounded 3.33 percentage points to 19.1% in 2026 Q2.
- Relative to 2025 Q4, the 2026 Q2 share was only 0.19 percentage points higher,
  a 1.0% relative increase.

### Fuel pressure and attention

Between 2025 Q4 and 2026 Q2:

- Average California regular gasoline prices rose from $4.34 to $5.73 per
  gallon, a 32.0% increase.
- Google Trends interest in `electric vehicle` rose 140%. This is a normalized
  relative index, not a count of searches.

### Seasonal benchmark

A linear time trend with calendar-quarter indicators, trained on 2023 Q1
through 2025 Q2, expected a 22.5% ZEV share in 2026 Q2. The observed 19.1% share
was 3.38 percentage points lower.

The observation remained inside the model's wide 95% prediction interval
(17.7% to 27.3%). The model has only five residual degrees of freedom and is a
descriptive benchmark, not a causal counterfactual.

Model comparison, robust standard errors, influence screening, residual
diagnostics, and leave-one-out error are reported in the generated analysis
tables. These checks make the uncertainty visible; they do not overcome the
short pre-event history.

### County heterogeneity

- 49 of 58 California counties had a higher ZEV share in 2026 Q2 than in
  2025 Q4.
- The median county increase was 2.35 percentage points.
- Among 33 counties averaging at least 1,000 quarterly light-duty sales, 30
  increased and the median increase was 2.25 percentage points.
- Small-county results are volatile because a handful of vehicle transactions
  can create a large percentage-point change.

### County market segments

A three-cluster k-means solution provides a second major analytical technique:

- **Low-adoption / stalled:** 16 mostly smaller counties averaged a 9.7% 2025
  Q4 ZEV share and a 0.36 percentage-point decline. This group calls for
  investigation of affordability, charging, and awareness barriers before
  adding inventory.
- **Small-market / fast rebound:** 15 small-market counties averaged an 8.4%
  baseline share and a 6.09 percentage-point increase. The direction is
  encouraging, but small denominators make the magnitude volatile.
- **Large established EV markets:** 27 counties averaged a 19.8% baseline share,
  a 2.03 percentage-point increase, and much greater sales volume. This is the
  strongest candidate for inventory and conversion-focused campaigns.

The three-cluster mean silhouette width is only about 0.34, effectively tied
with the best candidate solution. The segments are useful business summaries,
not evidence of sharply separated or permanent county types.

The official CEC statewide total includes vehicles registered in California
with an out-of-state mailing address. The official statewide share increased
0.19 percentage points, while the aggregate restricted to the 58 California
county mailing-address categories increased 1.27 percentage points. The
official CEC result should remain primary, with the county-only result reported
as a sensitivity analysis.

### Driving behavior

For March through May 2026, monthly VMT changes relative to the same months one
year earlier were +3.5%, -0.8%, and -0.1%.

- The three-month mean was +0.87%.
- The median was -0.10%.
- Two of the three months were slightly below the prior year.
- March through May 2025 averaged +1.20% year over year.

This is mixed evidence, not a large or sustained reduction in driving. May 2026
is preliminary and June 2026 is unavailable.

### Stated preferences

The rating-based conjoint analysis uses 123 completed profile ratings from 18
respondents. Price is the clearest attribute block (respondent-clustered
p = 0.013). A $30,000 profile scores 1.30 preference points above a $120,000
profile (95% CI 0.46 to 2.14; p = 0.005).

Fuel economy is directionally favorable but does not clear the 5% threshold
(p = 0.060), and brand is not statistically clear (p = 0.229). More
importantly, Tesla is almost always paired with 110 MPGe, so the brand and fuel
economy coefficients cannot be interpreted as clean independent effects.

## Presentation wording

> California's official ZEV share recovered from its first-quarter low and was
> essentially back to its immediate post-credit level by 2026 Q2. The rebound
> coincided with a 32% increase in gasoline prices and much greater EV search
> interest, but ZEV share remained below a pre-event seasonal benchmark.
> Driving behavior was mixed. These patterns are consistent with renewed EV
> attention, but they do not establish that the war or gasoline prices caused
> the rebound.

## Managerial recommendations

1. **Avoid a statewide inventory bet based on one quarter.** Treat the sharp
   increase in search interest as a leading indicator and confirm it against
   later registrations before committing broadly.
2. **Prioritize large established EV markets.** Maintain inventory availability
   and use fuel-cost messaging in the 27-county segment where adoption and
   addressable sales volume are already high.
3. **Diagnose barriers in stalled counties.** Investigate affordability,
   charging access, and awareness before adding inventory in the low-adoption
   segment.
4. **Do not overreact to small-market growth rates.** The fast-rebound segment
   has encouraging direction but volatile percentage changes because sales
   denominators are small.
5. **Lead with affordability, not a brand claim.** The survey provides its
   clearest evidence on price; the design cannot cleanly separate brand from
   fuel economy.
6. **Update the evidence monthly and quarterly.** Add new VMT, gasoline-price,
   search-interest, and CEC sales releases, then re-estimate the benchmark once
   more post-war quarters exist.

## Required caveat

There is only one complete post-war sales quarter. No regression using the
current statewide quarterly series can credibly separate the war from federal
tax-credit expiration, seasonal purchase timing, interest rates, vehicle
prices, and manufacturer incentives.

## Source-definition note

The California Energy Commission defines `Out of State` as vehicles registered
in California with a mailing address in another state:

https://www.energy.ca.gov/data-reports/energy-almanac/zero-emission-vehicle-and-infrastructure-statistics-collection/new-zev
