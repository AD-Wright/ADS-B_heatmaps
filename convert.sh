#!/bin/bash

# filename: convert.sh
###############################################################################
#                                                                             #
#   ADS-B_heatmaps: Collection of Linux Scripts for ADS-B data visualization  #
#  Coded by A.D. Wright - GPLv3 License - github.com/AD-Wright/ADS-B_heatmaps #
#                                                                             #
###############################################################################

# converts the log.dat file into Google Maps "csv" format, which can be used
# with tools such as https://adsb-heatmap.com/ (socket30003 proably compatible)

### USER CONFIGURATION ###
# installed directory (update after installation)
INSTALL_DIR=~/Documents/Gits/ADS-B_heatmaps
LOG_DIR=$INSTALL_DIR/log  # directory needs to exist or script will fail

### END USER CONFIGURATION ###

# put header row on csv file
echo "latitude;longitude" > $LOG_DIR/allpoints.csv

# create intermediate file (each point on newline), remove brackets, commas
# and grab out latitude, longitude, write separated by only a semicolon
cat $LOG_DIR/log.dat | tr -d '\n' | sed 's/\]\[/\]\
\[/g' | sed 's/\[ //g' | sed 's/\]//g' | tr -d ',' | awk '{printf("%3.6f;%3.6f \n", $1, $2)}' >> $LOG_DIR/allpoints.csv

echo "Converted and saved as 'allpoints.csv' in log directory"



