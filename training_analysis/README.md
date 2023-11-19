
# training_analysis

Tools for processing my training data.

Training load analysis and other statistics.
Implementing human performance models like TSB/PMC, Banister, Busso.

Output of graphs for desktop with conky, smartphone as background image,
pdf for computer and smartphone and maybe an html page. Everything is meant to
run periodically and the output is send to appropriate location/device.

The main training focus is endurance and long distances, in running, hiking and biking.

I use [GoldenCheetach](https://www.goldencheetah.org/) to manage training data,
but may read them directly also.

Data sources over the years are: Fenix 6x, etrex 30x, Polar rs800cx and other random GPS devices.


- **GAR_read_download.R              :**   Read data from Garmin Connect data dump
- **GC_conky_plots_rides_db.R        :**   Golden Cheetah plots for desktop with conky
- **GC_export_rides.R                :**   Golden Cheetach get activities from a running instance of GC
- **GC_more_plots_rides_db.R         :**   Human Performance plots and data for GC data for different uses
- **GC_read_activities_json.R        :**   Golden Cheetah read activities summary directly from individual files
- **GC_read_activities.R             :**   Golden Cheetah read activities summary directly
- **GC_read.R                        :**   Golden Cheetah read activities directly
- **GC_read_rides_db_json.R          :**   Golden Cheetah read activities summary directly from rideDB.json
- **GC_test_metrics_outliers.R       :**   Golden Cheetah detect outliers in metrics data
- **GC_test_metrics_pace_stats.R     :**   Golden Cheetah
- **GC_test_shoes_usage_duration.R   :**   Golden Cheetah plot shoes usage total duration vs total distance
- **GC_test_shoes_usage_timeseries.R :**   Golden Cheetah plot shoes usage total distance vs time
- **GC_test_shoes_usage_usage.R      :**   Golden Cheetah plot shoes usage total distance vs time
- **GC_test_target_estimation.R      :**   Golden Cheetah plot total trends
- **GC_test_target_load.R            :**   Golden Cheetah plot training load yearly summary
- **HRV_gather_GC.R                  :**   Parse HRV_monitor exported data
- **HRV_monitor_parse.R              :**   Parse HRV_monitor exported data


## Some references 

- [fellrnr/Modeling Human Performance](https://fellrnr.com/wiki/Modeling_Human_Performance)
- [ATL, CTL & TSB](https://ianbarrington.com/2007/03/02/atl-ctl-tsb-explained/)
- [Measuring Training Stress](https://run.wxm.be/notes/measuring-training-stress.html)
- [TRIMP Stress in GoldenCheetah](https://run.wxm.be/2020/11/07/trimp-stress-in-goldencheetah.html)
- [Scaled Heart Rate Impulse - SHRIMP](https://andrewcooke.github.io/choochoo/impulse.html)
- [Banister Impulse~Response Model in R](https://complementarytraining.net/banister-impulseresponse-model-in-r/)
- [Fitting impulse~response models in R](https://wintherperformance.netlify.app/post/banister-model/)


*Suggestions and improvements are always welcome.*

*I use those regular, but they have their quirks, may broke and maybe superseded by other tools.*
