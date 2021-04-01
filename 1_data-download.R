## Packages needed:
library(httr)
library(jsonlite)
library(tidyverse)

download_samplesbysite <- function(token, siteid, fromyear, toyear) {
  
  apicall <-
    paste("https://miljodata.slu.se/mvm/ws/ObservationsService.svc/",
          "rest/GetSamplesBySite?token=", token, "&siteid=", siteid,
          "&fromYear=", fromyear, "&toYear=", toyear, sep = "")
  
  res <- GET(apicall) # Function GET() is from package httr.
  
  if (res$status_code != 200) {
    
    cat("Error in download. Status code must be '200' to proceed.\n")
    cat("Check status code in res object to troubleshoot:\n")
    print(res)
    
  } else {
    
    data <- rawToChar(res$content) %>% fromJSON() %>% as.data.frame()
    # Function fromJSON from package jsonlite.
    # Gets the data downloaded with GET() into a more familiar format.
    # Function %>% from package tidyverse. Piping.
    return(data)
    
  }
}