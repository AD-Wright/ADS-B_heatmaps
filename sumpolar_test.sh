#!/bin/bash

# filename: sumpolar_test.sh
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

### END USER CONFIGURATION ###

# create intermediate file (each point on newline), remove brackets
cat $LOG_DIR/log.dat | tr -d '\n' | sed 's/\]\[/\]\
\[/g' | sed 's/\[ //g' | sed 's/\]//g' | tr -d ',' > $LOG_DIR/temp.dat

# convert from WGS84 datum to azimuth, elevation angles (https://en.wikipedia.org/wiki/Geodetic_datum)
#temp.dat to converted.dat
# elevation first line, then azimuth, then RSSI






# define size of canvas
AZISPAN=$(awk "BEGIN { print 360*$SCALE + 90) }")
ELESPAN=$(awk "BEGIN { print 90*$SCALE + 220) }")

# calculate margins
BMAR=$(awk "BEGIN { print 75/$ELESPAN }")
TMAR=$(awk "BEGIN { print 1-15/$ELESPAN }")
LMAR=$(awk "BEGIN { print 90/$AZISPAN }")
RMAR=$(awk "BEGIN { print 1-130/$AZISPAN }")

# iterate over grid, output one line per point appended to sorted file
for i in $(seq -f "%3.0f" 0 1 90); do
  for j in $(seq -f "%3.0f" 0 1 360); do
    printf "%3.0f %3.0f \n" $i $j >> $LOG_DIR/converted.dat
  done
done

# find maximum RSSI at each point
awk '{printf("%03.f %03.f \n", $1, $2, $3)}' $LOG_DIR/converted.dat | sort  -r -k1 -k2 -k3 | awk '{if($i!=l1 && $2!=l2)print $0; l1=$1; l2=$2;}' | awk 'NR>1 && $1!=p { print "" }{ p=$1 } 1' > $LOG_DIR/polar.dat

# plot rectangular heatmap file in gnuplot
gnuplot <<- EOF 
set xlabel "Longitude"
set ylabel "Latitude"
set key noautotitle
set style data lines
set pointsize 3 
set pm3d map
set term png size $AZISPAN,$ELESPAN
set bmargin at screen $BMAR
set tmargin at screen $TMAR
set lmargin at screen $LMAR
set rmargin at screen $RMAR
set logscale cb
set cbrange [0:10000]
set autoscale xfix
set autoscale yfix
set output "$LOG_DIR/polar.png"
set palette defined (0 0 0 0.5, 1 0 0 1, 2 0 0.5 1, 3 0 1 1, 4 0.5 1 0.5, 5 1 1 0, 6 1 0.5 0, 7 1 0 0, 8 0.5 0 0)
splot '$LOG_DIR/polar.dat' using 1:2:(\$3 - 1) with pm3d
EOF


