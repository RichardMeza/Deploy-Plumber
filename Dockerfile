FROM rocker/r-ver:4.4.1

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libcairo2-dev \
    libxt-dev \
    libfontconfig1-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages('plumber', repos='https://cloud.r-project.org')"
RUN R -e "install.packages('jsonlite', repos='https://cloud.r-project.org')"
RUN R -e "install.packages('randomForest', repos='https://cloud.r-project.org')"
RUN R -e "install.packages('caret', repos='https://cloud.r-project.org')"

WORKDIR /app

COPY . /app

EXPOSE 10000

CMD ["Rscript", "run.R"]
