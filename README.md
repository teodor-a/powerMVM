# powerMVM
Some R scripts to get data from Miljödata MVM to a nice personal database.


# Purpose
It would be nice to have a copy of the complete Miljödata MVM database, in order to analyse the data contained when for example exploring ecological patterns in multicellularity.

The database has a graphic interface that can be used to get data, but this cannot be automated and it only allows a certain data size per download, splitting a complete database download up into several .csv files.

In addition, we may want to easily update the personal database every once in a while, to get hold of new data. The scripts herein allow for this as well.


# Structure
The master script contains the full process of getting data from miljödata, reshaping it and tidying it and ultimately making a dataframe with one row per observation. See this file for further walkthrough. The process is divided into many steps, and for structure and clarity purposes it has been divided into several script files. The master script binds these together.
