#!/usr/bin/env bash

exec 9>"/dev/shm/$(basename $0).lock"
if ! flock -n 9  ; then
    echo "another instance of $0 is running";
    exit 1
fi

ldir="/tmp/data_streams/"
mkdir -p "$ldir"
LOG_FILE="$ldir/$(basename "$0")_$(date +%F_%R).log"
ERR_FILE="$ldir/$(basename "$0")_$(date +%F_%R).err"
exec  > >(tee -i "${LOG_FILE}")
exec 2> >(tee -i "${ERR_FILE}" >&2)

SCRIPT="$(basename "$0")"

info() { echo ; echo "$(date +'%F %T') ::${SCRIPT}:: $* ::" ; echo ; }

echo "###################################"
echo "####    $(date +"%F %T")    ####"
echo "###################################"

## ignore errors
set +e
pids=()


(
  info "##  W01_location_forecast.R  ##"
  Rscript -e "rmarkdown::render('~/CODE/data_streams/weather/W01_location_forecast.R',
                  output_format = 'html_document',
                  output_dir    = '~/Formal/REPORTS')"
  info "##  End W01_location_forecast.R  STATUS:$?  ##"
) & pids+=($!)


(
  sleep 1
  info "##  W02_LAP_Davis.R  ##"
  Rscript -e "rmarkdown::render('~/CODE/data_streams/weather/W02_LAP_Davis.R',
                  output_format = 'html_document',
                  output_dir    = '~/Formal/REPORTS')"
  info "##  End W02_LAP_Davis.R  STATUS:$?  ##"
) & pids+=($!)


(
  sleep 2
  info "##  C01_taplog_plot.R  ##"
  Rscript -e "rmarkdown::render('~/CODE/data_streams/car/C01_taplog_plot.R',
                  output_format = 'html_document',
                  output_dir    = '~/Formal/REPORTS')"
  info "##  End C01_taplog_plot.R  STATUS:$?  ##"
) & pids+=($!)



(
  sleep 3
  script="$HOME/CODE/data_streams/fi_analysis/M01_get_noa_mail.R"
  info "##  $(basename $script)  ##"
  "$script"
  info "##  End $(basename $script) STATUS:$?  ##"

  script="$HOME/CODE/data_streams/fi_analysis/M02_parse_data.R"
  info "##  $(basename $script)  ##"
  "$script"
  info "##  End $(basename $script) STATUS:$?  ##"
) & pids+=($!)


(
  sleep 4
  script="$HOME/CODE/data_streams/fi_analysis/S01_peiraios_syn.R"
  info "##  $(basename $script)  ##"
  "$script"
  info "##  End $(basename $script) STATUS:$?  ##"
) & pids+=($!)

(
  sleep 5
  script="$HOME/CODE/data_streams/fi_analysis/S02_trel_gol.R"
  info "##  $(basename $script)  ##"
  "$script"
  info "##  End $(basename $script) STATUS:$?  ##"
) & pids+=($!)

(
  sleep 6
  script="$HOME/CODE/data_streams/fi_analysis/S03_pdma.R"
  info "##  $(basename $script)  ##"
  "$script"
  info "##  End $(basename $script) STATUS:$?  ##"
) & pids+=($!)

(
  sleep 7
  script="$HOME/CODE/data_streams/fi_analysis/S04_tsig.R"
  info "##  $(basename $script)  ##"
  "$script"
  info "##  End $(basename $script) STATUS:$?  ##"
) & pids+=($!)

(
  sleep 8
  script="$HOME/CODE/data_streams/fi_analysis/S05_get_winbank_zip_noa.py"
  info "##  $(basename $script)  ##"
  "$script"
  info "##  End $(basename $script) STATUS:$?  ##"

  script="$HOME/CODE/data_streams/fi_analysis/S06_parse_winbank_csv.R"
  info "##  $(basename $script)  ##"
  "$script"
  info "##  End $(basename $script) STATUS:$?  ##"

) & pids+=($!)

(
  sleep 9
  info "##  M7_utilities.R  ##"
  Rscript -e "rmarkdown::render('~/CODE/data_streams/house/H01_utilities.R',
                  output_format = 'html_document',
                  output_dir    = '~/Formal/REPORTS')"
  info "##  End  M7_utilities.R  STATUS:$?  ##"
) & pids+=($!)

wait "${pids[@]}"; pids=()





##  Parse data  ----------------------------------------------------------------
(
  script="$HOME/CODE/data_streams/fi_analysis/M04_alerts.R"
  info "##  $(basename $script)  ##"
  "$script"
  info "##  End $(basename $script) STATUS:$?  ##"
) & pids+=($!)

(
  sleep 0.1
  script="$HOME/CODE/data_streams/fi_analysis/M05_exports.R"
  info "##  $(basename $script)  ##"
  "$script"
  info "##  End $(basename $script) STATUS:$?  ##"
) & pids+=($!)

(
  sleep 0.2
  script="$HOME/CODE/data_streams/fi_analysis/M06_conky_plot.R"
  info "##  $(basename $script)  ##"
  "$script"
  info "##  End $(basename $script) STATUS:$?  ##"
) & pids+=($!)

wait "${pids[@]}"; pids=()




##  Data display scripts  ------------------------------------------------------
(
  info "##  M3_plots.R  ##"
  Rscript -e "rmarkdown::render('~/CODE/data_streams/fi_analysis/M03_plots.R',
                  output_format = 'html_document',
                  output_dir    = '~/Formal/REPORTS')"
  info "##  End  M3_plots.R STATUS:$?  ##"
) & pids+=($!)

(
  sleep 0.1
  info "##  F01_placements.R  ##"
  Rscript -e "rmarkdown::render('~/CODE/data_streams/fi_analysis/F01_placements.R',
                  output_format = 'html_document',
                  output_dir    = '~/Formal/REPORTS')"
  info "##  End  F01_placements.R  STATUS:$?  ##"
) & pids+=($!)

(
  sleep 0.2
  info "##  F02_bonds.R  ##"
  Rscript -e "rmarkdown::render('~/CODE/data_streams/fi_analysis/F02_bonds.R',
                  output_format = 'html_document',
                  output_dir    = '~/Formal/REPORTS')"
  info "##  End  F02_bonds.R  STATUS:$?  ##"
) & pids+=($!)

(
  sleep 0.3
  info "##  F03_comod.R  ##"
  Rscript -e "rmarkdown::render('~/CODE/data_streams/fi_analysis/F03_comod.R',
                  output_format = 'html_document',
                  output_dir    = '~/Formal/REPORTS')"
  info "##  End  F03_comod.R  STATUS:$?  ##"
) & pids+=($!)


(
  sleep 0.4
  info "##  F04_zero.R  ##"
  Rscript -e "rmarkdown::render('~/CODE/data_streams/fi_analysis/F04_zero.R',
                  output_format = 'html_document',
                  output_dir    = '~/Formal/REPORTS')"
  info "##  End  F04_zero.R  STATUS:$?  ##"
) & pids+=($!)



(
  sleep 0.6
  info "##  C02_CarScannerParse.R  ##"
  Rscript -e "rmarkdown::render('~/CODE/data_streams/car/C02_CarScannerParse.R',
                  output_format = 'html_document',
                  output_dir    = '~/Formal/REPORTS')"
  info "##  End  C02_CarScannerParse.R  STATUS:$?  ##"
) & ## don't wait


wait "${pids[@]}"; pids=()


exit

##  Summary  -------------------------------------------------------------------
(
  info "##  F09_Dashboard.Rmd  ##"
  Rscript -e "rmarkdown::render('~/CODE/fi_analysis/F09_Dashboard.Rmd',
                  output_dir    = '~/Formal/REPORTS')"
  info "##  End  F09_Dashboard.Rmd  STATUS:$?  ##"
)


info "##    END $0    ##"
dura="$( echo "scale=6; ($SECONDS)/60" | bc)"
printf "%s %-10s %-10s %-10s %f\n" "$(date +"%F %H:%M:%S")" "$HOSTNAME" "$USER" "$(basename $0)" "$dura"
exit 0
