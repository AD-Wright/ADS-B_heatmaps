#!/bin/bash

# filename: getdata.sh
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

# plot binning configuration
FLAT_RES=1   # overlay binning grid size, in default units
POLAR_RES=2  # polar RSSI plot grid size, in degrees

### END USER CONFIGURATION ###

# kill any previous invocation
kill $(pgrep -f 'getdata.sh' | grep -v ^$$\$)

# get current receiver settings
RATE=$(curl -s $ADDR/receiver.json | jq '. | .refresh')
RATE=$(( $RATE / 1000 ))  # since default milliseconds
LAT=$(curl -s $ADDR/receiver.json | jq '. | .lat')
LON=$(curl -s $ADDR/receiver.json | jq '. | .lon')

# loop to update at the receiver rate
while true; do
  # grab current list, filter out new points, append lat, lon, alt, RSSI
  echo $( curl -s $ADDR/aircraft.json | jq -r --argjson RATE $RATE '.aircraft[] | select(.seen != null) | select(.seen <= $RATE) | select(.lat != null) | select(.alt_geom != null) | [.lat, .lon, .alt_geom, .rssi]' | tr -d '\n') >> $LOG_DIR/log.dat

    sleep $RATE
done
