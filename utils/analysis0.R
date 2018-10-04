

if (interactive()) {
  year = 2018
  quarter = 1
  work_dir='/Users/sw659h/Documents/training/mysql'
} else {
  ## Read in parameters passed in as arguments
  args = commandArgs(trailingOnly=TRUE)
  year = args[1]
  quarter = args[2]
  work_dir = args[3]
}

setwd(work_dir)
run_time = 60

## Load libraries
library(caret)
library(gbm)
library(parallelMap)
library(doParallel)

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

dat = droplevels(subset(dat, grade %in% c('D', 'E', 'F', 'G')))
dat = droplevels(subset(dat, purpose=='debt_consolidation'))
dat0 = dat


f = function(var_in, var_out='late_or_chargeoff') {
  form = as.formula(paste('~', var_in, '+', var_out))
  tab = xtabs(form, data=dat)
  out = data.frame(no=paste(tab[,1], '(', round(tab[,1] / apply(tab, 1, sum) * 100,2) , '%)'),
                   yes=paste(tab[,2], '(', round(tab[,2] / apply(tab, 1, sum) * 100,2), '%)'))
  rownames(out) = names(tab[,1])
  cat(var_in, '\n')
  print(out)
}

dat$late_or_chargeoff = factor(ifelse(dat$loan_status %in% c('Current', 'Fully Paid') == T, 'no', 'yes'))
f('grade')
f('verification_status')
f('home_ownership')
f('purpose')
dat$late_or_chargeoff = NULL



## Select outcome
classification = T

if (classification==T) {
  dat = dat0
  ## Outcome, 0 if current or fully paid. 1 if late or charged off
  outcome = 'late_or_chargeoff'
  dat$late_or_chargeoff = factor(ifelse(dat$loan_status %in% c('Current', 'Fully Paid') == T, 'no', 'yes'))
  dat$loan_status = NULL
  
  # table(dat[,outcome]) / nrow(dat) * 100
} else {
  dat = dat0
  outcome = 'int_rate'
  dat$loan_status = NULL
  dat$grade = NULL
  dat$purpose=NULL
}

## Split data into training/testing
set.seed(998)
id_train <- createDataPartition(dat[,outcome], p = .80, list = FALSE)
dat_train <- dat[ id_train,]
dat_test  <- dat[-id_train,]
id_train <- createDataPartition(dat_train[,outcome], p = .75, list = FALSE)
dat_valid  <- dat_train[-id_train,]
dat_train <- dat_train[ id_train,]
sapply(list(dat_train, dat_test, dat_valid), nrow) / nrow(dat)


# h2o
library(h2o)
h2o.init()

h2o_train = as.h2o(dat_train)
h2o_test = as.h2o(dat_test)
h2o_valid = as.h2o(dat_valid)
pred_names = setdiff(names(h2o_train), outcome)

mod_aml = h2o.automl(x=pred_names, y=outcome, training_frame=h2o_train, leaderboard_frame=h2o_valid, 
           max_runtime_secs=run_time, balance_classes=F)

mod_aml@leaderboard
ids = as.data.frame(mod_aml@leaderboard)$model_id
id_top_model = ids[startsWith(ids, 'Stacked') == F & startsWith(ids, 'GLM') == F][1]
top_model = h2o.getModel(id_top_model)
mod = mod_aml@leader
h2o.confusionMatrix(mod)

perf = list(
h2o.performance(mod, train=T),
h2o.performance(mod, valid=T),
h2o.performance(mod, xval=T))
lapply(perf, h2o.confusionMatrix)

h2o.varimp(top_model)


ls()








nfolds = 2; ncores = min(5, nfolds)
fitControl <- trainControl(
  method = "cv" ## k-fold CV
  , number = nfolds
  , classProbs = TRUE
  #, sampling = 'smote'
  )


set.seed(825)
preds = base::setdiff(colnames(dat), outcome)
form = as.formula(paste(outcome, '~ .'))

## Start cluster
#parallelStartSocket(ncores)
cl <- makePSOCKcluster(ncores)
registerDoParallel(cl)

tm = system.time({gbmFit1 <- train(
  form, 
  data = dat_train, 
  method = "gbm", 
  trControl = fitControl,
  verbose = FALSE)})
print(tm)

gbmFit1
summary(gbmFit1)


## Stop cluster
#parallelStop()
stopCluster(cl)
