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

## Principal limitations

- The time series is short and includes few post-war observations.
- The federal tax-credit expiration, vehicle prices, interest rates,
  manufacturer incentives, and other events overlap in time.
- Google Trends measures normalized relative interest rather than search volume.
- May 2026 VMT is preliminary, and June 2026 was unavailable for this draft.
- Associations displayed by the app should not be described as causal effects.
