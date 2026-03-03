#!/usr/bin/env nix-shell
#! nix-shell -i python "/home/athan/CODE/nixos/nix-shells/python_general_2.nix"
# -*- coding: utf-8 -*-


import openmeteo_requests
import pandas as pd
import numpy  as np
import requests_cache
from retry_requests import retry
from datetime import datetime

def get_open_meteo_forecasts(latitude, longitude):
    """
    Fetch weather data from Open-Meteo API for given coordinates.

    Parameters:
    -----------
    latitude : float
        Latitude of the location
    longitude : float
        Longitude of the location

    Returns:
    --------
    tuple : (hourly_data, daily_data)
        Two pandas DataFrames with hourly and daily weather data for all models
    """

    # Setup the Open-Meteo API client with cache and retry on error
    cache_session = requests_cache.CachedSession('.cache', expire_after = 3600/2)
    retry_session = retry(cache_session, retries=5, backoff_factor=0.2)
    openmeteo     = openmeteo_requests.Client(session=retry_session)

    # Define daily weather variables
    daily_vars_names = [
        "temperature_2m_max",
        "temperature_2m_min",
        "apparent_temperature_max",
        "apparent_temperature_min",
        "sunrise",
        "sunset",
        "rain_sum",
        "showers_sum",
        "snowfall_sum",
        "precipitation_sum",
        "precipitation_hours",
        "precipitation_probability_max"
    ]

    # Define hourly weather variables
    hourly_vars_names = [
        "temperature_2m",
        "relative_humidity_2m",
        "apparent_temperature",
        "precipitation_probability",
        "precipitation",
        "rain",
        "showers",
        "snowfall",
        "cloud_cover",
        "cloud_cover_low",
        "cloud_cover_mid",
        "cloud_cover_high",
        "wind_speed_10m",
        "wind_direction_10m",
        "freezing_level_height",
        "is_day",
        "shortwave_radiation_instant",
        "direct_radiation_instant",
        "diffuse_radiation_instant",
        "direct_normal_irradiance_instant"
    ]

    # Define weather models
    model_names = [
        "best_match",
        "ecmwf_ifs",
        "ecmwf_ifs025",
        "ecmwf_aifs025_single",
        "cma_grapes_global",
        "bom_access_global",
        "gfs_seamless",
        "gfs_global",
        "jma_seamless",
        "gfs_graphcast025",
        "ncep_aigfs025",
        "ncep_hgefs025_ensemble_mean",
        "kma_seamless",
        "icon_seamless",
        "icon_global",
        "icon_eu",
        "icon_d2",
        "gem_seamless",
        "metno_seamless",
        "metno_nordic",
        "italia_meteo_arpae_icon_2i",
        "meteoswiss_icon_seamless",
        "ukmo_seamless",
        "ukmo_global_deterministic_10km",
        "ukmo_uk_deterministic_2km",
        "meteofrance_seamless",
        "meteofrance_arpege_world",
        "meteofrance_arpege_europe",
        "meteofrance_arome_france",
        "meteofrance_arome_france_hd",
        "knmi_seamless",
        "knmi_harmonie_arome_europe",
        "knmi_harmonie_arome_netherlands",
        "dmi_seamless",
        "dmi_harmonie_arome_europe",
        "meteoswiss_icon_ch1",
        "meteoswiss_icon_ch2",
        "kma_ldps",
        "kma_gdps",
        "jma_msm",
        "jma_gsm",
        "gem_global",
        "gem_regional",
        "gem_hrdps_continental",
        "gem_hrdps_west"
    ]

    params = {
        "latitude":      latitude,
        "longitude":     longitude,
        "daily":         daily_vars_names,
        "hourly":        hourly_vars_names,
        "models":        model_names,
        "timezone":      "auto",
        "past_days":     2,
        "forecast_days": 16,
    }

    # Get data from all models
    responses = openmeteo.weather_api(url="https://api.open-meteo.com/v1/forecast", params=params)

    # Store all long-format data
    all_hourly_data = []
    all_daily_data = []

    # Process each model
    for i, response in enumerate(responses):
        model_name = model_names[i] if i < len(model_names) else f"model_{i}"

        # Get hourly data
        hourly = response.Hourly()

        # Create date range
        hourly_dates = pd.date_range(
            start=pd.to_datetime(hourly.Time(), unit="s", utc=True),
            end=pd.to_datetime(hourly.TimeEnd(), unit="s", utc=True),
            freq=pd.Timedelta(seconds=hourly.Interval()),
            inclusive="left"
        )

        # Process each hourly variable
        for v, var_name in enumerate(hourly_vars_names):
            values = hourly.Variables(v).ValuesAsNumpy()

            # Skip empty variables (all NaN or all zero)
            if v < len(hourly.Variables(0).ValuesAsNumpy()):  # Check if variable exists
                if np.all(np.isnan(values)) or np.all(values == 0):
                    # print(f"Skipping empty hourly variable: {var_name} for model: {model_name}")
                    continue


            # Create long-format dataframe for this variable
            var_df = pd.DataFrame({
                'date': hourly_dates,
                'model': model_name,
                'variable': var_name,
                'value': values,
                'latitude': latitude,
                'longitude': longitude,
                'timezone': response.Timezone()
            })

            all_hourly_data.append(var_df)

        # Get daily data
        daily = response.Daily()

        # Create date range
        daily_dates = pd.date_range(
            start=pd.to_datetime(daily.Time(), unit="s", utc=True),
            end=pd.to_datetime(daily.TimeEnd(), unit="s", utc=True),
            freq=pd.Timedelta(seconds=daily.Interval()),
            inclusive="left"
        )

        # Process each daily variable
        for v, var_name in enumerate(daily_vars_names):
            values = daily.Variables(v).ValuesAsNumpy()

            # Skip empty variables (all NaN or all zero)
            if v < len(daily.Variables(0).ValuesAsNumpy()):  # Check if variable exists
                if np.all(np.isnan(values)) or np.all(values == 0):
                    # print(f"Skipping empty daily variable: {var_name} for model: {model_name}")
                    continue


            var_df = pd.DataFrame({
                'date':      daily_dates,
                'model':     model_name,
                'variable':  var_name,
                'value':     values,
                'latitude':  latitude,
                'longitude': longitude,
                'timezone':  response.Timezone()
            })

            all_daily_data.append(var_df)

    # Combine all data
    hourly_data = pd.concat(all_hourly_data, ignore_index=True)
    daily_data = pd.concat(all_daily_data, ignore_index=True)

    # return hourly_data, daily_data

    # Convert to native Python types
    def clean_df(df):
        cleaned = { }
        for col in df.columns:
            # Convert column to list of native Python types
            values = df[col].tolist()
            cleaned[col] = [
                None if pd.isna(v) else (
                    int(v) if isinstance(v, (np.integer, np.int64, np.int32)) else
                    float(v) if isinstance(v, (np.floating, np.float64, np.float32)) else
                    str(v) if not isinstance(v, str) else v
                )
                for v in values
            ]
        return cleaned

    return {
        'hourly':  clean_df(hourly_data),
        'daily':   clean_df(daily_data),
        'success': True
    }






# Example usage:
if __name__ == "__main__":
    # Test the function with some coordinates
    lat, lon = 40.52, 23.00
    hourly_df, daily_df, su, me = get_open_meteo_forecasts(lat, lon)

    print("Hourly data shape:", hourly_df.shape)
    print("Daily data shape:", daily_df.shape)
    print("\nHourly data sample:")
    print(hourly_df.head())
    print("\nDaily data sample:")
    print(daily_df.head())
