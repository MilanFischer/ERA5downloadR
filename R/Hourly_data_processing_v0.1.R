suppressMessages(library(ncdf4))
suppressMessages(library(terra))

args=commandArgs(trailingOnly=TRUE)

# # Uncomment for troubleshooting
# cat(args,file='args.txt')
# string='WS10_avg 2 2023_08_01_10m_u_component_of_wind.nc 2023_08_01_10m_v_component_of_wind.nc /mnt/vt3era5-land/ERA5-land/Hourly/10m_u_component_of_wind /mnt/vt3era5-land/ERA5-land/Hourly/10m_v_component_of_wind u10 v10 0.1 mean 1 0 ERA5-land Linux'
# args=unlist(strsplit(string,split=' '))
# stop()

variable_name=args[1]
n_inputs=as.numeric(args[2])

if(n_inputs==1){
  File_1=args[3]
  path_1=args[4]
  ID_1=args[5]
}else if(n_inputs==2){
  File_1=args[3]
  File_2=args[4]
  path_1=args[5]
  path_2=args[6]
  ID_1=args[7]
  ID_2=args[8]
}else if(n_inputs==3){
  File_1=args[3]
  File_2=args[4]
  File_3=args[5]
  path_1=args[6]
  path_2=args[7]
  path_3=args[8]
  ID_1=args[9]
  ID_2=args[10]
  ID_3=args[11]
}

resolution=as.numeric(args[3+n_inputs*3])
fun=args[4+n_inputs*3]
multiplier=as.numeric(args[5+n_inputs*3])
offset=as.numeric(args[6+n_inputs*3])
product=args[7+n_inputs*3]
OS=args[8+n_inputs*3]

# To compute in RAM use tmp at Linux servers but be careful to not overload RAM
if(OS=='Linux'){
  temp_path<-'/tmp/raster'
}else if(OS=='Windows'){
  temp_path<-'./tmp/raster'
}else{
  stop("OS must be set either ot 'Liunux' or 'Windows'")
}
dir.create(paste(temp_path,'/', File_1, sep=''), showWarnings = FALSE, recursive = TRUE)

# Refer the terra package to the folder
terraOptions(tempdir=paste(temp_path,'/', File_1, sep='')) 

if(n_inputs==1){

  # Read NetCDF file
  Input<-nc_open(paste0(path_1,'/',File_1))
  Data<-rast(paste0(path_1,'/',File_1))
  
  Origin=gsub("hours since ","",Input[['dim']][['time']][['units']]); Origin=as.POSIXct(Origin,tz="GMT")
  Date=as.character(Origin+Input[['dim']][['time']][['vals']]*3600); Date=strftime(Date, format = "%Y-%m-%d",tz="UTC")[1]

  Name=Input$var[[ID_1]]$longname

  # LAI
  if(grepl('LAI',variable_name)){
    Name<-gsub(',','',Name) 
  }

  if(product=='ERA5-land'&variable_name=='P_sum'|product=='ERA5-land'&variable_name=='Rs_sum'){
    # Change the timestamp to one day before
    Date<-as.character(as.Date(Date)-1)
    # Aggregate to daily - taking the first layer which belongs to the previous day
    T<-subset(Data,subset=1)
  }else{
    # Aggregate to daily
    T<-app(Data,fun=get(fun),na.rm=TRUE)
  }
  
  # Convert units
  T<-multiplier*T+offset

  # Split the data into two halves
  E<-ext(T)
  x1<-crop(T, ext(E[1], 180-resolution/2, E[3], E[4]))
  E1<-ext(x1)
  x2<-crop(T, ext(180-resolution/2, 360-resolution/2, E[3], E[4]))
  E2<-ext(x2)
  ext(x1) <- E2
  ext(x2) <- E1
  
  # Flipped the halves and put them together
  # Map<-mosaic(x=x1,y=x2,fun='mean')
  Map<-merge(x=x1,y=x2)
  
  # To start at -180 and end at +180
  ext(Map)<-ext(Map)[]-c(180,180,0,0)

  # 2023-08-20 - this is because of new naming in the original ERA5 land data
  if(product=='ERA5-land'&variable_name=='Rs_sum'){
    # The brackets need be put out first
    Name <- gsub(pattern="(", replacement="", x=Name, fixed = TRUE) # "Fixed = TRUE" disables regex
    Name <- gsub(pattern=")", replacement="", x=Name, fixed = TRUE) # "Fixed = TRUE" disables regex
    
    Name <- gsub(pattern="Surface short-wave solar radiation downwards",
                 replacement="Surface_solar_radiation_downwards",
                 x=Name, fixed = TRUE)
  }
  
  writeRaster(Map,paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name,'/',gsub(' ','_',Name),'_',fun,'_',Date,'.tif'),overwrite=TRUE)

  nc_close(Input)

}else if(n_inputs==2){

  # Read NetCDF file 1
  Input_1<-nc_open(paste0(path_1,'/',File_1))
  Data_1<-rast(paste0(path_1,'/',File_1))

  Origin=gsub("hours since ","",Input_1[['dim']][['time']][['units']]); Origin=as.POSIXct(Origin,tz="GMT")
  Date_1=as.character(Origin+Input_1[['dim']][['time']][['vals']]*3600); Date_1=strftime(Date_1, format = "%Y-%m-%d",tz="UTC")[1]

  # Read NetCDF file 2
  Input_2<-nc_open(paste0(path_2,'/',File_2))
  Data_2<-rast(paste0(path_2,'/',File_2))

  Origin=gsub("hours since ","",Input_2[['dim']][['time']][['units']]); Origin=as.POSIXct(Origin,tz="GMT")
  Date_2=as.character(Origin+Input_2[['dim']][['time']][['vals']]*3600); Date_2=strftime(Date_2, format = "%Y-%m-%d",tz="UTC")[1]

  if(Date_1==Date_2){
    Date=Date_1
  }else{
    stop(paste0('The dates of ',File_1,' and ',File_2,' differ','\n'))
  }

  # Wind speed
  if(grepl('WS10',variable_name)){
    Data<-sqrt(Data_1^2+Data_2^2)
    Name<-'10 metre wind speed' 
  }

  # Vapor pressure deficit
  # This can be done more wisely and memory efficiently - e.g. keep in the memory only T and Td while writing and immediately removing the outputs from the memory
  if(grepl('VPD',variable_name)){
    T<-multiplier*Data_1+offset
    Td<-multiplier*Data_2+offset
    Data_es<-0.6108*exp(17.27*T/(T+237.3))
    Data_e<-0.6108*exp(17.27*Td/(Td+237.3))
    rm(T); gc()
    Data_e<-ifel(Data_e>Data_es,Data_es,Data_e)  # To ensure that VPD>=0 and RH<=100
    Data_RH<-Data_e/Data_es*100
    Data_Td<-Td
    rm(Td); gc()
    Data_VPD<-Data_es-Data_e
    Name_e<-'2 metre vapor pressure'
    Name_es<-'2 metre saturated vapor pressure'
    Name_RH<-'2 metre relative humidity'
    Name_Td<-Input_2$var[[ID_2]]$longname
    Name_VPD<-'2 metre vapor pressure deficit'
  }

  if(grepl('VPD',variable_name)){
    
    #+++
    # Aggregate e to daily
    e<-app(Data_e,fun=get(fun),na.rm=TRUE)
    rm(Data_e); gc()

    # Split the data into two halves
    E<-ext(e)
    x1<-crop(e, ext(E[1], 180-resolution/2, E[3], E[4]))
    E1<-ext(x1)
    x2<-crop(e, ext(180-resolution/2, 360-resolution/2, E[3], E[4]))
    E2<-ext(x2)
    ext(x1) <- E2
    ext(x2) <- E1
  
    # Flipped the halves and put them together
    # Map_e<-mosaic(x=x1,y=x2,fun='mean')
    Map_e<-merge(x=x1,y=x2)

    # To start at -180 and end at +180
    ext(Map_e)<-ext(Map_e)[]-c(180,180,0,0)

    writeRaster(Map_e,paste0('../ERA5-land_processing/ERA5-land_daily/',gsub('VPD','e',variable_name),'/',gsub(' ','_',Name_e),'_',fun,'_',Date,'.tif'),overwrite=TRUE)
    rm(Map_e); rm(e); gc()

    #+++
    # Aggregate es to daily
    es<-app(Data_es,fun=get(fun),na.rm=TRUE)
    rm(Data_es); gc()

    # Split the data into two halves
    E<-ext(es)
    x1<-crop(es, ext(E[1], 180-resolution/2, E[3], E[4]))
    E1<-ext(x1)
    x2<-crop(es, ext(180-resolution/2, 360-resolution/2, E[3], E[4]))
    E2<-ext(x2)
    ext(x1) <- E2
    ext(x2) <- E1
  
    # Flipped the halves and put them together
    # Map_es<-mosaic(x=x1,y=x2,fun='mean')
    Map_es<-merge(x=x1,y=x2)

    # To start at -180 and end at +180
    ext(Map_es)<-ext(Map_es)[]-c(180,180,0,0)

    writeRaster(Map_es,paste0('../ERA5-land_processing/ERA5-land_daily/',gsub('VPD','es',variable_name),'/',gsub(' ','_',Name_es),'_',fun,'_',Date,'.tif'),overwrite=TRUE)
    rm(Map_es); rm(es); gc()

    #+++
    # Aggregate RH to daily
    RH<-app(Data_RH,fun=get(fun),na.rm=TRUE)
    
    # Split the data into two halves
    E<-ext(RH)
    x1<-crop(RH, ext(E[1], 180-resolution/2, E[3], E[4]))
    E1<-ext(x1)
    x2<-crop(RH, ext(180-resolution/2, 360-resolution/2, E[3], E[4]))
    E2<-ext(x2)
    ext(x1) <- E2
    ext(x2) <- E1
  
    # Flipped the halves and put them together
    # Map_RH<-mosaic(x=x1,y=x2,fun='mean')
    Map_RH<-merge(x=x1,y=x2)

    # To start at -180 and end at +180
    ext(Map_RH)<-ext(Map_RH)[]-c(180,180,0,0)

    writeRaster(Map_RH,paste0('../ERA5-land_processing/ERA5-land_daily/',gsub('VPD','RH',variable_name),'/',gsub(' ','_',Name_RH),'_',fun,'_',Date,'.tif'),overwrite=TRUE)
    rm(Map_RH); rm(RH); gc()

    #+++
    # Aggregate RH to daily
    RH_min<-app(Data_RH,fun=min,na.rm=TRUE)
    rm(Data_RH); gc()

    # Split the data into two halves
    E<-ext(RH_min)
    x1<-crop(RH_min, ext(E[1], 180-resolution/2, E[3], E[4]))
    E1<-ext(x1)
    x2<-crop(RH_min, ext(180-resolution/2, 360-resolution/2, E[3], E[4]))
    E2<-ext(x2)
    ext(x1) <- E2
    ext(x2) <- E1
  
    # Flipped the halves and put them together
    # Map_RH_min<-mosaic(x=x1,y=x2,fun='mean')
    Map_RH_min<-merge(x=x1,y=x2)

    # To start at -180 and end at +180
    ext(Map_RH_min)<-ext(Map_RH_min)[]-c(180,180,0,0)

    writeRaster(Map_RH_min,paste0('../ERA5-land_processing/ERA5-land_daily/',gsub('VPD_avg','RH_min',variable_name),'/',gsub(' ','_',Name_RH),'_','min','_',Date,'.tif'),overwrite=TRUE)
    rm(Map_RH_min); rm(RH_min); gc()

    #+++
    # Aggregate Td to daily
    Td<-app(Data_Td,fun=get(fun),na.rm=TRUE)
    rm(Data_Td); gc()

    # Split the data into two halves
    E<-ext(Td)
    x1<-crop(Td, ext(E[1], 180-resolution/2, E[3], E[4]))
    E1<-ext(x1)
    x2<-crop(Td, ext(180-resolution/2, 360-resolution/2, E[3], E[4]))
    E2<-ext(x2)
    ext(x1) <- E2
    ext(x2) <- E1
  
    # Flipped the halves and put them together
    # Map_Td<-mosaic(x=x1,y=x2,fun='mean')
    Map_Td<-merge(x=x1,y=x2)

    # To start at -180 and end at +180
    ext(Map_Td)<-ext(Map_Td)[]-c(180,180,0,0)

    writeRaster(Map_Td,paste0('../ERA5-land_processing/ERA5-land_daily/',gsub('VPD','Td',variable_name),'/',gsub(' ','_',Name_Td),'_',fun,'_',Date,'.tif'),overwrite=TRUE)
    rm(Map_Td); rm(Td); gc()

    #+++
    # Aggregate VPD to daily
    VPD<-app(Data_VPD,fun=get(fun),na.rm=TRUE)
    rm(Data_VPD); gc()

    # Split the data into two halves
    E<-ext(VPD)
    x1<-crop(VPD, ext(E[1], 180-resolution/2, E[3], E[4]))
    E1<-ext(x1)
    x2<-crop(VPD, ext(180-resolution/2, 360-resolution/2, E[3], E[4]))
    E2<-ext(x2)
    ext(x1) <- E2
    ext(x2) <- E1
  
    # Flipped the halves and put them together
    # Map_VPD<-mosaic(x=x1,y=x2,fun='mean')
    Map_VPD<-merge(x=x1,y=x2)

    # To start at -180 and end at +180
    ext(Map_VPD)<-ext(Map_VPD)[]-c(180,180,0,0)

    writeRaster(Map_VPD,paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name,'/',gsub(' ','_',Name_VPD),'_',fun,'_',Date,'.tif'),overwrite=TRUE)
    rm(Map_VPD); rm(VPD); gc()

  }else{
    # Aggregate to daily
    T<-app(Data,fun=get(fun),na.rm=TRUE)

    # Convert units
    T<-multiplier*T+offset

    # Split the data into two halves
    E<-ext(T)
    x1<-crop(T, ext(E[1], 180-resolution/2, E[3], E[4]))
    E1<-ext(x1)
    x2<-crop(T, ext(180-resolution/2, 360-resolution/2, E[3], E[4]))
    E2<-ext(x2)
    ext(x1) <- E2
    ext(x2) <- E1
  
    # Flipped the halves and put them together
    # Map<-mosaic(x=x1,y=x2,fun='mean')
    Map<-merge(x=x1,y=x2)
  
    # To start at -180 and end at +180
    ext(Map)<-ext(Map)[]-c(180,180,0,0)

    writeRaster(Map,paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name,'/',gsub(' ','_',Name),'_',fun,'_',Date,'.tif'),overwrite=TRUE)
  }
  nc_close(Input_1);  nc_close(Input_2)
}
# Remove the temporary files
unlink(paste(temp_path,'/', File_1, sep=''), recursive=TRUE)
