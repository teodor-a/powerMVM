## This is the master script, with which to puzzle together the chain of 
## actions needed to get data from Miljödata MVM, using the API, and working it
## into a nice dataset which can be used for analysis.

## Contents of this script:
# 1. Data download and conversion from JSON to data frames and lists.
# 2. Reshaping data into an intuitive data frame
# 3. Tidying the big dataframe for analyses

## See separately scripts to do the following:
# 4. Code to supplement the data.
# 5. Statistical analyses, and its eventual additional data restructuring.

## General notes:
# Take a look at the separate scripts used (referred to and soruced in the
# beginning of each section below) to see if there are any packages used that
# you need to install first (see section at the top of each script for list of
# packages used).


##################################################################################
## Section 1: Data download ####
# Please refer to the script "1_data-download.R" for the code used.
# It contains the functions used to download data via the Miljödata API.
# It is sourced below:
source("1_data-download.R")

# Construct the API call details:

token <- "R398SAJDKLKA9AKJ2"
# This is a "key" that I got from Miljo:data/artdatabanken.
# Anyone can get one, just make an account. It is used in our API calls.

# Below we define the range of years we want to get data from:
fromyear <- 1996 # Which year do you want to start the range with?
toyear <- 1997 # which year do you want to end the range with?

# Uncomment the next line if you only want one site at a time:
siteid <- 145
# The present script, as you will see below, is designed to take multiple years
# from multiple sites in one go, but there is no API method for that so I use the
# "GetSamplesBySite" method (as used in the separate script for this section) and
# use it to loop all site IDs.

# Looking at the object 'res' we can see the http query, the date it was queried,
# the status (200 means it went ok), the content type, and the size.
# Look at the res object and make sure that "Status" is 200. Only 200 means OK,
# see this website for info on other codes:
# https://www.restapitutorial.com/httpstatuscodes.html

data <- download_samplesbysite(token = token, siteid = siteid,
                               fromyear = fromyear, toyear = toyear)
##################################################################################

##################################################################################
## Section 2: Data restructure ####
# The data we just downloaded is not in an optimal format and could use
# some restructuring. Fortunately, I figured out just what is what, and have here
# aimed to ultimately create a data frame with:
### >>> one row per sample <<< ###
# Please refer to the script "2_data-reshape.R" for the code used.
# It contains the functions used to restructure data via the Miljödata API.
# It is sourced below:
source("2_data-reshape.R")

restructured_data <- reshape_samplesbysite(df = data)

# Congratulations! You now have a dataframe with all observations
# (chemistry + biology) from the site you specified, from the starting year you # specified to the final year you specified, in the beginning of this script.


# Now, the process could be repeated for all sampling stations/sites.
# These can be found here: https://miljodata.slu.se/MVM/DataContents/SamplingSites