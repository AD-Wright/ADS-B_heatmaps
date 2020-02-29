#!/bin/bash

# filename: listen.sh
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
DIST=1056000 # in feet (default 200 statute miles)

### END USER CONFIGURATION ###

# kill any previous invocation
kill $(pgrep -f 'listen.sh' | grep -v ^$$\$)

# get current receiver settings
RATE=$(curl -s $ADDR/receiver.json | jq '. | .refresh')
RATE=$(( $RATE / 1000 ))  # since default milliseconds
RLAT=$(curl -s $ADDR/receiver.json | jq '. | .lat')
RLON=$(curl -s $ADDR/receiver.json | jq '. | .lon')
echo "$LAT $LON 1 $ALT" > $LOG_DIR/receiver.dat

# loop to update at the receiver rate
while true; do
  # grab current list, filter out new points, calculate distance, append if far enough
  curl -s $ADDR/aircraft.json | jq -r --argjson RATE $RATE '.aircraft[] | select(.seen != null) | select(.seen <= $RATE) | select(.lat != null) | select(.alt_geom != null) | [.lat, .lon, .alt_geom, .rssi, .hex, .flight]' | tr -d '\n' | sed 's/\]\[/\]\
\[/g' | sed 's/\[ //g' | sed 's/\]//g' | tr -d ',' | tr -d '"' | awk -v rlat=$RLAT -v rlon=$RLON -v ralt=$RALT dist=$DIST'
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
  if (d >= dist) { printf "%.6f %.6f %.0f %.1f %.0f %s %s \n", $1, $2, $3, $4, d, $5, $6} 
  else { }
}' | awk 'NF==7' >> $LOG_DIR/capture.dat

    sleep $RATE
done
