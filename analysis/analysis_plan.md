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
- Respondent-choice task for the future conjoint analysis.

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

### 3. County heterogeneity

Compare county ZEV share in 2025 Q4 and 2026 Q2. Exclude the `Out Of State`
category and flag small markets because percentage-point changes can be
unstable when sales counts are low.

Do not treat the 58 counties as 58 independent observations of the statewide
shock. They share the same policy and gasoline-price environment.

The official CEC statewide total includes an `Out Of State` regional category:
vehicles registered in California with a mailing address in another state.
Keep the published CEC statewide measure as the primary result, but report a
sensitivity analysis restricted to the 58 California county mailing-address
categories.

### 4. VMT behavior response

Use monthly year-over-year VMT changes to reduce normal seasonal variation.
Summarize March through May 2026 and compare that window with March through May
2025.

The current VMT evidence is incomplete: May 2026 is preliminary and June 2026
is unavailable.

## Future conjoint analysis

Once the survey data are available, reshape each choice task to one row per
alternative and estimate a conditional logit model. Candidate attributes
include purchase price, fuel cost, driving range, charging time, powertrain,
and tax-credit availability.

Report:

- Attribute-level utilities and uncertainty.
- Relative attribute importance.
- Willingness-to-pay estimates when a continuous price attribute is available.
- Predicted choice shares for policy and gasoline-price scenarios.
- Respondent-segment results only when sample sizes are adequate.

The conjoint analysis will address preferences and tradeoffs; the market data
will address observed timing and behavior. They should not be pooled into a
single causal model.

## Decision rule

The conclusion will emphasize effect size, direction, consistency across data
sources, and uncertainty. Statistical significance alone will not determine
whether the evidence is meaningful.
