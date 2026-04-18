FROM rocker/r-ver:4.4.1

# Librerías del sistema necesarias
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Instalar paquetes R desde CRAN (pero optimizado)
RUN R -e "install.packages(c('plumber','jsonlite','randomForest','recipes','tibble'), repos='https://cloud.r-project.org')"

WORKDIR /app
COPY . /app

EXPOSE 10000

CMD ["Rscript", "run.R"]
