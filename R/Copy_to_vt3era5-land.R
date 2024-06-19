rm(list = ls())

path_in <- "/mnt/data_local/ERA5-land/Hourly"
path_out <- "/mnt/vt3era5-land/ERA5-land/Hourly"


dirs_hourly <- c("10m_u_component_of_wind",
                 "10m_v_component_of_wind",
                 "2m_dewpoint_temperature",
                 "2m_temperature",
                 "surface_pressure",
                 "surface_solar_radiation_downwards",
                 "total_precipitation")


for(dd in 1:length(dirs_hourly)){
  Files <- list.files(path = paste0(path_in, "/", dirs_hourly[dd]), pattern='\\.nc$')
  
  file.copy(from = paste0(path_in, "/", dirs_hourly[dd], "/", Files),
            to = paste0(path_out, "/", dirs_hourly[dd], "/", Files), overwrite = TRUE)
} 

dirs_daily <- c('AP_avg',
                'cp_avg',
                'delta_avg',
                'e_avg',
                'es_avg',
                'ETo_sum',
                'gamma_avg',
                'lambda_avg',
                'P_sum',
                'PET_sum',
                'q_avg',
                'RH_avg',  
                'RH_min',
                'rho_avg',
                'Rn_sum',
                'Rs_sum',
                'T_avg',
                'T_max',
                'T_min',
                'Td_avg',
                'VPD_avg',
                'WS10_avg',
                'WS2_avg')

for(dd in 1:length(dirs_daily)){
  Files <- list.files(path = paste0(path_in, "/ERA5-land_processing/ERA5-land_daily/", dirs_daily[dd]), pattern='\\.tif$')
  
  file.copy(from = paste0(path_in, "/ERA5-land_processing/ERA5-land_daily/", dirs_daily[dd], "/", Files),
            to = paste0(path_out, "/ERA5-land_processing/ERA5-land_daily/", dirs_daily[dd], "/", Files), overwrite = TRUE)
} 
