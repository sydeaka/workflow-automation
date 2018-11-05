#!/usr/bin/env Rscript

msg <- function(u) cat('\n', u, '\n')

## Set session parameters
msg('Set session parameters')
if (interactive()) {
  year <- 2016
  quarter <- 2
  Gmail_name_from <- 'Watson, Sydeaka'
  Gmail_address_from <- 'sydeakawatson@gmail.com'
  email_address_to <- 'korelasidata@gmail.com'
} else {
  ## Read in parameters passed in as arguments
  args <- commandArgs(trailingOnly=TRUE); #print(args)
  year <- args[1]; #msg(year)
  quarter <- args[2]; #msg(quarter)
  Gmail_name_from <- args[3]; #msg(Gmail_name_from)
  Gmail_address_from <- args[4]; #msg(Gmail_address_from)
  email_address_to <- args[5]; #msg(email_address_to)
}


## Read in function that handles version control (Git)
source('utils/git.R')

## Commit message
commit_message <- paste0('Analysis of ', year, ' Q', quarter, ' Lending Club dataset')

## Check code in to Github repo
git(git_name=Gmail_name_from, git_email=Gmail_address_from, commit_message=commit_message) 
