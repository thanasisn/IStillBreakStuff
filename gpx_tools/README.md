
# gpx_tools


A collection of tools for gps files. Mainly centered on .gpx files.
I use a lot of them to process data from garmin etrex device.

Things they can do:
- **etrex_sync.sh              :**   Get all gpx files from etrex, update maps and some other files
- **gdb_to_gpx.sh              :**   Convert gdb to gpx
- **gpx_find_box.sh            :**   Search gpx files and based on coordinate box
- **gpx_plot_compare_files.R   :**   Compare multiple gpx files
- **gpx_remove_spaces.sh       :**   Reduce xml file size by removing spaces tabs and newlines.
- **gpx_simplify_crosstrack.sh :**   Simplify track within an error limit.
- **gpx_to_csv.sh              :**   Convert track gpx to csv
- **gpx_to_gdb.sh              :**   Convert gpx to gdb
- **gpx_to_gpx.sh              :**   Convert gpx to gpx
- **gpx_to_kml.sh              :**   Convert gpx to kml
- **kml_to_gdb.sh              :**   Convert kml to gdb
- **kml_to_gpx.sh              :**   Convert kml to gpx
- **kmz_to_gpx.sh              :**   Convert kmz to gpx, this is a lie
- **one_gps_track.sh           :**   Combine multiple gpx track files matching a pattern
- **tcx_to_gpx.sh              :**   Convert tcx to gpx



- Gpx files management (gpx_db)
	- Gather track point and waypoints for process
	- Clean, analyze, detect possible errors
	- Create summaries of problems
	- Create gridded aggregated data from all points for use in qgis

- Parse google location data (google_location)
    - **google_loc_export.R   :**   Export google location history to RDS
    - **google_loc_gpx_plot.R :**   Plot tracks from google, polar and other gps files
    - **google_loc_split.R    :**   Split google location history to smaller manageable files




*Suggestions and improvements are always welcome.*

*I use those regular, but they have their quirks, may broke and maybe superseded by other tools.*
