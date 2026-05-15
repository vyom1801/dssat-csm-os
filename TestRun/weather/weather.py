"""Module to fetch weather data from NetCDF files and format it for DSSAT.

This file contains both a worker (ClimateWorker) and client utilities.
"""

import datetime
import logging
import os
import random
from typing import Dict, Sequence

import netCDF4
import numpy as np
import pandas as pd

from utils.common.files.file_util import FileUtil


NC_FILE_PATHS = {
    'tasmax': './tasmax_2011_2014.nc',
    'tasmin': './tasmin_2011_2014.nc',
    'pr': './pr_2011_2014.nc',
    'rsds': './rsds_2011_2014.nc',
}


class ClimateWorker:
    """Worker to process climate data from NetCDF files."""

    def get_required_nc_files(self, start_year, end_year, ssp):
        available_blocks = [
            (1981, 1990),
            (1991, 2000),
            (2001, 2010),
            (2011, 2014),
            (2015, 2020),
            (2021, 2030),
            (2031, 2040),
            (2041, 2050),
        ]
        needed_blocks = []
        for block_start, block_end in available_blocks:
            if not (end_year < block_start or start_year > block_end):
                if block_start < 2015:
                    needed_blocks.append(f"{block_start}_{block_end}")
                else:
                    needed_blocks.append(f"{ssp}_{block_start}_{block_end}")
        print(needed_blocks)
        return needed_blocks

    def _convert_units(self, data_series, var_name):
        """Converts raw NetCDF units to DSSAT required units.

        Args:
          data_series: data for the given variables
          var_name: weather variable name

        Returns:
          A data series with converted units
        """
        if var_name == "rsds":
            return data_series * 0.0864  # W m-2 to MJ m-2 d-1
        elif var_name in ["tas", "tasmax", "tasmin", "T"]:
            return data_series - 273.15  # K to C
        elif var_name in ["pr", "precip"]:
            return (data_series * 86400).clip(lower=0.0)  # kg m-2 s-1 to mm/day
        return data_series

    def get_point_data(self, nc_file_path, target_lat, target_lon, var_name):
        """Fetch the values for the given specific lat long for specific weather varibale from the netcdf4 file.

        Args:
          nc_file_path: File path of netcdf file for waether variable
          target_lat: latitude
          target_lon: longitude
          var_name: weatheer varibale name

        Returns:
         A series of values for different time frame at specific location
        """
        try:
            with netCDF4.Dataset(nc_file_path, "r") as nc_file:
                lats = nc_file.variables["lat"][:]
                lons = nc_file.variables["lon"][:]
                time_var = nc_file.variables["time"]
                data_var = nc_file.variables[var_name]

                lat_idx = np.abs(lats - target_lat).argmin()
                lon_idx = np.abs(lons - target_lon).argmin()

                dates = netCDF4.num2date(time_var[:], time_var.units)
                # Slicing the data directly to save memory
                point_data = data_var[:, lat_idx, lon_idx]

                date_strings = [d.strftime("%Y%m%d") for d in dates]
                raw_series = pd.Series(point_data, index=date_strings)
                return self._convert_units(raw_series, var_name)
        except Exception as e:
            logging.error(f"Error reading {nc_file_path}: {e}")
            return None

    def get_dssat_weather_from_nc(self, params):
        """Reads weather data from local NetCDF (.nc) files, interpolates for the given

        latitude/longitude, and formats it for DSSAT (.WTH).

        Args:
            params (dict): Dictionary containing lat, lon, start_date, end_date,
              ssp, model.
        """
        lat = params["lat"]
        lon = params["lon"]
        start_dt = datetime.datetime.strptime(params["start_date"], "%Y%m%d")
        end_dt = datetime.datetime.strptime(params["end_date"], "%Y%m%d")

        needed_blocks = self.get_required_nc_files(
            start_dt.year, end_dt.year, params["ssp"]
        )
        all_series = {}
        for var_nasa, path in NC_FILE_PATHS.items():
            # TODO repalce this path with the config when we do the generic weather files for more years
            yearly_chunks = []
            for block_str in needed_blocks:
                file_name = f"{var_nasa}_{block_str}.nc"
                path = f"/tmp/climate/{params['model']}/{file_name}"

                try:
                    if not FileUtil().file_exists(path):
                        FileUtil().copy_file(
                            f"gs://kokua-data/climate/isimip/{params['model']}/{file_name}",
                            path,
                        )
                    logging.info(
                        f"Fetched {var_nasa} for block {block_str} from GCS"
                    )

                    series = self.get_point_data(path, lat, lon, var_nasa)
                    if series is not None:
                        yearly_chunks.append(series)
                    
                    # Delete the file once extracted to save space
                    
                except Exception as e:
                    logging.error(
                        f"Failed to fetch or process {file_name}: {e}"
                    )

            # Combine chunks and drop duplicate dates (if blocks overlap)
            if yearly_chunks:
                combined = pd.concat(yearly_chunks)
                all_series[var_nasa] = combined[
                    ~combined.index.duplicated(keep="first")
                ]
        
            # if os.path.exists(path):
            #     os.remove(path)

        if not all_series:
            logging.error("Failed to load any weather data from NetCDF files.")
            return None

        # 2. Create the exact date range string list for reindexing
        date_range_str = [
            d.strftime("%Y%m%d")
            for d in pd.date_range(start_dt, end_dt, freq="D")
        ]

        # 3. Align all data and build the final DataFrame
        final_data = pd.DataFrame(all_series).reindex(date_range_str)

        valid_temps = final_data[["tasmax", "tasmin"]].stack().dropna()

        if valid_temps.empty:
            raise ValueError(
                "No valid temperature data found in the filtered range."
            )

        tav = valid_temps.mean()
        amp = (valid_temps.max() - valid_temps.min()) / 2.0  # Simplified AMP

        final_data.index.name = "date"
        final_output = final_data.reset_index().to_dict(orient="list")

        final_output["tav"] = str(tav)
        final_output["amp"] = str(amp)
        final_output["lat"] = str(lat)
        final_output["lon"] = str(lon)
        # logging.info(f"final_data={final_output}")
        return final_output

    async def process_message(self, action):
        return self.get_dssat_weather_from_nc(
            action
        )



def write_wth_file(df, metadata, station_name="LOCAL"):
    """Writes DSSAT .WTH file content."""
    output = []
    tav = metadata.get("tav", -99.0)
    amp = metadata.get("amp", -99.0)

    # Header logic
    output.append(f"*WEATHER DATA : {station_name}")
    output.append("@ INSI      LAT     LONG  ELEV   TAV   AMP REFHT WNDHT")
    output.append(
        f"  {station_name[:4]:<4} {metadata['lat']:>8.3f} {metadata['lon']:>8.3f}   -99 {tav:>5.1f} {amp:>5.1f}   -99   -99"
    )

    # Data Table
    output.append("@DATE  SRAD  TMAX  TMIN  RAIN")
    for d_str, row in df.iterrows():
        dt = datetime.datetime.strptime(d_str, "%Y%m%d")
        yydoy = f"{dt.year % 100:02d}{dt.timetuple().tm_yday:03d}"

        # Format values with safe defaults
        line = f"{yydoy} {row.get('rsds', -99):>5.1f} {row.get('tasmax', -99):>5.1f} {row.get('tasmin', -99):>5.1f} {row.get('pr', -99):>5.1f}"
        output.append(line)

    return "\n".join(output)


def get_weather_data(lat, lon, start_date, end_date):
    """Fetches weather data and returns WTH content."""
    ssp = random.choice(["ssp126"])
    model = random.choice(["GFDL-ESM4"])
    lat = round(lat, 1)
    lon = round(lon, 1)
    action = {
        "lat": lat,
        "lon": lon,
        "start_date": start_date,
        "end_date": end_date,
        "ssp": ssp,
        "model": model,
    }
    worker = ClimateWorker()
    output = worker.get_dssat_weather_from_nc(action)
    
    if output is None:
        logging.error("Failed to get weather data")
        return None
        
    # logging.info(f"output={output}")
    metadata_keys = ["tav", "amp", "lat", "lon"]
    metadata = {k: float(output.pop(k)) for k in metadata_keys if k in output}
    df = pd.DataFrame(output)

    if "date" in df.columns:
        df.set_index("date", inplace=True)
    elif "index" in df.columns:
        df.set_index("index", inplace=True)
    # logging.info(f"df={df}")
    return write_wth_file(df, metadata)

if __name__ == "__main__":
    import sys
    logging.basicConfig(level=logging.INFO)
    filepath = sys.argv[1] if len(sys.argv) > 1 else "UGFA.WTH"
    # Default coordinates for Iowa as per previous turns
    lat = 42.0
    lon = -93.5
    start_date = "19850101"
    end_date = "20161231"
    
    wth_content = get_weather_data(lat, lon, start_date, end_date)
    
    if wth_content:
        with open(filepath, 'w') as f:
            f.write(wth_content)
        print(f"Created weather file at {filepath}")
    else:
        print("Failed to create weather file")

