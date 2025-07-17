# Base Python
FROM rocker/shiny

# Install Prequisites
RUN apt-get update && apt-get install -y build-essential cmake gfortran libcurl4-openssl-dev libssl-dev libxml2-dev python3-dev python3-pip python3-venv

# Install R packages
RUN R -e "install.packages(c('reticulate', 'bslib', 'bsicons', 'readr', 'tibble', 'htmltools'))"

# Push Data and scripts
RUN mkdir grantsAI
RUN mkdir grantsAI/data
COPY data/ grantsAI/data/
RUN mkdir grantsAI/www
COPY www/ grantsAI/www/
COPY 0_Environment.R 1_GetData.R 2_PrepareEnvironment.R 3_CreateEmbeddings.R grantsAI/
WORKDIR grantsAI

# Prepare Data
RUN Rscript 1_GetData.R

# Prepare Environment
RUN Rscript 2_PrepareEnvironment.R

# Create Embeddings
RUN Rscript 3_CreateEmbeddings.R

# Push App
COPY helpers.R ui.R server.R ./

# Expose Port
EXPOSE 8180

# Run App
CMD R -e "shiny::runApp(host='0.0.0.0',port=8180)"

# docker build --progress=plain -t grantsai .
# docker run -p 4562:8180 -d --restart unless-stopped grantsai