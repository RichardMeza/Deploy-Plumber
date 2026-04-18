library(plumber)
library(recipes)
library(tibble)

model <- readRDS("modelo_precio_rf.rds")
transformer_var <- readRDS("transformer_var.rds")

#* @apiTitle Prediccion del precio de la casa

#* @get /connection-status
function() {
  list(
    status = "Conexion exitosa a la API del precio de la casa",
    time = Sys.time()
  )
}

#* @get /predict
#* @param precio_terreno
#* @param metros_habitables
#* @param banios
#* @param antiguedad
#* @param metros_totales
#* @param dormitorios
function(precio_terreno, metros_habitables, banios,
         antiguedad, metros_totales, dormitorios) {

  new_df <- tibble(
    precio_terreno = as.numeric(precio_terreno),
    metros_habitables = as.numeric(metros_habitables),
    banios = as.numeric(banios),
    antiguedad = as.numeric(antiguedad),
    metros_totales = as.numeric(metros_totales),
    dormitorios = as.numeric(dormitorios)
  )

  trans_df <- bake(transformer_var, new_data = new_df)
  pred <- predict(model, new_data = trans_df)

  list(prediccion = as.numeric(pred$.pred))
}
