rm(list=ls())

# This is important when running from Cron
setwd('/mnt/data_local/ERA5-land/Hourly/R')

source('Wait_v0.1.R')

# Global parameters
OS<-'Linux'  # 'Linux' or 'Windows' 
n_proc=3
days_back=6 # Integer for specific number of days from the last day or 'all' for all days, use 6 by for normal operaration
waitingTime=60
product='ERA5-land' # 'ERA5' or 'ERA5-land'
time_step='both' # 'hourly' or 'daily' or 'both'
last_days_to_skip=0

# path_in='/mnt/data/ERA5-land_1950-1980'
path_in='/mnt/data_local/ERA5-land/Hourly'

# Does not need to be edited below
#########################################################################################################################

# To compute in RAM use tmp at Linux servers but be careful to not overload RAM
if(OS=='Linux'){
  temp_path<-'/tmp/raster'
}else if(OS=='Windows'){
  temp_path<-'./tmp/raster'
}else{
  stop("OS must be set either ot 'Liunux' or 'Windows'")
}
dir.create(temp_path, showWarnings = FALSE, recursive = TRUE)

if(product=='ERA5-land'){
  resolution=0.1
}else if(product=='ERA5'){
  resolution=0.25  
}else{
  stop("OS must be set either ot 'Liunux' or 'Windows'")
}

#########################################################################################################################
# Hourly data
#########################################################################################################################

if(time_step=='hourly'|time_step=='both'){
  path_u<-paste0(path_in, '/10m_u_component_of_wind')
  path_v<-paste0(path_in, '/10m_v_component_of_wind')
  path_T<-paste0(path_in, '/2m_temperature')
  path_Td<-paste0(path_in, '/2m_dewpoint_temperature')
  path_P<-paste0(path_in, '/total_precipitation')
  path_Rs<-paste0(path_in, '/surface_solar_radiation_downwards')
  path_AP<-paste0(path_in, '/surface_pressure')
  
  Files_u<-list.files(path_u,pattern="\\.nc$")
  Files_v<-list.files(path_v,pattern="\\.nc$")
  Files_T<-list.files(path_T,pattern="\\.nc$")
  Files_Td<-list.files(path_Td,pattern="\\.nc$")
  Files_P<-list.files(path_P,pattern="\\.nc$")
  Files_Rs<-list.files(path_Rs,pattern="\\.nc$")
  Files_AP<-list.files(path_AP,pattern="\\.nc$")
  
  if(product=='ERA5'){
    all<-c(length(Files_u),length(Files_v),length(Files_T),length(Files_Td),length(Files_P),length(Files_Rs),length(Files_AP))
    Date<-substr(x=get(c('Files_u','Files_v','Files_T','Files_Td','Files_P','Files_Rs','Files_AP')[which(all==min(all))[1]]),
                 start=1,stop=10) 
    Files_u<-Files_u[which(substr(Files_u,1,10) %in% Date)]
    Files_v<-Files_v[which(substr(Files_v,1,10) %in% Date)]
    Files_T<-Files_T[which(substr(Files_T,1,10) %in% Date)]
    Files_Td<-Files_Td[which(substr(Files_Td,1,10) %in% Date)]
    Files_P<-Files_P[which(substr(Files_P,1,10) %in% Date)]
    Files_Rs<-Files_Rs[which(substr(Files_Rs,1,10) %in% Date)]
    Files_AP<-Files_AP[which(substr(Files_AP,1,10) %in% Date)]
  }else if(product=='ERA5-land'){
    all<-c(length(Files_u),length(Files_v),length(Files_T),length(Files_Td),length(Files_P),length(Files_Rs),length(Files_AP))
    Date<-substr(x=get(c('Files_u','Files_v','Files_T','Files_Td','Files_P','Files_Rs','Files_AP')[which(all==min(all))[1]]),
                 start=1,stop=10) 
    Files_u<-Files_u[which(substr(Files_u,1,10) %in% Date)]
    Files_v<-Files_v[which(substr(Files_v,1,10) %in% Date)]
    Files_T<-Files_T[which(substr(Files_T,1,10) %in% Date)]
    Files_Td<-Files_Td[which(substr(Files_Td,1,10) %in% Date)]
    Files_P<-Files_P[which(substr(Files_P,1,10) %in% gsub('-','_',as.character(as.Date(gsub('_','-',Date))+1)))]
    Files_Rs<-Files_Rs[which(substr(Files_Rs,1,10) %in% gsub('-','_',as.character(as.Date(gsub('_','-',Date))+1)))]
    Files_AP<-Files_AP[which(substr(Files_AP,1,10) %in% Date)]
  }
  
  if(days_back=='all'){
    days_back<-length(Date)
  }
  
  ######################
  # Wind speed at 10 m #
  ######################
  
  cat('\n\n')
  cat('Working on 10 m wind speed\n')

  variable_name<-'WS10_avg'
  ID_u<-'u10'
  ID_v<-'v10'

  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)

  if(length(Files_u)==length(Files_v)){
    cat('All right - the number of u and v files is equal\n')
  }else{
    stop('There is a different number of u and v files\n')
  }

  N<-length(Files_u)-last_days_to_skip
  NP=0

  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }

  i=N-days_back+1

  cond=0

  while(cond==0){

    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Hourly_data_processing_v0.1.R',variable_name,n_inputs=2,Files_u[i],Files_v[i],path_u,path_v,ID_u,ID_v,resolution=resolution,fun='mean',
                   multiplier=1,offset=0,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  ##########################
  # Vapor pressure deficit #
  ##########################
  
  cat('\n\n')
  cat('Working on 2 m vapor pressure deficit and other air humidity variables\n')
  
  variable_name<-'VPD_avg'
  ID_T<-'t2m'
  ID_Td<-'d2m'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  if(variable_name=='VPD_avg'){
    dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/','e_avg'),showWarnings=FALSE,recursive=TRUE)
    dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/','es_avg'),showWarnings=FALSE,recursive=TRUE)
    dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/','RH_avg'),showWarnings=FALSE,recursive=TRUE)
    dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/','RH_min'),showWarnings=FALSE,recursive=TRUE)
    dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/','Td_avg'),showWarnings=FALSE,recursive=TRUE)
  }
  
  if(length(Files_T)==length(Files_Td)){
    cat('All right - the number of T and Td files is equal\n')
  }else{
    stop('There is a different number of T and Td files\n')
  }
  
  N<-length(Files_T)-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Hourly_data_processing_v0.1.R',variable_name,n_inputs=2,Files_T[i],Files_Td[i],path_T,path_Td,ID_T,ID_Td,resolution=resolution,fun='mean',
                   multiplier=1,offset=-273.15,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  #######################
  # Precipitation total #
  #######################
  
  cat('\n\n')
  cat('Working on precipitation\n')
  
  variable_name<-'P_sum'
  ID<-'tp'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  N<-length(Files_P)-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Hourly_data_processing_v0.1.R',variable_name,n_inputs=1,Files_P[i],path_P,ID,resolution=resolution,fun='sum',
                   multiplier=1000,offset=0,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  ###########################
  # Minimum air temperature #
  ###########################
  
  cat('\n\n')
  cat('Working on 2 m minimum daily air temperature\n')
  
  variable_name<-'T_min'
  ID<-'t2m'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  N<-length(Files_T)-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Hourly_data_processing_v0.1.R',variable_name,n_inputs=1,Files_T[i],path_T,ID,resolution=resolution,fun='min',
                   multiplier=1,offset=-273.15,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections()
  }
  wait(waitingTime)
  
  ###########################
  # Maximum air temperature #
  ###########################
  
  cat('\n\n')
  cat('Working on 2 m maximum daily air temperature\n')
  
  variable_name<-'T_max'
  ID<-'t2m'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  N<-length(Files_T)-last_days_to_skip
  NP=0
  
  i=N-days_back+1
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Hourly_data_processing_v0.1.R',variable_name,n_inputs=1,Files_T[i],path_T,ID,resolution=resolution,fun='max',
                   multiplier=1,offset=-273.15,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  ########################
  # Mean air temperature #
  ########################
  
  cat('\n\n')
  cat('Working on 2 m mean daily air temperature\n')
  
  variable_name<-'T_avg'
  ID<-'t2m'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  N<-length(Files_T)-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Hourly_data_processing_v0.1.R',variable_name,n_inputs=1,Files_T[i],path_T,ID,resolution=resolution,fun='mean',
                   multiplier=1,offset=-273.15,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  #########################
  # Solar radiation total #
  #########################
  
  cat('\n\n')
  cat('Working on solar radiation\n')
  
  variable_name<-'Rs_sum'
  ID<-'ssrd'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  N<-length(Files_Rs)-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Hourly_data_processing_v0.1.R',variable_name,n_inputs=1,Files_Rs[i],path_Rs,ID,resolution=resolution,fun='sum',
                   multiplier=1/10^6,offset=0,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  #####################
  # Mean air pressure #
  #####################
  
  cat('\n\n')
  cat('Working on atmospheric pressure\n')
  
  variable_name<-'AP_avg'
  ID<-'sp'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  N<-length(Files_AP)-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Hourly_data_processing_v0.1.R',variable_name,n_inputs=1,Files_AP[i],path_AP,ID,resolution=resolution,fun='mean',
                   multiplier=1/10^3,offset=0,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
}


#########################################################################################################################
# Daily data
#########################################################################################################################

if(time_step=='daily'|time_step=='both'){
  
  #########################################
  # Latent heat of vaporization (MJ kg-1) #
  #########################################
  
  cat('Working on latent heat of vaporization\n')
  
  variable_name<-'lambda_avg'
  path<-'../ERA5-land_processing/ERA5-land_daily/T_avg'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  Files<-list.files(path,pattern="\\.tif$")
  
  if(days_back=='all'){
    days_back<-length(Files)
  }
  
  N<-length(Files)#-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Daily_data_processing_v0.1.R',variable_name,n_inputs=1,Files[i],path,product,OS,
                   sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  ############################################################
  # Slope of saturation vapour pressure curve (kPa deg. C-1) #
  ############################################################
  
  cat('\n\n')
  cat('Working on slope of saturation vapour pressure curve\n')
  
  variable_name<-'delta_avg'
  path<-'../ERA5-land_processing/ERA5-land_daily/T_avg'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  Files<-list.files(path,pattern="\\.tif$")
  N<-length(Files)#-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Daily_data_processing_v0.1.R',variable_name,n_inputs=1,Files[i],path,product,OS,
                   sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  #####################
  # Wind speed at 2 m #
  #####################
  
  cat('\n\n')
  cat('Working on 2 m wind speed\n')
  
  variable_name<-'WS2_avg'
  path<-'../ERA5-land_processing/ERA5-land_daily/WS10_avg'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  Files<-list.files(path,pattern="\\.tif$")
  N<-length(Files)#-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Daily_data_processing_v0.1.R',variable_name,n_inputs=1,Files[i],path,product,OS,
                   sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  #################
  # Net radiation #
  #################
  
  cat('\n\n')
  cat('Working on net radiation\n')
  
  variable_name<-'Rn_sum'
  path_T<-'../ERA5-land_processing/ERA5-land_daily/T_avg'
  path_e<-'../ERA5-land_processing/ERA5-land_daily/e_avg'
  path_Rs<-'../ERA5-land_processing/ERA5-land_daily/Rs_sum'
  path_alt<-'../ERA5-land_processing/Static_inputs'
  path_lat<-'../ERA5-land_processing/Static_inputs'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  Files_T<-list.files(path_T,pattern="\\.tif$")
  Files_e<-list.files(path_e,pattern="\\.tif$")
  Files_Rs<-list.files(path_Rs,pattern="\\.tif$")
  File_alt<-'altitude.tif'
  File_lat<-'latitude.tif'
  
  if(length(Files_T)==length(Files_e)&length(Files_T)==length(Files_Rs)&length(Files_T)){
    cat('All right - the number of files is equal\n')
  }else{
    stop('There is a different number of files\n')
  }
  
  N<-length(Files_T)#-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Daily_data_processing_v0.1.R',variable_name,n_inputs=5,Files_T[i],Files_e[i],Files_Rs[i],File_alt,File_lat,
                   path_T,path_e,path_Rs,path_alt,path_lat,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  #####################
  # Specific humidity #
  #####################
  
  cat('\n\n')
  cat('Working on air specific humidity\n')
  
  variable_name<-'q_avg'
  path_e<-'../ERA5-land_processing/ERA5-land_daily/e_avg'
  path_AP<-'../ERA5-land_processing/Static_inputs'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  Files_e<-list.files(path_e,pattern="\\.tif$")
  File_AP<-'AP.tif'
  
  N<-length(Files_e)#-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Daily_data_processing_v0.1.R',variable_name,n_inputs=2,Files_e[i],File_AP,
                   path_e,path_AP,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  ########################
  # Specific heat of air #
  ########################
  
  cat('\n\n')
  cat('Working on specific heat of air\n')
  
  variable_name<-'cp_avg'
  path_q<-'../ERA5-land_processing/ERA5-land_daily/q_avg'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  Files_q<-list.files(path_q,pattern="\\.tif$")
  
  N<-length(Files_q)#-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Daily_data_processing_v0.1.R',variable_name,n_inputs=1,Files_q[i],
                   path_q,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  ###############
  # Air density #
  ###############
  
  cat('\n\n')
  cat('Working on air density\n')
  
  variable_name<-'rho_avg'
  path_T<-'../ERA5-land_processing/ERA5-land_daily/T_avg'
  path_e<-'../ERA5-land_processing/ERA5-land_daily/e_avg'
  path_AP<-'../ERA5-land_processing/Static_inputs'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  Files_T<-list.files(path_T,pattern="\\.tif$")
  Files_e<-list.files(path_e,pattern="\\.tif$")
  File_AP<-'AP.tif'
  
  if(length(Files_T)==length(Files_e)){
    cat('All right - the number of files is equal\n')
  }else{
    stop('There is a different number of files\n')
  }
  
  N<-length(Files_T)#-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Daily_data_processing_v0.1.R',variable_name,n_inputs=3,Files_T[i],Files_e[i],File_AP,
                   path_T,path_e,path_AP,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  ##########################
  # Psychrometric constant #
  ##########################
  
  cat('\n\n')
  cat('Working on psychrometric constant\n')
  
  variable_name<-'gamma_avg'
  path_cp<-'../ERA5-land_processing/ERA5-land_daily/cp_avg'
  path_AP<-'../ERA5-land_processing/Static_inputs'
  path_lambda<-'../ERA5-land_processing/ERA5-land_daily/lambda_avg'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  Files_cp<-list.files(path_cp,pattern="\\.tif$")
  Files_AP<-'AP.tif'
  Files_lambda<-list.files(path_lambda,pattern="\\.tif$")
  
  if(length(Files_cp)==length(Files_lambda)){
    cat('All right - the number of files is equal\n')
  }else{
    stop('There is a different number of files\n')
  }
  
  N<-length(Files_cp)#-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Daily_data_processing_v0.1.R',variable_name,n_inputs=3,Files_cp[i],File_AP,Files_lambda[i],
                   path_cp,path_AP,path_lambda,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  #################################################
  # Priestley-Taylor potential evapotranspiration #
  #################################################
  
  cat('\n\n')
  cat('Working on Priestley-Taylor potential evapotranspiration\n')
  
  variable_name<-'PET_sum'
  path_delta<-'../ERA5-land_processing/ERA5-land_daily/delta_avg'
  path_Rn<-'../ERA5-land_processing/ERA5-land_daily/Rn_sum'
  path_gamma<-'../ERA5-land_processing/ERA5-land_daily/gamma_avg'
  path_lambda<-'../ERA5-land_processing/ERA5-land_daily/lambda_avg'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  Files_delta<-list.files(path_delta,pattern="\\.tif$")
  Files_Rn<-list.files(path_Rn,pattern="\\.tif$")
  Files_gamma<-list.files(path_gamma,pattern="\\.tif$")
  Files_lambda<-list.files(path_lambda,pattern="\\.tif$")
  
  if(length(Files_delta)==length(Files_Rn)&length(Files_delta)==length(Files_gamma)&
     length(Files_delta)==length(Files_lambda)){
    cat('All right - the number of files is equal\n')
  }else{
    stop('There is a different number of files\n')
  }
  
  N<-length(Files_delta)#-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Daily_data_processing_v0.1.R',variable_name,n_inputs=4,Files_delta[i],Files_Rn[i],
                   Files_gamma[i],Files_lambda[i],path_delta,path_Rn,path_gamma,path_lambda,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
  
  ################################
  # Reference evapotranspiration #
  ################################
  
  cat('\n\n')
  cat('Working on FAO56 reference evapotranspiration\n')
  
  variable_name<-'ETo_sum'
  path_delta<-'../ERA5-land_processing/ERA5-land_daily/delta_avg'
  path_Rn<-'../ERA5-land_processing/ERA5-land_daily/Rn_sum'
  path_rho<-'../ERA5-land_processing/ERA5-land_daily/rho_avg'
  path_cp<-'../ERA5-land_processing/ERA5-land_daily/cp_avg'
  path_VPD<-'../ERA5-land_processing/ERA5-land_daily/VPD_avg'
  path_u2<-'../ERA5-land_processing/ERA5-land_daily/WS2_avg'
  path_gamma<-'../ERA5-land_processing/ERA5-land_daily/gamma_avg'
  path_lambda<-'../ERA5-land_processing/ERA5-land_daily/lambda_avg'
  
  dir.create(paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name),showWarnings=FALSE,recursive=TRUE)
  
  Files_delta<-list.files(path_delta,pattern="\\.tif$")
  Files_Rn<-list.files(path_Rn,pattern="\\.tif$")
  Files_rho<-list.files(path_rho,pattern="\\.tif$")
  Files_cp<-list.files(path_cp,pattern="\\.tif$")
  Files_VPD<-list.files(path_VPD,pattern="\\.tif$")
  Files_u2<-list.files(path_u2,pattern="\\.tif$")
  Files_gamma<-list.files(path_gamma,pattern="\\.tif$")
  Files_lambda<-list.files(path_lambda,pattern="\\.tif$")
  
  if(length(Files_delta)==length(Files_Rn)&
     length(Files_delta)==length(Files_rho)&
     length(Files_delta)==length(Files_cp)&
     length(Files_delta)==length(Files_VPD)&
     length(Files_delta)==length(Files_u2)&
     length(Files_delta)==length(Files_gamma)&
     length(Files_delta)==length(Files_lambda)){
    cat('All right - the number of files is equal\n')
  }else{
    stop('There is a different number of files\n')
  }
  
  N<-length(Files_delta)#-last_days_to_skip
  NP=0
  
  if(OS=='Windows'){
    NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
  }else if(OS=='Linux'){
    NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
  }else{
    stop("OS must be set to either 'Linux' or 'Windows'")
  }
  
  i=N-days_back+1
  
  cond=0
  
  while(cond==0){
    
    while((NP<n_proc) & (cond==0)){
      system(paste('Rscript Daily_data_processing_v0.1.R',variable_name,n_inputs=8,Files_delta[i],Files_Rn[i],
                   Files_rho[i],Files_cp[i],Files_VPD[i],Files_u2[i],Files_gamma[i],Files_lambda[i],
                   path_delta,path_Rn,path_rho,path_cp,path_VPD,path_u2,path_gamma,path_lambda,product,OS,sep=' '),intern=FALSE,wait=FALSE)
      cat(i); cat('\n'); flush.console()
      i=i+1
      NP=NP+1
      if(i>N){
        cond=1
      }
    }
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
    closeAllConnections(); gc()
  }
  wait(waitingTime)
}

# Remove the folder for temporary files
unlink(temp_path, recursive = TRUE)

