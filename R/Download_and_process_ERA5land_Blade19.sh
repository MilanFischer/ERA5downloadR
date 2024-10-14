#!/bin/bash

# Check if the R script is already running
if pgrep -f "Download_and_process_ERA5land_Blade19_MAIN.R" > /dev/null; then
    echo "The script is already running."
else
    echo "Starting the script."
    # Command to run your R script, adjust as necessary
    /usr/bin/Rscript /mnt/data_local/ERA5-land/Hourly/R/Download_and_process_ERA5land_Blade19_MAIN.R &
fi

