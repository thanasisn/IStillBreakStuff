#!/usr/bin/gnuplot

set term png transparent size 290,200 enhanced font "Liberation Mono Bold" 13

now   = system('date -d "+1 minutes"   +"%s"')
start = system('date -d "-1 hours"     +"%s"')
start = system('date -d "-60 minutes"  +"%s"')

set xdata   time
set timefmt "%s"
set format x ""
set xrange  [start:now]
#set format x "%H:%M"
#set xtics autofreq 600

set xtics textcolor rgb "white"
set ytics textcolor rgb "white"
set xlabel "X" textcolor rgb "white"
set ylabel "Y" textcolor rgb "white"
set key textcolor rgb "white"
set key outside

set key horizontal samplen 0.4 font ',8'
set xtics font  ",8" 
set ytics font  ",7" 
set xtics rotate 90
unset xlabel
unset ylabel

set output "/dev/shm/CONKY/processes.png"

plot "/dev/shm/CONKY/logps.dat" using 1:3 t "Athan"   w lines linewidth 2 lt 3,\
     "/dev/shm/CONKY/logps.dat" using 1:4 t "Tasks"   w lines linewidth 2 lt 4

    # "/dev/shm/CONKY/logps.dat" using 1:2 t "Process" w lines linewidth 2 lt 2,\

