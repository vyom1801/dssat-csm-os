# Instructions: Running DSSAT for Aller 2018 Study

This document provides detailed instructions on how to set up and run DSSAT simulations to validate the hypotheses from the Aller 2018 study, ensuring all specific conditions are met.

## 1. Set Up Soil Data

Use the following soil data from the "Soil Initial Conditions" in the dataset to configure your soil profile (e.g., in `IB.SOL` or via the DSSAT interface):

- **Layering**: Divide your soil into layers (e.g., 0–5, 5–15, 15–30 cm).
- **SLOC (Organic Carbon)**: Enter `2.55%` for the top layers.
- **SBD (Bulk Density)**: Enter `1.35` g/cm³.
- **Initial pH (SLPH)**: `6.5`.
- **Texture**: Fine-loamy (Clay: `22%`, Silt: `34%`, Sand: `44%`).
- **DUL & LL (Testing the Physical Hypothesis)**: This is the core of your test. For your "Biochar" treatments, manually increase the Drained Upper Limit (DUL) by approximately **0.02–0.03** compared to your "Control" soil. This simulates the increased water-holding capacity mentioned in the paper.

## 2. Set Up Management Events (.MGT / .MZX file)

### Biochar "Mechanism" Inputs

- **The Chemical Trigger (Years 1-5)**: Use the Corn Stover or Hardwood biochar data. Its low C:N ratio (`45`) is the driver for the "nutrient pulse" and reduced N-stress.
- **The Physical Trigger (Years 6-32)**: Use the same biochar data. Its high Surface Area (`315` m²/g) and high C:N ratio (`148`) make it the ideal candidate for modeling structural stability and water retention.

### Treatments Setup

In the DSSAT Management Editor, create two different levels (Treatments):

1.  **The Chemical Phase Test (Corn Stover)**:
    *   Go to the Organic Amendments section.
    *   Input the Application Rate (e.g., `21.728` t/ha or `87.3` t/ha from the Excel).
    *   Set the Nitrogen (N) Content and C:N Ratio (`45`) from the Corn Stover specs.
2.  **The Structural Test (Hardwood)**:
    *   Use the C:N Ratio (`148`). Because this is so high, you can observe if the model shows "Nitrogen Immobilization" (where the biochar temporarily steals nitrogen from the plant) in the first year.

## 3. Running a "Sequence Analysis" (32 Years)

Don't just run a single year. DSSAT allows you to run a Sequence, which is vital for your hypothesis:

- **Timeline**: Use the 32-year timeline provided in the Excel (`1985–2016`).
- **Initial Year**: Biochar is applied.
- **Result Verification**: Export the `SoilWat.OUT` (Soil Water) and `PlantGro.OUT` (Plant Growth) files to analyze the results.

> [!IMPORTANT]
> To fully validate the yield impact and comparative hypotheses, a **Control** run (No Biochar) and a **Corn Stover** run are required along with the **Hardwood** run.

## 4. Configuring `BIOCHAR.INP`

To run different biochar treatments, you must edit the `BIOCHAR.INP` file in the `TestRun` directory to match the specific biochar properties and application rates.

### Key Parameters to Change

For each treatment, update the following values in the application line:

- **AppDate**: The date of application in `YYDOY` format (e.g., `1985001` for Jan 1, 1985).
- **Amount**: The application rate in **kg/ha** (e.g., `21728.0` for 21.728 t/ha).
- **FCarbon**: The carbon fraction of the biochar (e.g., `0.76` for Hardwood or `0.62` for Corn Stover).
- **CN_BC**: The C:N ratio of the biochar (e.g., `148.0` or `232.0` for Hardwood, `45.0` for Corn Stover).

### Reference Values from Paper/CSV

| Biochar Type | Carbon Fraction (`FCarbon`) | C:N Ratio (`CN_BC`) |
| --- | --- | --- |
| **Hardwood** | `0.76` (Paper) / `0.743` (CSV) | `232.0` (Paper) / `148.0` (CSV) |
| **Corn Stover** | `0.62` (CSV) | `45.0` (CSV) |

Example application line for **Hardwood** at **22 Mg/ha**:
```
! AppDate Amount Depth FLoss FCarbon FLabile MRT1 MRT2 CN_BC CEC_INIT BCLV
  1985001 21728.0 20.0  0.0   0.743   0.10    0.5  200.0 148.0 40.0    1.5
```

## 5. How to Run the Simulation

Once you have configured the soil data, management events, and `BIOCHAR.INP`, you can run the simulation using the compiled DSSAT executable.

1.  Navigate to the `TestRun` directory:
    ```bash
    cd /usr/local/google/home/vyoms/Desktop/dssat_sotirios_biochar/TestRun
    ```
2.  Execute the model with the Maize treatment file:
    ```bash
    ./bin/dscsm048 MZCER048 A TEST01MZ.MZX
    ```
    *   `./bin/dscsm048`: The DSSAT executable.
    *   `MZCER048`: The model code for CERES-Maize.
    *   `A`: Run mode (Batch/Single).
    *   `TEST01MZ.MZX`: The experiment file you configured.

## 6. Running All Cases Automatically

To run all 9 runs (27 simulations) defined in the simulation plan automatically and generate the summary, follow these steps:

1.  Navigate to the `TestRun` directory:
    ```bash
    cd /usr/local/google/home/vyoms/Desktop/dssat_sotirios_biochar/TestRun
    ```
2.  Run the simulation script:
    ```bash
    python3 run_aller_simulations.py
    ```
    This script will iterate through all runs and scenarios in `aller2018_simulation_plan.json`, update `BIOCHAR.INP` and `TEST01MZ.MZX` for each case, run the simulation, and save the results to `simulation_results.json`.

3.  Generate the filled template summary:
    ```bash
    python3 generate_summary_markdown.py
    ```
    This will read `simulation_results.json` and update `aller2018_simulation_summary.md` with the filled tables for all runs also do add the conclusion for the same.


