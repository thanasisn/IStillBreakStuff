#!/usr/bin/env bash
## created on 2023-07-04

# watchdog process
mainpid=$$
(sleep $((60*1)); kill $mainpid > /dev/null 2>&1 ) &
watchdogpid=$!
# make sure we got destination
outputdir="/dev/shm/CONKY/"
mkdir -p "$outputdir"

rrds="/var/lib/munin/"

goback=$((16*60*60))
width="550"
heigth="180"
xgrid="MINUTE:15:HOUR:1:HOUR:2:0:%Hh"
col_fonts="#909090"

## with transparency
col_canvas="#00000000"
col_back="#00000000"

## hosts colors and alpha in hex
opf="BB"
col_crane="#FF7F0E${opf}"
col_blue="#1F77B4${opf}"
col_tyler="#2CA02C${opf}"
col_kostas="#8C564B${opf}"
col_yperos="#9467BD${opf}"
col_sagan="#B3E346${opf}"

## Plot loads

# --logarithmic                                                   \
# --units-exponent  1                                                 \
# --x-grid MINUTE:15:HOUR:1:HOUR:2:0:%H:%M                            \

rrdtool graph "${outputdir}load_graph.png"                              \
    -v "Load"                                                           \
    -w $width                                                           \
    -h $heigth                                                          \
    -a PNG                                                              \
    --font   TITLE:12                                                   \
    --font    UNIT:12                                                   \
    --font    AXIS:9                                                    \
    --font  LEGEND:9                                                    \
    --color CANVAS$col_canvas -c BACK$col_back -c FONT$col_fonts        \
    --start -$goback --end now                                          \
    --slope-mode                                                        \
    --logarithmic                                                       \
    --x-grid            ${xgrid}                                        \
    --lower-limit       0.01 --rigid                                    \
    --units-length      4                                               \
    --right-axis        1:0                                             \
    --right-axis-format %0.2lf                                          \
    --right-axis-format %0.2lf                                          \
    --border 0                                                          \
    --disable-rrdtool-tag                                               \
    DEF:bluel1="/var/lib/munin/blue/blue-load-load-g.rrd":42:MAX        \
    CDEF:bluel1n=bluel1,2,/      LINE3:bluel1n${col_blue}:"blue"        \
    DEF:sagan1="/var/lib/munin/sagan/sagan-load-load-g.rrd":42:MAX      \
    CDEF:saganl1n=sagan1,12,/    LINE3:saganl1n${col_sagan}:"sagan"     \
    DEF:tylerl1="/var/lib/munin/tyler/tyler-load-load-g.rrd":42:MAX     \
    CDEF:tylerl1n=tylerl1,4,/    LINE3:tylerl1n${col_tyler}:"tyler"     \

#    DEF:yperos1="/var/lib/munin/yperos/yperos-load-load-g.rrd":42:MAX   \
#    CDEF:yperosl1n=yperos1,32,/  LINE3:yperosl1n${col_yperos}:"yperos"  \

rrdtool graph "${outputdir}total_processes_graph.png"                           \
    -v "Processes"                                                              \
    -w $width                                                                   \
    -h $heigth                                                                  \
    -a PNG                                                                      \
    --font   TITLE:12                                                           \
    --font    UNIT:12                                                           \
    --font    AXIS:9                                                            \
    --font  LEGEND:9                                                            \
    --color CANVAS$col_canvas -c BACK$col_back -c FONT$col_fonts                \
    --start -$goback --end now                                                  \
    --slope-mode                                                                \
    --x-grid            ${xgrid}                                                \
    --units-length      3                                                       \
    --right-axis        1:0                                                     \
    --right-axis-format %3.0lf                                                  \
    --border 0                                                                  \
    --disable-rrdtool-tag                                                       \
    DEF:bluel1="/var/lib/munin/blue/blue-processes-processes-g.rrd":42:MAX      \
    CDEF:bluel1n=bluel1     LINE2:bluel1n${col_blue}:"blue"                     \
    DEF:sagan1="/var/lib/munin/sagan/sagan-processes-processes-g.rrd":42:MAX    \
    CDEF:saganl1n=sagan1    LINE2:saganl1n${col_sagan}:"sagan"                  \
    DEF:tylerl4="/var/lib/munin/tyler/tyler-processes-processes-g.rrd":42:MAX   \
    CDEF:tylerl1n=tylerl4   LINE2:tylerl1n${col_tyler}:"tyler"                  \
  

#     DEF:yperos1="/var/lib/munin/yperos/yperos-processes-processes-g.rrd":42:MAX \
#     CDEF:yperosl1n=yperos1  LINE2:yperosl1n${col_yperos}:"yperos"               \

rrdtool graph "${outputdir}running_processes_graph.png"                        \
    -v "Running Processes"                                                     \
    -w $width                                                                  \
    -h $heigth                                                                 \
    -a PNG                                                                     \
    --font   TITLE:12                                                          \
    --font    UNIT:12                                                          \
    --font    AXIS:9                                                           \
    --font  LEGEND:9                                                           \
    --color CANVAS$col_canvas -c BACK$col_back -c FONT$col_fonts               \
    --start -$goback --end now                                                 \
    --slope-mode                                                               \
    --logarithmic                                                              \
    --x-grid            ${xgrid}                                               \
    --lower-limit       0.9 --rigid                                            \
    --units-length      3                                                      \
    --right-axis        1:0                                                    \
    --right-axis-format %3.0lf                                                 \
    --border 0                                                                 \
    --disable-rrdtool-tag                                                      \
    DEF:bluel1="/var/lib/munin/blue/blue-processes-runnable-g.rrd":42:MAX      \
    CDEF:bluel1n=bluel1     LINE2:bluel1n${col_blue}:"blue"                    \
    DEF:sagan1="/var/lib/munin/sagan/sagan-processes-runnable-g.rrd":42:MAX    \
    CDEF:saganl1n=sagan1    LINE2:saganl1n${col_sagan}:"sagan"                 \
    DEF:tylerl5="/var/lib/munin/tyler/tyler-processes-runnable-g.rrd":42:MAX   \
    CDEF:tylerl1n=tylerl5   LINE2:tylerl1n${col_tyler}:"tyler"                 \

#     DEF:yperos1="/var/lib/munin/yperos/yperos-processes-runnable-g.rrd":42:MAX \
#     CDEF:yperosl1n=yperos1  LINE2:yperosl1n${col_yperos}:"yperos"              \

rrdtool graph "${outputdir}usage_graph.png"                                  \
    -v "Usage"                                                               \
    -w $width                                                                \
    -h $heigth                                                               \
    -a PNG                                                                   \
    --font   TITLE:12                                                        \
    --font    UNIT:12                                                        \
    --font    AXIS:9                                                         \
    --font  LEGEND:9                                                         \
    --color CANVAS$col_canvas -c BACK$col_back -c FONT$col_fonts             \
    --start -$goback --end now                                               \
    --slope-mode                                                             \
    --x-grid            ${xgrid}                                             \
    --units-length      3                                                    \
    --right-axis        1:0                                                  \
    --right-axis-format %3.0lf                                               \
    --border 0                                                               \
    --disable-rrdtool-tag                                                    \
    DEF:bluel1="/var/lib/munin/blue/blue-cpu-idle-d.rrd":42:MAX              \
    CDEF:bluel1n=100,bluel1,2,/,-      LINE3:bluel1n${col_blue}:"blue"       \
    DEF:sagan1="/var/lib/munin/sagan/sagan-cpu-idle-d.rrd":42:MAX            \
    CDEF:saganl1n=100,sagan1,12,/,-   LINE3:saganl1n${col_sagan}:"sagan"     \
    DEF:tylerl1="/var/lib/munin/tyler/tyler-cpu-idle-d.rrd":42:MAX           \
    CDEF:tylerl1n=100,tylerl1,4,/,-    LINE3:tylerl1n${col_tyler}:"tyler"    \


    # DEF:yperos1="/var/lib/munin/yperos/yperos-cpu-idle-d.rrd":42:MAX         \
    # CDEF:yperosl1n=100,yperos1,32,/,-  LINE3:yperosl1n${col_yperos}:"yperos" \
#     DEF:bluel1="/var/lib/munin/blue/blue-load-load-g.rrd":42:MAX        \
#     CDEF:bluel1n=bluel1,2,/      LINE3:bluel1n${col_blue}:"blue"        \
#     DEF:yperos1="/var/lib/munin/yperos/yperos-load-load-g.rrd":42:MAX   \
#     CDEF:yperosl1n=yperos1,32,/  LINE3:yperosl1n${col_yperos}:"yperos"  \
#     DEF:sagan1="/var/lib/munin/sagan/sagan-load-load-g.rrd":42:MAX      \
#     CDEF:saganl1n=sagan1,12,/    LINE3:saganl1n${col_sagan}:"sagan"     \



# rrdtool graph "${outputdir}load_graph.png"                          \
#     -t "1-min Load normalized"                                      \
#     -w $width                                                       \
#     -h $heigth                                                      \
#     -a PNG                                                          \
#     --font  TITLE:12                                                \
#     --font   AXIS:9                                                 \
#     --font LEGEND:9                                                 \
#     --color CANVAS$col_canvas -c BACK$col_back -c FONT$col_fonts    \
#     --start -$goback --end now                                      \
#     --slope-mode                                                    \
#     --x-grid MINUTE:10:HOUR:1:HOUR:1:0:%H:%M                        \
#     --grid-dash 1:12                                                \
#     --lower-limit 0 --rigid                                         \
#     --right-axis 1:0                                                \
#     --right-axis-format %0.1lf                                      \
#     --left-axis-format  %3.1lf \
#     --border 0                                                      \
#     --disable-rrdtool-tag                                           \
#     DEF:kostasl1="${rrds}/kostas/load/load.rrd":shortterm:AVERAGE            \
#     CDEF:kostasl1n=kostasl1,4,/   LINE3:kostasl1n${col_kostas}:"kostas"      \
#     DEF:greenl1="${rrds}/green/load/load.rrd":shortterm:AVERAGE              \
#     CDEF:greenl1n=greenl1,2,/     LINE3:greenl1n${col_green}:"green"         \
#     DEF:purplel1="${rrds}/purple/load/load.rrd":shortterm:AVERAGE            \
#     CDEF:purplel1n=purplel1,4,/   LINE3:purplel1n${col_purple}:"purple"      \
#     DEF:bluel1="${rrds}/blue/load/load.rrd":shortterm:AVERAGE                \
#     CDEF:bluel1n=bluel1,2,/       LINE3:bluel1n${col_blue}:"blue"            \
#     DEF:cranel1="${rrds}/crane.lan/load/load.rrd":shortterm:AVERAGE          \
#     CDEF:cranel1n=cranel1,4,/     LINE3:cranel1n${col_crane}:"crane"         \
#     DEF:saganl1="${rrds}/sagan/load/load.rrd":shortterm:AVERAGE              \
#     CDEF:saganl1n=saganl1,12,/    LINE3:saganl1n${col_sagan}:"sagan"         \

#     --grid-dash 1:2                                                 \
#     --left-axis-format %0.1lf                                       \
#     --logarithmic                                                   \
#     --lower-limit 0.2 --rigid                                       \
#     --right-axis 1:0                                                \
#     --right-axis-format %0.1lf                                      \
#     --use-nan-for-all-missing-data                                  \
#     --y-grid  0.1:2                                                 \




exit

rrdtool graph "${outputdir}hdd_temp.png"                            \
    -v "hdd Temperatures"                                           \
    -w $width                                                       \
    -h $heigth                                                      \
    -a PNG                                                          \
    --font  TITLE:12                                                \
    --font   UNIT:12                                                \
    --font   AXIS:9                                                 \
    --font LEGEND:9                                                 \
    --color CANVAS$col_canvas -c BACK$col_back -c FONT$col_fonts    \
    --start -$goback --end now                                      \
    --slope-mode                                                    \
    --units-length 1                                                \
    --x-grid MINUTE:10:HOUR:1:HOUR:1:0:%H:%M                        \
    --grid-dash 1:5                                                 \
    --right-axis 1:0                                                \
    --right-axis-format %2.0lf                                      \
    --border 0                                                      \
    --disable-rrdtool-tag                                           \
    DEF:kostasd1="${rrds}/kostas/hddtemp/temperature-sda.rrd":value:MAX    LINE3:kostasd1${col_kostas}:"kostas"  \
    DEF:greend1="${rrds}/green/hddtemp/temperature-sda.rrd":value:MAX      LINE3:greend1${col_green}:"green"     \
    DEF:blued1="${rrds}/blue/hddtemp/temperature-sda.rrd":value:MAX        LINE3:blued1${col_blue}:"blue"        \
    DEF:blued2="${rrds}/blue/hddtemp/temperature-sdb.rrd":value:MAX        LINE3:blued2${col_blue}:""            \
    DEF:craned1="${rrds}/crane.lan/hddtemp/temperature-sda.rrd":value:MAX  LINE3:craned1${col_crane}:"crane"     \
    DEF:craned2="${rrds}/crane.lan/hddtemp/temperature-sdb.rrd":value:MAX  LINE3:craned2${col_crane}:""          \
    DEF:sagand1="${rrds}/sagan/hddtemp/temperature-sda.rrd":value:MAX      LINE3:sagand1${col_sagan}:"sagan"     \
    DEF:sagand2="${rrds}/sagan/hddtemp/temperature-sdb.rrd":value:MAX      LINE3:sagand2${col_sagan}:""          \

#     DEF:blued3="${rrds}/blue/hddtemp/temperature-sdc.rrd":value:MAX          LINE2:blued3${col_blue}:""                 \
#     DEF:blued4="${rrds}/blue/hddtemp/temperature-sdd.rrd":value:MAX          LINE2:blued4${col_blue}:""                 \


# opf="78"
# col_crane="#FF7F0E${opf}"
# col_blue="#1F77B4${opf}"
# col_green="#2CA02C${opf}"
# col_kostas="#8C564B${opf}"
# col_purple="#9467BD${opf}"
# col_sagan="#B3E346${opf}"
#


rrdtool graph "${outputdir}cpu_temp.png"                            \
    -v "Core Temperatures"                                          \
    -w $width                                                       \
    -h $heigth                                                      \
    -a PNG                                                          \
    --font  TITLE:12                                                \
    --font   UNIT:12                                                \
    --font   AXIS:10                                                \
    --font LEGEND:9                                                 \
    --color CANVAS$col_canvas -c BACK$col_back -c FONT$col_fonts    \
    --start -$goback --end now                                      \
    --slope-mode                                                    \
    --left-axis-format %2.0lf                                       \
    --units-length 1                                                \
    --x-grid MINUTE:10:HOUR:1:HOUR:1:0:%H:%M                        \
    --grid-dash 1:5                                                 \
    --right-axis 1:0                                                \
    --right-axis-format %2.0lf                                      \
    --border 0                                                      \
    --disable-rrdtool-tag                                           \
    DEF:kostasc1="${rrds}/kostas/sensors-coretemp-isa-0000/temperature-temp2.rrd":value:MAX                                                    \
    DEF:kostasc2="${rrds}/kostas/sensors-coretemp-isa-0000/temperature-temp3.rrd":value:MAX                                                    \
    DEF:kostasc3="${rrds}/kostas/sensors-coretemp-isa-0000/temperature-temp4.rrd":value:MAX                                                    \
    DEF:kostasc4="${rrds}/kostas/sensors-coretemp-isa-0000/temperature-temp4.rrd":value:MAX                                                    \
    DEF:kostasc5="${rrds}/kostas/sensors-it8718-isa-0290/temperature-temp1.rrd":value:MAX                                                      \
    DEF:kostasc6="${rrds}/kostas/sensors-it8718-isa-0290/temperature-temp2.rrd":value:MAX                                                      \
    CDEF:maxcoreK=kostasc1,kostasc2,MAXNAN,kostasc3,MAXNAN,kostasc4,MAXNAN                            LINE3:maxcoreK${col_kostas}:"kostas"     \
    DEF:tylerc1="${rrds}/tyler/sensors-coretemp-isa-0000/temperature-temp1.rrd":value:MAX                                                      \
    DEF:tylerc2="${rrds}/tyler/sensors-coretemp-isa-0000/temperature-temp2.rrd":value:MAX                                                      \
    DEF:tylerc3="${rrds}/tyler/sensors-coretemp-isa-0000/temperature-temp3.rrd":value:MAX                                                      \
    CDEF:maxcoreG=tylerc1,tylerc2,MAXNAN,tylerc3,MAXNAN                                               LINE3:maxcoreG${col_green}:"tyler"       \
    DEF:bluec1="${rrds}/blue/sensors-coretemp-isa-0000/temperature-temp1.rrd":value:MAX                                                        \
    DEF:bluec2="${rrds}/blue/sensors-coretemp-isa-0000/temperature-temp2.rrd":value:MAX                                                        \
    DEF:bluec3="${rrds}/blue/sensors-coretemp-isa-0000/temperature-temp3.rrd":value:MAX                                                        \
    DEF:bluec4="${rrds}/blue/thermal-thermal_zone0/temperature.rrd":value:MAX                                                                  \
    CDEF:maxcoreB=bluec1,bluec2,MAXNAN,bluec3,MAXNAN,bluec4,MAXNAN                                    LINE3:maxcoreB${col_blue}:"blue"         \
    DEF:cranec1="${rrds}/crane.lan/sensors-coretemp-isa-0000/temperature-temp2.rrd":value:MAX                                                  \
    DEF:cranec2="${rrds}/crane.lan/sensors-coretemp-isa-0000/temperature-temp3.rrd":value:MAX                                                  \
    DEF:cranec3="${rrds}/crane.lan/sensors-coretemp-isa-0000/temperature-temp1.rrd":value:MAX                                                  \
    DEF:cranec4="${rrds}/crane.lan/sensors-acpitz-virtual-0/temperature-temp1.rrd":value:MAX                                                   \
    DEF:cranec5="${rrds}/crane.lan/thermal-thermal_zone0/temperature.rrd":value:MAX                                                            \
    DEF:cranec6="${rrds}/crane.lan/thermal-thermal_zone2/temperature.rrd":value:MAX                                                            \
    CDEF:maxcoreC=cranec1,cranec2,MAXNAN,cranec3,MAXNAN,cranec4,MAXNAN,cranec5,MAXNAN,cranec6,MAXNAN  LINE3:maxcoreC${col_crane}:"crane"       \
    DEF:saganc1="${rrds}/sagan/sensors-coretemp-isa-0000/temperature-temp1.rrd":value:MAX                                                      \
    DEF:saganc2="${rrds}/sagan/sensors-coretemp-isa-0000/temperature-temp2.rrd":value:MAX                                                      \
    DEF:saganc3="${rrds}/sagan/sensors-coretemp-isa-0000/temperature-temp3.rrd":value:MAX                                                      \
    DEF:saganc4="${rrds}/sagan/sensors-coretemp-isa-0000/temperature-temp4.rrd":value:MAX                                                      \
    DEF:saganc5="${rrds}/sagan/sensors-coretemp-isa-0000/temperature-temp5.rrd":value:MAX                                                      \
    DEF:saganc6="${rrds}/sagan/sensors-coretemp-isa-0000/temperature-temp6.rrd":value:MAX                                                      \
    DEF:saganc7="${rrds}/sagan/sensors-coretemp-isa-0000/temperature-temp7.rrd":value:MAX                                                      \
    DEF:saganc8="${rrds}/sagan/thermal-thermal_zone0/temperature.rrd":value:MAX                                                                \
    DEF:saganc9="${rrds}/sagan/thermal-thermal_zone0/temperature.rrd":value:MAX                                                                \
    CDEF:maxcoreS=saganc1,saganc2,MAXNAN,saganc3,MAXNAN,saganc4,MAXNAN,saganc5,MAXNAN,saganc6,MAXNAN,saganc7,MAXNAN,saganc8,MAXNAN,saganc9,MAXNAN   LINE3:maxcoreS${col_sagan}:"sagan" \



#     rrdtool xport     --start -$goback --end now                                      \
#     DEF:saganc1="${rrds}/sagan/sensors-coretemp-isa-0000/temperature-temp1.rrd":value:MAX     LINE2:saganc1${col_sagan}:"sagan"          \
#     DEF:saganc2="${rrds}/sagan/sensors-coretemp-isa-0000/temperature-temp2.rrd":value:MAX         LINE2:saganc2${col_sagan}:""                 \
#     DEF:saganc3="${rrds}/sagan/sensors-coretemp-isa-0000/temperature-temp3.rrd":value:MAX         LINE2:saganc3${col_sagan}:""                 \
#     DEF:saganc4="${rrds}/sagan/sensors-coretemp-isa-0000/temperature-temp4.rrd":value:MAX         LINE2:saganc4${col_sagan}:""                 \
#     DEF:saganc5="${rrds}/sagan/sensors-coretemp-isa-0000/temperature-temp5.rrd":value:MAX         LINE2:saganc5${col_sagan}:""                 \
#     DEF:saganc6="${rrds}/sagan/sensors-coretemp-isa-0000/temperature-temp6.rrd":value:MAX         LINE2:saganc6${col_sagan}:""                 \
#     DEF:saganc7="${rrds}/sagan/sensors-coretemp-isa-0000/temperature-temp7.rrd":value:MAX         LINE2:saganc7${col_sagan}:""                 \
#     DEF:saganc8="${rrds}/sagan/thermal-thermal_zone0/temperature.rrd":value:MAX                   LINE2:saganc8${col_sagan}:""                 \
#     DEF:saganc9="${rrds}/sagan/thermal-thermal_zone0/temperature.rrd":value:MAX                   LINE2:saganc9${col_sagan}:""                 \
#     CDEF:maxcore=saganc1,saganc2,MAXNAN,saganc3,MAXNAN \
#     XPORT:maxcore \
#     XPORT:saganc2 \



kill "$watchdogpid" > /dev/null 2>&1
exit 0


##########

convert ${outputdir}/cputemp.png \
	\( +clone -crop 160x80+0+190 \) -geometry +60+100 -composite \
	-crop 700x185+30+0 \
	${outputdir}/cputemp2.png

## move legneng
convert ${outputdir}/hddtemp.png \
	\( +clone -crop 170x60+0+190 \) -geometry +60+110 -composite \
	-crop 700x175+30+10 \
	${outputdir}/hddtemp2.png

convert ${outputdir}/cputemp2.png ${outputdir}/hddtemp2.png -append ${outputdir}/gangliatemps.png


