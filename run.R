library(plumber)
library(recipes)
library(tibble)

pr <- plumb("plumber_precio_casa.R")

port <- as.numeric(Sys.getenv("PORT", "10000"))

pr$run(
  host = "0.0.0.0",
  port = port
)
