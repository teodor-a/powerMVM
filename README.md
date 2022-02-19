# powerMVM
A program to get data from Miljödata MVM to a nice personal database.


# Purpose
It would be nice to have a copy of the complete Miljödata MVM database, in order to analyse the data contained when for example exploring ecological patterns in multicellularity.

The database has a graphic interface that can be used to get data, but this cannot be automated and it only allows a certain data size per download, splitting a complete database download up into several .csv files.

In addition, we may want to easily update the personal database every once in a while, to get hold of new data.

# To Do:
- [x] Create a series of functions which together download all observations from all sites and all years
- [ ] Fix the pseudo-duplicated column names. Preferrably by merging all child taxa into one parent taxa (on what level?? Genus?)
- [ ] Make it so it can be called from command line using flags
- [ ] add functions to use when simply updating the database with the latest entries
- [ ] Eventually add simple analysis methods (R?)
