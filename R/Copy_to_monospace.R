rm(list = ls())

monospace_path <- '/mnt/monospace-mendelu/ERA5-land/Hourly/ERA5-land_processing/ERA5-land_daily'

#Years <- 1950:2021
Years=2024

# Near real time
NRT=TRUE

# 'all' or some integer
N_files_to_copy=6
# N_files_to_copy='all'

Dirs <- list.dirs(path = '../ERA5-land_processing/ERA5-land_daily', recursive = FALSE, full.names = FALSE)

Vars = c('AP_avg',
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

Take = c(1,4,5,6,9,12,13,16,17,18,19,20,21,22)

print(Vars[Take])

Vars <- Vars[Take]

START=1
END=length(Years)

for(Y in START:END){
  if(NRT==TRUE){
    dir.create(paste0(monospace_path,'/',Years[Y],'_T'),showWarnings = FALSE)
  }else{
    dir.create(paste0(monospace_path,'/',Years[Y]),showWarnings = FALSE)
  }
  
  for(V in 1:length(Vars)){
    if(NRT==TRUE){
      dir.create(paste0(monospace_path,'/',Years[Y],'_T/',Vars[V]),showWarnings = FALSE)
    }else{
      dir.create(paste0(monospace_path,'/',Years[Y],'/',Vars[V]),showWarnings = FALSE)
    }
    
    Files <- list.files(path = paste0('../ERA5-land_processing/ERA5-land_daily/',Vars[V]), pattern='\\.tif$')
    Year_string <-  as.numeric(substr(x=Files, start = nchar(Files)-13, stop = nchar(Files)-10))
    
    To_copy <- which(Year_string %in% Years[Y])

    if(N_files_to_copy!='all'){
      To_copy <- To_copy[(length(To_copy)-N_files_to_copy+1):length(To_copy)]
    }

    if(NRT==TRUE){
      file.copy(from = paste0('../ERA5-land_processing/ERA5-land_daily/',Vars[V],'/',Files[To_copy]),
                to = paste0(monospace_path,'/',Years[Y],'_T/',Vars[V],'/',Files[To_copy]), overwrite = TRUE)
    }else{
      file.copy(from = paste0('../ERA5-land_processing/ERA5-land_daily/',Vars[V],'/',Files[To_copy]),
                to = paste0(monospace_path,'/',Years[Y],'/',Vars[V],'/',Files[To_copy]), overwrite = TRUE)
    }
  }
}
