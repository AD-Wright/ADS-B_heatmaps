#!/bin/bash

# filename: sumdata.sh
###############################################################################
#                                                                             #
#   ADS-B_heatmaps: Collection of Linux Scripts for ADS-B data visualization  #
#  Coded by A.D. Wright - GPLv3 License - github.com/AD-Wright/ADS-B_heatmaps #
#                                                                             #
###############################################################################

### USER CONFIGURATION ###
# installed directory (update after installation)
INSTALL_DIR=~/Documents/Gits/ADS-B_heatmaps
LOG_DIR=$INSTALL_DIR/log  # directory needs to exist or script will fail

# plot binning configuration
POLAR_RES=1  # polar RSSI plot grid size, in degrees

### END USER CONFIGURATION ###

# create intermediate file (each point on newline)
cat $LOG_DIR/log.dat | tr -d '\n' | sed 's/\]\[/\]\
\[/g' > $LOG_DIR/temp.dat

# sort by lat, lon, remove brackets
sort -k 2,3 $LOG_DIR/temp.dat | sed 's/\[ //g' | sed 's/\]//g' > $LOG_DIR/sorted.dat

# prep rectangular heatmap file for gnuplot (nix altitude data, trim to 2 dec.)
awk '{printf("%3.2f %3.2f \n", $1, $2)}' $LOG_DIR/sorted.dat | uniq -c -w 13 | awk '{printf("%3.2f %3.2f %.0f\n", $2, $3, $1)}' > $LOG_DIR/rect.dat
#awk '{printf("%3.2f %3.2f %.0f\n", $1, $2, 1)}' $LOG_DIR/sorted.dat > $LOG_DIR/rect.dat

# plot rectangular heatmap file in gnuplot
gnuplot <<- EOF 
set xlabel "Longitude"
set ylabel "Latitude"
set key noautotitle
set view map
set dgrid3d 500,500, box kdensity2d 0.01,0.01
set style data lines
set pointsize 3 
set pm3d
set term png
set logscale cb
set cbrange [0:10000]
set autoscale xfix
set autoscale yfix
set output "$LOG_DIR/rect.png"
set palette defined (0 0 0 0.5, 1 0 0 1, 2 0 0.5 1, 3 0 1 1, 4 0.5 1 0.5, 5 1 1 0, 6 1 0.5 0, 7 1 0 0, 8 0.5 0 0)
splot '$LOG_DIR/rect.dat' using 2:1:3 with pm3d, '$LOG_DIR/receiver.dat' using 2:1:3 with points pointtype 3
EOF

