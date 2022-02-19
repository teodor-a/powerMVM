# -*- coding: utf-8 -*-
"""
Created on Sat Feb 19 22:43:43 2022

@author: Teodor
"""

#%%
### Import some libraries ###
import requests # For handling API calls
import pandas as pd # For using data frames and working with data formats
from datetime import datetime # For converting silly date formats to normal
import re # For some regex.
import csv


#%%

# Some parameters used in the program which will not change (often):

# A token is used as a part of the request, to authorize/fingerprint it.
# The following is my personal token. One can get a token by visiting:
# https://miljodata.slu.se/MVM/OpenAPI

token = "PUJD93023KAS943HD"


#%%

# Function to create a request. I have chosen to use one of the API methods,
# called "GetSamplesBySite". It downloads all samples from the given site
# and the given years.

def makereq(siteid, fromyear, toyear):
    # Make a URL and use the function get() to make the request to the API:
    URL = "https://miljodata.slu.se/mvm/ws/ObservationsService.svc" \
            + "/rest/GetSamplesBySite?" \
            + "token=" + token \
            + "&siteid=" + str(siteid) \
            + "&fromYear=" + str(fromyear) \
            + "&toYear=" + str(toyear)
    response = requests.get(URL)
    # Return the response object,
    # which contains both the data and a status code:
    return(response)


#%%

# Function to convert the dates in json (data format returned from the API,
# more on this below) to normal date format:
    
def jsondate_to_normaldate(jsondate):
    m = re.search(r"Date\((\d+)\+", jsondate)
    newdate = datetime.fromtimestamp(int(m.group(1))/1000.0).strftime('%Y-%m-%d')
    return(newdate)  

#%%

# Function which takes one of the entries (one observation) and makes
# a single row out of it:
    
def make_row(list_entry):
    if list_entry['IsBiologicalSample'] == False:
        ### Code for abiotic entries ###
        framed = pd.json_normalize(list_entry, 'ObservationValues')
        prop_codes = [str(x)+"__" for x in framed['PropertyCode']]
        units = [str(x) for x in framed['UnitOfMeasureName']]
        headers = list(map(str.__add__, prop_codes, units))
        rowdata = [x.replace(",", ".") for x in framed['ReportedValue']]
        rowdata = [y.replace("<", "") for y in rowdata]
        rowdata = pd.to_numeric(rowdata, errors = "coerce")
        rowdata = rowdata.astype(float)
        dataframe = pd.DataFrame(columns = headers, data = [rowdata])
        #dataframe['SampleID'] = [list_entry['SampleId']]
        #dataframe['SiteID'] = [list_entry['SiteId']]
        #dataframe['sample_date'] = [list_entry['SampleDate']]
        #dataframe['nat_stat_ID'] = [list_entry['NationalStationId']]
    elif list_entry['IsBiologicalSample'] == True:
        ### Code for biotic entries ###
        # ObservationValues:
        framedOBS = pd.json_normalize(list_entry, 'ObservationValues')
        prop_abbrev = [str(x)+"__" for x in framedOBS['PropertyAbbrevName']]
        units = [str(x) for x in framedOBS['UnitOfMeasureName']]
        headers = list(map(str.__add__, prop_abbrev, units))
        rowdata = [str(x).replace(",", ".") for x in framedOBS['ReportedValue']]
        rowdata = pd.to_numeric(rowdata, errors = "coerce")
        dataframeOBS = pd.DataFrame(columns = headers, data = [rowdata])
        # IndexValues:
        framedIND = pd.json_normalize(list_entry, 'IndexValues')
        if 'FomaIndexShortName' in framedIND:
            fomaindexname = [str(x)+"__" for x in framedIND['FomaIndexShortName']]
            units = [str(x) for x in framedIND['UnitOfMeasureName']]
            headers = list(map(str.__add__, fomaindexname, units))
            rowdata = [str(x).replace(",", ".") for x in framedIND['Value']]
            rowdata = [str(y).replace("<", "") for y in rowdata]
            rowdata = pd.to_numeric(rowdata, errors = "coerce")
            rowdata = rowdata.astype(float)
            dataframeIND = pd.DataFrame(columns = headers, data = [rowdata])
            # Combine ObsVals and IndVals dataframes:
            dataframe = pd.concat([dataframeOBS, dataframeIND], axis = 1)
        else:
            dataframe = dataframeOBS
        dataframe = dataframe.loc[:,~dataframe.columns.duplicated()]
        # Add sample ID, site ID, sample date, and national station ID:
        #dataframe['SampleID'] = [list_entry['SampleId']]
        #dataframe['SiteID'] = [list_entry['SiteId']]
        #dataframe['sample_date'] = [list_entry['SampleDate']]
        #dataframe['nat_stat_ID'] = [list_entry['NationalStationId']]
    else:
        dataframe = "This is neither biotic nor abiotic sample."
    # Add sample ID, site ID, sample date, and national station ID:
    dataframe['SampleID'] = [list_entry['SampleId']]
    dataframe['SiteID'] = [list_entry['SiteId']]
    dataframe['sample_date'] = [jsondate_to_normaldate(list_entry['SampleDate'])]
    dataframe['nat_stat_ID'] = [list_entry['NationalStationId']]
    return(dataframe)



#%%

# Function to take all observations from a given site
# (from 1940 to 2021 inclusive) and combine them to a massive dataframe.
# For subsequent completions to the database, instead download data from
# all sites, but 2022-2023 (for example) instead.

# Uses site IDs as found at
# https://miljodata.slu.se/MVM/DataContents/SamplingSites?sitetype=1

def getallobs_fromsite(site):
    # Make the request for the site in question, using all years until 2021:
    response = makereq(site, 1940, 2021) # OBS MAKE SURE THE DATES ARE CORRECT
    data = response.json()
    # Make rows out of all observations downloaded, and then
    # combine them into one dataframe with one row per observation:

    # First initialise a big dataframe using the row created from
    # the first observation:
    allyears = make_row(data[0])
    # Then iterate over the remaining observations and add them to the "big df"
    # as you go:
    for obs in range(1, len(data)):
        row = make_row(data[obs])
        allyears = pd.merge(allyears, row, how = 'outer')

    # Check for repeated column names:
    duplicates = [col for col in list(allyears.columns) if \
                  list(allyears.columns).count(col) > 1]
    if duplicates:
        raise Exception('There seems to be duplicated column names in the \
                        final dataframe. This is not good.')
    # The result is a dataframe containing all data until 2021, for one site:
    return(allyears)


#%%

# Function to take all observations (from 1940 to 2021) from all sites.
# Again, uses site IDs as found at
# https://miljodata.slu.se/MVM/DataContents/SamplingSites?sitetype=1
# Click the CSV button to download a table of all stations.
# On february 19th 2022, I downloaded such a table. It can be found in the
# same directory as this script. Here, I load the csv to extract the 
# station IDs:

# Initialise list which will be used to store all stations:
list_of_stationids = []
# Keep the csv open:
with open("Miljödata MVM - Stationer.csv", mode = 'r') as file:
    # use csv reader function to read the file:
    stations = csv.reader(file)
    # Iterate over all lines in the file:
    for lines in stations:
        # Append the first item in each line (this is the station ID):
        list_of_stationids.append(lines[0])

# Remove the first list entry which is just "Id":        
list_of_stationids = list_of_stationids[1:]

# OBS JUST TO TEST, COMMENT/REMOVE THIS LINE LATER
list_of_stationids = list_of_stationids[0:20]


# Now define the function: 
    
def allobs_allsites():
    # Initialise with the data from the first site:
    compleet = getallobs_fromsite(list_of_stationids[0])
    # Then iterate over the remaining sites and add them to the "compleet df"
    for site in list_of_stationids[1:]:
        thissite = getallobs_fromsite(site)
        compleet = pd.merge(compleet, thissite, how = 'outer')
    # Check for repeated column names:
    duplicates = [col for col in list(compleet.columns) if \
                  list(compleet.columns).count(col) > 1]
    if duplicates:
        raise Exception('There seems to be duplicated column names in the \
                        final dataframe. This is not good.')
    # The result is a dataframe containing all data until 2021, for one site:
    return(compleet)


#%%
bigboy = allobs_allsites()