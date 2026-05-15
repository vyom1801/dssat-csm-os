# Guide: Extracting 32-Year Dataset from CSV

This document provides instructions on how to extract each and every parameter from the `precision_dataset_Aller2018.csv` file for a full 32-year simulation sequence.

## 1. Dataset Structure

The file `unit_tests/paper_data/precision_dataset_Aller2018.csv` contains data organized by treatment and year.
- Each treatment (e.g., `Ha_B22_N75`) has **32 consecutive rows**, representing years **1985 to 2016**.
- You must extract the data for ALL 32 years to run a proper sequence analysis.
- **Note**: For a specific treatment, the biochar properties and initial soil conditions are constant across all 32 years in the CSV. Only the `Year` and `Study_Year` columns change.

### Key Cases to Extract
To perform full validation as per study details, you should extract data for the following 3 cases:
1. **Hardwood Biochar**: Look for treatments starting with `Ha_` (e.g., `Ha_B22_N75`).
2. **Corn Stover Biochar**: Look for treatments starting with `Co_` (e.g., `Co_B22_N75`).
3. **No Biochar (Control)**: Look for treatments with `B0` (e.g., `Ha_B0_N75` or `Co_B0_N75`).

## 2. Parameters to Extract

For each year of the treatment, extract the following parameters from the columns:

| Column Header | Parameter | Description |
| --- | --- | --- |
| `Treatment_ID` | Treatment ID | e.g., `Ha_B22_N75` |
| `Year` | Calendar Year | 1985 to 2016 |
| `Study_Year` | Year of Study | 1 to 32 |
| `Biochar_Feedstock` | Feedstock | Hardwood or Corn Stover |
| `Biochar_Rate_tha_Dry`| Application Rate | Amount applied in t/ha (e.g., 21.728) |
| `N_Fertilizer_kgha` | N Rate | Nitrogen applied in kg/ha |
| `BC_Carbon_pct` | Carbon % | Biochar carbon percentage |
| `BC_CN_Ratio` | C:N Ratio | Biochar C:N ratio |
| `BC_pH` | Biochar pH | pH of the biochar |
| `Soil_Initial_pH` | Initial Soil pH | Soil pH at start (usually 6.5) |
| `Soil_Initial_BD` | Initial Soil BD | Soil Bulk Density (usually 1.35) |

## 3. Extraction Format Example (JSON)

Since the parameters are constant across all 32 years for a given treatment, there is no need to repeat them for each year. Structure the JSON to capture the **Runs** (groups of 3 scenarios) with their constant properties.

```json
{
  "runs": {
    "run1_N75_B22": {
      "N_rate": 75,
      "biochar_rate_Mg_ha": 22,
      "scenarios": {
        "control": {
          "treatment_id": "Ha_B0_N75",
          "biochar": {
            "amount": 0.0,
            "FCarbon": 0.0,
            "CN_BC": 0.0,
            "UpH": 0.0
          }
        },
        "hardwood": {
          "treatment_id": "Ha_B22_N75",
          "biochar": {
            "amount": 21728.0,
            "FCarbon": 0.743,
            "CN_BC": 148.0,
            "UpH": 9.1
          }
        },
        "corn_stover": {
          "treatment_id": "Co_B22_N75",
          "biochar": {
            "amount": 21728.0,
            "FCarbon": 0.62,
            "CN_BC": 45.0,
            "UpH": 9.8
          }
        }
      }
    }
    // ... you can add run2, run3 etc. ...
  }
}
```

## 4. Usage in DSSAT

These extracted values should be used to populate the Treatment file (`.MZX`) and the Biochar input file (`BIOCHAR.INP`) for the sequence run.

## 5. Suggested Workflow for Comparative Simulation

To properly validate the hypotheses, it is recommended to group your extractions and simulations by **Treatment_ID** to compare the three key cases under constant Nitrogen levels.

### Steps:
1.  **Select a specific Nitrogen rate** (e.g., `N75`) and **Biochar rate** (e.g., `B22`).
2.  **Extract by Treatment_ID**:
    *   Find all 32 rows for `Ha_B22_N75` (Hardwood) and extract parameters.
    *   Find all 32 rows for `Co_B22_N75` (Corn Stover) and extract parameters.
    *   Find all 32 rows for `Ha_B0_N75` (or `Co_B0_N75` for Control) and extract parameters.
    *   **Format**: Extract the parameters for each of the 32 years for all 3 scenarios as per the JSON format shown in **Section 3**.

3.  **Run Simulations**: Run DSSAT for each of these 3 extracted sequences.
4.  **Compare Results**: Compare the outputs to see the effect of biochar type vs control.

## 6. Aligning with Paper Runs

To replicate the study's findings, focus on extracting treatments that match the factorial design mentioned in the paper:
- **Biochar Types**: Hardwood (`Ha_`) and Corn Stover (`Co_`).
- **Biochar Rates**: 0, 22, 44, and 89 Mg/ha (look for `B0`, `B22`, `B44`, `B89` in `Treatment_ID`).
- **Nitrogen Rates**: 75, 150, and 225 kg N/ha (look for `N75`, `N150`, `N225` in `Treatment_ID`).

By extracting these specific combinations, you can recreate the comparison matrices to validate the full paper findings.


