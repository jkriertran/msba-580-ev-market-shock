# Capstone Presentation Outline

Target length: 12 minutes, followed by 3 minutes of questions. Assign at least
one speaking section and one anticipated question to every group member.

## 1. Business decision and answer — 1:00

- Decision-maker: California EV manufacturers, dealers, and marketing managers.
- Question: Did early-2026 fuel pressure produce a durable EV-demand rebound
  after the federal tax-credit expiration?
- Lead with the answer: the share recovered from its Q1 low but was only 0.19
  percentage points above the immediate post-credit baseline.

## 2. Data and definitions — 1:30

- Define new light-duty ZEV sales and distinguish them from all light-duty
  sales.
- Introduce CEC sales, EIA gasoline prices, Google Trends, economic controls,
  and FHWA/state-reported VMT.
- Introduce the anonymous conjoint survey: 18 rated respondents and 123 profile
  ratings.
- Explain the official statewide `Out Of State` mailing-address category.

## 3. Live Shiny demonstration — 2:00

1. Change the comparison quarter and explain why the indexed lines all equal
   100 in that selected quarter.
2. Hover over the Plotly timeline and context points.
3. Toggle policy and war markers.
4. Compare statewide and county ZEV share.
5. Show the year-over-year VMT response.
6. Filter the conjoint utilities to Price and hover over the confidence
   intervals.

## 4. Technique 1: event sequence and benchmark — 2:00

- Show the 2025 Q3 pull-forward, post-credit decline, 2026 Q1 low, and Q2
  rebound.
- Explain the pre-event time-plus-season regression benchmark.
- Report the 3.38-percentage-point 2026 Q2 shortfall and wide prediction
  interval.
- State the diagnostics: 10 training quarters, five residual degrees of
  freedom, one influential observation, and no model-selection advantage for
  the richer specification.

## 5. Technique 2: county segmentation — 1:45

- Show the baseline-share versus change scatterplot.
- Describe the three segments:
  - large established EV markets;
  - low-adoption/stalled markets;
  - small-market/fast-rebound markets.
- Explain that silhouette width near 0.34 means the segments are useful
  summaries, not sharply separated natural groups.

## 6. Behavioral response — 1:00

- March through May 2026 VMT changes were +3.5%, -0.8%, and -0.1%.
- Conclude that current evidence does not show a large, sustained reduction in
  driving.
- Flag preliminary May data and unavailable June data.

## 7. Technique 3: stated preferences — 1:00

- Explain that this is a rating-based part-worth model with respondent fixed
  effects and respondent-clustered uncertainty.
- Price was the clearest attribute (p = 0.013); $30,000 scored 1.30 preference
  points above $120,000 (p = 0.005).
- State the design limitation plainly: Tesla and 110 MPGe are confounded, so
  brand and fuel economy cannot be cleanly separated.

## 8. Recommendations — 1:00

- Maintain inventory and conversion campaigns in established high-volume
  markets.
- Diagnose charging, affordability, and awareness barriers in stalled markets.
- Use light-touch campaigns in fast-growing small markets and avoid reacting to
  volatile rates.
- Lead with affordability and ownership cost; do not make a brand-specific
  claim from this survey.
- Continue monthly leading-indicator tracking before making a statewide bet.

## 9. Limitations, next step, and close — 1:15

- Do not claim the war caused the rebound.
- Name the overlapping tax, price, interest-rate, manufacturer-incentive, and
  seasonal effects.
- Explain the conjoint sample-size, missing-rating, and attribute-confounding
  limitations.
- Close by restating the decision answer in one sentence.

## Q&A preparation — 3:00

Prepare concise responses to:

1. Why use share instead of sales counts?
2. Why is 2025 Q4 the main comparison?
3. Why is the regression not causal?
4. Why choose three clusters when five has a marginally higher silhouette?
5. Does rising search interest represent actual demand?
6. Why is this rating-based model not a conditional logit?
7. Why did you avoid willingness-to-pay and simulated-choice claims?
