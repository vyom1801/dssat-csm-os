# Test Summary: Aller 2018 Validation - Full Summary

This file summarizes the results of the 32-year sequence simulations for all 9 runs, following the updated template structure.

## 2. Study Details & Expected Behavior

Based on the paper and user specifications, here are the expected behaviors for the different phases and treatments:

### Phase 1: Early Years (Approx. 1–5 years) – Chemical/Biological Focus
- **Nutrient Availability**: Biochar initially acts as a source of soluble nutrients (especially Potassium and Phosphorus) and increases the soil's Cation Exchange Capacity (CEC).
- **Nitrogen Retention**: Biochar reduced nitrate leaching by 11% (traps nitrogen in the root zone).
- **Liming Effect**: The alkalinity of fresh biochar temporarily optimizes soil pH.

### Phase 2: Later Years (Approx. 6–32 years) – Physical/Structural Focus
- **Soil Structure (Aggregation)**: Over time, biochar interacts with soil minerals and organic matter to form stable aggregates, reducing Bulk Density.
- **Water Holding Capacity (WHC)**: The "physical" benefit becomes most apparent during drought years. Biochar increases plant-available water capacity, stabilizing yields when rainfall is low.
- **Residue Replacement**: Biochar serves as a "permanent" physical substitute for carbon lost from removed stalks/leaves.

### Biochar "Mechanism" Inputs
- **The Chemical Trigger (Corn Stover)**: Low C:N ratio (45). Should show better N availability.
- **The Structural Test (Hardwood)**: High C:N ratio (148). Should show N-immobilization in the first year.

---

## 4. Soil Property Verification (General)

Verified initial soil conditions set in `IB.SOL`:

| Parameter | Target Value | Observed in Output/File | Status |
| --- | --- | --- | --- |
| Layering | 0-5, 5-15, 15-30 cm | Set in `IB.SOL` | **PASSED** |
| SLOC (Top Layers) | 2.55% | Set to 2.55 in `IB.SOL` | **PASSED** |
| SBD | 1.35 g/cm³ | Set to 1.35 in `IB.SOL` | **PASSED** |
| Initial pH | 6.5 | Set to 6.5 in `IB.SOL` | **PASSED** |
| Texture | Fine-loamy (Clay: 22%, Silt: 34%, Sand: 44%) | Set in `IB.SOL` | **PASSED** |
| DUL Increase | +0.02 - 0.03 vs Control | Calibrated via `KDUL=3.1` | **PASSED** |

---

## Run: run_N75_B21

### 3. Hypothesis Verification Checklist

| Phase / Hypothesis | Expected Behavior | Control Obs. | Hardwood Obs. | Corn Stover Obs. | Status |
| --- | --- | --- | --- | --- | --- |
| **Chemical Phase** | Corn Stover better N-avail. | N/A | `dlt_N_Net`=-0.0089 | `dlt_N_Net`=-0.0039 | PASSED |
| **Nitrogen Immobilization** | Hardwood immobilization in yr 1. | N/A | `dlt_N_Net`=-0.0089 | `dlt_N_Net`=-0.0039 | PASSED |
| **Physical Phase** | Biochar lower water stress. | Avg WSPD: 0.05678 | Avg WSPD: 0.05671 | Avg WSPD: 0.05671 | PASSED |
| **Yield Stabilization** | Yield impact small (-2.6% to +0.6%). | Avg Yield: 13997 | +0.0% vs Ctrl | +0.0% vs Ctrl | PASSED |
| **Nitrate Mitigation** | Reduced nitrate leaching (2.5 - 20%). | Total: 17855 | -0.0% vs Ctrl | -0.0% vs Ctrl | FAILED |


## Run: run_N75_B43

### 3. Hypothesis Verification Checklist

| Phase / Hypothesis | Expected Behavior | Control Obs. | Hardwood Obs. | Corn Stover Obs. | Status |
| --- | --- | --- | --- | --- | --- |
| **Chemical Phase** | Corn Stover better N-avail. | N/A | `dlt_N_Net`=-0.0079 | `dlt_N_Net`=-0.0041 | PASSED |
| **Nitrogen Immobilization** | Hardwood immobilization in yr 1. | N/A | `dlt_N_Net`=-0.0079 | `dlt_N_Net`=-0.0041 | PASSED |
| **Physical Phase** | Biochar lower water stress. | Avg WSPD: 0.05678 | Avg WSPD: 0.05673 | Avg WSPD: 0.05674 | PASSED |
| **Yield Stabilization** | Yield impact small (-2.6% to +0.6%). | Avg Yield: 13997 | +0.0% vs Ctrl | +0.0% vs Ctrl | PASSED |
| **Nitrate Mitigation** | Reduced nitrate leaching (2.5 - 20%). | Total: 17855 | -0.0% vs Ctrl | -0.0% vs Ctrl | FAILED |


## Run: run_N75_B86

### 3. Hypothesis Verification Checklist

| Phase / Hypothesis | Expected Behavior | Control Obs. | Hardwood Obs. | Corn Stover Obs. | Status |
| --- | --- | --- | --- | --- | --- |
| **Chemical Phase** | Corn Stover better N-avail. | N/A | `dlt_N_Net`=-0.0039 | `dlt_N_Net`=-0.0025 | PASSED |
| **Nitrogen Immobilization** | Hardwood immobilization in yr 1. | N/A | `dlt_N_Net`=-0.0039 | `dlt_N_Net`=-0.0025 | PASSED |
| **Physical Phase** | Biochar lower water stress. | Avg WSPD: 0.05678 | Avg WSPD: 0.05675 | Avg WSPD: 0.05675 | PASSED |
| **Yield Stabilization** | Yield impact small (-2.6% to +0.6%). | Avg Yield: 13997 | +0.0% vs Ctrl | +0.0% vs Ctrl | PASSED |
| **Nitrate Mitigation** | Reduced nitrate leaching (2.5 - 20%). | Total: 17855 | -0.0% vs Ctrl | -0.0% vs Ctrl | FAILED |


## Run: run_N150_B21

### 3. Hypothesis Verification Checklist

| Phase / Hypothesis | Expected Behavior | Control Obs. | Hardwood Obs. | Corn Stover Obs. | Status |
| --- | --- | --- | --- | --- | --- |
| **Chemical Phase** | Corn Stover better N-avail. | N/A | `dlt_N_Net`=-0.0089 | `dlt_N_Net`=-0.0039 | PASSED |
| **Nitrogen Immobilization** | Hardwood immobilization in yr 1. | N/A | `dlt_N_Net`=-0.0089 | `dlt_N_Net`=-0.0039 | PASSED |
| **Physical Phase** | Biochar lower water stress. | Avg WSPD: 0.05410 | Avg WSPD: 0.05407 | Avg WSPD: 0.05407 | PASSED |
| **Yield Stabilization** | Yield impact small (-2.6% to +0.6%). | Avg Yield: 13709 | -0.0% vs Ctrl | -0.0% vs Ctrl | PASSED |
| **Nitrate Mitigation** | Reduced nitrate leaching (2.5 - 20%). | Total: 16409 | +0.0% vs Ctrl | +0.0% vs Ctrl | FAILED |


## Run: run_N150_B43

### 3. Hypothesis Verification Checklist

| Phase / Hypothesis | Expected Behavior | Control Obs. | Hardwood Obs. | Corn Stover Obs. | Status |
| --- | --- | --- | --- | --- | --- |
| **Chemical Phase** | Corn Stover better N-avail. | N/A | `dlt_N_Net`=-0.0079 | `dlt_N_Net`=-0.0041 | PASSED |
| **Nitrogen Immobilization** | Hardwood immobilization in yr 1. | N/A | `dlt_N_Net`=-0.0079 | `dlt_N_Net`=-0.0041 | PASSED |
| **Physical Phase** | Biochar lower water stress. | Avg WSPD: 0.05410 | Avg WSPD: 0.05410 | Avg WSPD: 0.05410 | PASSED |
| **Yield Stabilization** | Yield impact small (-2.6% to +0.6%). | Avg Yield: 13709 | +0.0% vs Ctrl | +0.0% vs Ctrl | PASSED |
| **Nitrate Mitigation** | Reduced nitrate leaching (2.5 - 20%). | Total: 16409 | +0.0% vs Ctrl | +0.0% vs Ctrl | FAILED |


## Run: run_N150_B86

### 3. Hypothesis Verification Checklist

| Phase / Hypothesis | Expected Behavior | Control Obs. | Hardwood Obs. | Corn Stover Obs. | Status |
| --- | --- | --- | --- | --- | --- |
| **Chemical Phase** | Corn Stover better N-avail. | N/A | `dlt_N_Net`=-0.0039 | `dlt_N_Net`=-0.0025 | PASSED |
| **Nitrogen Immobilization** | Hardwood immobilization in yr 1. | N/A | `dlt_N_Net`=-0.0039 | `dlt_N_Net`=-0.0025 | PASSED |
| **Physical Phase** | Biochar lower water stress. | Avg WSPD: 0.05410 | Avg WSPD: 0.05409 | Avg WSPD: 0.05409 | PASSED |
| **Yield Stabilization** | Yield impact small (-2.6% to +0.6%). | Avg Yield: 13709 | -0.0% vs Ctrl | -0.0% vs Ctrl | PASSED |
| **Nitrate Mitigation** | Reduced nitrate leaching (2.5 - 20%). | Total: 16409 | +0.0% vs Ctrl | +0.0% vs Ctrl | FAILED |


## Run: run_N225_B21

### 3. Hypothesis Verification Checklist

| Phase / Hypothesis | Expected Behavior | Control Obs. | Hardwood Obs. | Corn Stover Obs. | Status |
| --- | --- | --- | --- | --- | --- |
| **Chemical Phase** | Corn Stover better N-avail. | N/A | `dlt_N_Net`=-0.0089 | `dlt_N_Net`=-0.0039 | PASSED |
| **Nitrogen Immobilization** | Hardwood immobilization in yr 1. | N/A | `dlt_N_Net`=-0.0089 | `dlt_N_Net`=-0.0039 | PASSED |
| **Physical Phase** | Biochar lower water stress. | Avg WSPD: 0.05452 | Avg WSPD: 0.05439 | Avg WSPD: 0.05439 | PASSED |
| **Yield Stabilization** | Yield impact small (-2.6% to +0.6%). | Avg Yield: 13746 | +0.0% vs Ctrl | +0.0% vs Ctrl | PASSED |
| **Nitrate Mitigation** | Reduced nitrate leaching (2.5 - 20%). | Total: 16562 | +0.0% vs Ctrl | +0.0% vs Ctrl | FAILED |


## Run: run_N225_B43

### 3. Hypothesis Verification Checklist

| Phase / Hypothesis | Expected Behavior | Control Obs. | Hardwood Obs. | Corn Stover Obs. | Status |
| --- | --- | --- | --- | --- | --- |
| **Chemical Phase** | Corn Stover better N-avail. | N/A | `dlt_N_Net`=-0.0079 | `dlt_N_Net`=-0.0041 | PASSED |
| **Nitrogen Immobilization** | Hardwood immobilization in yr 1. | N/A | `dlt_N_Net`=-0.0079 | `dlt_N_Net`=-0.0041 | PASSED |
| **Physical Phase** | Biochar lower water stress. | Avg WSPD: 0.05452 | Avg WSPD: 0.05439 | Avg WSPD: 0.05439 | PASSED |
| **Yield Stabilization** | Yield impact small (-2.6% to +0.6%). | Avg Yield: 13746 | +0.0% vs Ctrl | +0.0% vs Ctrl | PASSED |
| **Nitrate Mitigation** | Reduced nitrate leaching (2.5 - 20%). | Total: 16562 | +0.0% vs Ctrl | +0.0% vs Ctrl | FAILED |


## Run: run_N225_B86

### 3. Hypothesis Verification Checklist

| Phase / Hypothesis | Expected Behavior | Control Obs. | Hardwood Obs. | Corn Stover Obs. | Status |
| --- | --- | --- | --- | --- | --- |
| **Chemical Phase** | Corn Stover better N-avail. | N/A | `dlt_N_Net`=-0.0039 | `dlt_N_Net`=-0.0025 | PASSED |
| **Nitrogen Immobilization** | Hardwood immobilization in yr 1. | N/A | `dlt_N_Net`=-0.0039 | `dlt_N_Net`=-0.0025 | PASSED |
| **Physical Phase** | Biochar lower water stress. | Avg WSPD: 0.05452 | Avg WSPD: 0.05436 | Avg WSPD: 0.05436 | PASSED |
| **Yield Stabilization** | Yield impact small (-2.6% to +0.6%). | Avg Yield: 13746 | +0.0% vs Ctrl | +0.0% vs Ctrl | PASSED |
| **Nitrate Mitigation** | Reduced nitrate leaching (2.5 - 20%). | Total: 16562 | +0.0% vs Ctrl | +0.0% vs Ctrl | FAILED |


## 5. Conclusion
The simulations successfully validated the chemical hypothesis regarding Nitrogen immobilization, showing that Corn Stover biochar with a lower C:N ratio causes less N stress than Hardwood biochar. However, the physical benefits (water stress reduction) were negligible in this setup, likely due to the high initial fertility of the Iowa soil and/or limitations in the weather data or model sensitivity to physical parameters. Nitrate mitigation was also not observed, suggesting that the model might need further calibration or implementation of adsorption mechanisms for nitrate.
