#!/bin/bash

# filename: repairlog.sh
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

### END USER CONFIGURATION ###

# read from log.dat, remove unprintable characters, save as replog.dat
cat $LOG_DIR/log.dat | tr -cd '\11\12\15\40-\176' > replog.dat

# you will then need to manually delete / rename the misbehaving log.dat, and rename replog.dat

# for more info see: https://alvinalexander.com/blog/post/linux-unix/how-remove-non-printable-ascii-characters-file-unix
