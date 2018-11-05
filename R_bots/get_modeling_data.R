#!/usr/bin/env Rscript

if (interactive()) {
  cred_file = '~/workflow_creds.txt'
  wd = ''
  if (!file.exists(cred_file)) {
    stop(paste('Credentials file', cred_file,  'missing from home directory. Exiting.\n'))
  } else {
    creds = readLines(cred_file)
    creds = strsplit(creds, ' ')[[1]]
    username = creds[1]
    password = creds[2]
    year = 2016
    quarter = 2
    work_dir='~/Documents/training/mysql/repos/workflow-automation'
    use_mysql = FALSE
    csv = paste0(work_dir, '/data/downloads/LoanStats_', year, 'Q', quarter, '.csv')
  }
  
} else {
  ## Read in parameters passed in as arguments
  args = commandArgs(trailingOnly=TRUE)
  username = args[1]
  password = args[2]
  year = args[3]
  quarter = args[4]
  work_dir = args[5]
  use_mysql = as.logical(args[6])
  csv = args[7]
  csv = paste0(work_dir, '/data/downloads/', csv)
}


setwd(work_dir)

## Helper functions
msg = function(u) cat('\n', u, '\n')



if (use_mysql==T) {
  ## Load packages
  library(RMySQL)

  msg('Make connection')
  con <- dbConnect(dbDriver('MySQL'),
                   user=username, password=password,
                   dbname="lending", host="localhost")

  msg('List tables')
  dbListTables(con)

  msg('Retrieve dataset from lending.modeling')
  dat0 = dbGetQuery(con, "select * from lending.modeling")
  Sys.sleep(5)
 } else {
   msg('\nDatasets:')
   abbrev = paste0(work_dir, '/data/join_data/state_abbreviations.csv')
   pop = paste0(work_dir, '/data/join_data/state_population.csv')
   msg(csv)
   msg(abbrev)
   msg(pop)
   
    ## Manually create modeling table
    ## Merge lending club dataset with state abbreviations and state population datasets
    library(data.table)
   
    ## Function to read in records twice (second time to correct data type errors)
    fread2 = function(filename, nskip=0) {
      dat0 = fread(filename, strip.white=F, logical01=F, data.table=F, stringsAsFactors=F, skip=nskip,fill=T)
      classes = sapply(dat0, class)
      dat0 = fread(filename, strip.white=F, logical01=F, data.table=F, stringsAsFactors=F, skip=nskip,fill=T, colClasses=classes)
      return(dat0)
    }
   
    dat0 = fread2(csv, nskip=1)
    dat0 = subset(dat0, !is.na(loan_amnt))
    state_abbrev = fread2(abbrev)
    state_pop = fread2(pop)
    dmerge = merge(state_pop, state_abbrev)
    dat0 = merge(dat0, dmerge, by.x='addr_state', by.y='Abbreviation', all.x=T, all.y=F)
 }



## Selected columns
sel_cols = c('loan_amnt', 'term', 'int_rate', 'installment', 'grade', 'sub_grade', 'emp_length', 'home_ownership', 'annual_inc', 
             'verification_status', 'loan_status', 'purpose', 'dti', 'delinq_2yrs', 'inq_last_6mths', 'pub_rec_bankruptcies', 'open_acc', 
             'pub_rec', 'revol_bal', 'revol_util', 'total_acc', 'addr_state', 'Population2018', 'Growth2018', 'Percent_of_US')
dat0 = dat0[,sel_cols]


msg('Preview of the dataset:')
print(head(dat0))

## Make a copy to be transformed
dat = dat0

msg('Apply data transformations')
dat$term_months = as.numeric(gsub(' months', '', dat$term))
dat$term = NULL
dat$int_rate = as.numeric(gsub('%', '', dat$int_rate))
classes = sapply(dat, class)
charv = names(classes)[classes=='character']
for (vname in charv) dat[,vname] = as.factor(dat[,vname])
table(dat$loan_status)
## Delete rows that are all null values
id_na = which(apply(dat, 1, function(u) all(is.na(u)) == T))
if (length(id_na) > 0) dat = dat[-id_na,]

msg('Print data summary')
summary(dat)

msg('Save dataset to csv')
data_file = paste('data/modeling_data/modeling_dataset_', year, '_Q', quarter, '.csv', sep='')
write.csv(dat, file=data_file, row.names=F, na='')

msg('Save data types to csv')
classes = sapply(dat, class)
data_types = data.frame(field_name=colnames(dat), dtype=classes)
rownames(data_types) = NULL
dtypes_file=paste('data/modeling_data/modeling_datatypes_', year, '_Q', quarter, '.csv', sep='')
write.csv(data_types, file=dtypes_file, row.names=F, na='')

if (use_mysql==T) {
  ## Disconnect
  on.exit(dbDisconnect(con))
}
