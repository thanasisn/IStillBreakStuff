#!/usr/bin/env python3
# -- coding: utf-8 --

#### Display sun info for current location

## Location is already known by:
## CONKY/Data_gather/Cnk_location.R
## CONKY/Data_gather/Current_OpenWeatherMAP_api.R


import os.path
import csv
import ephem
import calendar
from datetime import datetime, timedelta


## default values for Thessaloniki

global loc_lat
global loc_lng
global loc_acc
global loc_dt
global loc_nam


loc_lat = 40.632811
loc_lng = 22.955884
loc_elv = 62.0
loc_acc = "0"
loc_dt  = ""
loc_nam = "Thessaloniki"

## input files
LOCATION_fl = "/dev/shm/CONKY/last_location.dat"   ## get coord from wifi
# CURRENTW_fl = "/dev/shm/WHEATHER/last.dat"         ## get name of location

def diff_times_in_seconds(t1, t2):
    # caveat emptor - assumes t1 & t2 are python times, on the same day and t2 is after t1
    h1, m1, s1 = t1.hour, t1.minute, t1.second
    h2, m2, s2 = t2.hour, t2.minute, t2.second
    t1_secs = s1 + 60 * (m1 + 60*h1)
    t2_secs = s2 + 60 * (m2 + 60*h2)
    return( t2_secs - t1_secs)


## Read current location from file
try:
    if os.path.isfile(LOCATION_fl) :
        with open(LOCATION_fl) as locf:
            reader = csv.DictReader(locf)
            for r in reader:
                print(r)
                if r['Type'] == 'wifi':

                    ## capture last values only
                    loc_lat = float(r['Lat'])
                    loc_lng = float(r['Lng'])
                    loc_acc = str(r['Acc'])
                    loc_dt  = r['Dt']
                    loc_nam = r['City']

        # ## after location try to read current weather
        # if os.path.isfile(CURRENTW_fl):
        #     with open(CURRENTW_fl) as curf:
        #         reader2 = csv.DictReader(curf)
        #         for r in reader2:
        #             loc_nam = r['name']

except:
    print('Failed on parsing input files')
    print('Set default location')
    loc_lat = 40.632811
    loc_lng = 22.955884
    loc_elv = 62.0
    loc_acc = "99999"
    loc_dt  = ""
    loc_nam = "Thessaloniki"

#  print( loc_lat, loc_lng, loc_elv, loc_acc, loc_dt, loc_nam )

def ephem_day(lat, lon, date = datetime.utcnow()):
    observer = ephem.Observer()
    observer.horizon = 0
    observer.lat = lat * ephem.degree
    observer.lon = lon * ephem.degree
#    observer.elevation = Location.elevation   # meters above sea level
    observer.date = date

    sunrise = observer.previous_rising(ephem.Sun()).datetime() #Sunrise
    noon    = observer.next_transit   (ephem.Sun(), start=sunrise).datetime() #Solar noon
    sunset  = observer.next_setting   (ephem.Sun()).datetime() #Sunset

    return { "sunrise" :  sunrise ,  "noon" :  noon , "sunset":  sunset}


def utc_to_local(utc_dt):
    # get integer timestamp to avoid precision lost
    timestamp = calendar.timegm(utc_dt.timetuple())
    local_dt = datetime.fromtimestamp(timestamp)
    assert utc_dt.resolution >= timedelta(microseconds=1)
    return local_dt.replace(microsecond=utc_dt.microsecond)


def location_pango():
    try:
        lat = loc_lat
        lon = loc_lng
        acc = loc_acc

        sunnn = utc_to_local(ephem_day(lat=float(lat), lon=float(lon))['noon']).strftime('%H:%M')
        sundn = utc_to_local(ephem_day(lat=float(lat), lon=float(lon))['sunset']).strftime('%H:%M')
        sunup = utc_to_local(ephem_day(lat=float(lat), lon=float(lon))['sunrise']).strftime('%H:%M')

        # lightduration = diff_times_in_seconds( datetime.strptime( sunup, '%H:%M').time(), datetime.strptime( sundn, '%H:%M').time())
        # daypassed     = diff_times_in_seconds( datetime.strptime( sunup, '%H:%M').time(), datetime.now().time())
        # remainligh_pc = round( 100 * float(lightduration - daypassed) / lightduration, 1 )

        # today         = datetime.now().date()
        # start         = datetime(today.year, today.month, today.day)
        # diff          = datetime.now() - start
        # remainday_pc  = round( 100 * ( 3600*24 - diff.total_seconds() ) / (3600*24),1 )

#        sun_track = sun.sun_vector(date=datetime.utcnow(),lat=float(lat),lon=float(lon))
#        azz = "a:" + u"%0.2f\u00B0" % sun_track[0]
#        zen = "z:" + u"%0.2f\u00B0" % sun_track[1]

        ## create message
        text = "%s" % loc_nam
        text += "  ^" + sunup   + " v" + sundn + " |" + sunnn + "\n"
        text += "Lat:%6.3f" % lat + " Lon:%6.3f" % float(lon) + " Acc: %dm" % float(acc) #+ \
        #       "R " + sunup   + " S " + sundn + " N " + sunnn + " L "+ str(remainligh_pc) + "% D " + str(remainday_pc)+"%"
#        text += "\n%s" % loc_nam
        return(text)

    except:
        return "Where\nare\nyou?"

print(location_pango())
