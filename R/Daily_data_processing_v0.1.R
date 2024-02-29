suppressMessages(library(terra))

args=commandArgs(trailingOnly=TRUE)

 # cat(args,file='args.txt')
 # args=unlist(strsplit('Rn_sum 5 2_metre_temperature_mean_2006-11-23.tif 2_metre_vapor_pressure_mean_2006-11-23.tif Surface_solar_radiation_downwards_sum_2006-11-23.tif altitude.tif latitude.tif ./ERA5-land_daily/T_avg ./ERA5-land_daily/e_avg ./ERA5-land_daily/Rs_sum ./Static_inputs ./Static_inputs ERA5-land Linux',
 # split=' '))
 # stop()

variable_name=args[1]
n_inputs=as.numeric(args[2])

if(n_inputs==1){
  File_1=args[3]
  path_1=args[4]
}else if(n_inputs==2){
  File_1=args[3]
  File_2=args[4]
  path_1=args[5]
  path_2=args[6]
}else if(n_inputs==3){
  File_1=args[3]
  File_2=args[4]
  File_3=args[5]
  path_1=args[6]
  path_2=args[7]
  path_3=args[8]
}else if(n_inputs==4){
  File_1=args[3]
  File_2=args[4]
  File_3=args[5]
  File_4=args[6]
  path_1=args[7]
  path_2=args[8]
  path_3=args[9]
  path_4=args[10]
}else if(n_inputs==5){
  File_1=args[3]
  File_2=args[4]
  File_3=args[5]
  File_4=args[6]
  File_5=args[7]
  path_1=args[8]
  path_2=args[9]
  path_3=args[10]
  path_4=args[11]
  path_5=args[12]
}else if(n_inputs==8){
  File_1=args[3]
  File_2=args[4]
  File_3=args[5]
  File_4=args[6]
  File_5=args[7]
  File_6=args[8]
  File_7=args[9]
  File_8=args[10]
  path_1=args[11]
  path_2=args[12]
  path_3=args[13]
  path_4=args[14]
  path_5=args[15]
  path_6=args[16]
  path_7=args[17]
  path_8=args[18]
}

product=args[3+n_inputs*2]
OS=args[4+n_inputs*2]

# To compute in RAM use tmp at Linux servers but be carefull to not overload RAM
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
  if(variable_name=='delta_avg'){
    T<-rast(paste0(path_1,'/',File_1))
    delta=4098*(0.6108*exp(17.27*T/(T+237.3)))/(T+237.3)^2
    writeRaster(delta,paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name,'/',gsub('2_metre_temperature','delta',File_1)),overwrite=TRUE)
  }else if(variable_name=='lambda_avg'){
    T<-rast(paste0(path_1,'/',File_1))
    lambda<-2.501-0.002361*T
    writeRaster(lambda,paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name,'/',gsub('2_metre_temperature','lambda',File_1)),overwrite=TRUE)
  }else if(variable_name=='WS2_avg'){
    u10<-rast(paste0(path_1,'/',File_1))
    z<-10
    u2<-u10*4.87/log(67.8*z-5.42)
    writeRaster(u2,paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name,'/',gsub('10_metre','2_metre',File_1)),overwrite=TRUE)
  }else if(variable_name=='cp_avg'){
    q<-rast(paste0(path_1,'/',File_1))
    cpL<-1004.67
    cp<-cpL*(1+0.84*q) 
    writeRaster(cp,paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name,'/',gsub('humidity','heat_of_air',File_1)),overwrite=TRUE)
  }
}else if(n_inputs==2){
  if(variable_name=='q_avg'){
    e<-rast(paste0(path_1,'/',File_1))
    AP<-rast(paste0(path_2,'/',File_2))

    # Specific humidity (kg kg-1)
    q<-0.622*e/(AP-0.378*e) #Foken (2008)
   
    writeRaster(q,paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name,'/',gsub('vapor_pressure','specific_humidity',File_1)),overwrite=TRUE)
  }
}else if(n_inputs==3){
  if(variable_name=='rho_avg'){
    T<-rast(paste0(path_1,'/',File_1))
    e<-rast(paste0(path_2,'/',File_2))
    AP<-rast(paste0(path_3,'/',File_3))

    # Virtual temperature (K)
    T_virtual<-(T+273.15)/(1-0.378*e/AP)

    # Specific gas constant (J kg-1 K-1)
    R<-287

    rho<-1000*AP/(T_virtual*R)
    writeRaster(rho,paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name,'/',gsub('vapor_pressure','atmospheric_density',File_2)),overwrite=TRUE)
  }else if(variable_name=='gamma_avg'){
    cp<-rast(paste0(path_1,'/',File_1))
    AP<-rast(paste0(path_2,'/',File_2))
    lambda<-rast(paste0(path_3,'/',File_3))

    # Ratio of molecular weight of water vapour/dry air
    epsilon<-0.622
    gamma<-cp*AP/(epsilon*lambda*10^6)
    writeRaster(gamma,paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name,'/',gsub('specific_heat_of_air','psychrometric_constant',File_1)),overwrite=TRUE)
  }
}else if(n_inputs==4){
  if(variable_name=='Rn_sum'){
    T<-rast(paste0(path_1,'/',File_1))
    e<-rast(paste0(path_2,'/',File_2))
    Rs<-rast(paste0(path_3,'/',File_3))
    Rso<-rast(paste0(path_4,'/',File_4))

    Rns<-(1-0.23)*Rs
    clearness_index=Rs/Rso
    clearness_index<-ifel(clearness_index>1,1,clearness_index)
    clearness_index<-ifel(Rso<0.5,0.75,clearness_index) # In the case of very low Rso, clearness index cannot be determined and is set to 0.75

    # Net outgoing longwave radiation (MJ m-2 day-1); note that Rs/Rso must be <=1
    Rnl<-4.903*10^(-9)*(T+273.16)^4*(0.34-0.14*sqrt(e))*(1.35*(clearness_index)-0.35)

    # Net radiation (MJ m-2 day-1)
    Rn<-Rns-Rnl
    writeRaster(Rn,paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name,'/',gsub('_solar_radiation_downwards','_net_radiation',File_3)),overwrite=TRUE)
  }else if(variable_name=='PET_sum'){
    delta<-rast(paste0(path_1,'/',File_1))
    Rn<-rast(paste0(path_2,'/',File_2))
    gamma<-rast(paste0(path_3,'/',File_3))
    lambda<-rast(paste0(path_4,'/',File_4))
    G<-0
    alpha<-1.26

    PET<-(alpha*delta*(Rn-G)/(delta+gamma))/lambda
    PET<-ifel(PET<0,0,PET)
    writeRaster(PET,paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name,'/',gsub('Surface_net_radiation','Priestley-Taylor_potential_evapotranspiration',File_2)),overwrite=TRUE)
  }
}else if(n_inputs==5){
  if(variable_name=='Rn_sum'){
    T<-rast(paste0(path_1,'/',File_1))
    e<-rast(paste0(path_2,'/',File_2))
    Rs<-rast(paste0(path_3,'/',File_3))
    alt<-rast(paste0(path_4,'/',File_4))
    lat<-rast(paste0(path_5,'/',File_5))
    
    LatInRad<-lat/180*pi
    
    Date=as.Date(gsub('.tif','',gsub('2_metre_temperature_mean_','',File_1)))

    year<-as.numeric(strftime(Date, format = "%Y",tz="UTC"))
    JD<-as.numeric(strftime(Date, format = "%j",tz="UTC"))
    
    # Decide wheather the year is leap or not
    Leap<-year %% 4 == 0 & (year %% 100 != 0 | year %% 400 == 0)
    
    # Determine the number of days in year
    if(Leap %in% TRUE){
      days=366
    }else{
      days=365
    }
    
    # Inverse relative distance Earth-Sun
    dr=1+0.033*cos(2*pi/days*JD)
    
    # Solar declination (radians)
    SolDec=0.409*sin(2*pi/days*JD-1.39)
    
    omega=LatInRad
    omega=acos(ifel(-tan(LatInRad)*tan(SolDec)<(-1),-1,ifel(-tan(LatInRad)*tan(SolDec)>1,1,-tan(LatInRad)*tan(SolDec))))
    
    # Solar constant (MJ m-2 min-1)
    Gsc=0.0820
    
    # Extraterrestrial radiation (MJ m-2 day-1)
    Ra=24*60/pi*Gsc*dr*(omega*sin(LatInRad)*sin(SolDec)+cos(LatInRad)*cos(SolDec)*sin(omega))
    
    # Albedo (-)
    alpha=0.23  
    
    # Net solar or shortwave radiation (MJ m-2 day-1)
    Rns=(1-alpha)*Rs

    # Calculated clear-sky radiation (MJ m-2 day-1)
    Rso=(0.75+0.00002*alt)*Ra
    
    clearness_index=Rs/Rso
    clearness_index<-ifel(clearness_index>1,1,clearness_index)
    clearness_index<-ifel(Rso<0.5,0.75,clearness_index) # In the case of very low Rso, clearness index cannot be determined and is set to 0.75
    
    # Net outgoing longwave radiation (MJ m-2 day-1); note that Rs/Rso must be <=1
    Rnl<-4.903*10^(-9)*(T+273.16)^4*(0.34-0.14*sqrt(e))*(1.35*(clearness_index)-0.35)
    
    # Net radiation (MJ m-2 day-1)
    Rn<-Rns-Rnl
    writeRaster(Rn,paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name,'/',gsub('_solar_radiation_downwards','_net_radiation',File_3)),overwrite=TRUE)
  }
}else if(n_inputs==8){
  if(variable_name=='ETo_sum'){
    delta<-rast(paste0(path_1,'/',File_1))
    Rn<-rast(paste0(path_2,'/',File_2))
    rho<-rast(paste0(path_3,'/',File_3))
    cp<-rast(paste0(path_4,'/',File_4))
    VPD<-rast(paste0(path_5,'/',File_5))
    u2<-rast(paste0(path_6,'/',File_6))
    gamma<-rast(paste0(path_7,'/',File_7))
    lambda<-rast(paste0(path_8,'/',File_8))
    G<-0
    rs<-70
    ra<-208/u2
    cp<-cp*10^(-6) # MJ kg-1 K-1
    
    # FAO56 reference grass evapotranspiration
    ETo<-((delta*(Rn-G)+24*3600*rho*cp*VPD/ra)/(delta+gamma*(1+rs/ra)))/lambda
    ETo<-ifel(ETo<0,0,ETo)
    writeRaster(ETo,paste0('../ERA5-land_processing/ERA5-land_daily/',variable_name,'/',gsub('Surface_net_radiation','FAO56_reference_evapotranspiration',File_2)),overwrite=TRUE)
  }
}

# Remove the temporary files
unlink(paste(temp_path,'/', File_1, sep=''), recursive=TRUE)