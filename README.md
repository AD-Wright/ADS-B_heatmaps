# ADS-B_heatmaps
Collection of Linux Scripts for ADS-B receiver data visualization

## Requirements:
- Some device on your network running dump1090 (such as a piaware)
- Access to said device (default over port 8080)
- `jq` (https://stedolan.github.io/jq/) installed on local machine (`sudo apt-get install jq`)
- `curl` (`sudo apt-get install curl`)
- Note: current testing environment Ubuntu 18.04

## Current Capabilities:
- Save aircraft data to local file

## Planned:
- Generate a heatmap-style overlay on some kind of map based on traffic volume
  - Sort by altitude
  - Could just connect to port 30003 with `nc` and read SBS-1 messages (http://woodair.net/sbs/article/barebones42_socket_data.htm)
- Generate signal strength overlays 
  - Map overlay
  - Some kind of polar plot
  - Signal strengths need access to `<ip>:8080/data/aircraft.json` (https://github.com/SDRplay/dump1090/blob/master/README-json.md)
  
## Basic Troubleshooting
- If you can't access `<ip>:8080/data/aircraft.json`, you probably installed something that messed with your lighttpd configuration.  It should have an alias to `/run/dump1090/data`.  You can also create a link (`sudo ln -s /run/dump1090-fa /var/www/html/data`).

If you have problems or think you found a bug, please look through the current "Issues" and submit a new one if none of them help.  This project / collection is currently under development.
