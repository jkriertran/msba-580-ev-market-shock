# Washington Controls and Gas-Price Model

## Goal
Add reproducible Washington-specific controls and a separately labeled gas-price association model without overstating causality.

## Tasks
- [x] Extend the Washington pull script with monthly unemployment and electricity-price snapshots plus documented policy dates. Verify consecutive dates and source metadata.
- [x] Add Washington monthly VMT as a separate behavioral series. Verify that it is not used as a control in the ZEV-share model.
- [x] Create lagged gas and operating-cost features. Verify that every predictor precedes or coincides defensibly with title processing.
- [x] Compare the benchmark against parsimonious gas-price candidates using the existing rolling window. Verify improvement with RMSE and MAE, not in-sample fit alone.
- [x] Fit the selected association model with Newey–West uncertainty and incentive-rolloff controls. Verify coefficient stability and label it non-causal.
- [x] Add the model, data definitions, and limitations to the app and project documentation.

## Done When
- [x] The pipeline runs from source pulls through analysis outputs.
- [ ] Project validation passes and the app loads the new labeled model.
- [ ] The branch is committed and pushed to the existing pull request.

## Notes
Washington's state sales-tax exemption ended July 31, 2025, close to the federal credit expiration. The main event label should therefore describe a combined incentive rolloff unless the data can distinguish the policies.
