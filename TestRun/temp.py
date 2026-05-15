import io
import os
import re

import numpy as np
import pandas as pd
import plotly.express as px

# def extract_variables(text):
#     # 1. Parse Daily Data Blocks
#     daily_records = []
#     # Split by blocks starting with the WATBAL debug header
#     blocks = re.split(
#         r'DEBUG: WATBAL - Daily Rate Calculation Start for Day:\s+', text)

#     for block in blocks[1:]:
#         day_match = re.match(r'(\d+)', block)
#         if not day_match: continue
#         day_id = int(day_match.group(1))

#         data = {'Day': day_id}

#         # Regex mapping for each variable
#         patterns = {
#             'Rain_mm': r'Rain \(mm\)=\s*([\d\.E+-]+)',
#             'Irrigation_mm': r'Irrigation \(mm\)=\s*([\d\.E+-]+)',
#             'Snow_mm': r'Snow \(mm\)=\s*([\d\.E+-]+)',
#             'Flood_depth_mm': r'Inputs: Flood depth \(mm\)=\s*([\d\.E+-]+)',
#             'Soil_Evap_Input_mm_d':
#             r'Inputs:.*?Soil Evaporation \(mm/d\)=\s*([\d\.E+-]+)',
#             'Runoff_Water_Avail_mm': r'Water Available \(mm\)=\s*([\d\.E+-]+)',
#             'Curve_Number': r'Curve Number=\s*([\d\.E+-]+)',
#             'Calculated_Runoff_mm':
#             r'Calculated Runoff \(mm\)=\s*([\d\.E+-]+)',
#             'Potential_Infiltration_cm':
#             r'Potential Infiltration \(cm\)=\s*([\d\.E+-]+)',
#             'Infil_Drainage_mm':
#             r'Infiltration Calculation End: Drainage \(mm\)=\s*([\d\.E+-]+)',
#             'Excess_Surface_Water_cm':
#             r'Excess Surface Water \(cm\)=\s*([\d\.E+-]+)',
#             'Pot_Root_Water_Uptake_cm_d':
#             r'Potential Root Water Uptake \(cm/d\)=\s*([\d\.E+-]+)',
#             'Pot_Evap_Soil_mm_d': r'Potential Evap \(mm/d\)=\s*([\d\.E+-]+)',
#             'Water_for_Infil_mm':
#             r'Water for Infiltration \(mm\)=\s*([\d\.E+-]+)',
#             'Actual_Evap_Soil_mm_d': r'Actual Evap \(mm/d\)=\s*([\d\.E+-]+)',
#             'Pot_Trans_EOP_mm_d':
#             r'Potential Transpiration \(EOP, mm/d\)=\s*([\d\.E+-]+)',
#             'Infiltration_Integration_mm':
#             r'Water Balance Components:.*?Infiltration \(mm\)=\s*([\d\.E+-]+)',
#             'Runoff_Integration_mm':
#             r'Water Balance Components:.*?Runoff \(mm\)=\s*([\d\.E+-]+)',
#             'Profile_Drainage_mm': r'Profile Drainage \(mm\)=\s*([\d\.E+-]+)',
#             'Upward_Flow_cm_d':
#             r'Upward Flow from below \(cm/d\)=\s*([\d\.E+-]+)',
#             'Soil_Evap_Integration_mm_d':
#             r'Water Balance Components:.*?Soil Evaporation \(mm/d\)=\s*([\d\.E+-]+)',
#             'Snow_Melt_Acc_mm':
#             r'Snow melt/accumulation \(mm\)=\s*([\d\.E+-]+)',
#             'SWC_Before': r'Before Integration:\s*([\d\.E+-]+)',
#             'Actual_Root_Water_Uptake_mm':
#             r'Actual Water Uptake by Roots \(mm\):\s*([\d\.E+-]+)',
#             'SWC_After': r'After Integration:\s*([\d\.E+-]+)'
#         }

#         for var, pat in patterns.items():
#             m = re.search(pat, block, re.DOTALL)
#             data[var] = float(m.group(1)) if m else np.nan

#         daily_records.append(data)

#     df_daily = pd.DataFrame(daily_records)

# 2. Parse Summary Table
# summaries = []
# header_regex = r'RUN\s+TRT\s+FLO\s+MAT\s+TOPWT\s+HARWT\s+RAIN\s+TIRR\s+CET\s+PESW\s+TNUP\s+TNLF\s+TSON\s+TSOC'
# for match in re.finditer(header_regex, text):
#     lines_after = text[match.end():].strip().split('\n')
#     if len(lines_after) >= 2:
#         parts = lines_after[1].strip().split() # The line with numerical values
#         if len(parts) >= 14:
#             summaries.append({
#                 'RUN': parts[0], 'TRT': parts[1], 'FLO': int(parts[2]), 'MAT': int(parts[3]),
#                 'TOPWT': int(parts[4]), 'HARWT': int(parts[5]), 'RAIN_sum': int(parts[6]),
#                 'TIRR_sum': int(parts[7]), 'CET': int(parts[8]), 'PESW': int(parts[9]),
#                 'TNUP': int(parts[10]), 'TNLF': int(parts[11]), 'TSON': int(parts[12]), 'TSOC': int(parts[13])
#             })
# df_summary = pd.DataFrame(summaries)


# return df_daily, ""
def clean_dssat_row(row_list, target_len=99):
    # In your data, index 8, 9, 10 is 'AG9010', '-', 'Rainfed'
    # We merge them into one string: 'AG9010 - Rainfed'
    diff = len(row_list) - target_len
    if diff > 0:
        # Merge the split treatment name (usually starts around index 8)
        treatment_name = " ".join(row_list[8:8 + diff + 1])
        # Reconstruct the list: Part before + merged part + part after
        new_row = row_list[:8] + [treatment_name] + row_list[8 + diff + 1:]
        return new_row
    return row_list


def parse_dssat_summary(text):
    # 1. Locate the data lines (they start with whitespace followed by a digit)
    lines = text.split('\n')
    data_lines = [line for line in lines if re.match(r'^\s+\d+', line)]

    # 2. Extract Headers (the line starting with @)
    header_line = ""
    for line in lines:
        if line.startswith('@'):
            header_line = line.replace('@', ' ').strip()
            break

    headers = header_line.split()

    # 3. Create DataFrame
    # Using split() works here because data is space-separated
    old_data = [line.split() for line in data_lines]
    data = [clean_dssat_row(row) for row in old_data]
    print(len(headers))
    df = pd.DataFrame(data, columns=headers)

    # 4. Convert numeric columns and handle -99 (DSSAT's null value)
    for col in df.columns:
        df[col] = pd.to_numeric(df[col], errors='ignore')

    df = df.replace(-99, pd.NA)

    # 5. Map key variables to understandable names
    mapping = {
        'RUNNO': 'Run_ID',
        'SDAT': 'Planting_Date',
        'MDAT': 'Maturity_Date',
        'HDAT': 'Harvest_Date',
        'CWAM': 'Max_Biomass_kg_ha',
        'HWAM': 'Yield_kg_ha',
        'HIAM': 'Harvest_Index',
        'LAIX': 'Max_LAI',
        'PRCM': 'Seasonal_Rain_mm',
        'ETCM': 'Seasonal_ET_mm',
        'NUCM': 'N_Uptake_kg_ha',
        'TMAXA': 'Avg_Max_Temp',
        'TMINA': 'Avg_Min_Temp',
        'DRCM': 'Seasonal_Drainage_mm',
        'NFXM': 'N_Fixed_kg_ha',
        'NIAM': 'Soil_Inorg_N_Maturity_kg_ha',
        'NMINC': 'Net_N_Mineralization_kg_ha',
        'GNAM': 'Harvest_Prod_N_kg_ha',
        'NLCM': 'N_Leaching_kg_ha',
        'N2OEM': 'N2O_Emissions_kg_ha',
        'CO2EM': 'CO2_Emitted_kg_ha',
        'CH4EM': 'Methane_Emissions_kg_ha',
        'ONAM': 'Org_Soil_N_Maturity_kg_ha',
        'OCAM': 'Org_Soil_C_Maturity_kg_ha'
    }

    # Rename columns that exist in the mapping
    df.rename(columns={
        k: v
        for k, v in mapping.items() if k in df.columns
    },
              inplace=True)

    return df


# Example Usage:
# df_summary = parse_dssat_summary(summary_text)
def extract_variables(text):
    # Split the text into segments based on the Summary Table (which ends a run)
    # We look for the "RUN TRT FLO..." header as the boundary
    summary_header = r'RUN\s+TRT\s+FLO\s+MAT\s+TOPWT\s+HARWT\s+RAIN\s+TIRR\s+CET\s+PESW\s+TNUP\s+TNLF\s+TSON\s+TSOC'

    # We find where each run ends
    run_splits = re.split(summary_header, text)

    all_daily_records = []
    all_summary_records = []

    for i, segment in enumerate(run_splits):
        # The split creates a segment of daily data BEFORE the summary header.
        # However, the very last segment will contain the summary data for the last run.
        # We need to look forward to the next segment's start to get summary values.

        # Extract daily data from the current segment
        daily_blocks = re.split(
            r'DEBUG: WATBAL - Daily Rate Calculation Start for Day:\s+',
            segment)
        run_number = i + 1

        for block in daily_blocks[1:]:
            day_match = re.match(r'(\d+)', block)
            if not day_match: continue

            data = {'Run_ID': run_number, 'Day': int(day_match.group(1))}

            # Pattern dictionary for daily variables
            patterns = {
                'Rain_mm': r'Rain \(mm\)=\s*([\d\.E+-]+)',
                'Irrigation_mm': r'Irrigation \(mm\)=\s*([\d\.E+-]+)',
                'Snow_mm': r'Snow \(mm\)=\s*([\d\.E+-]+)',
                'Flood_depth_mm':
                r'Inputs: Flood depth \(mm\)=\s*([\d\.E+-]+)',
                'Soil_Evap_Input_mm_d':
                r'Inputs:.*?Soil Evaporation \(mm/d\)=\s*([\d\.E+-]+)',
                'Before_Runoff_Water_Avail_mm':
                r'Water Available \(mm\)=\s*([\d\.E+-]+)',
                'Curve_Number': r'Curve Number=\s*([\d\.E+-]+)',
                'Total_Calculated_Runoff_mm':
                r'Calculated Runoff \(mm\)=\s*([\d\.E+-]+)',
                'Potential_Infiltration_cm':
                r'Potential Infiltration \(cm\)=\s*([\d\.E+-]+)',
                'After_Infilteration_Drainage_mm':
                r'Infiltration Calculation End: Drainage \(mm\)=\s*([\d\.E+-]+)',
                'After_Infilteration_Excess_Surface_Water_cm':
                r'Excess Surface Water \(cm\)=\s*([\d\.E+-]+)',
                'Pot_Root_Water_Uptake_cm_d':
                r'Potential Root Water Uptake \(cm/d\)=\s*([\d\.E+-]+)',
                'Before_Pot_Evap_Soil_mm_d':
                r'Potential Evap \(mm/d\)=\s*([\d\.E+-]+)',
                'Water_for_Infil_mm':
                r'Water for Infiltration \(mm\)=\s*([\d\.E+-]+)',
                'Actual_Evap_Soil_mm_d':
                r'Actual Evap \(mm/d\)=\s*([\d\.E+-]+)',
                'Pot_Transpiration_EOP_mm_d':
                r'Potential Transpiration \(EOP, mm/d\)=\s*([\d\.E+-]+)',
                'Infiltration_Integration_mm':
                r'Water Balance Components:.*?Infiltration \(mm\)=\s*([\d\.E+-]+)',
                'Runoff_Integration_mm':
                r'Water Balance Components:.*?Runoff \(mm\)=\s*([\d\.E+-]+)',
                'Profile_Drainage_Integeration_mm':
                r'Profile Drainage \(mm\)=\s*([\d\.E+-]+)',
                'Upward_Flow_Integeration_cm_d':
                r'Upward Flow from below \(cm/d\)=\s*([\d\.E+-]+)',
                'Soil_Evap_Integration_mm_d':
                r'Water Balance Components:.*?Soil Evaporation \(mm/d\)=\s*([\d\.E+-]+)',
                'Snow_Melt_Acc_mm':
                r'Snow melt/accumulation \(mm\)=\s*([\d\.E+-]+)',
                'Soil_Water_Content_Before':
                r'Before Integration:\s*([\d\.E+-]+)',
                'Actual_Root_Water_Uptake_mm':
                r'Actual Water Uptake by Roots \(mm\):\s*([\d\.E+-]+)',
                'Soil_Water_Content_After':
                r'After Integration:\s*([\d\.E+-]+)'
            }

            for var, pat in patterns.items():
                m = re.search(pat, block, re.DOTALL)
                data[var] = float(m.group(1)) if m else np.nan

            all_daily_records.append(data)

    df_daily = pd.DataFrame(all_daily_records)
    return df_daily


def extract_plant_growth(text):
    runs = re.split(r'\*RUN\s+(\d+)\s+', text)

    all_data = []

    # The first element is usually the file header, then pairs of (run_id, content)
    for i in range(1, len(runs), 2):
        run_id = int(runs[i])
        run_content = runs[i + 1]

        # Find the header line starting with @YEAR
        lines = run_content.strip().split('\n')
        header_index = -1
        for idx, line in enumerate(lines):
            if line.strip().startswith('@YEAR'):
                header_index = idx
                break

        if header_index == -1:
            continue

        header = lines[header_index].replace('@', '').split()
        data_lines = []
        for line in lines[header_index + 1:]:
            # A data line usually starts with a 4-digit year
            if re.match(r'^\s*\d{4}\s+', line):
                data_lines.append(line.split())
            elif line.strip().startswith(
                    '*RUN'):  # Safety break if runs aren't split correctly
                break

        df_run = pd.DataFrame(data_lines, columns=header)
        df_run.insert(0, 'Run_ID', run_id)
        all_data.append(df_run)

    if not all_data:
        return pd.DataFrame()

    df_final = pd.concat(all_data, ignore_index=True)

    # Convert numeric columns
    for col in df_final.columns:
        df_final[col] = pd.to_numeric(df_final[col], errors='ignore')

    # Mapping to understandable names
    name_map = {
        'YEAR': 'Year',
        'DOY': 'Day_of_Year',
        'DAS': 'Days_After_Sowing',
        'DAP': 'Days_After_Planting',
        'LAID': 'LAI',
        'LWAD': 'Leaf_Weight_kg_ha',
        'SWAD': 'Stem_Weight_kg_ha',
        'GWAD': 'Grain_Weight_kg_ha',
        'RWAD': 'Root_Weight_kg_ha',
        'VWAD': 'Veg_Weight_kg_ha',
        'CWAD': 'Total_Biomass_kg_ha',
        'HIAD': 'Harvest_Index',
        'CHTD': 'Canopy_Height_m',
        'RDPD': 'Root_Depth_m'
    }

    df_final.rename(columns=name_map, inplace=True)

    return df_final


def extract_water_stress(text):
    """
    Parses PlantGro.OUT to extract water stress indices (SWFAC).
    """
    runs = re.split(r'\*RUN\s+(\d+)\s+', text)
    all_data = []

    for i in range(1, len(runs), 2):
        run_id, run_content = int(runs[i]), runs[i + 1]
        lines = run_content.strip().split('\n')

        header_index = -1
        for idx, line in enumerate(lines):
            if line.strip().startswith('@YEAR'):
                header_index = idx
                break

        if header_index == -1:
            continue

        header = lines[header_index].replace('@', '').split()
        if 'SWFAC' not in header:
            # If stress factors are not in the output, return empty.
            continue

        data_lines = [
            line.split() for line in lines[header_index + 1:]
            if re.match(r'^\s*\d{4}\s+', line)
        ]

        df_run = pd.DataFrame(data_lines, columns=header)
        df_run = df_run[['YEAR', 'DOY', 'SWFAC']].copy()
        df_run.insert(0, 'Run_ID', run_id)
        all_data.append(df_run)

    if not all_data:
        return pd.DataFrame()

    df_final = pd.concat(all_data, ignore_index=True)
    for col in df_final.columns:
        if col != 'Run_ID':
            df_final[col] = pd.to_numeric(df_final[col], errors='coerce')

    return df_final


import re

import numpy as np
import pandas as pd


def parse_soil_water(text):
    runs = re.split(r'\*RUN\s+(\d+)\s+', text)
    all_data = []

    # Define Depth Labels for the 10 layers
    depths = [
        "0-5cm", "5-15cm", "15-30cm", "30-45cm", "45-60cm", "60-80cm",
        "80-100cm", "100-119cm", "119-139cm", "139-200cm"
    ]

    for i in range(1, len(runs), 2):
        run_id, run_content = int(runs[i]), runs[i + 1]
        lines = run_content.strip().split('\n')

        # Find header
        header_index = next(
            (idx for idx, line in enumerate(lines) if "@YEAR" in line), -1)
        if header_index == -1: continue

        header = lines[header_index].replace('@', '').split()
        data = [
            line.split() for line in lines[header_index + 1:]
            if re.match(r'^\s*\d{4}\s+', line)
        ]

        df_run = pd.DataFrame(data, columns=header)
        df_run.insert(0, 'Run_ID', run_id)

        # --- RENAME TO UNDERSTANDABLE NAMES ---
        new_names = {
            'YEAR': 'Year',
            'DOY': 'Day_of_Year',
            'DAS': 'Days_After_Start'
        }

        # Map Soil Layers (LL=WiltingPoint, DUL=FieldCapacity, SW=CurrentWater)
        for idx, depth in enumerate(depths, 1):
            new_names[f'LL{idx}D'] = f'WiltingPoint_{depth}'
            new_names[f'DUL{idx}D'] = f'FieldCapacity_{depth}'
            new_names[f'SAT{idx}D'] = f'Saturation_{depth}'
            new_names[f'SW{idx}D'] = f'CurrentWater_{depth}'
            new_names[f'BD{idx}D'] = f'SoilDensity_{depth}'

        df_run.rename(columns=new_names, inplace=True)
        all_data.append(df_run)

    final_df = pd.concat(all_data, ignore_index=True)
    return final_df.apply(pd.to_numeric, errors='ignore').replace(-99, np.nan)


import re

import pandas as pd


def parse_stages_with_yield_row(text):
    lines = text.split('\n')
    records = []
    current_run_id = None

    yield_pattern = re.compile(r'yield harvested\s+([\d\.]+)\s+kg/ha')

    for line in lines:
        if not line.strip(): continue

        # Track Run ID
        parts = line.split()
        if parts and parts[0].isdigit():
            current_run_id = int(parts[0])

        # 1. Capture Growth Stages
        s_match = re.search(
            r'([A-Z]{3}\s+\d+,\s+\d{4})\s+(\d+).*?MZ\s+(\d{2})\s+([a-zA-Z0-9%/\s]+)',
            line)
        if s_match:
            records.append({
                "Run_ID": current_run_id,
                "Date": s_match.group(1),
                "Day_of_Year": int(s_match.group(2)),
                "Stage_Name": s_match.group(4).strip()
            })

        # 2. Capture Harvest Event
        elif "Harvest" in line and current_run_id is not None:
            h_match = re.search(r'([A-Z]{3}\s+\d+,\s+\d{4})\s+(\d+).*?Harvest',
                                line)
            if h_match:
                records.append({
                    "Run_ID": current_run_id,
                    "Date": h_match.group(1),
                    "Day_of_Year": int(h_match.group(2)),
                    "Stage_Name": "Harvest"
                })

        # 3. Capture Yield as a new row
        y_match = yield_pattern.search(line)
        if y_match and current_run_id is not None:
            yield_val = y_match.group(1).rstrip('.')
            # We use the date from the last record (Harvest date) for the yield row
            last_date = records[-1]["Date"] if records else ""
            last_doy = records[-1]["Day_of_Year"] if records else ""

            records.append({
                "Run_ID": current_run_id,
                "Date": last_date,
                "Day_of_Year": last_doy,
                "Stage_Name": f"Final Yield: {yield_val} kg/ha"
            })

    return pd.DataFrame(records)


# df_stages = extract_stages_only(management_text)
# df_soil = parse_soil_water_file(your_file_text)

# Usage:
with open('./1.txt', 'r') as f:
    data_text = f.read()
df_daily = extract_variables(data_text)
with open('./Summary.OUT', 'r') as f1:
    summary_text = f1.read()
    print(summary_text)
df_summary = parse_dssat_summary(summary_text)

with open('./PlantGro.OUT', 'r') as f1:
    plant_growth = f1.read()
    print(plant_growth)
df_plant_growth = extract_plant_growth(plant_growth)
if os.path.exists('./SoilWater.OUT'):
    with open('./SoilWater.OUT', 'r') as f:
        data_text = f.read()
    df_soil_water = parse_soil_water(data_text)
else:
    df_soil_water = pd.DataFrame()
with open('./MgmtEvent.OUT', 'r') as f:
    data_text = f.read()
df_stages = parse_stages_with_yield_row(data_text)

import os
# To get individual pandas Series:
# rain_series = df_daily['Rain_mm']
# runoff_series = df_daily['Calculated_Runoff_mm']
import re

import numpy as np
import pandas as pd
import plotly.express as px
import streamlit as st

# --- STREAMLIT UI ---
st.set_page_config(page_title="DSSAT Simulation Dashboard", layout="wide")
st.title("🌾 DSSAT Simulation Explorer")
st.sidebar.header("Apply filters")
df = df_daily.copy()  #extract_multi_run_data(content)
df['Day'] = df['Day'].astype(str).str[-3:].astype(int)
df = df.fillna(0)
if not df.empty:
    # Sidebar Filters

    runs = st.sidebar.multiselect("Select Runs to Compare",
                                  options=df['Run_ID'].unique(),
                                  default=df['Run_ID'].unique())
    filtered_df_water = df[df['Run_ID'].isin(runs)]
    # if not df_water_stress.empty:
    #     print(df_water_stress)
    #     filtered_df_stress = df_water_stress[df_water_stress['Run_ID'].isin(
    #         runs)]

    if not df_plant_growth.empty:
        filtered_df_plants = df_plant_growth[df_plant_growth['Run_ID'].isin(
            runs)]
    if not df_soil_water.empty:
        filtered_df_soil_water = df_soil_water[df_soil_water['Run_ID'].isin(
            runs)]
    if not df_stages.empty:
        filtered_df_stages = df_stages[df_stages['Run_ID'].isin(runs)]
    filtered_df_stages = df_stages[df_stages['Run_ID'].isin(runs)]

    # --- Dashboard Metrics ---
    col1, col2 = st.columns(2)
    col1.metric("Total Days", len(df['Day'].unique()))
    col2.metric("Total Runs", df['Run_ID'].nunique())
    # col3.metric("Max SWC",
    #             f"{filtered_df_water['Soil_Water_Content_After'].max():.3f}")

    st.divider()

    # if not filtered_df_stress.empty:
    #     with st.expander("Water Stress Analysis", expanded=True):
    #         st.subheader("Water Stress Factor (SWFAC)")
    #         st.info(
    #             "SWFAC is a key indicator of water stress. A value of 1 means no stress, while values closer to 0 indicate severe water stress affecting growth."
    #         )
    #         stress_fig = px.line(
    #             filtered_df_stress,
    #             x="Day_of_Year",
    #             y="SWFAC",
    #             color="Run_ID",
    #             title="Daily Water Stress Factor (SWFAC)",
    #             labels={
    #                 "Day_of_Year": "Day of Year",
    #                 "SWFAC": "Water Stress Factor (0=Max Stress, 1=No Stress)"
    #             },
    #             markers=True)
    #         stress_fig.update_yaxes(range=[0, 1.05])
    #         st.plotly_chart(stress_fig, use_container_width=True)

    # --- Dynamic Graphing Section ---
    with st.expander("Water Tracking Metrics"):
        st.subheader("Interactive Variable Explorer")
        variable = st.selectbox(
            "Select a Variable to Graph",
            options=[
                c for c in df.columns if c not in
                ['Run_ID', 'Day', 'Curve_Number', 'Soil_Eval_Input_mm_d']
            ])

        # Plotly graph for interactivity
        fig = px.line(filtered_df_water,
                      x="Day",
                      y=variable,
                      color="Run_ID",
                      title=f"Trend Analysis: {variable}",
                      labels={"Run_ID": "Simulation Run"},
                      markers=True)
        st.plotly_chart(fig, use_container_width=True)

        # --- Grid of All Columns ---
        # st.divider()
        with st.expander("All Variables Snapshot"):
            st.subheader("All Variables Snapshot")
            cols = [
                c for c in df.columns if c not in
                ['Run_ID', 'Day', 'Curve_Number', 'Soil_Eval_Input_mm_d']
            ]

            # Display 2 columns of smaller charts
            grid_cols = st.columns(2)
            for i, col in enumerate(cols):
                with grid_cols[i % 2]:
                    small_fig = px.line(filtered_df_water,
                                        x="Day",
                                        y=col,
                                        color="Run_ID",
                                        height=300)
                    st.write(f"**{col}**")
                    st.plotly_chart(small_fig, use_container_width=True)
    if not df_soil_water.empty:
        with st.expander("Soil metrics"):
            st.subheader("Soil water metrics")
            with st.expander("Soil water metrics variables"):
                variable = st.selectbox(
                    "Select a Variable to Graph",
                    options=[
                        c for c in filtered_df_soil_water.columns if c in [
                            'CurrentWater_0-5cm', 'CurrentWater_5-15cm',
                            'CurrentWater_15-30cm', 'CurrentWater_30-45cm',
                            'CurrentWater_45-60cm', 'CurrentWater_60-80cm',
                            'CurrentWater_80-100cm', 'CurrentWater_100-119cm',
                            'CurrentWater_119-139cm', 'CurrentWater_139-200cm'
                        ]
                    ])

                # Plotly graph for interactivity
                fig = px.line(filtered_df_soil_water,
                              x="Day_of_Year",
                              y=variable,
                              color="Run_ID",
                              title=f"Trend Analysis: {variable}",
                              labels={"Run_ID": "Simulation Run"},
                              markers=True)
                st.plotly_chart(fig, use_container_width=True)

            # --- Grid of All Columns ---
            # st.divider()
            with st.expander("All Variables Snapshot"):
                st.subheader("All Variables Snapshot")
                cols = [
                    c for c in filtered_df_soil_water.columns if c in [
                        'CurrentWater_0-5cm', 'CurrentWater_5-15cm',
                        'CurrentWater_15-30cm', 'CurrentWater_30-45cm',
                        'CurrentWater_45-60cm', 'CurrentWater_60-80cm',
                        'CurrentWater_80-100cm', 'CurrentWater_100-119cm',
                        'CurrentWater_119-139cm', 'CurrentWater_139-200cm'
                    ]
                ]

                # Display 2 columns of smaller charts
                grid_cols = st.columns(2)
                for i, col in enumerate(cols):
                    with grid_cols[i % 2]:
                        small_fig = px.line(filtered_df_soil_water,
                                            x="Day_of_Year",
                                            y=col,
                                            color="Run_ID",
                                            height=300)
                        st.write(f"**{col}**")
                        st.plotly_chart(small_fig, use_container_width=True)

            with st.expander("Data Preview"):
                st.dataframe(df_soil_water)
        # st.dataframe(pd.read_csv('./soil_temp.csv'))
    if not df_plant_growth.empty:
        with st.expander("Plant metrics"):
            st.subheader("Plant Growth")
            with st.expander("Plant Growth variables"):

                variable = st.selectbox("Select a Variable to Graph",
                                        options=[
                                            c
                                            for c in filtered_df_plants.columns
                                            if c not in [
                                                'Run_ID',
                                                'Year',
                                                'Day_of_Year',
                                                'Days_After_Sowing',
                                                'Days_After_Planting',
                                                'LAI',
                                            ]
                                        ])

                # Plotly graph for interactivity
                fig = px.line(filtered_df_plants,
                              x="Day_of_Year",
                              y=variable,
                              color="Run_ID",
                              title=f"Trend Analysis: {variable}",
                              labels={"Run_ID": "Simulation Run"},
                              markers=True,
                              color_discrete_sequence=[
                                  "#006400", "#228B22", "#32CD32", "#90EE90"
                              ])
                st.plotly_chart(fig, use_container_width=True)

                # # --- Grid of All Columns ---
                # st.divider()
                with st.expander("All Variables Snapshot"):
                    st.subheader("All Variables Snapshot")
                    cols = [
                        c for c in filtered_df_plants.columns if c not in [
                            'Run_ID',
                            'Year',
                            'Day_of_Year',
                            'Days_After_Sowing',
                            'Days_After_Planting',
                            'LAI',
                        ]
                    ]

                    # Display 2 columns of smaller charts
                    grid_cols = st.columns(2)
                    for i, col in enumerate(cols):
                        with grid_cols[i % 2]:
                            small_fig = px.line(filtered_df_plants,
                                                x="Day_of_Year",
                                                y=col,
                                                color="Run_ID",
                                                height=300,
                                                color_discrete_sequence=[
                                                    "#006400", "#228B22",
                                                    "#32CD32", "#90EE90"
                                                ])
                            st.write(f"**{col}**")
                            st.plotly_chart(small_fig,
                                            use_container_width=True)
                with st.expander("Data Preview"):
                    st.dataframe(df_plant_growth)
    # --- Data Preview ---
    with st.expander("Data Preview"):
        with st.expander("View Stages"):
            for run_id in runs:
                df_stages_run = df_stages[df_stages['Run_ID'] == run_id]
                st.subheader(f"Stages for Run {run_id}")
                st.dataframe(df_stages_run)
        with st.expander("View Raw Processed Data"):
            st.dataframe(filtered_df_water)
        with st.expander("View Summary of Data"):
            st.dataframe(df_summary)

else:
    st.error(
        "Could not find any simulation data in the file. Please check the format."
    )
