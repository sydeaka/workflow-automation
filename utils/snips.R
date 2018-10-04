id_top_models = ids[1:5]
cat('Saving models:\n')
for (id in id_top_models) {
  cat(id, '\n')
  model = h2o.getModel(id)
  h2o.saveModel(object=model, path='./model_results', force=T)
}




## GBM Grid Search
# Search criteria
criteria = list(strategy = "RandomDiscrete", max_runtime_secs = 360)

# GBM hyperparamters
gbm_params1 <- list(learn_rate = seq(0.01, 0.1, .01),
                    max_depth = 5:9,
                    sample_rate = c(0.8, 1.0),
                    col_sample_rate = seq(0.5, 1.0, 0.1),
                    ntrees=500:2000)

# Train and validate a cartesian grid of GBMs
gbm_grid1 <- h2o.grid("gbm", x = pred_names, y = outcome,
                      grid_id = "gbm_grid1",
                      training_frame = h2o_train,
                      validation_frame = h2o_valid,
                      seed = 1,
                      hyper_params = gbm_params1,
                      search_criteria = criteria
)

# Get the grid results, sorted by validation AUC
gbm_gridperf1 <- h2o.getGrid(grid_id = "gbm_grid1",
                             sort_by = "auc",
                             decreasing = TRUE)
print(gbm_gridperf1)

# Grab the top GBM model, chosen by validation AUC
best_gbm1 <- h2o.getModel(gbm_gridperf1@model_ids[[1]])

# Now let's evaluate the model performance on a test set
# so we get an honest estimate of top model performance
best_gbm_perf1 <- h2o.performance(model = best_gbm1,
                                  newdata = test)
h2o.auc(best_gbm_perf1)  # 0.7781932

# Look at the hyperparamters for the best model
print(best_gbm1@model[["model_summary"]])

# GBM hyperparamters (bigger grid than above)
gbm_params2 <- list(learn_rate = seq(0.01, 0.1, 0.01),
                    max_depth = seq(2, 10, 1),
                    sample_rate = seq(0.5, 1.0, 0.1),
                    col_sample_rate = seq(0.1, 1.0, 0.1))
search_criteria <- list(strategy = "RandomDiscrete", max_models = 100, seed = 1)

# Train and validate a random grid of GBMs
gbm_grid2 <- h2o.grid("gbm", x = pred_names, y = outcome,
                      grid_id = "gbm_grid2",
                      training_frame = h2o_train,
                      validation_frame = h2o_valid,
                      ntrees = 1000,
                      seed = 1,
                      hyper_params = gbm_params2,
                      search_criteria = search_criteria)

gbm_gridperf2 <- h2o.getGrid(grid_id = "gbm_grid2",
                             sort_by = "auc",
                             decreasing = TRUE)
print(gbm_gridperf2)







explainer  <- lime(dat_train, top_model, n_bins = 5)
nsamples <- 4
explanation_aml <- explain(dat_valid[1:nsamples,], explainer, labels = c("yes"), 
                           kernel_width = 3, #feature_select = "highest_weights",
                           n_permutations = 5000,
                           #dist_fun = "manhattan",
                           n_features = 10, 
                           feature_select = "lasso_path")


plot_features(explanation_aml)

p1 <- plot_features(explanation_aml, ncol = 1) + ggtitle("aml")
p2 <- plot_explanations(explanation_aml)
gridExtra::grid.arrange(p1, ncol = 1)
gridExtra::grid.arrange(p2, ncol = 1)
