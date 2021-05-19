
#### Definitions of global variables for gpx_db scripts

## This is file is sourced by R scripts


## Repo of track points of all gpx files ####
EPSG_WGS84      <- 4326
EPSG            <- 3857
trackpoints_fl  <- paste0("~/GISdata/Count_sl2_",EPSG,".Rds")


## Layer with multiple polygons in which the gpx files may be
fl_regions      <- "~/GISdata/Layers/path_regions.shp"

## Files to evaluate track problems ####
baseoutput      <- "~/GISdata/"
## track points with no times
fl_notimes      <- paste0(baseoutput,"/Files_points_no_time.csv")
## overlapping tracks above threshold
fl_suspctpt     <- paste0(baseoutput,"/Dups_point_suspects.csv")
cover_threshold <- 0.95
## all overlapping tracks above threshold
fl_suspctpt_all <- paste0(baseoutput,"/Dups_point_suspects_all.csv")


## Output for qgis grid display ####

## one file for all data
layers_out      <- "~/GISdata/Layers/Auto/"
fl_gis_data     <-  paste0(layers_out,"/Grid_mega.gpkg")

## Spatial aggregation
rsls <- unique(c(
    5,
    10,
    20,
    50,
    100,
    500,
    1000,
    5000,
    10000,
    20000,
    50000 ))

## Temporal aggregation
rsltemp         <- 300    ##  in seconds
## points inside the square counts once every 300 secs


## Characterize all gpx file by region ####

## The resolution to simplify data points for localization
resolution_lcz     <- 200
## List of localized gpx files
fl_localized       <- paste0(baseoutput,"/Location_list.Rds")
## Command to gather all gpx in folder to one gpx file for osmand easy load
gather_command <- "~/CODE/gpx_tools/gather_tracks_gpx.sh"


## Gather and process waypoints ####

## Waypoints repo
fl_waypoints <- paste0(baseoutput,"/Location_waypoins.Rds")

## waypoints proximity flag threshold
close_flag   <- 10       ## meters between points to flag as close


