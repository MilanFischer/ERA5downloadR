rm(list = ls()); gc()

library(ecmwfr)
library(keyring)

keyring_unlock('ecmwfr', password='your_password')
PAT = "Personal Access Token"
UID = "User ID"
wf_set_key(user = UID, key = PAT)

source('/mnt/vt3era5-land/ERA5-land/Hourly/R/Download_ERA5land_Blade19.R')
source('/mnt/vt3era5-land/ERA5-land/Hourly/R/Main_Blade19_v0.1.R')
source('/mnt/vt3era5-land/ERA5-land/Hourly/R/Copy_to_monospace.R')
source('/mnt/data_local/ERA5-land/Hourly/R/Copy_to_vt3era5-land.R')
