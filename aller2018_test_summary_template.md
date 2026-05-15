# Test Summary Template: Aller 2018 Validation

Use this template to record the results of your 32-year sequence simulations and verify if they ran according to the study details and hypotheses.

## 1. Simulation Metadata
- **Run Date**: [Insert Date]
- **Treatment Tested**: [e.g., `Ha_B22_N75` or `Co_B22_N75`]
- **Simulation Period**: 1985 – 2016 (32 Years)
- **Weather File Used**: [e.g., `UFGA1201.WTH`]

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

## 3. Hypothesis Verification Checklist

Record your observations from the output files (`SoilWat.OUT`, `PlantGro.OUT`, `BIOCHAR.OUT`) and compare them with the study details.

Observations from output files (`Summary.OUT`, `BIOCHAR.OUT`, `PlantGro.OUT`).
*   **Key Columns to Check**: `NSTD` (N stress), `WSPD`/`WSGD` (Water stress), `HWAM` (Yield), `NLCM` (Leaching), `BC_Recalc` (Carbon).

| Phase / Hypothesis | Expected Behavior | Control Obs. | Hardwood Obs. | Corn Stover Obs. | Status |
| --- | --- | --- | --- | --- | --- |
| **Chemical Phase (Years 1-5)** | **Corn Stover** should show better N-availability. | | | | |
| **Nitrogen Immobilization** | **Hardwood** should show N-immobilization in year 1. | | | | |
| **Physical Phase (Years 6-32)** | Biochar should show lower water stress. | | | | |
| **Yield Stabilization** | Yield impact small (-2.6% to +0.6%). | | | | |
| **Nitrate Mitigation** | Reduced nitrate leaching (2.5 - 20%). | | | | |
| **SOC Increase** | Soil Organic Carbon levels should increase. | | | | |

## 4. Soil Property Verification

Verify that the initial soil conditions were set correctly as per instructions:

| Parameter | Target Value | Observed in Output/File | Status |
| --- | --- | --- | --- |
| Layering | 0-5, 5-15, 15-30 cm | | |
| SLOC (Top Layers) | 2.55% | | |
| SBD | 1.35 g/cm³ | | |
| Initial pH | 6.5 | | |
| Texture | Fine-loamy (Clay: 22%, Silt: 34%, Sand: 44%) | | |
| DUL Increase | +0.02 - 0.03 vs Control | | |

## 5. Biochar Property Verification

Verify that the biochar properties used in the simulation match the values extracted from the paper/CSV:

| Parameter | Target Value (Hardwood / Corn Stover) | Observed in Output/File | Status |
| --- | --- | --- | --- |
| **Application Date** | 1985130 (or as per CSV) | | |
| **Application Amount**| ~22,400 kg/ha (or specific CSV rate) | | |
| **Incorporation Depth**| 20 cm | | |
| **Carbon Content** | 74.3% (Ha, CSV) / 62% (Co, CSV) | | |
| **C:N Ratio** | 148 (Ha, CSV) / 45 (Co, CSV) | | |
| **Labile Fraction** | 0.1 | | |


## 5. Conclusion
Summarize whether the test successfully validated the paper's hypotheses or if further calibration is needed.

