# Wait before all Rscripts are complete

wait<-function(waitingTime=10){
  NP<-1
  while(NP>0){
    Sys.sleep(waitingTime)
    if(OS=='Windows'){
      NP=max(length(system('tasklist /FI "IMAGENAME eq Rscript.exe" ', intern = TRUE))-3,0)
    }else if(OS=='Linux'){
      NP=as.numeric(system('pidof R |wc -w',intern = TRUE))-1
    }else{
      stop("OS must be set to either 'Linux' or 'Windows'")
    }
  }
}