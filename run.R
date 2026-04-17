library(plumber)

pr <- plumb("plumber_precio_casa.R")

pr$run(
  host = "0.0.0.0",
  port = as.numeric(Sys.getenv("PORT"))
)