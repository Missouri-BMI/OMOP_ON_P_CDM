FROM apache/airflow:2.10.0-python3.12

USER root

RUN apt-get update && \
    apt-get install -y \
        zip \
        unzip \
        r-base \
        r-base-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
        libssl-dev \
        wget \
        java-common && \
    apt-get clean

# Install Amazon Corretto 8 (Java 1.8)
RUN wget -O corretto-8.deb https://corretto.aws/downloads/latest/amazon-corretto-8-x64-linux-jdk.deb && \
    dpkg -i corretto-8.deb && \
    rm corretto-8.deb

# Set Java environment variables for Amazon Corretto 8
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-amazon-corretto
ENV PATH=$JAVA_HOME/bin:$PATH

# Run R CMD javareconf to configure Java with R
RUN R CMD javareconf

# Fix permissions for R package installations
RUN chmod -R 777 /usr/local/lib/R/site-library

# Install R packages required for OHDSI tools
RUN R -e "install.packages('rJava', repos='http://cran.rstudio.com/');"
RUN R -e "install.packages('remotes', repos='http://cran.rstudio.com/');"
RUN R -e "remotes::install_github('OHDSI/SqlRender');"
RUN R -e "install.packages('DatabaseConnector', repos='http://cran.rstudio.com/');"
RUN R -e "remotes::install_github('OHDSI/Achilles');"
# RUN R -e "install.packages('pak', repos='http://cran.rstudio.com/');"
# RUN R -e "pak::pak('keyring');"

# Switch back to airflow user
USER airflow

# Install Python dependencies
ADD requirements.txt .
RUN pip install apache-airflow==${AIRFLOW_VERSION} -r requirements.txt
