# Clear the environment
rm(list = ls())

# Define the input and output paths
path_in <- "/mnt/data_local/ERA5-land/Hourly"
path_out <- "/mnt/vt3era5-land/ERA5-land/Hourly"

# Define the hourly directories
dirs_hourly <- c("10m_u_component_of_wind",
                 "10m_v_component_of_wind",
                 "2m_dewpoint_temperature",
                 "2m_temperature",
                 "surface_pressure",
                 "surface_solar_radiation_downwards",
                 "total_precipitation")

# Copy files from the hourly directories
for(dd in 1:length(dirs_hourly)){
  Files <- list.files(path = paste0(path_in, "/", dirs_hourly[dd]), pattern='\\.nc$')
  
  file.copy(from = paste0(path_in, "/", dirs_hourly[dd], "/", Files),
            to = paste0(path_out, "/", dirs_hourly[dd], "/", Files), overwrite = TRUE)
  rm(Files)
  
  # Remove the hourly directory after copying files
  unlink(paste0(path_in, "/", dirs_hourly[dd]), recursive = TRUE)
} 

# Define the daily directories
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

# Copy files from the daily directories
for(dd in 1:length(dirs_daily)){
  Files <- list.files(path = paste0(path_in, "/ERA5-land_processing/ERA5-land_daily/", dirs_daily[dd]), pattern='\\.tif$')
  
  file.copy(from = paste0(path_in, "/ERA5-land_processing/ERA5-land_daily/", dirs_daily[dd], "/", Files),
            to = paste0(path_out, "/ERA5-land_processing/ERA5-land_daily/", dirs_daily[dd], "/", Files), overwrite = TRUE)
  rm(Files)
  
  # Remove the daily directory after copying files
  # unlink(paste0(path_in, "/ERA5-land_processing/ERA5-land_daily/", dirs_daily[dd]), recursive = TRUE)
} 
