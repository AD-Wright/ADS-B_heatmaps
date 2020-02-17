#!/bin/bash

# filename: sumpolar.sh
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
SCALE=4      # 4 recommended

### END USER CONFIGURATION ###

# create intermediate file (each point on newline), remove brackets
cat $LOG_DIR/log.dat | tr -d '\n' | sed 's/\]\[/\]\
\[/g' | sed 's/\[ //g' | sed 's/\]//g' | tr -d ',' > $LOG_DIR/temp.dat

# get receiver position, alt
RLAT=$(awk '{ var=$1 ; print var }' $LOG_DIR/receiver.dat )
RLON=$(awk '{ var=$2 ; print var }' $LOG_DIR/receiver.dat )
RALT=$(awk '{ var=$4 ; print var }' $LOG_DIR/receiver.dat )

# Convert delta in lat, lon, alt to elevation and azimuth
# working formulae, after much searching, found in https://raw.githubusercontent.com/caiusseverus/adsbcompare/master/polar.sh
awk -v rlat=$RLAT -v rlon=$RLON -v ralt=$RALT '
BEGIN {
PI = atan2(0,-1)
R = 20887680 
rlat = rlat * PI/180
rlon = rlon * PI/180
}
{
  lat = $1 * PI/180; lon = $2 * PI/180; alt = $3; rssi = $4;
  dlon = lon - rlon; dlat = lat - rlat;
  a = sin(dlat/2)^2 + cos(rlat) * cos(lat) * sin(dlon/2)^2;
  d = 2 * atan2(sqrt(a), sqrt(1-a)) * R;
  azi = 180/PI * atan2(sin(dlon * cos(lat)),cos(rlat)*sin(lat) - sin(rlat)*cos(lat)*cos(dlon));
  azi = (azi + 360) % 360;
  ele = 180/PI * atan2((alt - ralt) / d - d / (2 * R), 1);
  printf "%.1f %.1f %.1f %.0f %.0f\n", ele, azi, rssi, d, alt
}' $LOG_DIR/temp.dat > $LOG_DIR/converted.dat

# define size of canvas
AZISPAN=$(awk "BEGIN { print 360*$SCALE + 90 }" )
ELESPAN=$(awk "BEGIN { print 100*$SCALE + 220 }" )

# calculate margins
BMAR=$(awk "BEGIN { print 75/$ELESPAN }")
TMAR=$(awk "BEGIN { print 1-15/$ELESPAN }")
LMAR=$(awk "BEGIN { print 90/$AZISPAN }")
RMAR=$(awk "BEGIN { print 1-130/$AZISPAN }")

# sort from strongest signal to weakest (dark colors on top)
cat $LOG_DIR/converted.dat | sort -r -nk3 > $LOG_DIR/polar.dat

# plot azimuth vs. elevation
# use black background because human eye picks out bright on dark better
# inspiration from https://discussions.flightaware.com/t/signal-strength-heatmap/53109/107
gnuplot <<- EOF 
set xlabel "Azimuth" tc rgb 'white'
set ylabel "Elevation" tc rgb 'white'
set border lc rgb 'white'
set key tc rgb 'white'
set key noautotitle
set pointsize 1 
set term png size $AZISPAN,$ELESPAN background rgb 'black'
set bmargin at screen $BMAR
set tmargin at screen $TMAR
set lmargin at screen $LMAR
set rmargin at screen $RMAR
set cbrange [-10:0]
set autoscale xfix
set autoscale yfix
set output "$LOG_DIR/polar.png"
set palette rgb 34,35,36
plot '$LOG_DIR/polar.dat' using 2:1:3 with points pt 0 palette
EOF

# define size of canvas
DISSPAN=$(awk "BEGIN { print 250*$SCALE + 90 }" )
ALTSPAN=$(awk "BEGIN { print 100*$SCALE + 220 }" )

# calculate margins
BMAR=$(awk "BEGIN { print 75/$ALTSPAN }")
TMAR=$(awk "BEGIN { print 1-15/$ALTSPAN }")
LMAR=$(awk "BEGIN { print 90/$DISSPAN }")
RMAR=$(awk "BEGIN { print 1-130/$DISSPAN }")

# plot distance vs. altitude
# inspiration same as above
gnuplot <<- EOF 
set xlabel "Distance (mi)" tc rgb 'white'
set ylabel "Altitude (ft)" tc rgb 'white'
set border lc rgb 'white'
set key tc rgb 'white'
set key noautotitle
set pointsize 1 
set term png size $DISSPAN,$ALTSPAN background rgb 'black'
set bmargin at screen $BMAR
set tmargin at screen $TMAR
set lmargin at screen $LMAR
set rmargin at screen $RMAR
set cbrange [-10:0]
set autoscale xfix
set autoscale yfix
set output "$LOG_DIR/section.png"
set palette rgb 34,35,36
plot '$LOG_DIR/polar.dat' using (\$4/5280):5:3 with points pt 0 palette
EOF


