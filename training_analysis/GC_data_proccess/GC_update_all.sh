#!/usr/bin/env bash
## created on 2024-03-11

#### Run all regular data proccess for GoldenCheetah

## Init
mkdir -p "/dev/shm/CONKY"
set +e
pids=()

## Parse data and plot data from GoldenGheetah
"$HOME/CODE/training_analysis/GC_data_proccess/GC_read_rides_db_json.R"
"$HOME/CODE/training_analysis/GC_data_proccess/GC_more_plots_rides_db.R"
"$HOME/CODE/training_analysis/GC_data_proccess/GC_conky_plots_rides_db.R"

# todo
"/home/athan/CODE/training_analysis/GC_data_proccess/GC_shoes_usage_duration.R"

sleep 1 & pids+=($!)

wait "${pids[@]}"; pids=()
echo "Took $SECONDS seconds for $0 to complete"
exit 0
