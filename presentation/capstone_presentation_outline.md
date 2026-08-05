# Washington Capstone Presentation Outline

Target: 12 minutes plus 3 minutes of questions. Assign every group member at
least one speaking section and one anticipated question.

## 1. Decision and answer — 1:00

- Question: Did higher gasoline prices revive Washington ZEV demand after the
  federal credit expired?
- Answer: title share increased only 0.56 points; the additional modeled
  post-war change is not statistically distinct.

## 2. Data and definitions — 1:30

- Explain original titles versus dealer sales.
- Show why both `Original Title` and `New` filters are required.
- Define light-duty and ZEV filters.
- Introduce 114 Washington months, EIA gasoline prices, California comparison,
  and the conjoint survey.

## 3. Shiny demonstration — 2:00

1. Change the timeline from 2021 to the full 2017 history.
2. Switch ZEV share to gasoline price.
3. Select King, Pierce, or Clark County.
4. Hover over the regression benchmark.
5. Filter conjoint utilities to Price.

## 4. Technique 1: regression benchmark — 2:00

- Compare seasonal-only, linear, and quadratic models.
- Explain 42 rolling one-month-ahead validations.
- Report selected RMSE: 3.66 percentage points.
- Show observed post-war share of 14.5% versus expected 25.7%.

## 5. Technique 2: interrupted time series — 1:30

- Post-credit coefficient: −11.59 points, p < 0.001.
- Additional post-war coefficient: +1.15 points, p = 0.285.
- Explain Newey–West uncertainty and why the model is not causal.

## 6. County and California evidence — 1:15

- 32 of 39 counties increased; median change +3.34 points.
- Highlight Pierce, Snohomish, Clark, and King.
- Use California only as a directional quarterly comparison.

## 7. Technique 3: conjoint — 1:00

- 18 rated respondents and 123 profile ratings.
- Price was clearest: $30,000 versus $120,000 difference = 1.30 points.
- Explain brand–fuel-economy confounding.

## 8. Recommendations and close — 1:45

- Avoid a statewide inventory bet.
- Lead with affordability and total cost.
- Target large counties with positive movement.
- Update the model as later DOL months arrive.
- Close: fuel pressure raised attention, but current title data do not show a
  distinct statewide recovery.

## Q&A preparation

1. Why are titles not the same as sales?
2. Why does the post-credit title period begin in November?
3. Why select a quadratic trend?
4. What does Newey–West correct?
5. Why is Washington now primary and California secondary?
6. Why does a positive coefficient not prove the war caused the change?
7. Why are conjoint brand and fuel-economy results confounded?
