packages <- c("plumber", "tidymodels", "recipes", "tibble")

for (p in packages) {
  if (!require(p, character.only = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
    library(p, character.only = TRUE)
  }
}

tryCatch({
  pr <- plumb("plumber_precio_casa.R")

  port <- as.numeric(Sys.getenv("PORT", "10000"))

  pr$run(
    host = "0.0.0.0",
    port = port
  )
}, error = function(e) {
  message("ERROR DETECTADO EN PRODUCCION:")
  message(conditionMessage(e))
  quit(status = 1)
})
