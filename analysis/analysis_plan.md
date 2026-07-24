# Final-Project Analysis Plan

## Primary research question

Did California's ZEV market show evidence of a demand rebound as gasoline
prices increased in early 2026, and was that rebound large enough to offset the
decline following the September 2025 federal tax-credit expiration?

This is an observational study. The analysis estimates descriptive changes and
benchmarks, not a causal effect of the Iran war.

## Units of analysis

- State-quarter for ZEV sales, market share, gasoline prices, economic controls,
  and Google Trends.
- County-quarter for geographic heterogeneity in ZEV share.
- State-month for vehicle-miles traveled.
- Respondent-profile rating for the conjoint analysis.

## Testable hypotheses

1. **Credit-rolloff decline:** ZEV share fell after the 2025 Q3 purchase
   pull-forward and federal credit expiration.
2. **Fuel-pressure rebound:** ZEV share, gasoline prices, and EV search interest
   rose between the post-credit/pre-war quarter and the first complete post-war
   quarter.
3. **Driving response:** California VMT fell relative to the same months one
   year earlier after the war began.
4. **Geographic heterogeneity:** County changes were not uniform and differed
   between large and small vehicle markets.

## Primary analyses

### 1. Event contrasts

Report both percentage-point and relative-percent changes:

- 2025 Q3 to 2025 Q4: purchase pull-forward to post-credit quarter.
- 2025 Q4 to 2026 Q1: post-credit/pre-war to transition quarter.
- 2026 Q1 to 2026 Q2: transition to first complete post-war quarter.
- 2025 Q4 to 2026 Q2: net change across the fuel-pressure period.

The primary outcome is ZEV share rather than sales volume because total
light-duty sales vary substantially across quarters.

### 2. Seasonal pre-event benchmark

Fit a simple linear time trend plus calendar-quarter indicators using 2023 Q1
through 2025 Q2. Compare later observations with the model's prediction
interval.

This model is a descriptive benchmark only. It has five residual degrees of
freedom and cannot isolate the war, tax policy, prices, interest rates, and
manufacturer incentives.

### 3. County heterogeneity and market segmentation

Compare county ZEV share in 2025 Q4 and 2026 Q2. Exclude the `Out Of State`
category and flag small markets because percentage-point changes can be
unstable when sales counts are low.

Use standardized baseline ZEV share, percentage-point change, and log average
quarterly light-duty sales in a k-means segmentation. Compare two through six
clusters using mean silhouette width. Select three clusters because it provides
a parsimonious and managerially interpretable solution with fit effectively
tied with the best candidate. Treat the segments as descriptive market
archetypes, not natural or permanent county types.

Do not treat the 58 counties as 58 independent observations of the statewide
shock. They share the same policy and gasoline-price environment.

The official CEC statewide total includes an `Out Of State` regional category:
vehicles registered in California with a mailing address in another state.
Keep the published CEC statewide measure as the primary result, but report a
sensitivity analysis restricted to the 58 California county mailing-address
categories.

### Regression validation and robustness

Compare mean-only, time-only, seasonal-only, and time-plus-season benchmark
models using AICc and leave-one-out RMSE. For the selected benchmark, report
conventional and HC1 heteroskedasticity-robust standard errors, residual
normality, an approximate Durbin-Watson statistic, Cook's distance, and
leave-one-out error.

These diagnostics are warnings rather than proof of model validity. With only
10 pre-event quarters and five residual degrees of freedom, the benchmark
cannot support strong hypothesis tests or causal attribution.

### 4. VMT behavior response

Use monthly year-over-year VMT changes to reduce normal seasonal variation.
Summarize March through May 2026 and compare that window with March through May
2025.

The current VMT evidence is incomplete: May 2026 is preliminary and June 2026
is unavailable.

## 5. Rating-based conjoint analysis

The survey displays seven profiles per SurveyID and asks respondents to rate
each profile from 1 (best) to 5 (worst); ties are permitted. Convert ratings to
`6 - rating` so higher scores indicate stronger preference. Estimate an OLS
part-worth model using effect coding for brand, fuel economy, and price,
respondent fixed effects, and respondent-clustered CR1 standard errors.

Report attribute utilities with 95% intervals, cluster-robust joint tests, and
pairwise level contrasts. Treat relative-importance estimates as exploratory.
The design pairs Tesla almost exclusively with 110 MPGe, so brand and fuel
economy are confounded and cannot be cleanly interpreted separately. Do not
calculate willingness to pay or scenario choice shares from this design.

The conjoint analysis addresses stated preferences; the market data address
observed timing and behavior. They are complementary and are not pooled into a
single causal model.

## Decision rule

The conclusion will emphasize effect size, direction, consistency across data
sources, and uncertainty. Statistical significance alone will not determine
whether the evidence is meaningful.
