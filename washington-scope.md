# Washington-Based Project Scope

## Goal

Make Washington monthly new light-duty title transactions the primary observed-market outcome, retain California quarterly ZEV sales as a comparison, and keep the conjoint survey as stated-preference evidence.

## Tasks

- [x] Audit the `cdk6-5kdf` schema and define reproducible new/light-duty/ZEV filters → Verified monthly counts, missingness, and coverage.
- [x] Build the Washington monthly pipeline and interrupted-time-series models → Verified rolling validation, robust uncertainty, and saved result tables.
- [x] Refactor the Shiny app around Washington trends and regression evidence → Verified all inputs and the Shiny server with `testServer`.
- [x] Rewrite the report, methodology, findings, README, and presentation → Verified consistent Washington-first language and an 816-word report.
- [x] Run project validation, render the report, push the branch, and update Posit Cloud → Verified local and GitHub checks plus the live Posit app.

## Done When

- [x] No primary conclusion depends on imputed monthly California sales.
- [x] Washington data are observed monthly transactions and labeled as titles rather than dealer sales.
- [x] California appears only as a harmonized quarterly comparison.
- [x] All local reproducibility checks pass.

## Notes

Original Washington titles can include vehicles previously used elsewhere; the primary filter must also require the dataset's new-vehicle classification.
