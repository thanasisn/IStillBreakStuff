#!/usr/bin/env bash
## created on 2024-03-11

#### enter description here

## Init
mkdir -p "/dev/shm/CONKY"
set +e
pids=()

## Parse data from GoldenGheetah data base
"$HOME/CODE/training_analysis/GC_data_proccess/GC_read_rides_db_json.R"
"$HOME/CODE/training_analysis/GC_data_proccess/GC_more_plots_rides_db.R"
"$HOME/CODE/training_analysis/GC_data_proccess/GC_conky_plots_rides_db.R"

## Create current plots

sleep 1 & pids+=($!)

wait "${pids[@]}"; pids=()
echo "Took $SECONDS seconds for $0 to complete"
exit 0
