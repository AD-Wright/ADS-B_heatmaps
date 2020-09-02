#!/bin/bash

# filename: generate_liveview.sh
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

# receiver configuration (what is running dump1090)
REC_IP=192.168.193.125
REC_PORT=8080
DATA_DIR=/data/
ADDR=$REC_IP:$REC_PORT$DATA_DIR
ALT=4708  # Total altitude: altitude of antenna above gound + ground alt (ft)

# minimum distance (log planes and positions beyond this radius)
DIST=100 # in feet (default 100 feet)
SCALE=4      # 4 recommended

### END USER CONFIGURATION ###

# kill any previous invocation
kill $(pgrep -f 'generate_liveview.sh' | grep -v ^$$\$)

# remove files from previous run
> $LOG_DIR/html.dat
> $LOG_DIR/recent.dat

# get current receiver settings
RATE=$(curl -s $ADDR/receiver.json | jq '. | .refresh')
RATE=$(( $RATE / 1000 ))  # since default milliseconds
#RATE=$(( $RATE / 10 ))  # since it takes a while to graph
RLAT=$(curl -s $ADDR/receiver.json | jq '. | .lat')
RLON=$(curl -s $ADDR/receiver.json | jq '. | .lon')
echo "$LAT $LON 1 $ALT" > $LOG_DIR/receiver.dat

# define size of canvas
AZISPAN=$(awk "BEGIN { print 360*$SCALE + 90 }" )
ELESPAN=$(awk "BEGIN { print 100*$SCALE + 220 }" )

# calculate margins
BMAR=$(awk "BEGIN { print 65/$ELESPAN }")
TMAR=$(awk "BEGIN { print 1-15/$ELESPAN }")
LMAR=$(awk "BEGIN { print 80/$AZISPAN }")
RMAR=$(awk "BEGIN { print 1-140/$AZISPAN }")

# loop to update at the receiver rate
while true; do
  # grab current list, filter out new points, calculate angles, plot aircraft
  curl -s $ADDR/aircraft.json | jq -r --argjson RATE $RATE '.aircraft[] | select(.seen != null) | select(.seen <= $RATE) | select(.lat != null) | select(.alt_geom != null) | [.lat, .lon, .alt_geom, .rssi, .hex, .flight]' | tr -d '\n' | sed 's/\]\[/\]\
\[/g' | sed 's/\[ //g' | sed 's/\]//g' | tr -d ',' | tr -d '"' | awk -v rlat=$RLAT -v rlon=$RLON -v ralt=$RALT '
BEGIN {
PI = atan2(0,-1)
R = 20887680 
rlat = rlat * PI/180
rlon = rlon * PI/180
}
{
  lat = $1 * PI/180; lon = $2 * PI/180; alt = $3; rssi = $4; hex = $5; flight = $6;
  dlon = lon - rlon; dlat = lat - rlat;
  a = sin(dlat/2)^2 + cos(rlat) * cos(lat) * sin(dlon/2)^2;
  d = 2 * atan2(sqrt(a), sqrt(1-a)) * R;
  azi = 180/PI * atan2(sin(dlon * cos(lat)),cos(rlat)*sin(lat) - sin(rlat)*cos(lat)*cos(dlon));
  azi = (azi + 360) % 360;
  ele = 180/PI * atan2((alt - ralt) / d - d / (2 * R), 1);
  printf "%.1f %.1f %.1f %.0f %.0f %s [%s]\n", ele, azi, rssi, d, alt, hex, flight
}' | tee -a $LOG_DIR/html.dat | awk 'NF==7' > $LOG_DIR/recent.dat

# plot azimuth vs. elevation
# use black background because human eye picks out bright on dark better
gnuplot <<- EOF 
set xlabel "Azimuth" tc rgb 'white'
set ylabel "Elevation" tc rgb 'white'
set border lc rgb 'white'
set key tc rgb 'white'
set key noautotitle
set pointsize 1 
set style textbox opaque noborder
set term png size $AZISPAN,$ELESPAN background rgb 'black'
set bmargin at screen $BMAR
set tmargin at screen $TMAR
set lmargin at screen $LMAR
set rmargin at screen $RMAR
set cbrange [-10:0]
set xrange [0:360]
set yrange [-5:90]
set output "$LOG_DIR/liveview.png"
plot '$LOG_DIR/html.dat' using 2:1 with points pt 2 linecolor rgb "green", '$LOG_DIR/recent.dat' using 2:1:7 w labels boxed font "Courier,9" textcolor rgb "green"
EOF

    sleep $RATE
    sleep $RATE
    sleep $RATE
    sleep $RATE
    sleep $RATE
    sleep $RATE
done
