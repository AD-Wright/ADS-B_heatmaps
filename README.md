# ADS-B_heatmaps
Collection of Linux Scripts for ADS-B receiver data visualization

## Requirements:
- Some device on your network running dump1090 (such as a piaware)
- Access to said device (default over port 8080, specifically `<ip>:8080/data/aircraft.json`)
- `bash`
- `jq` (https://stedolan.github.io/jq/) installed on local machine (`sudo apt-get install jq`)
- `curl`
- `gnuplot`
- Note: current testing environment Ubuntu 18.04

## Current Capabilities:
- Save aircraft data from your receiver to local file
- Generate basic heatmap-style overlay based on traffic volume (sumdata.sh)
![Image of 48 hours of data](https://github.com/AD-Wright/ADS-B_heatmaps/raw/master/images/rect48.png)
- Generate socket30003-like Google Maps compatible "csv" file (convert.sh)

## Planned:
- Sort heatmap by altitude
- Generate signal strength overlays 
  - Map overlay
  - Some kind of polar plot
  - RSSI vs. Distance?
  
## Basic Troubleshooting
- If you can't access `<ip>:8080/data/aircraft.json`, you probably installed something that messed with your lighttpd configuration.  It should have an alias to `/run/dump1090/data`.  You can create a link (`sudo ln -s /run/dump1090-fa /var/www/html/data`).

If you have problems or think you found a bug, please look through the current "Issues" and submit a new one if none of them help.  This project / collection is currently under development.
