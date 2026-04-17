library(tidymodels)
library(ggpubr)
library(ggplot2)
library(reshape2)
library(mosaicData)
library(doParallel)
library(conflicted)
library(skimr)

conflict_prefer("spec", "yardstick")
conflict_prefer("rmse", "yardstick")
conflict_prefer("melt", "reshape2")
conflict_prefer("filter", "dplyr")
data("SaratogaHouses", package = "mosaicData")
datos <- SaratogaHouses
head(datos)
# Se renombran las columnas para que sean más descriptivas
colnames(datos) <- c("precio", "metros_totales", "antiguedad", "precio_terreno",
                     "metros_habitables", "universitarios",
                     "dormitorios", "chimenea", "banios", "habitaciones",
                     "calefaccion", "consumo_calefacion", "desague",
                     "vistas_lago","nueva_construccion", "aire_acondicionado")

head(datos)
skim(datos)

#------------------------------------------------------------------#
#                  Selección de variables                  #
#------------------------------------------------------------------#
# Selección de variables
# ----------------------
start <- Sys.time()  # Para calcular el tiempo de ejecución
doParallel::registerDoParallel(cores = parallel::detectCores() - 1) # Nucleos
set.seed(2000)
results <- rfe(precio ~ ., data = datos, sizes=c(1:15),
               rfeControl=rfeControl(functions=rfFuncs, method="cv", number=5))

Sys.time() - start
doParallel::stopImplicitCluster()
# summarize the results
results
# list the chosen features
predictors(results)
# plot the results
plot(results, type=c("g", "o"))

importance <- varImp(results, scale=FALSE)
# summarize importance
print(importance)

# Conjunto de datos final
# -----------------------
df <- datos1 %>% select(precio,precio_terreno,metros_habitables,banios,antiguedad,
                        metros_totales,dormitorios)

#------------------------------------------------------------------#
#                           FORMULACIÓN DE MODELOS                 #
#------------------------------------------------------------------#

# Paso 1: datos train y test
# ==========================
set.seed(2000)
split_inicial <- initial_split(data=df, prop = 0.8, strata = precio)

train_set <- training(split_inicial)
dim(train_set)

test_set  <- testing(split_inicial)
dim(test_set)

# Paso 2: preprocesamiento de datos
# =================================
prepr <- recipe(formula = precio ~ ., data = train_set) %>%
  step_naomit(all_predictors()) %>%
  step_nzv(all_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_dummy(all_predictors(), -all_numeric(), one_hot = F)

# Paso 3: aprender las transformaciones y aplicar al train y test
# ===============================================================
# Se aprende del objeto recipe
transformer_fit <- prep(prepr)

df_train_prep <- bake(transformer_fit, new_data = train_set)
df_test_prep  <- bake(transformer_fit, new_data = test_set)
glimpse(df_train_prep)
super_model$preproc
# Paso 4: Seleccionando los datos para validación cruzada
# ===============================================================
set.seed(2000)
cv_folds <- vfold_cv(data = train_set, v = 4, strata  = precio)

# Paso 5: Formulación de algoritmos
# ==================================================================
#------------------------------------------------------------------#
#                         RANDOM FOREST                            #
#------------------------------------------------------------------#
mod_rf <- rand_forest( mode = "regression",
                       min_n      = tune(),
                       trees      = tune(),) %>% 
  set_engine(engine = "randomForest")

# Flujo de trabajo
wfw_rf <- workflow() %>% add_recipe(prepr) %>% add_model(mod_rf)

start <- Sys.time()  # Para calcular el tiempo de ejecución
doParallel::registerDoParallel(cores = parallel::detectCores() - 1) # Nucleos

# Tuning
# -------------------
set.seed(2000)
grid_rf <- tune_grid(object = wfw_rf,
                     resamples    = cv_folds,
                     metrics = metric_set(rmse, mape, rsq),
                     control = control_grid(save_pred = T, verbose = T),
                     grid         = 30 )
Sys.time() - start
doParallel::stopImplicitCluster()

# resultados de la Validación cruzada
# --------------------------------------------

# Selección del modelo final
# --------------------------
mod_rf_fin <- finalize_model(x = mod_rf, 
              parameters = select_best(grid_rf, metric = "rmse")) %>%
              fit(precio ~ ., data = df_train_prep)

# Predicciones
# ------------
pred_rf <- mod_rf_fin %>% predict( new_data = df_test_prep) %>% 
  bind_cols(df_test_prep %>% select(precio))
pred_rf

eval_metrics <- metric_set(rmse, mape, rsq)
metric_rf <- eval_metrics(pred_rf, truth = precio, estimate = .pred) %>% select(-2)
metric_rf

#------------------------------
# saveRDS(mod_rf_fin, "./modelo_precio_rf.rds")
# saveRDS(transformer_fit, "./transformer_var.rds")

