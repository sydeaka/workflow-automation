#!/usr/bin/env Rscript

## Set session parameters
if (interactive()) {
  year <- 2016
  quarter <- 4
  work_dir <- '~/Documents/training/mysql/repos/workflow-automation'
} else {
  ## Read in parameters passed in as arguments
  args <- commandArgs(trailingOnly=TRUE)
  year <- args[1]
  quarter <- args[2]
  work_dir <- args[3]
}

## Container to hold objects/parameters to be saved for reporting
saved_objects <- list()
saved_objects$parameters <- list()
saved_objects$datasets <- list()
saved_objects$automl <- list()
saved_objects$descriptives <- list()

## Set working directory, and set additional parameters
setwd(work_dir)
run_time <- 150
run_min <- round(run_time/60 ,3)
saved_objects$parameters$run_time <- run_time
saved_objects$parameters$year <- year
saved_objects$parameters$quarter <- quarter

## Load libraries
suppressMessages(library(h2o))
suppressMessages(library(lime))
suppressMessages(library(caret))

## Function to Exit R session with informative message printed to console on exit
exitR <- function(message_string, hard_exit = F) {
  if (hard_exit == T) {
    cat(message_string, '\nExiting R session.\n')
    q()
  } else {
    stop(message_string)
  }
}

## Table, showing NA's if any
tablef <- function(u) {
  tab <- table(u, useNA='ifany')
  names(tab)[names(tab) == ''] <- 'BLANK'
  return(tab)
}

msg <- function(u) cat('\n', u, '\n')

## Get confusion matrices for training, validation, and testing sets
confusionf <- function(mod) {
  perf <- list(
    h2o.performance(mod, train=T),
    h2o.performance(mod, valid=T),
    h2o.performance(mod, xval=T))
  confusion <- lapply(perf, h2o.confusionMatrix)
  names(confusion) <- c('train', 'valid', 'xval')
  return(confusion)
}



## Look for dataset and data types files
msg('Look for dataset and data types files')
data_file <- paste('data/modeling_data/modeling_dataset_', year, '_Q', quarter, '.csv', sep='')
dtypes_file <- paste('data/modeling_data/modeling_datatypes_', year, '_Q', quarter, '.csv', sep='')
if (!file.exists(data_file)) exitR(paste(data_file, 'does not exist.'))
if (!file.exists(dtypes_file)) exitR(paste(dtypes_file, 'does not exist.'))
saved_objects$parameters$data_file <- data_file
saved_objects$parameters$dtypes_file <- dtypes_file
dtypes_df <- read.csv(dtypes_file, stringsAsFactors=F)
dtypes <- dtypes_df$dtype
names(dtypes) <- dtypes_df$field_name

## Use data.table package to leverage fread utility for fast-load of csv file if available
## Otherwise, use read.csv
msg('Read in csv file')
if ('data.table' %in% installed.packages()) {
  dat <- data.table::fread(data_file, colClasses=dtypes, data.table=F)
} else {
  dat <- read.csv(data_file, colClasses=dtypes)
}

## Descriptive summaries for full dataset
msg('Prepare descriptive summaries for full dataset')
num_records <- nrow(dat)
miss_dat_cnt <- apply(dat, 2, function(u) length(which(is.na(u))))
miss_dat_pct <- round(miss_dat_cnt / num_records * 100)
cnt_by_purpose <- tablef(dat$purpose)
dsummary <- data.frame(data_types=dtypes, miss_dat_cnt=miss_dat_cnt, miss_dat_pct=miss_dat_pct)

saved_objects$descriptives$overall=list(
  num_records=num_records
  , miss_dat_cnt=miss_dat_cnt
  , miss_dat_pct=miss_dat_pct
  , cnt_by_purpose=cnt_by_purpose
  , dsummary=dsummary
  )
rm(num_records,miss_dat_cnt,miss_dat_pct)

## Filter for debt consolidation
msg('Filter for debt consolidation')
#dat <- droplevels(subset(dat, grade %in% c('E', 'F', 'G')))
dat <- droplevels(subset(dat, purpose=='debt_consolidation'))


## Create outcome
## 0 if current or fully paid. 1 if late or charged off
msg('Create outcome')
outcome <- 'late_or_chargeoff'
saved_objects$parameters$outcome <- outcome
dat[,outcome] <- factor(ifelse(dat$loan_status %in% c('Current', 'Fully Paid') == T, 'no', 'yes'))
dat$loan_status <- NULL
saved_objects$datasets$dat <- dat

num_records <- nrow(dat)
outcome_dist <- table(dat[,outcome]) / nrow(dat) * 100
saved_objects$descriptives$analysis_subset <- list(num_records=num_records,outcome_dist=outcome_dist)

cat('Outcome distribution (%):\n')
print(outcome_dist)


## Remove columns with zero variance
id_rm <- which(sapply(dat, function(u) length(unique(u)) <= 1))
if (length(id_rm) > 0) {
  msg("The following columns have no variance and will be removed:")
  print(colnames(dat)[id_rm])
  dat <- dat[,-id_rm]
}


## Figures
msg('Figures')
png('plots/plot_purpose.png', width=480*1, height=480*1); par(cex.lab=0.85, mar=c(5,10,4,2))
barplot(sort(cnt_by_purpose), horiz=T, las=1, main='Number of loans, by purpose')
invisible(dev.off())
png('plots/plot_grade.png', width=480*1, height=480*1); par(cex.lab=0.85)
barplot(tablef(dat$grade), horiz=F, las=1, main='Number of loans, by grade')
invisible(dev.off())
png('plots/plot_loan_amnt_by_grade.png', width=480*1, height=480*1); par(cex.lab=0.85)
boxplot(loan_amnt ~ grade, data=dat, horizontal=F, las=1, main='Loan amounts ($) by grade')
invisible(dev.off())
png('plots/plot_int_rate_by_grade.png', width=480*1, height=480*1); par(cex.lab=0.85)
boxplot(int_rate ~ grade, data=dat, horizontal=F, las=1, main='Interest rate (%) by grade')
invisible(dev.off())




## Split data into training/testing/validation sets
msg('Split data into training/testing/validation sets')
set.seed(998)
id_train <- createDataPartition(dat[,outcome], p = .80, list = FALSE)
dat_train <- dat[ id_train,]
dat_test  <- dat[-id_train,]
id_train <- createDataPartition(dat_train[,outcome], p = .75, list = FALSE)
dat_valid  <- dat_train[-id_train,]
dat_train <- dat_train[ id_train,]
data_splits_pct = round(sapply(list(train=dat_train, test=dat_test, valid=dat_valid), nrow) / nrow(dat) * 100,2)
saved_objects$parameters$data_splits_pct = data_splits_pct
  
saved_objects$datasets$partitions <- list()
saved_objects$datasets$partitions$dat_train <- dat_train
saved_objects$datasets$partitions$dat_test <- dat_test
saved_objects$datasets$partitions$dat_valid <- dat_valid

## Initialize h2o
msg('Initialize h2o')
h2o.init()

# Create h2o dataframes
msg('Create h2o dataframes')
h2o_train <- as.h2o(dat_train)
h2o_test <- as.h2o(dat_test)
h2o_valid <- as.h2o(dat_valid)
pred_names <- setdiff(names(h2o_train), outcome)
saved_objects$parameters$pred_names <- pred_names


## AutoML
msg(paste0('AutoML, run time = ', run_time, ' seconds (', run_min, ' minutes)'))
automl_seed <- 547
saved_objects$automl$automl_seed <- automl_seed
mod_aml <- h2o.automl(x=pred_names, y=outcome, training_frame=h2o_train, validation_frame=h2o_valid, 
           max_runtime_secs=run_time, exclude_algos='GLM', 
           seed=automl_seed, balance_classes=T)

leaderboard <- as.data.frame(mod_aml@leaderboard); head(leaderboard,10)
saved_objects$automl$leaderboard <- leaderboard
ids <- leaderboard$model_id
id_top_gbm <- ids[startsWith(ids, 'GBM') == T][1]
top_gbm <- h2o.getModel(id_top_gbm)
top_model <- mod_aml@leader




saved_objects$automl$confusion <- list()
saved_objects$automl$confusion$top_model <- confusionf(top_model)
saved_objects$automl$confusion$top_gbbm <- confusionf(top_gbm)


saved_objects$automl$varimp <- as.data.frame(h2o.varimp(top_gbm))


## Clear model results folder
cmd <- "
rm -rf ./model_results/*
mkdir ./model_results/top_model
mkdir ./model_results/top_gbm
"
system(cmd)

## Save models
msg('Save models')
h2o.saveModel(top_gbm, path='model_results/top_gbm/', force=T)
h2o.saveModel(top_model, path='model_results/top_model/', force=T)

## Explanation of predictions for a few random samples from the validation set
msg('Explanation of predictions for a few random samples from the validation set')
explainer  <- lime(dat_train, top_model, n_bins = 5)
nsamples <- 4
set.seed(123)
id_select = sample(1:nrow(dat_valid), nsamples)
explanation_aml <- explain(dat_valid[id_select,]
                           , explainer, labels = c("yes") 
                           , kernel_width = 3
                           , n_permutations = 5000
                           , n_features = 5
                           , feature_select = "highest_weights"
                           )



png('plots/plot_lime.png', width=480*2, height=480*2); par(cex.lab=0.85)
plot_features(explanation_aml)
invisible(dev.off())

## Save objects to disk
msg('Save objects to disk')
save(saved_objects, file='model_results/saved_objects.RData')

h2o.shutdown(F)

