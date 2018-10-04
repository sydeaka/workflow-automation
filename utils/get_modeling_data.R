#!/usr/bin/env Rscript

if (interactive()) {
  cred_file = '~/workflow_creds.txt'
  wd = 
  if (!file.exists(cred_file)) {
    stop(paste('Credentials file', cred_file,  'missing from home directory. Exiting.\n'))
  } else {
    creds = readLines(cred_file)
    creds = strsplit(creds, ' ')[[1]]
    username = creds[1]
    password = creds[2]
    year = 2018
    quarter = 2
    work_dir='/Users/sw659h/Documents/training/mysql'
  }
  
} else {
  ## Read in parameters passed in as arguments
  args = commandArgs(trailingOnly=TRUE)
  username = args[1]
  password = args[2]
  year = args[3]
  quarter = args[4]
  work_dir = args[5]
  
}

setwd(work_dir)

## Load packages
library(RMySQL)

## Helper functions
msg = function(u) cat('\n', u, '\n')

msg(paste('Running in interactive mode? ', interactive()))

msg('Make connection')
con <- dbConnect(dbDriver('MySQL'),
                 user=username, password=password,
                 dbname="lending", host="localhost")

msg('List tables')
dbListTables(con)

msg('Retrieve dataset from lending.modeling')
dat0 = dbGetQuery(con, "select * from lending.modeling")
Sys.sleep(5)

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

## Disconnect
on.exit(dbDisconnect(con))
