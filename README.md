# PCORnet CDM to OMOP CDM Harmonization
This repository contains Snowflake source code to convert PCORnet CDM (Common Data Model) to OMOP CDM (Observational Medical Outcomes Partnership Common Data Model).

## Overview
The OMOP on PCORnet CDM Converter is a set of Snowflake SQL scripts designed to transform data from the PCORnet CDM format to the OMOP CDM format. This conversion allows for broader interoperability and standardization of healthcare data, enabling more comprehensive analyses and research.

## Usage of Makefile

### OMOP_ON_PCORNET_CDM

The `Makefile` in this repository provides several commands to streamline the setup and management of the OMOP on PCORnet CDM environment. Below are the available targets:

- **Build Stack**  
    The `make build-stack` target checks for the presence of the `docker-compose.yaml` file. If it doesn't exist, it downloads the file from the official Apache Airflow documentation.

- **Start Airflow Services**  
    The `make run-airflow` target starts all Airflow services using Docker Compose.

- **Launch Jupyter Lab**  
    The `make run-jupyter` target launches Jupyter Lab with root access and no browser.

### OMOP_SERVERLESS

The `Makefile` also includes commands for managing serverless deployments and Docker images for Atlas and WebAPI. Below are the key targets:

- **AWS Login**  
    Use `make aws-login-dev` or `aws-login-prod` to log in to AWS using the appropriate profile.

- **Docker Login**  
    Use `make docker-login-dev` or `docker-login-prod` to authenticate Docker with AWS Elastic Container Registry (ECR).

- **Build Docker Images for Atlas**  
    Use `make atlas-dev` or `atlas-prod` to build Docker images for Atlas with the appropriate WebAPI URL.

- **Build Docker Images for WebAPI**  
    Use `make webapi-dev` or `webapi-prod` to build Docker images for WebAPI with the specified environment (dev or prod).
