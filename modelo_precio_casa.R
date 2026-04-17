library(tidymodels)
library(ggpubr)
library(ggplot2)
library(reshape2)
library(mosaicData)
library(doParallel)
library(conflicted)
library(skimr)
library(dplyr)

conflict_prefer("spec", "yardstick")
conflict_prefer("rmse", "yardstick")
conflict_prefer("melt", "reshape2")
conflict_prefer("filter", "dplyr")

data("SaratogaHouses", package = "mosaicData")
datos <- SaratogaHouses

colnames(datos) <- c("precio", "metros_totales", "antiguedad", "precio_terreno",
                     "metros_habitables", "universitarios",
                     "dormitorios", "chimenea", "banios", "habitaciones",
                     "calefaccion", "consumo_calefacion", "desague",
                     "vistas_lago","nueva_construccion", "aire_acondicionado")

df <- datos %>% 
  select(precio, precio_terreno, metros_habitables, banios,
         antiguedad, metros_totales, dormitorios)

set.seed(2000)
split_inicial <- initial_split(data = df, prop = 0.8, strata = precio)

train_set <- training(split_inicial)
test_set  <- testing(split_inicial)

prepr <- recipe(precio ~ ., data = train_set) %>%
  step_naomit(all_predictors()) %>%
  step_nzv(all_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(all_predictors(), -all_numeric(), one_hot = FALSE)

transformer_fit <- prep(prepr)

df_train_prep <- bake(transformer_fit, new_data = train_set)
df_test_prep  <- bake(transformer_fit, new_data = test_set)

set.seed(2000)
cv_folds <- vfold_cv(data = train_set, v = 4, strata = precio)

mod_rf <- rand_forest(
  mode = "regression",
  min_n = tune(),
  trees = tune()
) %>% 
  set_engine("randomForest")

wfw_rf <- workflow() %>% 
  add_recipe(prepr) %>% 
  add_model(mod_rf)

doParallel::registerDoParallel(cores = parallel::detectCores() - 1)

set.seed(2000)
grid_rf <- tune_grid(
  object = wfw_rf,
  resamples = cv_folds,
  metrics = metric_set(rmse, mape, rsq),
  control = control_grid(save_pred = TRUE, verbose = TRUE),
  grid = 30
)

doParallel::stopImplicitCluster()

mod_rf_fin <- finalize_model(
  x = mod_rf,
  parameters = select_best(grid_rf, metric = "rmse")
) %>%
  fit(precio ~ ., data = df_train_prep)

pred_rf <- mod_rf_fin %>%
  predict(new_data = df_test_prep) %>%
  bind_cols(df_test_prep %>% select(precio))

eval_metrics <- metric_set(rmse, mape, rsq)
metric_rf <- eval_metrics(pred_rf, truth = precio, estimate = .pred) %>%
  select(-2)

saveRDS(mod_rf_fin, "modelo_precio_rf.rds")
saveRDS(transformer_fit, "transformer_var.rds")
