FROM rocker/r-ver:4.4.1

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    r-cran-plumber \
    r-cran-recipes \
    r-cran-tibble \
    r-cran-jsonlite \
    r-cran-randomforest \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

EXPOSE 10000

CMD ["Rscript", "run.R"]
