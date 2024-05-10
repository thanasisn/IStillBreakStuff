#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu May  2 21:21:18 2024

@author: athan
"""

"""
Get only coordinates and time for gpx location database
and meta data from json.

There are too much info to upack form fit files and most of it is
read by golden cheetah.

If we read fit files we do not need the gpx in golden

Validate fit files has a gpx in golden and remove it

Read json activities from golden

There are more activities in garmin that are not exported to golden

"""


import fitdecode
from pathlib import Path

from datetime import datetime, timedelta
from typing import Dict, Union, Optional,Tuple

import pandas as pd
from sys import exit





# The names of the columns we will use in our points DataFrame. For the data we will be getting
# from the FIT data, we use the same name as the field names to make it easier to parse the data.
POINTS_COLUMN_NAMES = ['latitude', 'longitude', 'lap', 'altitude', 'timestamp', 'heart_rate', 'cadence', 'speed']

# The names of the columns we will use in our laps DataFrame.
LAPS_COLUMN_NAMES = ['number', 'start_time', 'total_distance', 'total_elapsed_time',
                     'max_speed', 'max_heart_rate', 'avg_heart_rate']

def get_fit_lap_data(frame: fitdecode.records.FitDataMessage) -> Dict[str, Union[float, datetime, timedelta, int]]:
    """Extract some data from a FIT frame representing a lap and return
    it as a dict.
    """

    data: Dict[str, Union[float, datetime, timedelta, int]] = {}

    for field in LAPS_COLUMN_NAMES[1:]:  # Exclude 'number' (lap number) because we don't get that
                                        # from the data but rather count it ourselves
        if frame.has_field(field):
            data[field] = frame.get_value(field)

    return data

def get_fit_point_data(frame: fitdecode.records.FitDataMessage) -> Optional[Dict[str, Union[float, int, str, datetime]]]:
    """Extract some data from an FIT frame representing a track point
    and return it as a dict.
    """

    data: Dict[str, Union[float, int, str, datetime]] = {}

    if not (frame.has_field('position_lat') and frame.has_field('position_long')):
        # Frame does not have any latitude or longitude data. We will ignore these frames in order to keep things
        # simple, as we did when parsing the TCX file.
        return None
    else:
        data['latitude'] = frame.get_value('position_lat') / ((2**32) / 360)
        data['longitude'] = frame.get_value('position_long') / ((2**32) / 360)

    for field in POINTS_COLUMN_NAMES[3:]:
        if frame.has_field(field):
            data[field] = frame.get_value(field)

    return data


def get_dataframes(fname: str) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """Takes the path to a FIT file (as a string) and returns two Pandas
    DataFrames: one containing data about the laps, and one containing
    data about the individual points.
    """

    points_data = []
    laps_data = []
    lap_no = 1
    with fitdecode.FitReader(fname) as fit_file:
        for frame in fit_file:
            if isinstance(frame, fitdecode.records.FitDataMessage):
                if frame.name == 'record':
                    single_point_data = get_fit_point_data(frame)
                    if single_point_data is not None:
                        single_point_data['lap'] = lap_no
                        points_data.append(single_point_data)
                elif frame.name == 'lap':
                    single_lap_data = get_fit_lap_data(frame)
                    single_lap_data['number'] = lap_no
                    laps_data.append(single_lap_data)
                    lap_no += 1

    # Create DataFrames from the data we have collected. If any information is missing from a particular lap or track
    # point, it will show up as a null value or "NaN" in the DataFrame.

    laps_df = pd.DataFrame(laps_data, columns=LAPS_COLUMN_NAMES)
    laps_df.set_index('number', inplace=True)
    points_df = pd.DataFrame(points_data, columns=POINTS_COLUMN_NAMES)

    return laps_df, points_df













## read naked fit files
pathlist = Path('/home/athan/TRAIN/GoldenCheetah/Athan/imports/').rglob('*.fit')
for path in pathlist:
    # because path is object not string
    path_in_str = str(path)
    print(path_in_str)

    laps_df, points_df = get_dataframes(path_in_str)
    print('LAPS:')
    print(laps_df)
    print('\nPOINTS:')
    print(points_df)

    with fitdecode.FitReader(path_in_str) as fit_file:
        for frame in fit_file:
            if isinstance(frame, fitdecode.records.FitDataMessage):
                for field in frame.fields:
                  # field is a FieldData object
                  try:
                    value = frame.get_value(field.name)
                    print(field.name,":", value)
                  except:
                    pass
                # frame.get_value('position_lat')
                # frame.has_field('position_lat')

    exit()








pathlist = Path('/home/athan/TRAIN/Garmin_Exports/original/').rglob('*')
for path in pathlist:
    # because path is object not string
    path_in_str = str(path)
    print(path_in_str)

# with fitdecode.FitReader('activity_15104896735_Thessaloniki_Running.zip') as fit_file:
#     for frame in fit_file:
#         if isinstance(frame, fitdecode.records.FitDataMessage):
#             if frame.name == 'lap':
#                 # This frame contains data about a lap.
#                 print("lap")
#             elif frame.name == 'record':
#                 # This frame contains data about a "track point".
#                 print("record")

# for field in frame.fields:
#     # field is a FieldData object
#     print(field.name)

# # Assuming the frame is a "record"
# if frame.has_field('position_lat') and frame.has_field('position_long'):
#     print('latitude:', frame.get_value('position_lat'))
#     print('longitude:', frame.get_value('position_long'))

# # Or you can provide a "fallback" argument to give you a default
# # value if the field is not present:
# print('non_existent_field:', frame.get_value('non_existent_field', fallback='field not present'))






if __name__ == '__main__':

    # from sys import argv
    # fname = argv[1]  # Path to FIT file to be given as first argument to script

    fname = '/home/athan/TRAIN/Garmin_Exports/original/2024/15155407132_ACTIVITY.fit'  # Path to FIT file to be given as first argument to script

    laps_df, points_df = get_dataframes(fname)
    print('LAPS:')
    print(laps_df)
    print('\nPOINTS:')
    print(points_df)
