# Guide: Extracting JSON Parameters from Paper Document

This document guides you on how to extract biochar parameters from the paper document and format them into the JSON structure required by the Biochar module or test scripts.

## 1. Source Document
The paper file is located in your Downloads folder:
`/usr/local/google/home/vyoms/Downloads/1-s2.0-S0378429017318646-main (1).docx`

We have already extracted the text from this file to:
`unit_tests/paper_data/paper_text.txt`

## 2. Extracted Data Points
Based on a search of the extracted text, here are the key parameters found for the **Hardwood Biochar/Corn Stover**:

- **Carbon Content**: 76% (Found in text: "high carbon hardwood biochar (76% C)") -> `FCarbon = 0.76`
- **C:N Ratio**: 232:1 (Found in text: "high C:N ratio of 232:1") -> `CN_BC = 232.0`
- **Application Rate**: 22.4 t/ha (Found in text: "applied at a rate of 22.4 t ha−1") -> Convert to kg/ha: `Amount = 22400.0`
- **Incorporation Depth**: 20 cm (Found in text: "incorporated to a depth of 20 cm") -> `Depth = 20.0`

## 3. Target JSON Format

You can use these extracted values to create or update your JSON configuration file (e.g., `biochar_properties.json`).

Here is how the extracted data maps to the JSON structure:

```json
{
  "biochar_name": "Aller2018_Hardwood",
  "properties": {
    "CNRF_BC": 0.5,
    "Opt_bc": 20.0,
    "CEC_MAX": 120.0
  },
  "applications": [
    {
      "AppDate": 1985001,
      "Amount": 22400.0,
      "Depth": 20.0,
      "FCarbon": 0.76,
      "CN_BC": 232.0,
      "FLabile": 0.1
    }
  ]
}
```

Use this file as a template when extracting data for other biochar types or treatments mentioned in the paper.
