library(plyr)
library(stringr)

reshape_samplesbysite <- function(df) {
  
  df_nonrec <- df[!sapply(df, is.list)]
  # Takes the columns of the dataframe-ified JSON data which are not themselves
  # lists, i.e. are already one row per sample and do not need further work.
  
  df_rec <- df[sapply(df, is.list)]
  # Takes the columns of the dataframe-ified JSON data, which are lists and
  # therefore need to be changed into dataframes with the same number of
  # rows as samples.
  
  df_rec <- as.list(df_rec)
  
  #names(df_rec) # Do not uncomment.
  # Only here if one wants to follow my line of discovery.
  
  # They are:
  # IndexValues
  indvals <- df_rec$IndexValues
  # ObservationValues
  obsvals <- df_rec$ObservationValues
  # ObservedPropertyList
  obspl <- df_rec$ObservedPropertyList
  # SampleMetadataList
  samp_meta <- df_rec$SampleMetadataList
  # SiteMetadata
  site_meta <- df_rec$SiteMetadata
  # TaxonGroupCalculationValues
  taxcalc <- df_rec$TaxonGroupCalculationValues
  
  #sapply(df_rec, length)  # Do not uncomment.
  # Only here if one wants to follow my line of discovery.
  # They are all lists of the same number of entries as there are samples in the
  # data. For example, ObservationValues contains 4 dataframes, and each should
  # be made into one row.
  
  ####################################
  ## IndexValues: ############

  # names(indvals[[6]]) == names(indvals[[7]]) # Do not uncomment.
  # Only here if one wants to follow my line of discovery.
  # All dataframes within "IndexValues" contain the same type of data,
  # confirming that each is the equivalent of one sample.
  
  rows <- vector("list", length(indvals))
  # Make empty list in which to store our newly created rows.
  
  for (indval_entry in 1:length(indvals)) {
    # Isolate the observation:
    entry <- indvals[[indval_entry]]
    # Sometimes there is no sample, so only proceed if more than 0 rows:
    if (nrow(entry) > 0) {
      # Make empty vector to later store the names of the columns:
      names_of_columns <- c(rep(NA, nrow(entry)))
      # Make empty vector to later store the data in the rows:
      data_in_row <- c(rep(NA, nrow(entry)))
      for (colindex in 1:length(names_of_columns)) {
        # Name each column-to-be after the parameter type and its unit:
        names_of_columns[colindex] <- paste(entry$FomaIndexShortName[colindex],
                                            "_",
                                            entry$UnitOfMeasureName[colindex],
                                            sep = "")
        # Fill in the data values:
        data_in_row[colindex] <- entry$Value[colindex]
      }
      # Also add a column containing the observation ID:
      names_of_columns <- c(names_of_columns, "ObservationSetId")
      # Fill this column with the observation ID:
      data_in_row <- as.character(c(data_in_row, entry$ObservationSetId[1]))
      # Change the column names to replace problematic/ugly characters:
      names_of_columns <-
        str_replace_all(string = names_of_columns, c("/" = "_per_",
                                                     "Âµ" = "micro",
                                                     "Ã¤" = "ae",
                                                     "%" = "percent",
                                                     "Â°" = "deg",
                                                     " " = ".")
                        ) # Function str_replace_all from package stringr.
      # Make data frame out of the data:
      singlerow <- as.data.frame(matrix(data = data_in_row, nrow = 1,
                                        ncol = length(data_in_row)))
      # Name the columns of the newly created data frame:
      colnames(singlerow) <- names_of_columns
      # Add the newly created data frame to the list
      # We will bind together all these one-row data frames later.
      rows[[indval_entry]] <- singlerow
    }
  }
  
  # Bind the rows together:
  indvals_transformed <- rbind.fill(rows) # Function rbind.fill from package plyr
  
  ####################################
  ## ObservationValues: ######
  # Note: the below code is very similar to what was used above for IndexValues
  # (and the whole code could indeed be improved so it is not repeated, but that
  # is an optimisation issue we can deal with later), so I will not comment it.
  # Instead refer to the corresponding code above for IndexValues, for comments.
  
  rows <- vector("list", length(obsvals))
  
  for (obsval_entry in 1:length(obsvals)) {
    entry <- obsvals[[obsval_entry]]
    if (nrow(entry) > 0) {
      names_of_columns <- c(rep(NA, nrow(entry)))
      data_in_row <- c(rep(NA, nrow(entry)))
      for (colindex in 1:length(names_of_columns)) {
        names_of_columns[colindex] <- paste(entry$PropertyAbbrevName[colindex],
                                            "_",
                                            entry$UnitOfMeasureName[colindex],
                                            sep = "")
        data_in_row[colindex] <- entry$ReportedValue[colindex]
      }
      names_of_columns <- c(names_of_columns, "ObservationSetId")
      data_in_row <- as.character(c(data_in_row, entry$ObservationSetId[1]))
      names_of_columns <-
        str_replace_all(string = names_of_columns, c("/" = "_per_",
                                                     "Âµ" = "micro",
                                                     "Ã¤" = "ae",
                                                     "%" = "percent",
                                                     "Â°" = "deg",
                                                     " " = ".")
                        ) # Function str_replace_all from package stringr.
      singlerow <- as.data.frame(matrix(data = data_in_row, nrow = 1,
                                        ncol = length(data_in_row)))
      colnames(singlerow) <- names_of_columns
      rows[[obsval_entry]] <- singlerow
    }
  }
  
  obsvals_transformed <- rbind.fill(rows)
  
  
  ####################################
  # ObservedPropertyList: ####
  # When I was exploring the data with an example site and years, this was empty.   # I'm not sure what it would contain, but the biology and chemistry is in the
  # other list entries so I'm quite satisfied.
  
  ####################################
  ## SampleMetadataList: #####
  # I will not be concerned about this data as I don't think it will be that
  # useful. I can always get any sample's full data, including metadata,
  # later if I need it using the appropriate API method.
  
  ####################################
  ## SiteMetadata: ###########
  # Same here, as for SampleMetadatalist.
  
  ####################################
  ## TaxonGroupCalculationValues: ####
  # Note: the below code is very similar to what was used above for IndexValues
  # (and the whole code could indeed be improved so it is not repeated, but that
  # is an optimisation issue we can deal with later), so I will not comment it.
  # Instead refer to the corresponding code above for IndexValues, for comments.
  
  # Note 1: This one is a little tricky, however. In some entries (data frames),
  # some columns are themselves a data frame. This messes with the indexing,
  # and we should "straighten out" the data frame to be "flat" first.
  # This is solved below.
  # Note 2: Also, there are two different unit types ("abundance" and "sum").
  # We should include both to be sure. Each has an associated value
  # ("BioSumValue" and "AbundanceSumValue" respectively).
  # This is solved below.
  
  rows <- vector("list", length(taxcalc))
  
  for (taxcalc_entry in 1:length(taxcalc)) {
    entry <- taxcalc[[taxcalc_entry]]
    if (nrow(entry) > 0) {
      entry_need_straightening <- entry[sapply(entry, is.data.frame)]
      entry_therest <- entry[!sapply(entry, is.data.frame)]
      
      new_entry_need_straightening <-
        entry_need_straightening[[1]]
      
      new_entry_need_straightening <-
        vector("list", ncol(entry_need_straightening))
      
      for (weirdcolumn in 1:ncol(entry_need_straightening)) {
        new_entry_need_straightening[[weirdcolumn]] <-
          entry_need_straightening[[weirdcolumn]]
        
        colnames(new_entry_need_straightening[[weirdcolumn]]) <-
          paste(names(entry_need_straightening)[weirdcolumn],
                names(new_entry_need_straightening[[weirdcolumn]]),
                sep = "_")
      }
      
      new_entry_need_straightening <-
        do.call(cbind, new_entry_need_straightening)
      
      entry <- cbind(new_entry_need_straightening, entry_therest)
      rm(entry_need_straightening)
      rm(entry_therest)
      rm(new_entry_need_straightening)
      # What we need is...    
      # GroupTaxonProperty_AbbrevName for both of the following:
      # AbundanceSumUnit_Code + AbundanceSumValue
      # BioSumUnit_Code + BioSumValue
      names_of_columns <- c(rep(NA, nrow(entry)))
      data_in_row <- c(rep(NA, nrow(entry)))
      for (colindex in 1:length(names_of_columns)) {
        # We need one set of column names and values if the sample contains 
        # Biosum, and a different set of column names and values if the sample
        # contains abundance:
        # I have decided that if the sample contains both (I'm not sure if this
        # is ever the case or not), I will go for Biosum. It's a pretty arbitrary
        # choice but can easily be changed if needed.
        if ("BioSumValue" %in% names(entry)) {
          names_of_columns[colindex] <-
            paste(entry$GroupTaxonProperty_AbbrevName[colindex],
                  "_",
                  entry$BioSumUnit_Code[colindex],
                  sep = "")
          data_in_row[colindex] <- entry$BioSumValue[colindex]
        } else {
          names_of_columns[colindex] <-
            paste(entry$GroupTaxonProperty_AbbrevName[colindex],
                  "_",
                  entry$AbundanceSumUnit_Code[colindex],
                  sep = "")
          data_in_row[colindex] <- entry$AbundanceSumValue[colindex]
        }
      }
      
      names_of_columns <- c(names_of_columns, "ObservationSetId")
      data_in_row <- as.character(c(data_in_row, entry$ObservationSetId[1]))
      names_of_columns <-
        str_replace_all(string = names_of_columns, c("/" = "_per_",
                                                     "Âµ" = "micro",
                                                     "Ã¤" = "ae",
                                                     "%" = "percent",
                                                     "Â°" = "deg",
                                                     " " = ".",
                                                     "Ã–" = "Oe")
                        ) # Function str_replace_all from package stringr.
      singlerow <- as.data.frame(matrix(data = data_in_row, nrow = 1,
                                        ncol = length(data_in_row)))
      colnames(singlerow) <- names_of_columns
      rows[[taxcalc_entry]] <- singlerow
    }
  }
  
  taxcalc_transformed <- rbind.fill(rows)
  # Function rbind.fill() from package plyr.
  
  ####################################
  ## Next steps: #####################
  # Whew! Now we have all the "strange" contents sorted out.
  # Now, all we need to do it combine these three into one really wide dataframe.
  # Use the observation ID columns to match rows.
  # Each observation should only have one row in each of these three data frames.
  # Combine columns.
  # Uncomment the next three lined if you want to see the observations in each:
  # indvals_transformed$ObservationSetId 
  # obsvals_transformed$ObservationSetId
  # taxcalc_transformed$ObservationSetId
  ind_obs <- merge(indvals_transformed, obsvals_transformed,
                   by = "ObservationSetId", all = TRUE)
  ind_obs_tax <- merge(ind_obs, taxcalc_transformed, by = "ObservationSetId",
                       all = TRUE)
  
  ### Remember the part of the data that was "fine"? We need to add that as well.
  # The three we just spend a long time on tidying above need to meet with their
  # friends again.
  # Combine ind_obs_tax with the rest from the original download:
  # Use the ObservationSetId column from ind_obs_tax and the SampleId column from
  # df_nonrec to match rows.
  # Each observation should only have one row in each of these three data frames.
  # Combine columns.
  # In ind_obs_tax, the observation ID column is called ObservationSetID:
  #ind_obs_tax$ObservationSetId
  # In df_nonrec, the observation ID column is called SampleId:
  #df_nonrec$SampleId
  # Change the names:
  names(df_nonrec)[names(df_nonrec) == 'SampleId'] <- "ObservationSetId"
  final_dataframe <- merge(ind_obs_tax, df_nonrec, by = "ObservationSetId",
                           all = TRUE)
  
  return(final_dataframe)
}