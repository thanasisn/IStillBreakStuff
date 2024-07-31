
#### Definitions of global variables for gps_wpt scripts

## Repo of track points of all gpx files  --------------------------------------
EPSG_WGS84      <- 4326
EPSG_MERCA      <- 3857

##  Layer with multiple polygons in which the gpx files may be
fl_regions      <- "~/GISdata/Layers/path_regions.shp"

##  Paths with GPX file to parse
gpx_repo        <- c("~/GISdata/GPX/")

##  Output
baseoutput      <- "~/DATA/GIS/WPT/"

## Files to evaluate track problems  -------------------------------------------

# ## track points with no times
# fl_notimes      <- paste0(baseoutput,"/Files_points_no_time.csv")
# ## overlapping tracks above threshold
# fl_suspctpt     <- paste0(baseoutput,"/Dups_point_suspects.csv")
# cover_threshold <- 0.95
# ## all overlapping tracks above threshold
# fl_suspctpt_all <- paste0(baseoutput,"/Dups_point_suspects_all.csv")




# ## Characterize all gpx file by region  ----------------------------------------
#
# ## The resolution to simplify data points for localization
# resolution_lcz     <- 200
# ## List of localized gpx files
# fl_localized       <- paste0(baseoutput,"/Location_list.Rds")
# ## Command to gather all gpx in folder to one gpx file for osmand easy load
# gather_command     <- "~/CODE/gpx_tools/gather_tracks_gpx.sh"
#
#
## Gather and process waypoints  -----------------------------------------------

## Waypoints repo
fl_waypoints <- paste0(baseoutput, "/Location_waypoins.Rds")

## waypoints proximity flag threshold
close_flag   <- 12    ## meters between points to flag as close for inspection

#
# ## Export gpx track files by location  -----------------------------------------
# outputrep     <- "~/ZHOST/Gpx_by_location/"
#
