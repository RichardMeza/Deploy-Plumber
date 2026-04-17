library(tidymodels)
library(plumber)
library(caret)
library(jsonlite)
library(ggpubr)
library(recipes)
library(readr)
library(conflicted)
conflict_prefer("filter", "dplyr")
#--------------------------------------------------
# Read in model 
#--------------------------------------------------
setwd("C:/Users/armez/Documents/plumber/ngrok-v3-stable-windows-amd64")
model <- readr::read_rds("./modelo_precio_rf.rds")
summary(model)
transformer_var <- readr::read_rds("./transformer_var.rds")

new_df <- data.frame(precio_terreno=4, metros_habitables=4,
                       banios=5, antiguedad=6, metros_totales=7,
                       dormitorios=8)
trans_df <- data.frame(bake(transformer_var, new_data = new_df))
predict(model, trans_df)

#* @apiTitle Prediccion del precio de la casa

#* Conectar a la api
#* @get /connection-status

function(){
  list(status = "Conexion exitosa a la API del precio de la casa", 
       time = Sys.time(),
       username = Sys.getenv("USERNAME"))
}

#* Predecir el precio de una casa
#* @param precio_terreno precio del terreno
#* @param metros_habitables metros habitables
#* @param banios cantidad de banios
#* @param antiguedad antiguedad de la casa
#* @param metros_totales metros de la casa
#* @param dormitorios cantidad de dormitores
#* @get /predict

function(precio_terreno, metros_habitables,banios,
         antiguedad, metros_totales, dormitorios){
  new_df <- tibble(precio_terreno = as.numeric(precio_terreno),
                   metros_habitables = as.numeric(metros_habitables),
                   banios = as.numeric(banios), 
                   antiguedad = as.numeric(antiguedad),
                   metros_totales = as.numeric(metros_totales),
                   dormitorios = as.numeric(dormitorios))
  trans_df <- tibble(bake(transformer_var, new_data = new_df))
  predict(model, new_data =trans_df)
}

