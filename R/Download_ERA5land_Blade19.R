Path = "/mnt/vt3era5-land/ERA5-land/Hourly"
VARS = c(
  "10m_u_component_of_wind",
  "10m_v_component_of_wind",
  "2m_temperature",
  "2m_dewpoint_temperature",
  "surface_pressure",
  "total_precipitation",
  "surface_solar_radiation_downwards"
)

START = Sys.Date()-7-6
END = Sys.Date()-7

#############################################################################################################################

for(V in 1:length(VARS)){
  dir.create(paste0(Path,'/',VARS[V]), showWarnings = FALSE)
}

Date <- seq.Date(from=as.Date(START), to=as.Date(END),by=1)

# Loop over the variables
for(V in 1:length(VARS)){
  
  # Loop over the dates
  for(i in 1:length(Date)){
    YEAR  <- strftime(Date[i], format = '%Y')
    MONTH <- strftime(Date[i], format = '%m')
    DAY   <- strftime(Date[i], format = '%d')
    VAR   <- VARS[V]
    
    # Create the request
    request <- list(
      nocache            = round(as.numeric(Sys.time()), digits=0),
      dataset_short_name = "reanalysis-era5-land",
      format             = "netcdf",
      variable           = VAR,
      year               = YEAR,
      month              = MONTH,
      day                = DAY,
      time               = c("00:00", "01:00", "02:00", "03:00", "04:00", "05:00",
                             "06:00", "07:00", "08:00", "09:00", "10:00", "11:00",
                             "12:00", "13:00", "14:00", "15:00", "16:00", "17:00",
                             "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"),
      
      # area is specified as N, W, S, E
      # area               = c(90, -180, -90, 180),
      target             = paste0(YEAR,'_',MONTH, '_', DAY, '_', VAR,'.nc')
    )
    
    cat('Downloading ', paste0(YEAR,'_',MONTH, '_', DAY, '_', VAR,'.nc'),'\n')
    
    # Download function which can fail and will be repeated
    DownloadRequest <- function(request){
      wf_request(user = UID, request = request, transfer = TRUE, path = paste0(Path, '/', VAR), time_out = 12*3600, verbose = FALSE)
      
      # Assigning into main environment
      STATUS              <<- 1
    }
    
    # Download the file
    STATUS <- 0
    while(STATUS==0){
      try(DownloadRequest(request), silent=TRUE)
      if(STATUS==0){
        cat('New attempt to download ', paste0(YEAR,'_',MONTH, '_', DAY, '_', VAR,'.nc'),'\n')
        Sys.sleep(10)
      }
    }
    
    cat('Done! \n\n')
  
    if(VARS[V] %in% c("total_precipitation", "surface_solar_radiation_downwards") & i==length(Date)){
      
      YEAR  <- strftime(Date[i]+1, format = '%Y')
      MONTH <- strftime(Date[i]+1, format = '%m')
      DAY   <- strftime(Date[i]+1, format = '%d')
      VAR   <- VARS[V]
      
      # Create the request
      request <- list(
        nocache            = round(as.numeric(Sys.time()), digits=0),
        dataset_short_name = "reanalysis-era5-land",
        format             = "netcdf",
        variable           = VAR,
        year               = YEAR,
        month              = MONTH,
        day                = DAY,
        time               = c("00:00"),
        
        # area is specified as N, W, S, E
        # area               = c(90, -180, -90, 180),
        target             = paste0(YEAR,'_',MONTH, '_', DAY, '_', VAR,'.nc')
      )
      
      cat('Downloading the first hour for ', paste0(YEAR,'_',MONTH, '_', DAY, '_', VAR,'.nc'),'\n')
      
      # Download function which can fail and will be repeated
      DownloadRequest <- function(request){
        wf_request(user = UID, request = request, transfer = TRUE, path = paste0(Path, '/', VAR), time_out = 12*3600, verbose = FALSE)
        
        # Assigning into main environment
        STATUS              <<- 1
      }
      
      # Download the file
      STATUS <- 0
      while(STATUS==0){
        try(DownloadRequest(request), silent=TRUE)
        if(STATUS==0){
          cat('New attempt to download ', paste0(YEAR,'_',MONTH, '_', DAY, '_', VAR,'.nc'),'\n')
          Sys.sleep(10)
        }
      }
    }
  }
}
