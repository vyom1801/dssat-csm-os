# Biochar Module Test Summary

This file summarizes the results of the hypothesis tests for the Biochar module, based on `hypothesis_tests.md`.

## Passed Tests

| Test Case | Description | Status | Reason / Notes |
| --- | --- | --- | --- |
| 1 | The Nitrogen Cascade & Alkalinity Buffering | **PASSED** | pH increased as expected upon biochar application. |

## Failed Tests

| Test Case | Description | Status | Reason / Notes |
| --- | --- | --- | --- |
| 2 | Aluminium Occupancy & Non-Linear Sorption Recovery | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 3 | npSOM Bridging & Negative Priming | **FAILED** | Placeholder for future development. |
| 4 | Anion Competition & Leaching Vulnerability | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 5 | Dual-Driven Oxidation & Slow-Drip Acidification | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 6 | Plant-Microbe ODE Competition | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 7 | The Precipitation Sink vs. AEC Sorption | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 8 | The pH 5.5 Aluminium Threshold Collapse | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 9 | Moisture-Driven Soluble Ash Pulses | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 10 | Overflow Respiration and Mass Balance | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 11 | Temperature-Driven pKa Shift vs. Sorption | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 12 | Ash Exhaustion and the Buffering Cliff | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 13 | Competitive Langmuir Exhaustion | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 14 | The Immobilization-Weathering Feedback Cascade | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 15 | Pure Thermal Oxidation | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 16 | The Absolute Drought Kinetic Freeze | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 17 | The Transient Immobilization Cliff | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |
| 18 | The Alkaline Volatilization Trap | **FAILED** | Critical failure in current Fortran build (sequential vs simultaneous). |
| 19 | AEC Erosion via Acidification | **FAILED** | Pending implementation. |
| 20 | The Infinite Host Sink Overdraw | **FAILED** | Mechanism not implemented in `Biochar_mod.f90`. |

## How to Run the Tests

To run the tests, navigate to the `unit_tests` directory, compile the test file, and run the binary:

```bash
cd /usr/local/google/home/vyoms/Desktop/dssat_sotirios_biochar/unit_tests
gfortran -I../Soil/Biochar -I../Utilities -o test_Biochar_mod ../Utilities/ModuleDefs.for ../Soil/Biochar/Biochar_mod.f90 test_Biochar_mod.f90
./test_Biochar_mod
```

