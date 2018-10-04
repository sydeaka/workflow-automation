
## Set session parameters
if (interactive()) {
  year = 2017
  quarter = 2
  work_dir='/Users/sw659h/Documents/training/mysql'
} else {
  ## Read in parameters passed in as arguments
  args = commandArgs(trailingOnly=TRUE)
  year = args[1]
  quarter = args[2]
  work_dir = args[3]
}

## Container to hold objects/parameters to be saved for reporting
saved_objects = list()
saved_objects$parameters = list()
saved_objects$datasets = list()
saved_objects$automl = list()


## Set working directory, and set additional parameters
setwd(work_dir)
run_time = 180
saved_objects$parameters$run_time = run_time

## Load libraries
library(h2o)
library(lime)
library(caret)

## Function to Exit R session with informative message printed to console on exit
exitR = function(message_string) {
  cat(message_string, '\nExiting R session.\n')
  q()
}

## Look for dataset and data types files
data_file = paste('data/modeling_data/modeling_dataset_', year, '_Q', quarter, '.csv', sep='')
dtypes_file=paste('data/modeling_data/modeling_datatypes_', year, '_Q', quarter, '.csv', sep='')
if (!file.exists(data_file)) exitR(paste(data_file, 'does not exist.'))
if (!file.exists(dtypes_file)) exitR(paste(dtypes_file, 'does not exist.'))
saved_objects$parameters$data_file = data_file
saved_objects$parameters$dtypes_file = dtypes_file
dtypes_df = read.csv(dtypes_file, stringsAsFactors=F)
dtypes = dtypes_df$dtype
names(dtypes) = dtypes_df$field_name

## Use data.table package to leverage fread utility for fast-load of csv file if available
## Otherwise, use read.csv
if ('data.table' %in% installed.packages()) {
  dat = data.table::fread(data_file, colClasses=dtypes, data.table=F)
} else {
  dat = read.csv(data_file, colClasses=dtypes)
}

## Filter for lower grade loans for debt consolidation
#dat = droplevels(subset(dat, grade %in% c('E', 'F', 'G')))
dat = droplevels(subset(dat, purpose=='debt_consolidation'))



## Create outcome
## 0 if current or fully paid. 1 if late or charged off
outcome = 'late_or_chargeoff'
saved_objects$parameters$outcome = outcome
dat[,outcome] = factor(ifelse(dat$loan_status %in% c('Current', 'Fully Paid') == T, 'no', 'yes'))
dat$loan_status = NULL
saved_objects$datasets$dat = dat


## Print outcome distribution
table(dat[,outcome]) / nrow(dat) * 100
#table(dat[,'loan_status']) / nrow(dat) * 100


## Split data into training/testing/validation sets
set.seed(998)
id_train <- createDataPartition(dat[,outcome], p = .80, list = FALSE)
dat_train <- dat[ id_train,]
dat_test  <- dat[-id_train,]
id_train <- createDataPartition(dat_train[,outcome], p = .75, list = FALSE)
dat_valid  <- dat_train[-id_train,]
dat_train <- dat_train[ id_train,]
sapply(list(dat_train, dat_test, dat_valid), nrow) / nrow(dat)

saved_objects$datasets$partitions = list()
saved_objects$datasets$partitions$dat_train = dat_train
saved_objects$datasets$partitions$dat_test = dat_test
saved_objects$datasets$partitions$dat_valid = dat_valid

## Initialize h2o
h2o.init()

# Create h2o dataframes
h2o_train = as.h2o(dat_train)
h2o_test = as.h2o(dat_test)
h2o_valid = as.h2o(dat_valid)
pred_names = setdiff(names(h2o_train), outcome)
saved_objects$parameters$pred_names = pred_names


## AutoML
automl_seed = 547
saved_objects$automl$automl_seed = automl_seed
mod_aml = h2o.automl(x=pred_names, y=outcome, training_frame=h2o_train, validation_frame=h2o_valid, 
           max_runtime_secs=run_time, exclude_algos='GLM', 
           seed=automl_seed, balance_classes=T)

leaderboard = as.data.frame(mod_aml@leaderboard); head(leaderboard,10)
saved_objects$automl$leaderboard = leaderboard
ids = leaderboard$model_id
id_top_gbm = ids[startsWith(ids, 'GBM') == T][1]
top_gbm = h2o.getModel(id_top_gbm)
top_model = mod_aml@leader



confusionf = function(mod) {
  perf = list(
  h2o.performance(mod, train=T),
  h2o.performance(mod, valid=T),
  h2o.performance(mod, xval=T))
  confusion = lapply(perf, h2o.confusionMatrix)
  names(confusion) = c('train', 'valid', 'xval')
  return(confusion)
}

saved_objects$automl$confusion = list()
saved_objects$automl$confusion$top_model = confusionf(top_model)
saved_objects$automl$confusion$top_gbbm = confusionf(top_gbm)


saved_objects$automl$varimp = as.data.frame(h2o.varimp(top_gbm))


## Clear model results folder
cmd = "
rm -rf ./model_results/*
mkdir ./model_results/top_model
mkdir ./model_results/top_gbm
"
system(cmd)

## Save models
h2o.saveModel(top_gbm, path='model_results/top_gbm/', force=T)
h2o.saveModel(top_model, path='model_results/top_model/', force=T)

## Explanation of predictions for a few random samples from the validation set
explainer  <- lime(dat_train, top_model, n_bins = 5)
nsamples <- 4
id_select = sample(1:nrow(dat_valid), nsamples)
explanation_aml <- explain(dat_valid[id_select,], explainer, labels = c("yes"), 
                           kernel_width = 3, #feature_select = "highest_weights",
                           n_permutations = 5000,
                           #dist_fun = "manhattan",
                           n_features = 5, 
                           feature_select = "lasso_path")

saved_objects$lime = list()
saved_objects$lime$explainer = explainer
saved_objects$lime$explanation_aml = explanation_aml

## Save objects to disk
save(saved_objects, file='model_results/saved_objects.RData')

h2o.shutdown(F)

