#!/usr/bin/env Rscript

if (interactive()) {
  cred_file <- '~/workflow_creds.txt'
  wd <- ''
  if (!file.exists(cred_file)) {
    stop(paste('Credentials file', cred_file,  'missing from home directory. Exiting.\n'))
  } else {
    creds <- readLines(cred_file)
    creds <- strsplit(creds, ' ')[[1]]
    username <- creds[1]
    password <- creds[2]
    mysql_script_filename <- 'data/sql/modeling.sql'
  }
  
} else {
  ## Read in parameters passed in as arguments
  args <- commandArgs(trailingOnly=TRUE)
  username <- args[1]
  password <- args[2]
  mysql_script_filename <- args[3]
}



## Helper functions
msg <- function(u) cat('\n', u, '\n')

## Read in the contents of the MySQL script as a vector of strings (i.e., one entry per command)
queries <- paste(readLines(mysql_script_filename), collapse=" ")
queries <- sapply(strsplit(queries, ';')[[1]], function(u) paste0(trimws(u), ';'))
names(queries) <- NULL


## Load packages
library(RMySQL)

msg('Make connection')
con <- dbConnect(dbDriver('MySQL'),
                 user=username, password=password,
                 dbname="lending", host="localhost")

msg('Execute contents of MySQL script')
for (query in queries) {
  cat(query)
  dbSendStatement(con, query)
  msg('done.')
}


