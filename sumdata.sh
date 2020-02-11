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
SCALE=2      # side length of a bin in pixels
POLAR_RES=1  # polar RSSI plot grid size, in degrees

### END USER CONFIGURATION ###

# create intermediate file (each point on newline)
cat $LOG_DIR/log.dat | tr -d '\n' | sed 's/\]\[/\]\
\[/g' > $LOG_DIR/temp.dat

# sort by lat, lon, remove brackets
sort -k 2,3 $LOG_DIR/temp.dat | sed 's/\[ //g' | sed 's/\]//g' | tr -d ',' > $LOG_DIR/sort.dat

# find graph bounding box
MIN_LAT=$(head -n1 $LOG_DIR/sort.dat | cut -d ' ' -f1)
MAX_LAT=$(sort -nrk1 $LOG_DIR/sort.dat | head -n1 | cut -d ' ' -f1)
MIN_LON=$(sort -nk2 $LOG_DIR/sort.dat | head -n1 | cut -d ' ' -f2)
MAX_LON=$(sort -nrk2 $LOG_DIR/sort.dat | head -n1 | cut -d ' ' -f2)

# trim to proper decimal places
MIN_LAT=$(printf "%3.2f" $MIN_LAT)
MAX_LAT=$(printf "%3.2f" $MAX_LAT)
MIN_LON=$(printf "%3.2f" $MIN_LON)
MAX_LON=$(printf "%3.2f" $MAX_LON)

# calculate span of lat,lon
LATSPAN=$(awk "BEGIN { print int(sqrt(($MAX_LAT - $MIN_LAT)^2)*$SCALE*100 + 90) }")
LONSPAN=$(awk "BEGIN { print int(sqrt(($MAX_LON - $MIN_LON)^2)*$SCALE*100 + 220) }")

# calculate margins
BMAR=$(awk "BEGIN { print 75/$LATSPAN }")
TMAR=$(awk "BEGIN { print 1-15/$LATSPAN }")
LMAR=$(awk "BEGIN { print 90/$LONSPAN }")
RMAR=$(awk "BEGIN { print 1-130/$LONSPAN }")

# iterate over min,max grid, output one line per point appended to sorted file
for i in $(seq -f "%3.2f" $MIN_LAT 0.01 $MAX_LAT); do
  for j in $(seq -f "%3.2f" $MIN_LON 0.01 $MAX_LON); do
    printf "%3.2f %3.2f \n" $i $j >> $LOG_DIR/sort.dat
  done
done

# nix altitude data, trim to 2 dec, count repeats (end up with 1 extra pt. ea)
awk '{printf("%3.2f %3.2f \n", $1, $2)}' $LOG_DIR/sort.dat | sort -k 1,2 | uniq -c -w 13 | awk '{printf("%3.2f %3.2f %.0f\n", $2, $3, $1)}' | awk 'NR>1 && $1!=p { print "" }{ p=$1 } 1' > $LOG_DIR/rect.dat

# plot rectangular heatmap file in gnuplot
gnuplot <<- EOF 
set xlabel "Longitude"
set ylabel "Latitude"
set key noautotitle
set style data lines
set pointsize 3 
set pm3d map
set term png size $LONSPAN,$LATSPAN
set bmargin at screen $BMAR
set tmargin at screen $TMAR
set lmargin at screen $LMAR
set rmargin at screen $RMAR
set logscale cb
set cbrange [0:10000]
set autoscale xfix
set autoscale yfix
set output "$LOG_DIR/rect.png"
set palette defined (0 0 0 0.5, 1 0 0 1, 2 0 0.5 1, 3 0 1 1, 4 0.5 1 0.5, 5 1 1 0, 6 1 0.5 0, 7 1 0 0, 8 0.5 0 0)
splot '$LOG_DIR/rect.dat' using 2:1:(\$3 - 1) with pm3d, '$LOG_DIR/receiver.dat' using 2:1:3 with points pointtype 3 linecolor rgb "white" linewidth 2, '$LOG_DIR/receiver.dat' using 2:1:3 with points pointtype 3 linecolor rgb "black" linewidth 1
EOF


