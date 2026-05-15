import io
import os
import re
import numpy as np
import pandas as pd

def clean_dssat_row(row_list, target_len=99):
    """
    Merges split treatment names if the row length exceeds target_len.
    """
    diff = len(row_list) - target_len
    if diff > 0:
        treatment_name = " ".join(row_list[8:8 + diff + 1])
        new_row = row_list[:8] + [treatment_name] + row_list[8 + diff + 1:]
        return new_row
    return row_list

def extract_params(file_path):
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return None

    with open(file_path, 'r') as f:
        text = f.read()

    lines = text.split('\n')
    data_lines = [line for line in lines if re.match(r'^\s+\d+', line)]

    header_line = ""
    for line in lines:
        if line.startswith('@'):
            header_line = line.replace('@', ' ').strip()
            break

    if not header_line:
        print("Could not find header line starting with @")
        return None

    headers = header_line.split()
    
    old_data = [line.split() for line in data_lines]
    data = [clean_dssat_row(row, len(headers)) for row in old_data]
    
    try:
        df = pd.DataFrame(data, columns=headers)
    except ValueError as e:
        print(f"Error creating DataFrame: {e}")
        print(f"Headers length: {len(headers)}")
        print(f"First row length: {len(data[0]) if data else 'N/A'}")
        return None

    for col in df.columns:
        df[col] = pd.to_numeric(df[col], errors='ignore')

    df = df.replace(-99, pd.NA)

    # Mapping requested by user + Run identification
    mapping = {
        'RUNNO': 'Run_ID',
        'ETCM': 'Total_Seasonal_ET_mm',
        'DRCM': 'Total_Seasonal_Drainage_mm',
        'HWAM': 'Yield_at_Maturity_kg_ha',
        'NFXM': 'Total_N_Fixed_kg_ha',
        'NUCM': 'N_Uptake_kg_ha',
        'NIAM': 'Soil_Inorg_N_Maturity_kg_ha',
        'NMINC': 'Cum_Net_N_Mineralization_kg_ha',
        'GNAM': 'Harvest_Prod_N_kg_ha',
        'NLCM': 'N_Leaching_kg_ha',
        'N2OEM': 'N2O_Emissions_kg_ha',
        'CO2EM': 'Cum_CO2_Emitted_kg_ha',
        'CH4EM': 'Methane_Emissions_kg_ha',
        'ONAM': 'Org_Soil_N_Maturity_kg_ha',
        'OCAM': 'Org_Soil_C_Maturity_kg_ha'
    }

    # Filter to only include requested columns (or their mapped names)
    available_requested = [col for col in mapping.keys() if col in df.columns]
    
    df_filtered = df[available_requested].copy()
    df_filtered.rename(columns=mapping, inplace=True)

    return df_filtered

if __name__ == "__main__":
    summary_file = "./Summary.OUT"
    df = extract_params(summary_file)
    if df is not None:
        print(df.to_string(index=False))
