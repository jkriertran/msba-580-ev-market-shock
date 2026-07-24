# Methodology

## Analytical question

The app examines whether California EV demand appeared to rebound after fuel
pressure increased in early 2026, despite the expiration of the federal EV tax
credit in September 2025.

The evidence is descriptive. Event markers organize time; they do not identify
causal effects.

## Outcome definitions

- **ZEV sales:** New light-duty battery-electric, plug-in-hybrid, and
  hydrogen-fuel-cell vehicles.
- **ZEV share:** ZEV sales divided by all new light-duty vehicle sales.
- **VMT:** Estimated vehicle-miles traveled on all California roads and streets.
- **VMT year-over-year change:** Monthly VMT relative to the same month one year
  earlier. This comparison reduces ordinary seasonal effects.

## Context-chart transformation

For a selected comparison quarter, each context series is converted to:

`index = 100 × observed value / comparison-quarter value`

Every series therefore equals 100 in the selected quarter. A value of 120 means
the series is 20% above its comparison-quarter value; a value of 80 means it is
20% below.

## Analytical techniques

### Pre-event regression benchmark

The theory-specified benchmark fits ZEV share to a linear time index and
calendar-quarter indicators using 2023 Q1 through 2025 Q2. Later observations
are compared with its 95% prediction interval. Mean-only, time-only,
seasonal-only, and time-plus-season models are also compared using AICc and
leave-one-out RMSE.

The pipeline reports conventional and HC1 robust coefficient uncertainty,
Shapiro-Wilk residual normality, an approximate Durbin-Watson statistic, Cook's
distance, and leave-one-out error. These diagnostics expose weaknesses; they
cannot make a 10-quarter training sample causal.

### County market segmentation

K-means clustering uses three standardized features: 2025 Q4 ZEV share, the
percentage-point change through 2026 Q2, and log average quarterly light-duty
sales. Two through six clusters are compared using mean silhouette width. The
three-cluster solution is selected for parsimony and managerial interpretation;
its silhouette near 0.34 is effectively tied with the maximum candidate value.

The resulting segments are descriptive archetypes. They should not be treated
as sharply separated, permanent, or causal county categories.

## Principal limitations

- The time series is short and includes few post-war observations.
- The federal tax-credit expiration, vehicle prices, interest rates,
  manufacturer incentives, and other events overlap in time.
- Google Trends measures normalized relative interest rather than search volume.
- May 2026 VMT is preliminary, and June 2026 was unavailable for this draft.
- Associations displayed by the app should not be described as causal effects.
