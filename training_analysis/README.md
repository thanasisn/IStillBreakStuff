
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


- **GC_plots_2.R                     :**   Golden Cheetah plots
- **GC_plots_3.R                     :**   Golden Cheetah plots
- **GC_plots.R                       :**   Golden Cheetah plots
- **GC_read_activities.R             :**   Golden Cheetah read activities summary directly
- **GC_read.R                        :**   Golden Cheetah read activities directly
- **GC_read_rides.R                  :**   Golden Cheetah read activities summary directly
- **GC_test_metrics_outliers.R       :**   Golden Cheetah detect outliers in metrics data
- **GC_test_metrics_pace_stats.R     :**   Golden Cheetah
- **GC_test_shoes_usage_duration.R   :**   Golden Cheetah plot shoes usage total duration vs total distance
- **GC_test_shoes_usage_timeseries.R :**   Golden Cheetah plot shoes usage total distance vs time
- **GC_test_shoes_usage_usage.R      :**   Golden Cheetah plot shoes usage total distance vs time
- **GC_test_target_estimation.R      :**   Golden Cheetah plot shoes usage total distance vs time
- **GC_test_target_load.R            :**   Golden Cheetah plot shoes usage total distance vs time






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
