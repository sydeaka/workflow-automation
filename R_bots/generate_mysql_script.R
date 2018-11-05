#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly=TRUE)

## Read in parameters
year <- args[1]
quarter <- args[2]



file_name <- paste("LoanStats_", year, "Q", quarter, sep='')
csv_name <- paste(file_name, ".csv", sep='')
table_name <- paste('', file_name, sep='')

## Read in utility
source("utils/create_mysql_table.R")

createMySQLTable(infile_path='data/downloads', # '/Users/sw659h/Documents/training/mysql/repos/workflow-automation/data/downloads' 
                 sql_path='data/sql', # '/Users/sw659h/Documents/training/mysql/repos/workflow-automation/data/sql'
                 infile_name=csv_name, 
                 mysql_db='lending', mysql_table_name=table_name, 
                 mysql_file_name=gsub('csv', 'sql', paste('mysql_script_', csv_name, sep='')))
