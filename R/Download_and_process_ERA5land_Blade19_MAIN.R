rm(list = ls()); gc()

library(ecmwfr)
library(keyring)

keyring_unlock('ecmwfr', password='your_password')
cds.key = "your_cds.key"
UID     = "your_UID_number"
wf_set_key(user = UID, key = cds.key, service = "cds")

source('/mnt/vt3era5-land/ERA5-land/Hourly/R/Download_ERA5land_Blade19.R')
source('/mnt/vt3era5-land/ERA5-land/Hourly/R/Main_Blade19_v0.1.R')
source('/mnt/vt3era5-land/ERA5-land/Hourly/R/Copy_to_monospace.R')
